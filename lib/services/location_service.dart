import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Battery _battery = Battery();
  final Location _location = Location();
  final Connectivity _connectivity = Connectivity();
  Timer? _locationTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<LocationData>? _locationUpdates;
  var _serviceStatusSubscription;

  // Tracking state
  bool _isTracking = false;
  String? _currentToken;
  String? _currentDayLogId;
  final List<Map<String, Object>> _locationQueue = [];

  // Status flags
  bool _hasPermission = false;
  bool _serviceEnabled = false;
  bool _isConnected = true;
  bool _isInBackground = false;

  // Configuration
  static const int _foregroundInterval = 30; // seconds
  static const int _backgroundInterval = 60; // seconds
  static const int _maxRetryAttempts = 3;
  static const Duration _locationTimeout = Duration(seconds: 30);
  static const Duration _apiTimeout = Duration(seconds: 10);
  static const String _backgroundTaskName = 'locationBackgroundTask';

  bool get isTracking => _isTracking;

  @pragma('vm:entry-point')
  LocationService() {
    _initializeService();
    _setupBackgroundService();
    _setupAppLifecycle();
  }

  Future<void> _initializeService() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        List<ConnectivityResult> result,
      ) {
        _isConnected = result != ConnectivityResult.none;
        if (_isConnected && _locationQueue.isNotEmpty) {
          _processLocationQueue();
        }
      }, onError: (error) => debugPrint('Connectivity error: $error'));

      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;

      // Initialize service status monitoring
      await _checkAndMonitorServiceStatus();
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }

  Future<void> _checkAndMonitorServiceStatus() async {
    // Initial check
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled && _isTracking) {
      debugPrint('Location service disabled while tracking');
      await stopTracking();
    }

    // Set up periodic checks since there's no direct stream
    _serviceStatusSubscription = Stream.periodic(
      const Duration(seconds: 10),
    ).listen((_) async {
      final currentStatus = await _location.serviceEnabled();
      if (_serviceEnabled != currentStatus) {
        _serviceEnabled = currentStatus;
        if (!_serviceEnabled && _isTracking) {
          debugPrint('Location service disabled while tracking');
          await stopTracking();
        }
      }
    });
  }

  Future<void> _setupBackgroundService() async {
    if (Platform.isAndroid) {
      // Initialize Workmanager for periodic background tasks
      await Workmanager().initialize(
        _backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );

      // Initialize Flutter Background Service for persistent background tasks
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onBackgroundServiceStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'location_tracker',
          initialNotificationTitle: 'Location Tracking',
          initialNotificationContent: 'Tracking your location',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(),
      );
    }
  }

  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      final token = await SharedPrefHelper.getToken();
      final dayLogId = await SharedPrefHelper.getActiveDayLogId();

      if (token == null || dayLogId == null) {
        return Future.value(false);
      }

      final location = Location();
      try {
        final locationData = await location.getLocation().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Location request timed out'),
        );

        if (locationData.latitude != null && locationData.longitude != null) {
          final battery = Battery();
          final batteryLevel = await battery.batteryLevel;
          final gpsStatus = await _getGpsStatusLocation(location);

          final locationPayload = {
            "trip_id": dayLogId,
            "latitude": locationData.latitude,
            "longitude": locationData.longitude,
            "gps_status": "${gpsStatus.value}",
            if (batteryLevel != -1) "battery_percentage": "$batteryLevel",
          };

          final response = await BasicService()
              .postDayLogLocations(token, locationPayload)
              .timeout(const Duration(seconds: 10));

          // Stop tracking if API response indicates failure
          if (response == null ||
              response.success == false ||
              response.errors != null ||
              response.data == null) {
            debugPrint('Background API response indicates failure');
            return Future.value(false);
          }
        }
      } catch (e) {
        debugPrint('Background task error: $e');
        return Future.value(false);
      }

      return Future.value(true);
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    // Add this at the beginning
    service.on('stopService').listen((event) async {
      service.stopSelf();
    });

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();

    if (token == null || dayLogId == null) {
      service.stopSelf();
      return;
    }

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Get location immediately when service starts
    await _sendLocationInBackground(service, token, dayLogId);

    // Then set up periodic updates
    Timer.periodic(const Duration(seconds: _backgroundInterval), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Location Tracker",
            content: "Tracking your location in background",
          );
        }
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
      final location = Location();
      final locationData = await location.getLocation().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      if (locationData.latitude == null || locationData.longitude == null) {
        return;
      }

      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final gpsStatus = await _getGpsStatusLocation(location);

      final locationPayload = {
        "trip_id": dayLogId,
        "latitude": locationData.latitude,
        "longitude": locationData.longitude,
        "gps_status": "${gpsStatus.value}",
        if (batteryLevel != -1) "battery_percentage": "$batteryLevel",
      };

      final response = await BasicService()
          .postDayLogLocations(token, locationPayload)
          .timeout(const Duration(seconds: 10));

      // Stop tracking if API response indicates failure
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

  static Future<GpsStatus> _getGpsStatusLocation(Location location) async {
    try {
      final serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) return GpsStatus.disabled;

      final permission = await location.hasPermission();
      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.deniedForever) {
        return GpsStatus.unavailable;
      }

      return GpsStatus.enabled;
    } catch (e) {
      return GpsStatus.unavailable;
    }
  }

  Future<void> _setupAppLifecycle() async {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('AppLifecycleState: $msg');

      switch (msg) {
        case 'AppLifecycleState.inactive':
          _isInBackground = true;
          _handleAppBackgrounded();
          break;
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

  void _handleAppBackgrounded() {
    if (!_isTracking) return;

    debugPrint('App moved to background - adjusting location tracking');

    // Stop foreground updates and start background service
    _locationUpdates?.pause();
    _locationTimer?.cancel();

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.startService();

      Workmanager().registerPeriodicTask(
        '1',
        _backgroundTaskName,
        frequency: const Duration(minutes: 15),
      );
    }
  }

  void _handleAppForegrounded() {
    if (!_isTracking) return;

    debugPrint('App moved to foreground - adjusting location tracking');

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      Workmanager().cancelByTag('1');
    }

    _locationUpdates?.resume();
    _startPeriodicLocationUpdates();
  }

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

    // Store credentials for background use
    if (!await _checkLocationServices()) return false;
    if (!await _checkLocationPermissions()) return false;

    _isTracking = true;

    // Start with immediate location update
    await _sendCurrentLocation();

    // Start periodic updates based on foreground/background state
    _startPeriodicLocationUpdates();

    // Start listening to continuous location updates
    _locationUpdates = _location.onLocationChanged.listen((
      LocationData locationData,
    ) {
      if (locationData.latitude != null && locationData.longitude != null) {
        _sendLocationToAPI(
          _currentToken ?? "",
          _currentDayLogId ?? "",
          locationData.latitude ?? 0,
          locationData.longitude ?? 0,
        );
      }
    }, onError: (e) => debugPrint('Location update error: $e'));

    // Adjust based on app state
    if (_isInBackground) {
      _locationUpdates?.pause();
    }

    return true;
  }

  void _startPeriodicLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(
        seconds: _isInBackground ? _backgroundInterval : _foregroundInterval,
      ),
      (_) => _sendCurrentLocation(),
    );
  }

  Future<bool> _checkLocationServices() async {
    try {
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          debugPrint('Location services disabled by user');
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Location service check failed: $e');
      if (e.toString().contains('MissingPluginException')) {
        debugPrint(
          'Location plugin not registered. Run flutter pub get and rebuild',
        );
      }
      return false;
    }
  }

  Future<bool> _checkLocationPermissions() async {
    try {
      var permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied ||
          permissionStatus == PermissionStatus.deniedForever) {
        permissionStatus = await _location.requestPermission();
      }

      _hasPermission =
          permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.grantedLimited;

      if (!_hasPermission) {
        debugPrint('Location permission denied');
        return false;
      }

      // Request background permission on Android
      if (Platform.isAndroid &&
          await _location.hasPermission() == PermissionStatus.granted) {
        final backgroundStatus = await _location.requestPermission();
        if (backgroundStatus != PermissionStatus.granted) {
          debugPrint('Background location permission not granted');
        }
      }

      return _hasPermission;
    } catch (e) {
      debugPrint('Location permission check failed: $e');
      return false;
    }
  }

  @pragma('vm:entry-point')
  Future<void> stopTracking() async {
    // Cancel all timers and subscriptions
    _locationTimer?.cancel();
    _locationTimer = null;

    await _locationUpdates?.cancel();
    _locationUpdates = null;

    // Process any remaining locations in queue
    if (_locationQueue.isNotEmpty) {
      await _processLocationQueue();
    }

    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;

    // Clear stored credentials
    // Stop background services more thoroughly
    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        // Ensure service is actually running before trying to stop it
        final isRunning = await service.isRunning();
        if (isRunning) {
          service.invoke('stopService');
          // Add delay to ensure service stops
          await Future.delayed(const Duration(seconds: 1));
        }

        // Cancel all workmanager tasks
        await Workmanager().cancelAll();
        await Workmanager().cancelByUniqueName(_backgroundTaskName);
      } catch (e) {
        debugPrint('Error stopping background services: $e');
      }
    }
  }

  Future<void> _sendCurrentLocation() async {
    if (!_isTracking || _currentToken == null || _currentDayLogId == null)
      return;

    try {
      final LocationData locationData;
      try {
        locationData = await _location.getLocation().timeout(
          _locationTimeout,
          onTimeout: () {
            debugPrint('Location acquisition timeout');
            throw TimeoutException('Location request timed out');
          },
        );
      } on TimeoutException {
        return;
      } catch (e) {
        debugPrint('Error getting location: $e');
        return;
      }

      if (locationData.latitude == null || locationData.longitude == null) {
        debugPrint('Invalid location data received');
        return;
      }

      await _sendLocationToAPI(
        _currentToken!,
        _currentDayLogId!,
        locationData.latitude!,
        locationData.longitude!,
      );
    } catch (e) {
      debugPrint('Error in location sending process: $e');
    }
  }

  Future<GpsStatus> _getGpsStatus() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) return GpsStatus.disabled;

      final permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.deniedForever) {
        return GpsStatus.unavailable;
      }

      if (_isTracking) {
        return GpsStatus.searching;
      }

      return GpsStatus.enabled;
    } catch (e) {
      debugPrint('Error getting GPS status: $e');
      return GpsStatus.unavailable;
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
      batteryLevel = null;
    }

    final gpsStatus = await _getGpsStatus();
    final locationPayload = {
      "trip_id": dayLogId,
      "latitude": latitude,
      "longitude": longitude,
      "gps_status": "${gpsStatus.value}",
      if (batteryLevel != null) "battery_percentage": "$batteryLevel",
    };

    if (!_isConnected) {
      _locationQueue.add(locationPayload);
      debugPrint(
        'Offline - location queued (Battery: ${batteryLevel ?? 'N/A'}%)',
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
        debugPrint('API response indicates failure - stopping tracking');
        await stopTracking();
        return;
      }

      debugPrint(
        'Location sent successfully (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
    } on TimeoutException {
      _locationQueue.add(locationPayload);
      debugPrint(
        'API timeout - location queued (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
      await stopTracking();
    } catch (e) {
      _locationQueue.add(locationPayload);
      debugPrint(
        'API error - location queued: $e (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
      await stopTracking();
    }
  }

  Future<void> _processLocationQueue() async {
    if (!_isConnected || _locationQueue.isEmpty || _currentToken == null) {
      return;
    }

    int attempt = 0;
    while (attempt < _maxRetryAttempts && _locationQueue.isNotEmpty) {
      try {
        final payload = _locationQueue.first;
        final currentGpsStatus = await _getGpsStatus();
        payload['gps_status'] = "${currentGpsStatus.value}";

        final response = await BasicService()
            .postDayLogLocations(_currentToken!, payload)
            .timeout(_apiTimeout);

        if (response == null ||
            response.success == false ||
            response.data == null) {
          debugPrint('API response indicates failure - stopping tracking');
          await stopTracking();
          return;
        }

        _locationQueue.removeAt(0);
        debugPrint('Queued location sent successfully');
      } catch (e) {
        attempt++;
        debugPrint('Retry attempt $attempt failed: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> forceStopAllServices() async {
    await stopTracking();

    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        service.invoke('stopService');
        await Workmanager().cancelAll();
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('Force stop error: $e');
      }
    }
  }

  Future<void> dispose() async {
    await stopTracking();
    await _connectivitySubscription?.cancel();
    await _locationUpdates?.cancel();
    await _serviceStatusSubscription?.cancel();

    _locationQueue.clear();

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      Workmanager().cancelByTag('1');
    }
  }
}
