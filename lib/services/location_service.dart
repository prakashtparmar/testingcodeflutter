import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:battery_plus/battery_plus.dart'; // Add this import at the top
import 'package:location/location.dart' as location_package;

enum GpsStatus {
  disabled(0),
  enabled(1),
  searching(2),
  unavailable(3);

  final int value;
  const GpsStatus(this.value);
}

class LocationTrackingService {
  final Battery _battery = Battery();

  final Location _location = Location();
  final Connectivity _connectivity = Connectivity();
  Timer? _locationTimer;
  var _connectivitySubscription;

  // Tracking state
  bool _isTracking = false;
  String? _currentToken;
  String? _currentDayLogId;
  final List<Map<String, Object>> _locationQueue = [];

  // Status flags
  bool _hasPermission = false;
  bool _serviceEnabled = false;
  bool _isConnected = true;

  // Configuration
  static const int _locationInterval = 30; // seconds
  static const int _maxRetryAttempts = 3;
  static const Duration _locationTimeout = Duration(seconds: 30);
  static const Duration _apiTimeout = Duration(seconds: 10);

  bool get isTracking => _isTracking;

  LocationTrackingService() {
    _initializeService();
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

      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }

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

    // Start tracking
    _isTracking = true;

    // Send initial location immediately
    await _sendCurrentLocation();

    // Start periodic updates
    _locationTimer = Timer.periodic(
      const Duration(seconds: _locationInterval),
      (_) => _sendCurrentLocation(),
    );

    return true;
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
      return true;
    } catch (e) {
      debugPrint('Location permission check failed: $e');
      return false;
    }
  }

  Future<void> stopTracking() async {
    _locationTimer?.cancel();
    _locationTimer = null;

    // Process any remaining locations in queue
    if (_locationQueue.isNotEmpty) {
      await _processLocationQueue();
    }

    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;
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
        // Don't queue timeout errors - try again next interval
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

  // Add this method to get GPS status
  Future<GpsStatus> _getGpsStatus() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) return GpsStatus.disabled;

      final permission = await _location.hasPermission();
      if (permission == location_package.PermissionStatus.denied ||
          permission == location_package.PermissionStatus.deniedForever) {
        return GpsStatus.unavailable;
      }

      // Check if we're currently getting location updates
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
    // Get battery level
    int? batteryLevel;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      batteryLevel = null;
    }
    // Get GPS status
    final gpsStatus = await _getGpsStatus();
    final locationPayload = {
      "trip_id": dayLogId,
      "latitude": latitude,
      "longitude": longitude,
      "gps_status": "${gpsStatus.value}", // Send numeric value

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
    } catch (e) {
      _locationQueue.add(locationPayload);
      debugPrint(
        'API error - location queued: $e (Battery: ${batteryLevel ?? 'N/A'}%)',
      );
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
        payload['gps_status'] = "$currentGpsStatus.value";

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

  Future<void> dispose() async {
    await stopTracking();
    await _connectivitySubscription?.cancel();
    _locationQueue.clear();
  }
}
