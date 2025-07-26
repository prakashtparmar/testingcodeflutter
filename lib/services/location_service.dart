import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
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
  final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Timer? _locationTimer;
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

  static const int _foregroundInterval = 10;
  static const int _backgroundInterval = 10;
  static const String _backgroundTaskName = 'locationBackgroundTask';
  static const String _locationDatabaseName = 'locations.db';

  bool get isTracking => _isTracking;

  factory LocationService() => _instance;

  double? _lastSentLatitude;
  double? _lastSentLongitude;
  DateTime? _lastLocationSentTime;
  static const double _locationChangeThreshold = 0.0001; // ~11 meters
  static const Duration _minLocationSendInterval = Duration(seconds: 30);

  @pragma('vm:entry-point')
  LocationService._internal() {
    debugPrint(
      '[LocationService] Initializing LocationService singleton instance',
    );
    _initializeService();
    _setupBackgroundService();
    _setupAppLifecycle();
    _initDatabase();
  }

  // Database Methods
  Future<void> _initDatabase() async {
    try {
      debugPrint('[LocationService] Initializing database...');
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _locationDatabaseName);
      debugPrint('[LocationService] Database path: $path');

      _locationDatabase = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          debugPrint(
            '[LocationService] Creating new database version $version',
          );
          await db.execute('''
            CREATE TABLE locations(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              recorded_at INTEGER NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              gps_status INTEGER NOT NULL,
              battery_level INTEGER,
              synced INTEGER DEFAULT 0
            )
          ''');
          debugPrint('[LocationService] Database table created successfully');
        },
      );
      debugPrint('[LocationService] Database initialized successfully');
    } catch (e) {
      debugPrint('[LocationService] Database initialization error: $e');
    }
  }

  Future<void> _saveLocationToDatabase(Map<String, dynamic> location) async {
    if (_locationDatabase == null) {
      debugPrint(
        '[LocationService] Database not initialized - cannot save location',
      );
      return;
    }

    try {
      debugPrint(
        '[LocationService] Saving location to database: ${location['latitude']}, ${location['longitude']}',
      );
      final id = await _locationDatabase!.insert('locations', {
        'recorded_at': DateTime.now().millisecondsSinceEpoch,
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'gps_status': location['gps_status'],
        'battery_level': location['battery_percentage'],
        'synced': 0,
      });
      debugPrint('[LocationService] Location saved to database with id: $id');
    } catch (e) {
      debugPrint('[LocationService] Error saving location to database: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getUnsyncedLocations() async {
    if (_locationDatabase == null) {
      debugPrint(
        '[LocationService] Database not initialized - cannot get unsynced locations',
      );
      return [];
    }

    try {
      debugPrint('[LocationService] Fetching unsynced locations from database');
      final locations = await _locationDatabase!.query(
        'locations',
        where: 'synced = 0',
        orderBy: 'recorded_at ASC',
      );
      debugPrint(
        '[LocationService] Found ${locations.length} unsynced locations',
      );
      return locations;
    } catch (e) {
      debugPrint('[LocationService] Error getting unsynced locations: $e');

      return [];
    }
  }

  Future<void> _markLocationsAsSynced(List<int> ids) async {
    if (_locationDatabase == null || ids.isEmpty) {
      debugPrint(
        '[LocationService] Database not initialized or empty ids list - cannot mark as synced',
      );
      return;
    }

    try {
      debugPrint(
        '[LocationService] Marking ${ids.length} locations as synced: $ids',
      );
      await _locationDatabase!.update('locations', {
        'synced': 1,
      }, where: 'id IN (${ids.join(',')})');
      debugPrint('[LocationService] Successfully marked locations as synced');
    } catch (e) {
      debugPrint('[LocationService] Error marking locations as synced: $e');
    }
  }

  // Service Initialization
  Future<void> _initializeService() async {
    try {
      debugPrint('[LocationService] Initializing service...');

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> result) {
          _isConnected = result != ConnectivityResult.none;
          debugPrint(
            '[LocationService] Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}',
          );
          if (_isConnected) {
            debugPrint(
              '[LocationService] Network available - attempting to sync stored locations',
            );
            _syncStoredLocations();
          }
        },
        onError:
            (error) =>
                debugPrint('[LocationService] Connectivity error: $error'),
      );

      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;
      debugPrint(
        '[LocationService] Initial connectivity state: ${_isConnected ? 'Connected' : 'Disconnected'}',
      );

      await _checkAndMonitorServiceStatus();
      debugPrint('[LocationService] Service initialization complete');
    } catch (error) {
      debugPrint('[LocationService] Service initialization error: $error');
    }
  }

  Future<void> _checkAndMonitorServiceStatus() async {
    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint(
        '[LocationService] Location service status: ${_serviceEnabled ? 'Enabled' : 'Disabled'}',
      );

      if (!_serviceEnabled && _isTracking) {
        debugPrint(
          '[LocationService] Location service disabled while tracking - stopping tracking',
        );
        await stopTracking();
      }

      _serviceStatusStream = Geolocator.getServiceStatusStream().listen(
        (status) {
          _serviceEnabled = status == ServiceStatus.enabled;
          debugPrint(
            '[LocationService] Location service status changed: ${_serviceEnabled ? 'Enabled' : 'Disabled'}',
          );

          if (!_serviceEnabled && _isTracking) {
            debugPrint(
              '[LocationService] Location service disabled while tracking - stopping tracking',
            );
            stopTracking();
          }
        },
        onError:
            (e) =>
                debugPrint('[LocationService] Service status stream error: $e'),
      );
    } catch (e) {
      debugPrint('[LocationService] Error checking service status: $e');
    }
  }

  // Background Service Management
  Future<void> _setupBackgroundService() async {
    if (!Platform.isAndroid) {
      debugPrint(
        '[LocationService] Background service setup skipped (not Android)',
      );
      return;
    }

    try {
      debugPrint('[LocationService] Setting up background service...');

      await Workmanager().initialize(
        _backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );
      debugPrint('[LocationService] Workmanager initialized');

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
      debugPrint('[LocationService] Background service configured');
    } catch (e) {
      debugPrint('[LocationService] Background service setup error: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    debugPrint('[BackgroundTask] Background task triggered');
    Workmanager().executeTask((task, inputData) async {
      debugPrint('[BackgroundTask] Executing background task: $task');

      try {
        final token = await SharedPrefHelper.getToken();
        final dayLogId = await SharedPrefHelper.getActiveDayLogId();

        if (token == null || dayLogId == null) {
          debugPrint(
            '[BackgroundTask] No token or dayLogId available - aborting',
          );
          return Future.value(false);
        }

        debugPrint('[BackgroundTask] Getting current position...');
        final position = await _getCurrentPositionWithTimeout();

        if (!_isValidLocation(position)) {
          debugPrint('[BackgroundTask] Invalid location received - aborting');
          return Future.value(false);
        }

        debugPrint('[BackgroundTask] Creating location payload...');
        final locationPayload = await _createLocationPayload(
          position,
          dayLogId,
          await Battery().batteryLevel,
        );

        debugPrint('[BackgroundTask] Sending location to API...');
        final response = await _sendLocationToApiWithTimeout(
          token,
          locationPayload,
        );

        debugPrint('[BackgroundTask] API response: ${response?.success}');
        return Future.value(response?.success ?? false);
      } catch (e) {
        debugPrint('[BackgroundTask] Error during execution: $e');
        return Future.value(false);
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    debugPrint('[BackgroundService] Service started');

    if (service is AndroidServiceInstance) {
      debugPrint('[BackgroundService] Setting as foreground service');
      service.setAsForegroundService();
      service.on('stopService').listen((event) {
        debugPrint('[BackgroundService] Stop service command received');
        service.stopSelf();
      });
    }

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();

    if (token == null || dayLogId == null) {
      debugPrint(
        '[BackgroundService] No token or dayLogId available - stopping service',
      );
      service.stopSelf();
      return;
    }

    debugPrint('[BackgroundService] Starting background location updates');
    await _sendLocationInBackground(service, token, dayLogId);

    Timer.periodic(const Duration(seconds: _backgroundInterval), (timer) async {
      debugPrint('[BackgroundService] Periodic update triggered');

      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        debugPrint('[BackgroundService] Updating foreground notification');
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
    debugPrint('[BackgroundService] Sending location in background');

    try {
      debugPrint('[BackgroundService] Getting current position...');
      final position = await _getCurrentPositionWithTimeout();

      if (!_isValidLocation(position)) {
        debugPrint('[BackgroundService] Invalid location received - skipping');
        return;
      }

      debugPrint('[BackgroundService] Creating location payload...');
      final locationPayload = await _createLocationPayload(
        position,
        dayLogId,
        await Battery().batteryLevel,
      );

      debugPrint('[BackgroundService] Sending location to API...');
      final response = await _sendLocationToApiWithTimeout(
        token,
        locationPayload,
      );

      if (response?.success != true) {
        debugPrint(
          '[BackgroundService] API response indicates failure - stopping service',
        );
        service.stopSelf();
      } else {
        debugPrint('[BackgroundService] Location sent successfully');
      }
    } catch (e) {
      debugPrint('[BackgroundService] Error sending location: $e');
    }
  }

  // Location Tracking
  Future<bool> startTracking({
    required String token,
    required String dayLogId,
  }) async {
    debugPrint('[LocationService] Start tracking requested');

    if (_isTracking) {
      debugPrint('[LocationService] Tracking already active');
      return true;
    }

    _currentToken = token;
    _currentDayLogId = dayLogId;
    debugPrint('[LocationService] Set current token and dayLogId');

    if (!await _checkLocationServices()) {
      debugPrint('[LocationService] Location services check failed');
      return false;
    }

    if (!await _checkLocationPermissions()) {
      debugPrint('[LocationService] Location permissions check failed');
      return false;
    }

    _isTracking = true;
    debugPrint('[LocationService] Tracking started');

    await _syncStoredLocations();

    _positionStream?.cancel();
    debugPrint('[LocationService] Starting position stream...');

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy:
            _isInBackground
                ? LocationAccuracy.bestForNavigation
                : LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      debugPrint(
        '[LocationService] New position received: ${position.latitude}, ${position.longitude}',
      );

      if (_isValidLocation(position)) {
        _sendLocationToAPI(
          _currentToken!,
          _currentDayLogId!,
          position.latitude,
          position.longitude,
        );
      } else {
        debugPrint('[LocationService] Position not valid - skipping');
      }
    }, onError: (e) => debugPrint('[LocationService] Position update error: $e'));

    if (_isInBackground) {
      debugPrint(
        '[LocationService] App is in background - pausing position stream',
      );
      _positionStream?.pause();
    }

    return true;
  }

  Future<void> stopTracking() async {
    if (!_isTracking) {
      debugPrint('[LocationService] Not tracking - nothing to stop');
      return;
    }

    debugPrint('[LocationService] Stopping tracking service...');

    // First attempt to sync all remaining locations
    await syncAllUnsyncedLocationsBeforeClosing();

    await _positionStream?.cancel();
    _positionStream = null;
    debugPrint('[LocationService] Position stream cancelled');

    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;
    _lastSentLatitude = null;
    _lastSentLongitude = null;
    _lastLocationSentTime = null;
    debugPrint('[LocationService] Tracking state reset');

    try {
      if (Platform.isAndroid) {
        debugPrint('[LocationService] Stopping Android background services');
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          debugPrint('[LocationService] Invoking stopService command');
          service.invoke('stopService');
          await Future.delayed(const Duration(seconds: 1));
        }

        debugPrint('[LocationService] Cancelling all workmanager tasks');
        await Workmanager().cancelAll();
        await Workmanager().cancelByUniqueName(_backgroundTaskName);
      }
    } catch (e) {
      debugPrint('[LocationService] Error stopping services: $e');
    }

    debugPrint('[LocationService] Tracking stopped successfully');
  }

  // Helper Methods
  Future<void> _sendCurrentLocation() async {
    if (!_isTracking || _currentToken == null || _currentDayLogId == null) {
      debugPrint(
        '[LocationService] Not tracking or missing credentials - skipping location send',
      );
      return;
    }

    try {
      debugPrint('[LocationService] Getting current position...');
      final position = await _getCurrentPositionWithTimeout();

      if (!_isValidLocation(position)) {
        debugPrint('[LocationService] Invalid position received - skipping');
        return;
      }

      debugPrint('[LocationService] Sending location to API...');
      await _sendLocationToAPI(
        _currentToken!,
        _currentDayLogId!,
        position.latitude,
        position.longitude,
      );
    } on TimeoutException {
      debugPrint('[LocationService] Location acquisition timeout');
    } catch (e) {
      debugPrint('[LocationService] Error getting location: $e');
    }
  }

  static Future<Position> _getCurrentPositionWithTimeout() async {
    debugPrint('[LocationService] Getting current position with timeout');
    final locationSettings = _getPlatformSpecificSettings();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    ).timeout(const Duration(seconds: 15));

    debugPrint(
      '[LocationService] Position acquired: ${position.latitude}, ${position.longitude}',
    );
    return position;
  }

  static LocationSettings _getPlatformSpecificSettings() {
    debugPrint('[LocationService] Getting platform-specific location settings');
    if (Platform.isAndroid) {
      return _getAndroidSettings();
    } else {
      return _getAppleSettings();
    }
  }

  static AndroidSettings _getAndroidSettings() {
    debugPrint('[LocationService] Creating Android-specific location settings');
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
    debugPrint('[LocationService] Creating iOS-specific location settings');
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
    debugPrint('[LocationService] Creating location payload');
    final gpsStatus = await _getGpsStatusGeolocator();
    final payload = {
      "trip_id": dayLogId,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "gps_status": "${gpsStatus.value}",
      "battery_percentage": "$batteryLevel",
    };

    debugPrint('[LocationService] Payload created: $payload');
    return payload;
  }

  static Future<GpsStatus> _getGpsStatusGeolocator() async {
    try {
      debugPrint('[LocationService] Checking GPS status');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS status: Disabled');
        return GpsStatus.disabled;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
          '[LocationService] GPS status: Unavailable (permission denied)',
        );
        return GpsStatus.unavailable;
      }

      debugPrint('[LocationService] GPS status: Enabled');
      return GpsStatus.enabled;
    } catch (e) {
      debugPrint('[LocationService] Error getting GPS status: $e');
      return GpsStatus.unavailable;
    }
  }

  static Future<DayLogStoreLocationResponseModel?>
  _sendLocationToApiWithTimeout(
    String token,
    Map<String, dynamic> payload,
  ) async {
    debugPrint('[LocationService] Sending location to API with timeout');
    return await BasicService().postDayLogLocations(token, payload);
  }

  static bool _isValidLocation(Position position) {
    if (position.accuracy > 100) {
      debugPrint(
        '[LocationService] Location accuracy too low: ${position.accuracy} meters',
      );
      return false;
    }

    if (DateTime.now().difference(position.timestamp) > Duration(minutes: 5)) {
      debugPrint(
        '[LocationService] Location timestamp too old: ${position.timestamp}',
      );
      return false;
    }

    debugPrint('[LocationService] Location is valid');
    return true;
  }

  // App Lifecycle
  Future<void> _setupAppLifecycle() async {
    debugPrint('[LocationService] Setting up app lifecycle handlers');
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('[AppLifecycle] State changed: $msg');

      switch (msg) {
        case 'AppLifecycleState.inactive':
        case 'AppLifecycleState.paused':
          _isInBackground = true;
          debugPrint('[AppLifecycle] App moved to background');
          _handleAppBackground();
          break;
        case 'AppLifecycleState.resumed':
          _isInBackground = false;
          debugPrint('[AppLifecycle] App moved to foreground');
          _handleAppForegrounded();
          break;
      }
      return null;
    });
  }

  void _handleAppBackground() async {
    if (!_isTracking) {
      debugPrint('[AppLifecycle] Not tracking - skipping background handling');
      return;
    }

    debugPrint('[AppLifecycle] Adjusting location tracking for background');

    try {
      if (Platform.isAndroid) {
        debugPrint('[AppLifecycle] Starting Android background service');
        final service = FlutterBackgroundService();
        await service.startService();

        debugPrint('[AppLifecycle] Pausing position stream');
        _positionStream?.pause();

        debugPrint('[AppLifecycle] Registering periodic workmanager task');
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
      debugPrint('[AppLifecycle] Error handling background transition: $e');
    }
  }

  void _handleAppForegrounded() async {
    if (!_isTracking) {
      debugPrint('[AppLifecycle] Not tracking - skipping foreground handling');
      return;
    }

    debugPrint('[AppLifecycle] Adjusting location tracking for foreground');

    try {
      if (Platform.isAndroid) {
        debugPrint('[AppLifecycle] Stopping Android background service');
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
          await Workmanager().cancelByTag('1');
        }
      }

      debugPrint('[AppLifecycle] Recreating position stream');
      await _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          debugPrint(
            '[AppLifecycle] New position in foreground: ${position.latitude}, ${position.longitude}',
          );
          if (_isValidLocation(position)) {
            _sendLocationToAPI(
              _currentToken!,
              _currentDayLogId!,
              position.latitude,
              position.longitude,
            );
          }
        },
        onError: (e) {
          debugPrint('[AppLifecycle] Position stream error on resume: $e');
        },
      );

      debugPrint('[AppLifecycle] Forcing sync of stored locations');
      await _syncStoredLocations(force: true);
    } catch (e) {
      debugPrint('[AppLifecycle] Error handling foreground transition: $e');
    }
  }

  Future<bool> _checkLocationServices() async {
    try {
      debugPrint('[LocationService] Checking location services status');
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!_serviceEnabled) {
        debugPrint('[LocationService] Location services disabled by user');
        return false;
      }

      debugPrint('[LocationService] Location services enabled');
      return true;
    } catch (e) {
      debugPrint('[LocationService] Location service check failed: $e');

      return false;
    }
  }

  Future<bool> _checkLocationPermissions() async {
    try {
      debugPrint('[LocationService] Checking location permissions');
      _permissionStatus = await Geolocator.checkPermission();

      if (_permissionStatus == LocationPermission.denied ||
          _permissionStatus == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission denied - requesting');
        _permissionStatus = await Geolocator.requestPermission();
      }

      if (_permissionStatus == LocationPermission.denied ||
          _permissionStatus == LocationPermission.deniedForever) {
        debugPrint(
          '[LocationService] Location permission denied after request',
        );
        return false;
      }

      debugPrint('[LocationService] Location permission granted');
      return true;
    } catch (e) {
      debugPrint('[LocationService] Location permission check failed: $e');

      return false;
    }
  }

  Future<void> _optimizeForBattery() async {
    try {
      debugPrint('[LocationService] Checking battery level for optimization');
      final level = await _battery.batteryLevel;
      debugPrint('[LocationService] Current battery level: $level%');

      if (level < 15) {
        debugPrint(
          '[LocationService] Low battery ($level%) - reducing location update frequency',
        );
        // Implementation would go here
      }
    } catch (e) {
      debugPrint('[LocationService] Error checking battery level: $e');
    }
  }

  Future<void> dispose() async {
    debugPrint('[LocationService] Disposing service...');
    await stopTracking();

    debugPrint('[LocationService] Cancelling subscriptions');
    await _connectivitySubscription?.cancel();
    await _positionStream?.cancel();
    await _serviceStatusStream?.cancel();

    if (Platform.isAndroid) {
      debugPrint('[LocationService] Stopping Android services');
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      Workmanager().cancelByTag('1');
    }

    debugPrint('[LocationService] Closing database');
    await _locationDatabase?.close();
    _locationDatabase = null;

    debugPrint('[LocationService] Service disposed');
  }

  Future<bool> isServiceRunning() async {
    debugPrint('[LocationService] Checking if service is running');
    bool isTrackingActive = _isTracking;
    bool isBackgroundServiceRunning = false;

    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        isBackgroundServiceRunning = await service.isRunning();
        debugPrint(
          '[LocationService] Background service running: $isBackgroundServiceRunning',
        );
      } catch (e) {
        debugPrint('[LocationService] Error checking service status: $e');
      }
    }

    final result = isTrackingActive || isBackgroundServiceRunning;
    debugPrint('[LocationService] Service running status: $result');
    return result;
  }

  Future<void> _syncStoredLocations({bool force = false}) async {
    if ((!_isConnected && !force) ||
        _currentToken == null ||
        _currentDayLogId == null) {
      debugPrint('[LocationService] Sync conditions not met - skipping sync');
      debugPrint('  - Connected: $_isConnected, Force: $force');
      debugPrint('  - Token available: ${_currentToken != null}');
      debugPrint('  - DayLogId available: ${_currentDayLogId != null}');
      return;
    }

    debugPrint('[LocationService] Starting sync of stored locations');
    final unsyncedLocations = await _getUnsyncedLocations();

    if (unsyncedLocations.isEmpty) {
      debugPrint('[LocationService] No unsynced locations found');
      return;
    }

    debugPrint(
      '[LocationService] Found ${unsyncedLocations.length} unsynced locations - syncing',
    );
    final successfulIds = <int>[];
    const batchSize = 10;
    final batches = (unsyncedLocations.length / batchSize).ceil();

    for (var i = 0; i < batches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, unsyncedLocations.length);
      final batch = unsyncedLocations.sublist(
        start,
        end > unsyncedLocations.length ? unsyncedLocations.length : end,
      );

      debugPrint(
        '[LocationService] Processing batch $i (${batch.length} locations)',
      );

      try {
        final responses = await Future.wait(
          batch.map((location) async {
            final String formattedDate = DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(
              DateTime.fromMillisecondsSinceEpoch(location['recorded_at']),
            );

            final payload = {
              "trip_id": _currentDayLogId!,
              "latitude": location['latitude'],
              "longitude": location['longitude'],
              "gps_status": "${location['gps_status']}",
              "battery_percentage": "${location['battery_level']}",
              "recorded_at": formattedDate,
            };

            debugPrint(
              '[LocationService] Sending location ${location['id']} to API',
            );
            DayLogStoreLocationResponseModel? response = await BasicService()
                .postDayLogLocations(_currentToken!, payload);

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
          debugPrint('[LocationService] Batch $i had failures - continuing');
          continue;
        }
      } catch (e) {
        debugPrint('[LocationService] Error syncing batch $i: $e');

        break;
      }
    }

    if (successfulIds.isNotEmpty) {
      debugPrint(
        '[LocationService] Marking ${successfulIds.length} locations as synced',
      );
      await _markLocationsAsSynced(successfulIds);
    } else {
      debugPrint('[LocationService] No locations were successfully synced');
    }
  }

  Future<void> _sendLocationToAPI(
    String token,
    String dayLogId,
    double latitude,
    double longitude,
  ) async {
    debugPrint('[LocationService] Preparing to send location to API');

    // Check if location has changed significantly or enough time has passed
    final now = DateTime.now();
    final hasMovedSignificantly =
        _lastSentLatitude == null ||
        _lastSentLongitude == null ||
        (latitude - _lastSentLatitude!).abs() > _locationChangeThreshold ||
        (longitude - _lastSentLongitude!).abs() > _locationChangeThreshold;

    final shouldSendDueToTime =
        _lastLocationSentTime == null ||
        now.difference(_lastLocationSentTime!) > _minLocationSendInterval;

    if (!hasMovedSignificantly && !shouldSendDueToTime) {
      debugPrint('[LocationService] Location unchanged - skipping API call');
      debugPrint('  - Moved significantly: $hasMovedSignificantly');
      debugPrint(
        '  - Time elapsed: ${_lastLocationSentTime != null ? now.difference(_lastLocationSentTime!).inSeconds : 'N/A'}s',
      );
      return;
    }

    int? batteryLevel;
    try {
      debugPrint('[LocationService] Getting battery level');
      batteryLevel = await _battery.batteryLevel;
    } catch (e) {
      debugPrint('[LocationService] Error getting battery level: $e');
    }

    final gpsStatus = await _getGpsStatus();
    final locationPayload = {
      "trip_id": dayLogId,
      "latitude": latitude,
      "longitude": longitude,
      "gps_status": "${gpsStatus.value}",
      "recorded_at": apiFormat.format(DateTime.now()),
      "battery_percentage": "$batteryLevel",
    };

    debugPrint('[LocationService] Saving location to database');
    await _saveLocationToDatabase(locationPayload);

    // Update last sent location info
    _lastSentLatitude = latitude;
    _lastSentLongitude = longitude;
    _lastLocationSentTime = now;
    debugPrint('[LocationService] Updated last sent location info');

    if (!_isConnected) {
      debugPrint(
        '[LocationService] Offline - location saved to database (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
      return;
    }

    try {
      debugPrint('[LocationService] Sending location to API');
      final response = await BasicService().postDayLogLocations(
        token,
        locationPayload,
      );

      if (response == null ||
          response.success == false ||
          response.errors != null ||
          response.data == null) {
        debugPrint('[LocationService] API response indicates failure');
        debugPrint('  - Success: ${response?.success}');
        debugPrint('  - Errors: ${response?.errors}');
        debugPrint('  - Data: ${response?.data}');

        return;
      }

      final lastInsertId = await _locationDatabase?.rawQuery(
        'SELECT last_insert_rowid()',
      );
      if (lastInsertId != null && lastInsertId.isNotEmpty) {
        final id = lastInsertId.first.values.first as int;
        debugPrint('[LocationService] Marking location $id as synced');
        await _markLocationsAsSynced([id]);
      }

      debugPrint(
        '[LocationService] Location sent successfully (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
      await _syncStoredLocations();
    } catch (e) {
      debugPrint(
        '[LocationService] API error: $e (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
    }
  }

  Future<GpsStatus> _getGpsStatus() async {
    try {
      debugPrint('[LocationService] Getting GPS status');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS status: Disabled');
        return GpsStatus.disabled;
      }

      if (_permissionStatus == LocationPermission.denied ||
          _permissionStatus == LocationPermission.deniedForever) {
        debugPrint(
          '[LocationService] GPS status: Unavailable (permission denied)',
        );
        return GpsStatus.unavailable;
      }

      debugPrint(
        '[LocationService] GPS status: ${_isTracking ? 'Searching' : 'Enabled'}',
      );
      return _isTracking ? GpsStatus.searching : GpsStatus.enabled;
    } catch (e) {
      debugPrint('[LocationService] Error getting GPS status: $e');

      return GpsStatus.unavailable;
    }
  }

  Future<void> syncAllUnsyncedLocationsBeforeClosing() async {
    if (_currentToken == null || _currentDayLogId == null) {
      debugPrint('[FinalSync] No active trip - nothing to sync');
      return;
    }

    debugPrint(
      '[FinalSync] Starting final sync of all unsynced locations before closing trip',
    );

    // Get all unsynced locations
    final unsyncedLocations = await _getUnsyncedLocations();
    if (unsyncedLocations.isEmpty) {
      debugPrint('[FinalSync] No unsynced locations found');
      return;
    }

    debugPrint(
      '[FinalSync] Found ${unsyncedLocations.length} unsynced locations to sync',
    );

    final successfulIds = <int>[];
    const batchSize = 5; // Smaller batch size for more reliable final sync
    final batches = (unsyncedLocations.length / batchSize).ceil();

    for (var i = 0; i < batches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, unsyncedLocations.length);
      final batch = unsyncedLocations.sublist(
        start,
        end > unsyncedLocations.length ? unsyncedLocations.length : end,
      );

      debugPrint(
        '[FinalSync] Processing final batch $i (${batch.length} locations)',
      );

      try {
        // Use longer timeout for final sync attempts
        final responses = await Future.wait(
          batch.map((location) async {
            final String formattedDate = DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(
              DateTime.fromMillisecondsSinceEpoch(location['recorded_at']),
            );

            final payload = {
              "trip_id": _currentDayLogId!,
              "latitude": location['latitude'],
              "longitude": location['longitude'],
              "gps_status": "${location['gps_status']}",
              "battery_percentage": "${location['battery_level']}",
              "recorded_at": formattedDate,
            };

            debugPrint('[FinalSync] Sending location ${location['id']} to API');
            final response = await BasicService().postDayLogLocations(
              _currentToken!,
              payload,
            );

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

        // If any in batch failed, stop and preserve remaining for next attempt
        if (responses.any((r) => !(r['success'] as bool))) {
          debugPrint('[FinalSync] Batch $i had failures - stopping final sync');
          continue;
        }
      } catch (e) {
        debugPrint('[FinalSync] Error syncing final batch $i: $e');

        break;
      }
    }

    if (successfulIds.isNotEmpty) {
      debugPrint(
        '[FinalSync] Marking ${successfulIds.length} locations as synced',
      );
      await _markLocationsAsSynced(successfulIds);
    }

    // Log how many locations remain unsynced
    final remainingUnsynced = unsyncedLocations.length - successfulIds.length;
    if (remainingUnsynced > 0) {
      debugPrint(
        '[FinalSync] Warning: $remainingUnsynced locations remain unsynced after final attempt',
      );
    }
  }
}
