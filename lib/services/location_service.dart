import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

enum GpsStatus {
  disabled(0),
  enabled(1),
  searching(2),
  unavailable(3);

  final int value;
  const GpsStatus(this.value);
}

@pragma('vm:entry-point')
class LocationService {
  static final LocationService _instance = LocationService._internal();
  static const MethodChannel _platform = MethodChannel('location_tracker');
  static const int _maxErrorRetryAttempts = 3;

  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  Timer? _locationTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  bool _isTracking = false;
  String? _currentToken;
  String? _currentDayLogId;
  Database? _locationDatabase;

  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _serviceEnabled = false;
  bool _isConnected = true;
  static bool _isInBackground = false;

  static const int _foregroundInterval = 15;
  static const int _backgroundInterval = 30;
  static const Duration _apiTimeout = Duration(seconds: 15);
  static const String _backgroundTaskName = 'locationBackgroundTask';
  static const String _locationDatabaseName = 'locations.db';

  bool get isTracking => _isTracking;

  factory LocationService() => _instance;

  @pragma('vm:entry-point')
  LocationService._internal() {
    _initializeService();
    _setupBackgroundService();
    _setupAppLifecycle();
    _initDatabase();
  }

  // Database Methods
  Future<void> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _locationDatabaseName);

      _locationDatabase = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE locations(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              gps_status INTEGER NOT NULL,
              battery_level INTEGER,
              synced INTEGER DEFAULT 0
            )
          ''');
        },
      );
    } catch (e) {
      debugPrint('Database initialization error: $e');
    }
  }

  Future<void> _saveLocationToDatabase(Map<String, dynamic> location) async {
    if (_locationDatabase == null) return;

    try {
      await _locationDatabase!.insert('locations', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'gps_status': location['gps_status'],
        'battery_level': location['battery_percentage'],
        'synced': 0,
      });
    } catch (e) {
      debugPrint('Error saving location to database: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getUnsyncedLocations() async {
    if (_locationDatabase == null) return [];
    try {
      return await _locationDatabase!.query(
        'locations',
        where: 'synced = 0',
        orderBy: 'timestamp ASC',
      );
    } catch (e) {
      debugPrint('Error getting unsynced locations: $e');
      return [];
    }
  }

  Future<void> _markLocationsAsSynced(List<int> ids) async {
    if (_locationDatabase == null || ids.isEmpty) return;
    try {
      await _locationDatabase!.update('locations', {
        'synced': 1,
      }, where: 'id IN (${ids.join(',')})');
    } catch (e) {
      debugPrint('Error marking locations as synced: $e');
      await _logErrorToServer(
        errorType: 'DatabaseSyncError',
        errorMessage: e.toString(),
        context: 'LocationService._markLocationsAsSynced',
      );
    }
  }

  // Service Initialization
  Future<void> _initializeService() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        List<ConnectivityResult> result,
      ) {
        _isConnected = result != ConnectivityResult.none;
        if (_isConnected) _syncStoredLocations();
      }, onError: (error) => debugPrint('Connectivity error: $error'));

      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;

      await _checkAndMonitorServiceStatus();
    } catch (error) {
      debugPrint('Service initialization error: $error');
      await _logErrorToServer(
        errorType: 'ConnectivityError',
        errorMessage: error.toString(),
        context: 'LocationService._initializeService',
      );
    }
  }

  Future<void> _checkAndMonitorServiceStatus() async {
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled && _isTracking) {
      debugPrint('Location service disabled while tracking');
      await stopTracking();
    }

    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      _serviceEnabled = status == ServiceStatus.enabled;
      if (!_serviceEnabled && _isTracking) {
        debugPrint('Location service disabled while tracking');
        stopTracking();
      }
    });
  }

  // Background Service Management
  Future<void> _setupBackgroundService() async {
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(
      _backgroundTaskCallback,
      isInDebugMode: kDebugMode,
    );

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracker',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking your location in background',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.connectedDevice,
        ],
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      final token = await SharedPrefHelper.getToken();
      final dayLogId = await SharedPrefHelper.getActiveDayLogId();

      if (token == null || dayLogId == null) return Future.value(false);

      try {
        final position = await _getCurrentPositionWithTimeout();
        if (!_isValidLocation(position)) return Future.value(false);

        final locationPayload = await _createLocationPayload(
          position,
          dayLogId,
          await Battery().batteryLevel,
        );

        final response = await _sendLocationToApiWithTimeout(
          token,
          locationPayload,
        );

        return Future.value(response?.success ?? false);
      } catch (e) {
        debugPrint('Background task error: $e');
        return Future.value(false);
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.on('stopService').listen((event) => service.stopSelf());
    }

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();

    if (token == null || dayLogId == null) {
      service.stopSelf();
      return;
    }

    await _sendLocationInBackground(service, token, dayLogId);

    Timer.periodic(const Duration(seconds: _backgroundInterval), (timer) async {
      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Location Tracker",
          content: "Last update: ${DateTime.now()}",
        );
      }
      await _sendLocationInBackground(service, token, dayLogId);
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _sendLocationInBackground(
    ServiceInstance service,
    String token,
    String dayLogId,
  ) async {
    try {
      final position = await _getCurrentPositionWithTimeout();
      if (!_isValidLocation(position)) return;

      final locationPayload = await _createLocationPayload(
        position,
        dayLogId,
        await Battery().batteryLevel,
      );

      final response = await _sendLocationToApiWithTimeout(
        token,
        locationPayload,
      );

      if (response?.success != true) {
        debugPrint(
          'Background service API response indicates failure - stopping',
        );
        service.stopSelf();
      }
    } catch (e) {
      debugPrint('Background location error: $e');
    }
  }

  // Location Tracking
  Future<bool> startTracking({
    required String token,
    required String dayLogId,
  }) async {
    if (_isTracking) {
      debugPrint('Tracking already active');
      return true;
    }

    _currentToken = token;
    _currentDayLogId = dayLogId;

    if (!await _checkLocationServices()) return false;
    if (!await _checkLocationPermissions()) return false;

    _isTracking = true;
    await _syncStoredLocations();
    await _sendCurrentLocation();
    _startPeriodicLocationUpdates();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy:
            _isInBackground
                ? LocationAccuracy.bestForNavigation
                : LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (_isValidLocation(position)) {
        _sendLocationToAPI(
          _currentToken!,
          _currentDayLogId!,
          position.latitude,
          position.longitude,
        );
      }
    }, onError: (e) => debugPrint('Position update error: $e'));

    if (_isInBackground) _positionStream?.pause();
    return true;
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    debugPrint('Stopping tracking service...');
    _locationTimer?.cancel();
    _locationTimer = null;
    await _positionStream?.cancel();
    _positionStream = null;
    await _syncStoredLocations();

    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;

    try {
      // await _platform.invokeMethod('stopBackgroundService');

      if (Platform.isAndroid) {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
          await Future.delayed(const Duration(seconds: 1));
        }
        await Workmanager().cancelAll();
        await Workmanager().cancelByUniqueName(_backgroundTaskName);
      }
    } catch (e) {
      debugPrint('Error stopping services: $e');
    }
  }

  // Helper Methods
  Future<void> _sendCurrentLocation() async {
    if (!_isTracking || _currentToken == null || _currentDayLogId == null) {
      return;
    }

    try {
      final position = await _getCurrentPositionWithTimeout();
      if (!_isValidLocation(position)) return;

      await _sendLocationToAPI(
        _currentToken!,
        _currentDayLogId!,
        position.latitude,
        position.longitude,
      );
    } on TimeoutException {
      debugPrint('Location acquisition timeout');
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  static Future<Position> _getCurrentPositionWithTimeout() async {
    final locationSettings = _getPlatformSpecificSettings();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    ).timeout(const Duration(seconds: 15));

    return position;
  }

  static LocationSettings _getPlatformSpecificSettings() {
    if (Platform.isAndroid) {
      return _getAndroidSettings();
    } else {
      return _getAppleSettings();
    }
  }

  static AndroidSettings _getAndroidSettings() {
    return AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _isInBackground ? 20 : 10, // meters
      forceLocationManager: false, // Use FusedLocationProvider
      intervalDuration: const Duration(seconds: 10),
      timeLimit: const Duration(seconds: 12), // Shorter than overall timeout
      foregroundNotificationConfig:
          _isInBackground
              ? const ForegroundNotificationConfig(
                notificationText: "Tracking your location in background",
                notificationTitle: "Location Tracker",
                enableWakeLock: true,
              )
              : null,
      useMSLAltitude: true, // Use mean sea level altitude if available
    );
  }

  static AppleSettings _getAppleSettings() {
    return AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _isInBackground ? 20 : 10, // meters
      pauseLocationUpdatesAutomatically: false,
      activityType: ActivityType.fitness,
      timeLimit: const Duration(seconds: 12), // Shorter than overall timeout
      showBackgroundLocationIndicator: _isInBackground,
      allowBackgroundLocationUpdates: true,
    );
  }

  static Future<Map<String, dynamic>> _createLocationPayload(
    Position position,
    String dayLogId,
    int? batteryLevel,
  ) async {
    final gpsStatus = await _getGpsStatusGeolocator();
    return {
      "trip_id": dayLogId,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "gps_status": "${gpsStatus.value}",
      if (batteryLevel != -1) "battery_percentage": "$batteryLevel",
    };
  }

  static Future<GpsStatus> _getGpsStatusGeolocator() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return GpsStatus.disabled;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return GpsStatus.unavailable;
      }

      return GpsStatus.enabled;
    } catch (e) {
      return GpsStatus.unavailable;
    }
  }

  static Future<DayLogStoreLocationResponseModel?>
  _sendLocationToApiWithTimeout(
    String token,
    Map<String, dynamic> payload,
  ) async {
    return await BasicService()
        .postDayLogLocations(token, payload)
        .timeout(const Duration(seconds: 10));
  }

  static bool _isValidLocation(Position position) {
    if (position.accuracy > 100) {
      debugPrint('Location accuracy too low: ${position.accuracy} meters');
      return false;
    }

    if (DateTime.now().difference(position.timestamp) > Duration(minutes: 5)) {
      debugPrint('Location timestamp too old: ${position.timestamp}');
      return false;
    }

    return true;
  }

  // App Lifecycle
  Future<void> _setupAppLifecycle() async {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('AppLifecycleState: $msg');

      switch (msg) {
        case 'AppLifecycleState.inactive':
        case 'AppLifecycleState.paused':
          _isInBackground = true;
          _handleAppBackground();
          break;
        case 'AppLifecycleState.resumed':
          _isInBackground = false;
          _handleAppForegrounded();
          break;
      }
      return null;
    });
  }

  void _handleAppBackground() async {
    if (!_isTracking) return;
    debugPrint('App moved to background - adjusting location tracking');

    try {
      // await _platform.invokeMethod('startBackgroundService');

      if (Platform.isAndroid) {
        final service = FlutterBackgroundService();
        await service.startService();
        _positionStream?.pause();
        _locationTimer?.cancel();

        await Workmanager().registerPeriodicTask(
          '1',
          _backgroundTaskName,
          frequency: const Duration(minutes: 15),
          initialDelay: const Duration(seconds: 10),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
        );
        await _optimizeForBattery();
      }
    } catch (e) {
      debugPrint('Error starting background service: $e');
    }
  }

  void _handleAppForegrounded() async {
    if (!_isTracking) return;
    debugPrint('App moved to foreground - adjusting location tracking');

    try {
      // await _platform.invokeMethod('stopBackgroundService');

      if (Platform.isAndroid) {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) service.invoke('stopService');
        await Workmanager().cancelByTag('1');
      }

      _positionStream?.resume();
      _startPeriodicLocationUpdates();
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }

  // Other Methods
  Future<void> _startPeriodicLocationUpdates() async {
    _locationTimer?.cancel();
    await _optimizeForBattery();

    _locationTimer = Timer.periodic(
      Duration(
        seconds: _isInBackground ? _backgroundInterval : _foregroundInterval,
      ),
      (_) => _sendCurrentLocation(),
    );
  }

  Future<bool> _checkLocationServices() async {
    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) debugPrint('Location services disabled by user');
      return _serviceEnabled;
    } catch (e) {
      debugPrint('Location service check failed: $e');
      return false;
    }
  }

  Future<bool> _checkLocationPermissions() async {
    try {
      _permissionStatus = await Geolocator.checkPermission();
      if (_permissionStatus == LocationPermission.denied ||
          _permissionStatus == LocationPermission.deniedForever) {
        _permissionStatus = await Geolocator.requestPermission();
      }

      if (_permissionStatus == LocationPermission.denied ||
          _permissionStatus == LocationPermission.deniedForever) {
        debugPrint('Location permission denied');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Location permission check failed: $e');
      return false;
    }
  }

  Future<void> _optimizeForBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (level < 15) {
        debugPrint(
          'Low battery ($level%) - reducing location update frequency',
        );
        _locationTimer?.cancel();
        _locationTimer = Timer.periodic(
          Duration(seconds: _isInBackground ? 180 : 90),
          (_) => _sendCurrentLocation(),
        );
      }
    } catch (e) {
      debugPrint('Error checking battery level: $e');
    }
  }

  Future<void> dispose() async {
    await stopTracking();
    await _connectivitySubscription?.cancel();
    await _positionStream?.cancel();
    await _serviceStatusStream?.cancel();

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      Workmanager().cancelByTag('1');
    }

    await _locationDatabase?.close();
    _locationDatabase = null;
  }

  Future<bool> isServiceRunning() async {
    bool isTrackingActive = _isTracking;
    bool isBackgroundServiceRunning = false;

    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        isBackgroundServiceRunning = await service.isRunning();
      } catch (e) {
        debugPrint('Error checking service status: $e');
      }
    }

    return isTrackingActive || isBackgroundServiceRunning;
  }

  Future<void> _syncStoredLocations() async {
    if (!_isConnected || _currentToken == null || _currentDayLogId == null) {
      return;
    }

    final unsyncedLocations = await _getUnsyncedLocations();
    if (unsyncedLocations.isEmpty) return;

    debugPrint(
      'Found ${unsyncedLocations.length} unsynced locations - syncing',
    );

    final successfulIds = <int>[];
    const batchSize = 10;
    final batches = (unsyncedLocations.length / batchSize).ceil();

    for (var i = 0; i < batches; i++) {
      final start = i * batchSize;
      final end = (i + 1) * batchSize;
      final batch = unsyncedLocations.sublist(
        start,
        end > unsyncedLocations.length ? unsyncedLocations.length : end,
      );

      try {
        final responses = await Future.wait(
          batch.map((location) async {
            final payload = {
              "trip_id": _currentDayLogId!,
              "latitude": location['latitude'],
              "longitude": location['longitude'],
              "gps_status": location['gps_status'],
              if (location['battery_level'] != null)
                "battery_percentage": "${location['battery_level']}",
              "timestamp": location['timestamp'],
            };

            DayLogStoreLocationResponseModel? response = await BasicService()
                .postDayLogLocations(_currentToken!, payload)
                .timeout(_apiTimeout);

            return {
              'id': location['id'],
              'success': response?.success ?? false,
            };
          }),
        );

        successfulIds.addAll(
          responses
              .where((r) => r['success'] as bool)
              .map((r) => r['id'] as int),
        );

        if (responses.any((r) => !(r['success'] as bool))) {
          break;
        }
      } catch (e) {
        debugPrint('Error syncing batch $i: $e');
        await _logErrorToServer(
          errorType: 'BatchSyncProcessingError',
          errorMessage: e.toString(),
          context: 'LocationService._syncStoredLocations',
          additionalData: {'batch_index': i},
        );
        break;
      }
    }

    if (successfulIds.isNotEmpty) {
      await _markLocationsAsSynced(successfulIds);
      debugPrint('Successfully synced ${successfulIds.length} locations');
    }
  }

  Future<void> _sendLocationToAPI(
    String token,
    String dayLogId,
    double latitude,
    double longitude,
  ) async {
    int? batteryLevel;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      await _logErrorToServer(
        errorType: 'BatteryLevelError',
        errorMessage: e.toString(),
        context: 'LocationService._sendLocationToAPI',
      );
    }

    final gpsStatus = await _getGpsStatus();
    final locationPayload = {
      "trip_id": dayLogId,
      "latitude": latitude,
      "longitude": longitude,
      "gps_status": "${gpsStatus.value}",
      if (batteryLevel != null) "battery_percentage": "$batteryLevel",
    };

    await _saveLocationToDatabase(locationPayload);

    if (!_isConnected) {
      debugPrint(
        'Offline - location saved to database (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
      return;
    }

    try {
      final response = await BasicService()
          .postDayLogLocations(token, locationPayload)
          .timeout(_apiTimeout);

      if (response == null ||
          response.success == false ||
          response.errors != null ||
          response.data == null) {
        debugPrint('API response indicates failure');
        await _logErrorToServer(
          errorType: 'LocationApiFailure',
          errorMessage: response?.errors?.toString() ?? 'Unknown API failure',
          context: 'LocationService._sendLocationToAPI',
          additionalData: {
            'api_response': response?.toJson(),
            'location_data': locationPayload,
          },
        );
        return;
      }

      final lastInsertId = await _locationDatabase?.rawQuery(
        'SELECT last_insert_rowid()',
      );
      if (lastInsertId != null && lastInsertId.isNotEmpty) {
        final id = lastInsertId.first.values.first as int;
        await _markLocationsAsSynced([id]);
      }

      debugPrint(
        'Location sent successfully (Battery: ${batteryLevel ?? 'N/A'}%)',
      );

      await _syncStoredLocations();
    } catch (e) {
      debugPrint('API error: $e (Battery: ${batteryLevel ?? 'N/A'}%)');
      await _logErrorToServer(
        errorType: 'LocationApiError',
        errorMessage: e.toString(),
        context: 'LocationService._sendLocationToAPI',
        additionalData: {'location_data': locationPayload},
      );
    }
  }

  Future<GpsStatus> _getGpsStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return GpsStatus.disabled;

      if (_permissionStatus == LocationPermission.denied ||
          _permissionStatus == LocationPermission.deniedForever) {
        return GpsStatus.unavailable;
      }

      return _isTracking ? GpsStatus.searching : GpsStatus.enabled;
    } catch (e) {
      debugPrint('Error getting GPS status: $e');
      await _logErrorToServer(
        errorType: 'GpsStatusError',
        errorMessage: e.toString(),
        context: 'LocationService._sendLocationToAPI',
      );
      return GpsStatus.unavailable;
    }
  }

  // Add this method to handle error logging
  Future<void> _logErrorToServer({
    required String errorType,
    required String errorMessage,
    required String context,
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentToken == null) return;

    final errorPayload = {
      'error_type': errorType,
      'error_message': errorMessage,
      'context': context,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (additionalData != null) 'additional_data': additionalData,
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
      'app_state': {
        'is_tracking': _isTracking,
        'is_background': _isInBackground,
        'battery_level': await _battery.batteryLevel,
        'connectivity': _isConnected ? 'connected' : 'disconnected',
      },
    };

    for (int attempt = 1; attempt <= _maxErrorRetryAttempts; attempt++) {
      try {
        final Map<String, String> formData = {
          "connection": "mobile",
          "queue": "default",
          "payload": jsonEncode(errorPayload),
          "exception": errorType,
        };
        final response = await BasicService()
            .postFailedJob(formData)
            .timeout(const Duration(seconds: 10));

        if (response?.success == true) {
          debugPrint('Error logged successfully (attempt $attempt)');
          return;
        }
      } catch (e) {
        debugPrint('Failed to log error (attempt $attempt): $e');
      }

      if (attempt < _maxErrorRetryAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    debugPrint('All attempts to log error failed');
  }
}
