import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:snap_check/services/share_pref.dart';
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
  static const MethodChannel _platform = MethodChannel('location_tracker');
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  Timer? _locationTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  // Tracking state
  bool _isTracking = false;
  String? _currentToken;
  String? _currentDayLogId;
  final List<Map<String, Object>> _locationQueue = [];

  // Status flags
  LocationPermission _permissionStatus = LocationPermission.denied;
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
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled && _isTracking) {
      debugPrint('Location service disabled while tracking');
      await stopTracking();
    }

    // Set up service status stream
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      _serviceEnabled = status == ServiceStatus.enabled;
      if (!_serviceEnabled && _isTracking) {
        debugPrint('Location service disabled while tracking');
        stopTracking();
      }
    });
  }

  Future<void> _setupBackgroundService() async {
    if (Platform.isAndroid) {
      // Initialize Workmanager
      await Workmanager().initialize(
        _backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );

      // Configure background service
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

  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      final token = await SharedPrefHelper.getToken();
      final dayLogId = await SharedPrefHelper.getActiveDayLogId();

      if (token == null || dayLogId == null) {
        return Future.value(false);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 30),
        );

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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

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
        debugPrint('Background service API response indicates failure - stopping');
        service.stopSelf();
        return;
      }
    } catch (e) {
      debugPrint('Background location error: $e');
    }
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

  void _handleAppBackgrounded() async {
    if (!_isTracking) return;

    debugPrint('App moved to background - adjusting location tracking');

    // Start native Android foreground service
    try {
      await _platform.invokeMethod('startBackgroundService');
    } catch (e) {
      debugPrint('Native background service start error: $e');
    }

    if (Platform.isAndroid) {
      try {
        // Start background service first
        final service = FlutterBackgroundService();
        await service.startService();

        // Then pause foreground updates
        _positionStream?.pause();
        _locationTimer?.cancel();

        // Register periodic workmanager task
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
      } catch (e) {
        debugPrint('Error starting background service: $e');
      }
    }
  }

  void _handleAppForegrounded() async {
    if (!_isTracking) return;

    debugPrint('App moved to foreground - adjusting location tracking');

    // Stop native Android foreground service
    try {
      await _platform.invokeMethod('stopBackgroundService');
    } catch (e) {
      debugPrint('Native background service stop error: $e');
    }

    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
        }
        await Workmanager().cancelByTag('1');
      } catch (e) {
        debugPrint('Error stopping background service: $e');
      }
    }

    // Resume foreground updates
    _positionStream?.resume();
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

    // Start listening to continuous position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // meters
      ),
    ).listen((Position position) {
      _sendLocationToAPI(
        _currentToken ?? "",
        _currentDayLogId ?? "",
        position.latitude,
        position.longitude,
      );
    }, onError: (e) => debugPrint('Position update error: $e'));

    // Adjust based on app state
    if (_isInBackground) {
      _positionStream?.pause();
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
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        // Note: Geolocator doesn't have a direct method to request service enablement
        // You might need to show a dialog directing users to settings
        debugPrint('Location services disabled by user');
        return false;
      }
      return true;
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

  @pragma('vm:entry-point')
  Future<void> stopTracking() async {
    // Cancel all timers and subscriptions
    _locationTimer?.cancel();
    _locationTimer = null;

    await _positionStream?.cancel();
    _positionStream = null;

    // Process any remaining locations in queue
    if (_locationQueue.isNotEmpty) {
      await _processLocationQueue();
    }

    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;

    // Stop background services more thoroughly
    if (Platform.isAndroid) {
      try {
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();
        if (isRunning) {
          service.invoke('stopService');
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
    if (!_isTracking || _currentToken == null || _currentDayLogId == null) return;

    try {
      final Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: _locationTimeout,
        );
      } on TimeoutException {
        debugPrint('Location acquisition timeout');
        return;
      } catch (e) {
        debugPrint('Error getting location: $e');
        return;
      }

      await _sendLocationToAPI(
        _currentToken!,
        _currentDayLogId!,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('Error in location sending process: $e');
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
      debugPrint('Offline - location queued (Battery: ${batteryLevel ?? 'N/A'}%)');
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

      debugPrint('Location sent successfully (Battery: ${batteryLevel ?? 'N/A'}%)');
    } on TimeoutException {
      _locationQueue.add(locationPayload);
      debugPrint('API timeout - location queued (Battery: ${batteryLevel ?? 'N/A'}%)');
      await stopTracking();
    } catch (e) {
      _locationQueue.add(locationPayload);
      debugPrint('API error - location queued: $e (Battery: ${batteryLevel ?? 'N/A'}%)');
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
    await _positionStream?.cancel();
    await _serviceStatusStream?.cancel();

    _locationQueue.clear();

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      Workmanager().cancelByTag('1');
    }
  }
}