import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// Enum representing different GPS status states with their corresponding values
enum GpsStatus {
  disabled(0),
  enabled(1),
  searching(2),
  unavailable(3);

  final int value;
  const GpsStatus(this.value);
}

/// Main location tracking service that handles all location-related functionality
@pragma('vm:entry-point')
class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();

  // Platform channel for native Android communication
  static const MethodChannel _platform = MethodChannel('location_tracker');

  // Dependencies
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Timers and subscriptions
  Timer? _locationTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  // Tracking state
  bool _isTracking = false;
  String? _currentToken;
  String? _currentDayLogId;
  Database? _locationDatabase; // SQLite database for storing locations

  // Status flags
  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _serviceEnabled = false;
  bool _isConnected = true;
  bool _isInBackground = false;

  // Configuration constants
  static const int _foregroundInterval =
      15; // Update interval in seconds when app is in foreground
  static const int _backgroundInterval =
      30; // Update interval in seconds when app is in background
  static const int _maxRetryAttempts =
      5; // Maximum number of retry attempts for failed API calls
  static const Duration _locationTimeout = Duration(
    seconds: 15,
  ); // Timeout for getting location
  static const Duration _apiTimeout = Duration(
    seconds: 15,
  ); // Timeout for API calls
  static const String _backgroundTaskName =
      'locationBackgroundTask'; // Workmanager task name
  static const String _locationDatabaseName =
      'locations.db'; // Database file name
  static const int _maxDatabaseLocations =
      1000; // Maximum locations to store locally before cleanup

  /// Getter for tracking status
  bool get isTracking => _isTracking;

  // Add these new instance variables
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _lastNetworkState = true;
  GpsStatus _lastGpsStatus = GpsStatus.enabled;

  /// Factory constructor returns the singleton instance
  factory LocationService() {
    return _instance;
  }

  /// Private internal constructor for singleton pattern
  @pragma('vm:entry-point')
  LocationService._internal() {
    _initializeService();
    _setupBackgroundService();
    _setupAppLifecycle();
    _initDatabase();
    _initNotifications(); // Initialize notifications
  }

  // Add this new method to initialize notifications
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: null, // iOS not configured as we're focusing on Android
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  // Add this new method to show notification with vibration
  Future<void> _showAlertNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'location_alerts',
          'Location Alerts',
          channelDescription: 'Alerts for location tracking issues',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          enableVibration: true,
          actions: [AndroidNotificationAction('settings', 'Open Settings')],
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Vibrate first
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 500);
    }

    // Then show notification
    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
    );
  }

  /// Initializes the SQLite database for storing locations
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

  /// Saves a location to the local database
  Future<void> _saveLocationToDatabase(Map<String, dynamic> location) async {
    if (_locationDatabase == null) return;

    try {
      // Insert the new location
      await _locationDatabase!.insert('locations', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'gps_status': location['gps_status'],
        'battery_level': location['battery_percentage'],
        'synced': 0, // 0 means not synced yet
      });
    } catch (e) {
      debugPrint('Error saving location to database: $e');
    }
  }

  /// Retrieves all unsynced locations from the database
  Future<List<Map<String, dynamic>>> _getUnsyncedLocations() async {
    if (_locationDatabase == null) return [];

    try {
      return await _locationDatabase!.query(
        'locations',
        where: 'synced = 0',
        orderBy: 'timestamp ASC', // Oldest first
      );
    } catch (e) {
      debugPrint('Error getting unsynced locations: $e');
      return [];
    }
  }

  /// Marks locations as synced in the database
  Future<void> _markLocationsAsSynced(List<int> ids) async {
    if (_locationDatabase == null || ids.isEmpty) return;

    try {
      await _locationDatabase!.update(
        'locations',
        {'synced': 1}, // 1 means synced
        where: 'id IN (${ids.join(',')})',
      );
    } catch (e) {
      debugPrint('Error marking locations as synced: $e');
    }
  }

  /// Initializes the service by setting up connectivity monitoring
  Future<void> _initializeService() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        List<ConnectivityResult> result,
      ) {
        final newState = result != ConnectivityResult.none;
        if (newState != _lastNetworkState) {
          _lastNetworkState = newState;
          if (!newState) {
            _showAlertNotification(
              title: 'Network Lost',
              body: 'Location tracking continues offline',
            );
          } else {
            _showAlertNotification(
              title: 'Network Restored',
              body: 'Syncing locations with server',
            );
          }
        }
        _isConnected = newState;
        if (_isConnected) {
          _syncStoredLocations();
        }
      }, onError: (error) => debugPrint('Connectivity error: $error'));

      // Initial connectivity check
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;
      _lastNetworkState = _isConnected;

      // Initialize service status monitoring
      await _checkAndMonitorServiceStatus();
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }

  /// Checks and monitors the status of location services
  // Modify the GPS status monitoring in _checkAndMonitorServiceStatus
  Future<void> _checkAndMonitorServiceStatus() async {
    // Initial check
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _lastGpsStatus = _serviceEnabled ? GpsStatus.enabled : GpsStatus.disabled;

    if (!_serviceEnabled && _isTracking) {
      debugPrint('Location service disabled while tracking');
      await _showAlertNotification(
        title: 'GPS Disabled',
        body: 'Location tracking paused - enable GPS to continue',
      );
      await stopTracking();
    }

    // Set up service status stream
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      final newStatus =
          status == ServiceStatus.enabled
              ? GpsStatus.enabled
              : GpsStatus.disabled;

      if (newStatus != _lastGpsStatus) {
        _lastGpsStatus = newStatus;
        if (newStatus == GpsStatus.disabled && _isTracking) {
          _showAlertNotification(
            title: 'GPS Signal Lost',
            body: 'Location tracking may be inaccurate',
          );
        } else if (newStatus == GpsStatus.enabled && _isTracking) {
          _showAlertNotification(
            title: 'GPS Signal Restored',
            body: 'Location tracking resumed',
          );
        }
      }

      _serviceEnabled = status == ServiceStatus.enabled;
      if (!_serviceEnabled && _isTracking) {
        debugPrint('Location service disabled while tracking');
        stopTracking();
      }
    });
  }

  /// Sets up background service for Android
  Future<void> _setupBackgroundService() async {
    if (Platform.isAndroid) {
      // Initialize Workmanager for periodic background tasks
      await Workmanager().initialize(
        _backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );

      // Configure Flutter background service
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
  }

  /// Background task callback for Workmanager
  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      final token = await SharedPrefHelper.getToken();
      final dayLogId = await SharedPrefHelper.getActiveDayLogId();

      if (token == null || dayLogId == null) {
        return Future.value(false);
      }

      try {
        // Get current position with optimized settings
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );

        // Validate the location before processing
        if (!_isValidLocation(position)) {
          return Future.value(false);
        }

        final battery = Battery();
        final batteryLevel = await battery.batteryLevel;
        final gpsStatus = await _getGpsStatusGeolocator();

        final locationPayload = {
          "trip_id": dayLogId,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "gps_status": "${gpsStatus.value}",
          if (batteryLevel != -1) "battery_percentage": "$batteryLevel",
        };

        final response = await BasicService()
            .postDayLogLocations(token, locationPayload)
            .timeout(const Duration(seconds: 10));

        if (response == null ||
            response.success == false ||
            response.errors != null ||
            response.data == null) {
          debugPrint('Background API response indicates failure');
          return Future.value(false);
        }
      } catch (e) {
        debugPrint('Background task error: $e');
        return Future.value(false);
      }

      return Future.value(true);
    });
  }

  /// Background service start handler
  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();

      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();

    if (token == null || dayLogId == null) {
      service.stopSelf();
      return;
    }

    // Immediate location update
    await _sendLocationInBackground(service, token, dayLogId);

    // Set up periodic updates
    Timer.periodic(const Duration(seconds: _backgroundInterval), (timer) async {
      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        // Update notification to show service is running
        service.setForegroundNotificationInfo(
          title: "Location Tracker",
          content: "Last update: ${DateTime.now()}",
        );
      }

      await _sendLocationInBackground(service, token, dayLogId);
    });
  }

  /// Sends location from background service
  @pragma('vm:entry-point')
  static Future<void> _sendLocationInBackground(
    ServiceInstance service,
    String token,
    String dayLogId,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      // Validate location
      if (!_isValidLocation(position)) {
        return;
      }

      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final gpsStatus = await _getGpsStatusGeolocator();

      final locationPayload = {
        "trip_id": dayLogId,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "gps_status": "${gpsStatus.value}",
        if (batteryLevel != -1) "battery_percentage": "$batteryLevel",
      };

      final response = await BasicService()
          .postDayLogLocations(token, locationPayload)
          .timeout(const Duration(seconds: 10));

      if (response == null ||
          response.success == false ||
          response.errors != null ||
          response.data == null) {
        debugPrint(
          'Background service API response indicates failure - stopping',
        );
        service.stopSelf();
        return;
      }
    } catch (e) {
      debugPrint('Background location error: $e');
    }
  }

  /// Gets GPS status using Geolocator
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

  /// Sets up app lifecycle state monitoring
  Future<void> _setupAppLifecycle() async {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('AppLifecycleState: $msg');

      switch (msg) {
        case 'AppLifecycleState.inactive':
        case 'AppLifecycleState.paused':
          _isInBackground = true;
          _handleAppBackgrounded();
          break;
        case 'AppLifecycleState.resumed':
          _isInBackground = false;
          _handleAppForegrounded();
          break;
      }
      return null;
    });
  }

  /// Handles app moving to background
  void _handleAppBackgrounded() async {
    if (!_isTracking) return;

    debugPrint('App moved to background - adjusting location tracking');

    try {
      // Start native Android foreground service
      await _platform.invokeMethod('startBackgroundService');

      if (Platform.isAndroid) {
        // Start Flutter background service
        final service = FlutterBackgroundService();
        await service.startService();

        // Pause foreground updates to save battery
        _positionStream?.pause();
        _locationTimer?.cancel();

        // Register periodic workmanager task as backup
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

        // Optimize for battery
        await _optimizeForBattery();
      }
    } catch (e) {
      debugPrint('Error starting background service: $e');
    }
  }

  /// Handles app moving to foreground
  void _handleAppForegrounded() async {
    if (!_isTracking) return;

    debugPrint('App moved to foreground - adjusting location tracking');

    try {
      // Stop native Android foreground service
      await _platform.invokeMethod('stopBackgroundService');

      if (Platform.isAndroid) {
        // Stop Flutter background service
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
        }

        // Cancel workmanager tasks
        await Workmanager().cancelByTag('1');
      }

      // Resume foreground updates
      _positionStream?.resume();
      _startPeriodicLocationUpdates();
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }

  /// Starts tracking locations with the given credentials
  @pragma('vm:entry-point')
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

    // Check and request location services and permissions
    if (!await _checkLocationServices()) return false;
    if (!await _checkLocationPermissions()) return false;

    _isTracking = true;

    // Sync any previously stored locations
    await _syncStoredLocations();

    // Get immediate location
    await _sendCurrentLocation();

    // Start periodic updates
    _startPeriodicLocationUpdates();

    // Listen to position stream for continuous updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy:
            _isInBackground
                ? LocationAccuracy.bestForNavigation
                : LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    ).listen((Position position) {
      if (_isValidLocation(position)) {
        _sendLocationToAPI(
          _currentToken ?? "",
          _currentDayLogId ?? "",
          position.latitude,
          position.longitude,
        );
      }
    }, onError: (e) => debugPrint('Position update error: $e'));

    // Pause if starting in background
    if (_isInBackground) {
      _positionStream?.pause();
    }

    return true;
  }

  /// Starts periodic location updates with appropriate interval
  void _startPeriodicLocationUpdates() {
    _locationTimer?.cancel();

    // Adjust interval based on battery level
    _optimizeForBattery().then((_) {
      _locationTimer = Timer.periodic(
        Duration(
          seconds: _isInBackground ? _backgroundInterval : _foregroundInterval,
        ),
        (_) => _sendCurrentLocation(),
      );
    });
  }

  /// Checks if location services are enabled
  Future<bool> _checkLocationServices() async {
    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        debugPrint('Location services disabled by user');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Location service check failed: $e');
      return false;
    }
  }

  /// Checks and requests location permissions
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

  /// Stops tracking locations and cleans up resources
  @pragma('vm:entry-point')
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    debugPrint('Stopping tracking service...');

    // Cancel timers and subscriptions
    _locationTimer?.cancel();
    _locationTimer = null;

    await _positionStream?.cancel();
    _positionStream = null;

    // Sync any remaining locations
    await _syncStoredLocations();

    // Reset tracking state
    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;

    try {
      // Stop native background service
      await _platform.invokeMethod('stopBackgroundService');

      if (Platform.isAndroid) {
        // Stop Flutter background service
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
          await Future.delayed(const Duration(seconds: 1));
        }

        // Cancel all workmanager tasks
        await Workmanager().cancelAll();
        await Workmanager().cancelByUniqueName(_backgroundTaskName);
      }
    } catch (e) {
      debugPrint('Error stopping services: $e');
    }
  }

  /// Sends the current location to API and database
  Future<void> _sendCurrentLocation() async {
    if (!_isTracking || _currentToken == null || _currentDayLogId == null)
      return;

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            _isInBackground
                ? LocationAccuracy.bestForNavigation
                : LocationAccuracy.high,
        timeLimit: _locationTimeout,
      );

      // Validate location before sending
      if (!_isValidLocation(position)) {
        return;
      }

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

  /// Gets the current GPS status
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
      return GpsStatus.unavailable;
    }
  }

  /// Sends location to API and handles the response
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
    }

    final gpsStatus = await _getGpsStatus();
    final locationPayload = {
      "trip_id": dayLogId,
      "latitude": latitude,
      "longitude": longitude,
      "gps_status": "${gpsStatus.value}",
      if (batteryLevel != null) "battery_percentage": "$batteryLevel",
    };

    // Always save to database first for reliability
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
        return;
      }

      // Mark as synced in database
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

      // Sync any other stored locations
      await _syncStoredLocations();
    } catch (e) {
      debugPrint('API error: $e (Battery: ${batteryLevel ?? 'N/A'}%)');
    }
  }

  /// Syncs all stored locations with the server
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
    const batchSize = 10; // Sync in batches to avoid overwhelming the API
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

            final response = await BasicService()
                .postDayLogLocations(_currentToken!, payload)
                .timeout(_apiTimeout);

            return {
              'id': location['id'],
              'success': response?.success ?? false,
            };
          }),
        );

        // Collect successful IDs
        successfulIds.addAll(
          responses
              .where((r) => r['success'] as bool)
              .map((r) => r['id'] as int),
        );

        // If any in batch failed, stop and try again later
        if (responses.any((r) => !(r['success'] as bool))) {
          break;
        }
      } catch (e) {
        debugPrint('Error syncing batch $i: $e');
        break;
      }
    }

    // Mark successfully synced locations
    if (successfulIds.isNotEmpty) {
      await _markLocationsAsSynced(successfulIds);
      debugPrint('Successfully synced ${successfulIds.length} locations');
    }
  }

  /// Forces an immediate sync of locations
  Future<void> triggerEmergencySync() async {
    if (!_isTracking) return;

    debugPrint('Triggering emergency sync');

    // Force immediate location update and sync
    await _sendCurrentLocation();
    await _syncStoredLocations();

    // Reset the timer
    _startPeriodicLocationUpdates();
  }

  /// Validates if a location is reasonable and should be processed
  static bool _isValidLocation(Position position) {
    // Check for reasonable accuracy (meters)
    if (position.accuracy != null && position.accuracy! > 100) {
      debugPrint('Location accuracy too low: ${position.accuracy} meters');
      return false;
    }

    // Check for reasonable timestamp (not too old)
    if (position.timestamp != null &&
        DateTime.now().difference(position.timestamp!) > Duration(minutes: 5)) {
      debugPrint('Location timestamp too old: ${position.timestamp}');
      return false;
    }

    return true;
  }

  /// Optimizes tracking based on battery level
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

  /// Cleans up resources when service is disposed
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

  /// Checks if any tracking services are currently running
  Future<bool> isServiceRunning() async {
    bool isTrackingActive = _isTracking;
    bool isBackgroundServiceRunning = false;
    bool hasWorkmanagerTasks = false;

    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        isBackgroundServiceRunning = await service.isRunning();
        hasWorkmanagerTasks = await _checkWorkmanagerTasks();
      } catch (e) {
        debugPrint('Error checking service status: $e');
      }
    }

    return isTrackingActive ||
        isBackgroundServiceRunning ||
        hasWorkmanagerTasks;
  }

  /// Workaround for checking Workmanager tasks
  Future<bool> _checkWorkmanagerTasks() async {
    // Note: Workmanager doesn't provide a reliable way to check running tasks
    return false;
  }
}
