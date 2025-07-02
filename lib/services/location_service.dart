import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:snap_check/services/basic_service.dart';

class LocationTrackingService {
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
  static const Duration _locationTimeout = Duration(seconds: 15);
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

  Future<void> _sendLocationToAPI(
    String token,
    String dayLogId,
    double latitude,
    double longitude,
  ) async {
    final locationPayload = {
      "trip_id": dayLogId,
      "latitude": latitude,
      "longitude": longitude,
    };

    if (!_isConnected) {
      _locationQueue.add(locationPayload);
      debugPrint('Offline - location queued');
      return;
    }

    try {
      final response = await BasicService()
          .postDayLogLocations(token, locationPayload)
          .timeout(_apiTimeout);

      if (response != null) {
        debugPrint('Location sent successfully');
      } else {
        _locationQueue.add(locationPayload);
        debugPrint('API returned null - location queued');
      }
    } on TimeoutException {
      _locationQueue.add(locationPayload);
      debugPrint('API timeout - location queued');
    } catch (e) {
      _locationQueue.add(locationPayload);
      debugPrint('API error - location queued: $e');
    }
  }

  Future<void> _processLocationQueue() async {
    if (!_isConnected || _locationQueue.isEmpty || _currentToken == null)
      return;

    int attempt = 0;
    while (attempt < _maxRetryAttempts && _locationQueue.isNotEmpty) {
      try {
        final payload = _locationQueue.first;
        final response = await BasicService()
            .postDayLogLocations(_currentToken!, payload)
            .timeout(_apiTimeout);

        if (response != null) {
          _locationQueue.removeAt(0);
          debugPrint('Queued location sent successfully');
        } else {
          attempt++;
          debugPrint('Retry attempt $attempt for queued location');
        }
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
