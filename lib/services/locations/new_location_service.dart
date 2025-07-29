import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:workmanager/workmanager.dart';

import 'location_database_service.dart';
import 'location_background_service.dart';
import 'location_api_service.dart';
import 'location_utils.dart';
import 'location_permission_service.dart';

enum GpsStatus {
  disabled(0),
  enabled(1),
  searching(2),
  unavailable(3);

  final int value;
  const GpsStatus(this.value);
}

@pragma('vm:entry-point')
class NewLocationService {
  static final NewLocationService _instance = NewLocationService._internal();
  final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  // Services
  final LocationDatabaseService _databaseService = LocationDatabaseService();
  final LocationBackgroundService _backgroundService =
      LocationBackgroundService();
  final LocationApiService _apiService = LocationApiService();
  final LocationPermissionService _permissionService =
      LocationPermissionService();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Stream subscriptions
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  // State variables
  bool _isTracking = false;
  String? _currentToken;
  String? _currentDayLogId;
  bool _serviceEnabled = false;
  bool _isConnected = true;
  static bool _isInBackground = false;

  // Location tracking state
  double? _lastSentLatitude;
  double? _lastSentLongitude;
  DateTime? _lastLocationSentTime;

  bool get isTracking => _isTracking;

  factory NewLocationService() => _instance;

  @pragma('vm:entry-point')
  NewLocationService._internal() {
    debugPrint('[NewLocationService] Initializing NewLocationService');
    _initializeService();
    _setupAppLifecycle();
    _databaseService.initDatabase();
    if (Platform.isAndroid) {
      _backgroundService.setup();
    }
  }

  Future<void> _initializeService() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        result,
      ) {
        _isConnected = result != ConnectivityResult.none;
        if (_isConnected) _syncStoredLocations();
      });

      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;

      await _checkAndMonitorServiceStatus();
    } catch (error) {
      debugPrint('[NewLocationService] Initialization error: $error');
      await _logErrorToServer(
        errorType: 'ServiceInitError',
        errorMessage: error.toString(),
        context: 'NewLocationService._initializeService',
      );
    }
  }

  Future<void> _checkAndMonitorServiceStatus() async {
    _serviceEnabled = await _permissionService.isLocationEnabled();
    if (!_serviceEnabled && _isTracking) {
      await stopTracking();
    }

    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      _serviceEnabled = status == ServiceStatus.enabled;
      if (!_serviceEnabled && _isTracking) {
        stopTracking();
      }
    });
  }

  Future<bool> startTracking({
    required String token,
    required String dayLogId,
  }) async {
    if (_isTracking) return true;

    _currentToken = token;
    _currentDayLogId = dayLogId;

    if (!await _permissionService.isLocationEnabled()) return false;
    if (!await _permissionService.checkAndRequestPermissions()) return false;

    _isTracking = true;
    await _syncStoredLocations();

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy:
            _isInBackground
                ? LocationAccuracy.bestForNavigation
                : LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      if (await LocationUtils.isValidLocation(position)) {
        _sendLocationToAPI(position.latitude, position.longitude);
      }
    });

    if (_isInBackground) _positionStream?.pause();
    return true;
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await syncAllUnsyncedLocationsBeforeClosing();

    await _positionStream?.cancel();
    _positionStream = null;

    _isTracking = false;
    _currentToken = null;
    _currentDayLogId = null;
    _lastSentLatitude = null;
    _lastSentLongitude = null;
    _lastLocationSentTime = null;

    try {
      if (Platform.isAndroid) {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
          await Future.delayed(const Duration(seconds: 1));
        }
        await Workmanager().cancelAll();
      }
    } catch (e) {
      debugPrint('[NewLocationService] Error stopping services: $e');
    }
  }

  Future<void> _sendLocationToAPI(double latitude, double longitude) async {
    if (!LocationUtils.shouldSendLocation(
      latitude,
      longitude,
      _lastSentLatitude,
      _lastSentLongitude,
      _lastLocationSentTime,
    )) {
      return;
    }

    final batteryLevel = await _battery.batteryLevel;
    final locationPayload = {
      "tripId": _currentDayLogId!,
      "latitude": latitude,
      "longitude": longitude,
      "gps_status": "${GpsStatus.enabled.value}",
      "recorded_at": apiFormat.format(DateTime.now()),
      "battery_percentage": "$batteryLevel",
    };

    await _databaseService.saveLocation(locationPayload);

    _lastSentLatitude = latitude;
    _lastSentLongitude = longitude;
    _lastLocationSentTime = DateTime.now();

    if (!_isConnected) return;

    try {
      final response = await _apiService.sendLocation(
        _currentToken!,
        _currentDayLogId!,
        latitude,
        longitude,
        batteryLevel,
        "${GpsStatus.enabled.value}",
      );

      if (response?.success == true) {
        try {
          final lastInsertId = await _databaseService.getLastInsertId();
          if (lastInsertId != null) {
            await _databaseService.markLocationsAsSynced([lastInsertId]);
            debugPrint(
              '[LocationService] Successfully synced location ID: $lastInsertId',
            );
          }
        } catch (e) {
          debugPrint('[LocationService] Error marking location as synced: $e');
          await _logErrorToServer(
            errorType: 'SyncMarkError',
            errorMessage: e.toString(),
            context: 'LocationService._sendLocationToAPI',
          );
        }
      }
    } catch (e) {
      debugPrint('[NewLocationService] API error: $e');
      await _logErrorToServer(
        errorType: 'LocationApiError',
        errorMessage: e.toString(),
        context: 'NewLocationService._sendLocationToAPI',
      );
    }
  }

  Future<void> _syncStoredLocations({bool force = false}) async {
    if ((!_isConnected && !force) ||
        _currentToken == null ||
        _currentDayLogId == null) {
      return;
    }

    final unsyncedLocations = await _databaseService.getUnsyncedLocations();
    if (unsyncedLocations.isEmpty) return;

    final successfulIds = <int>[];
    const batchSize = 10;

    for (var i = 0; i < unsyncedLocations.length; i += batchSize) {
      final batch = unsyncedLocations.sublist(
        i,
        i + batchSize > unsyncedLocations.length
            ? unsyncedLocations.length
            : i + batchSize,
      );

      try {
        for (final location in batch) {
          final response = await _apiService.sendLocation(
            _currentToken!,
            _currentDayLogId!,
            location['latitude'],
            location['longitude'],
            location['battery_level'],
            location['gps_status'].toString(),
          );

          if (response?.success == true) {
            successfulIds.add(location['id']);
          }
        }
      } catch (e) {
        debugPrint('[NewLocationService] Batch sync error: $e');
        break;
      }
    }

    if (successfulIds.isNotEmpty) {
      await _databaseService.markLocationsAsSynced(successfulIds);
    }
  }

  Future<void> syncAllUnsyncedLocationsBeforeClosing() async {
    if (_currentToken == null || _currentDayLogId == null) return;

    final unsyncedLocations = await _databaseService.getUnsyncedLocations();
    if (unsyncedLocations.isEmpty) return;

    final successfulIds = <int>[];

    for (final location in unsyncedLocations) {
      try {
        final response = await _apiService.sendLocation(
          _currentToken!,
          _currentDayLogId!,
          location['latitude'],
          location['longitude'],
          location['battery_level'],
          location['gps_status'].toString(),
        );

        if (response?.success == true) {
          successfulIds.add(location['id']);
        }
      } catch (e) {
        debugPrint('[NewLocationService] Final sync error: $e');
      }
    }

    if (successfulIds.isNotEmpty) {
      await _databaseService.markLocationsAsSynced(successfulIds);
    }
  }

  void _setupAppLifecycle() {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
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

  void _handleAppBackground() {
    if (!_isTracking) return;

    _isInBackground = true;

    // Ensure database is initialized
    _databaseService.initDatabase();

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.startService();

      // Instead of pausing, let the background service take over
      _positionStream?.cancel();
      _positionStream = null;
    }
  }

  void _handleAppForegrounded() {
    if (!_isTracking) return;

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
    }

    _positionStream?.resume();
    _syncStoredLocations(force: true);
  }

  Future<void> dispose() async {
    await stopTracking();
    await _connectivitySubscription?.cancel();
    await _positionStream?.cancel();
    await _serviceStatusStream?.cancel();
    await _databaseService.close();
  }

  Future<bool> isServiceRunning() async {
    bool isBackgroundServiceRunning = false;
    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      isBackgroundServiceRunning = await service.isRunning();
    }
    return _isTracking || isBackgroundServiceRunning;
  }

  Future<void> _logErrorToServer({
    required String errorType,
    required String errorMessage,
    required String context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentToken == null) return;

    final errorPayload = {
      'error_type': errorType,
      'error_message': errorMessage,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      if (additionalData != null) 'additional_data': additionalData,
    };

    try {
      // Implement error logging to server
      debugPrint('[NewLocationService] Logging error: $errorPayload');
    } catch (e) {
      debugPrint('[NewLocationService] Error logging failed: $e');
    }
  }
}
