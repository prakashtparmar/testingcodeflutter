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
      ) async {
        _isConnected = result != ConnectivityResult.none;
        if (_isConnected) {
          // Sync immediately when connection is restored
          await _syncStoredLocations(force: true);

          // If in background, also trigger background service sync
          if (_isInBackground && Platform.isAndroid) {
            final service = FlutterBackgroundService();
            if (await service.isRunning()) {
              service.invoke('forceSync');
            }
          }
        }
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
    final androidSettings = AndroidSettings(
      accuracy:
          _isInBackground
              ? LocationAccuracy
                  .bestForNavigation // Android background
              : LocationAccuracy.best, // Android foreground

      distanceFilter: 30, // Meters
      forceLocationManager: false, // Use FusedLocationProvider by default
      intervalDuration:
          _isInBackground
              ? const Duration(seconds: 60) // Less frequent in background
              : const Duration(seconds: 15), // Minimum time between updates
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Tracking your location",
        notificationTitle: "Location Service Active",
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings:
          Platform.isAndroid
              ? androidSettings
              : LocationSettings(
                accuracy:
                    _isInBackground
                        ? LocationAccuracy
                            .bestForNavigation // iOS background
                        : LocationAccuracy.best, // Android foreground

                distanceFilter: 10, // Meters
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

    // First sync all locations
    try {
      await syncAllUnsyncedLocationsBeforeClosing();
    } catch (e) {
      debugPrint('[NewLocationService] Final sync error: $e');
      await _logErrorToServer(
        errorType: 'FinalSyncError',
        errorMessage: e.toString(),
        context: 'NewLocationService.stopTracking',
      );
      // Don't return here - we still want to stop tracking
    }

    // Then stop all services
    await _stopAllServices();

    // Finally clear state
    _clearTrackingState();
  }

  Future<void> _stopAllServices() async {
    await _positionStream?.cancel();
    _positionStream = null;

    try {
      if (Platform.isAndroid) {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('stopService');
          // await service.stopSelf();
          await Future.delayed(const Duration(seconds: 1));
        }
        await Workmanager().cancelAll();
      }
    } catch (e) {
      debugPrint('[NewLocationService] Error stopping services: $e');
      await _logErrorToServer(
        errorType: 'ServiceStopError',
        errorMessage: e.toString(),
        context: 'NewLocationService._stopAllServices',
      );
    }
  }

  void _clearTrackingState() {
    _isTracking = false;
    _lastSentLatitude = null;
    _lastSentLongitude = null;
    _lastLocationSentTime = null;

    // Don't clear token and dayLogId until we're sure sync is complete
    // They'll be cleared when the service is completely stopped
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
        apiFormat.format(DateTime.now()),
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
    await _databaseService.initDatabase();

    final unsyncedLocations = await _databaseService.getUnsyncedLocations(
      int.tryParse(_currentDayLogId!) ?? 0,
    );
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
            apiFormat.format(
              DateTime.fromMillisecondsSinceEpoch(location['recorded_at']),
            ),
          );

          if (response?.success == true) {
            successfulIds.add(location['id']);
          }
        }
      } catch (e) {
        debugPrint('[NewLocationService] Batch sync error: $e');
      }
    }

    if (successfulIds.isNotEmpty) {
      await _databaseService.markLocationsAsSynced(successfulIds);
    }
  }

  Future<void> syncAllUnsyncedLocationsBeforeClosing() async {
    if (_currentToken == null || _currentDayLogId == null) {
      debugPrint(
        '[NewLocationService] No credentials available for final sync',
      );
      return;
    }

    // Wait for connection if none available
    if (!_isConnected) {
      try {
        debugPrint('[NewLocationService] Waiting for network connection...');
        await waitForConnection();
        debugPrint('[NewLocationService] Network connection established');
      } catch (e) {
        debugPrint(
          '[NewLocationService] No connection available for final sync: $e',
        );
        return;
      }
    }
    // Keep database connection open during sync
    await _databaseService.initDatabase();

    final unsyncedLocations = await _databaseService.getUnsyncedLocations(
      int.tryParse(_currentDayLogId!) ?? 0,
    );
    if (unsyncedLocations.isEmpty) return;

    debugPrint(
      '[NewLocationService] Syncing ${unsyncedLocations.length} locations before closing',
    );

    final successfulIds = <int>[];
    final failedLocations = <Map<String, dynamic>>[];

    // Sync in batches with retry logic
    const batchSize = 5;
    const maxRetries = 3;

    for (var i = 0; i < unsyncedLocations.length; i += batchSize) {
      final batch = unsyncedLocations.sublist(
        i,
        i + batchSize > unsyncedLocations.length
            ? unsyncedLocations.length
            : i + batchSize,
      );

      for (final location in batch) {
        int retryCount = 0;
        bool success = false;

        while (retryCount < maxRetries && !success) {
          try {
            final response = await _apiService.sendLocation(
              _currentToken!,
              _currentDayLogId!,
              location['latitude'],
              location['longitude'],
              location['battery_level'],
              location['gps_status'].toString(),
              apiFormat.format(
                DateTime.fromMillisecondsSinceEpoch(location['recorded_at']),
              ),
            );

            if (response?.success == true) {
              successfulIds.add(location['id']);
              success = true;
            } else {
              retryCount++;
              await Future.delayed(Duration(seconds: 1 * retryCount));
            }
          } catch (e) {
            retryCount++;
            debugPrint(
              '[NewLocationService] Sync attempt $retryCount failed: $e',
            );
            await Future.delayed(Duration(seconds: 1 * retryCount));
          }
        }

        if (!success) {
          failedLocations.add(location);
          debugPrint(
            '[NewLocationService] Failed to sync location: ${location['id']}',
          );
        }
      }
    }

    // Mark successfully synced locations
    if (successfulIds.isNotEmpty) {
      await _databaseService.markLocationsAsSynced(successfulIds);
      debugPrint(
        '[NewLocationService] Successfully synced ${successfulIds.length} locations',
      );
    }

    // Log failed syncs
    if (failedLocations.isNotEmpty) {
      debugPrint(
        '[NewLocationService] Failed to sync ${failedLocations.length} locations',
      );
      await _logErrorToServer(
        errorType: 'FailedFinalSyncs',
        errorMessage: '${failedLocations.length} locations failed to sync',
        context: 'NewLocationService.syncAllUnsyncedLocationsBeforeClosing',
        additionalData: {
          'failed_count': failedLocations.length,
          'last_failed_id': failedLocations.last['id'],
        },
      );
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
    _databaseService.initDatabase();

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.startService();

      // Set up periodic sync attempts
      Timer.periodic(Duration(minutes: 5), (timer) async {
        if (await _connectivity.checkConnectivity() !=
            ConnectivityResult.none) {
          await _syncStoredLocations(force: true);
        }
      });
    }

    _positionStream?.cancel();
    _positionStream = null;
  }

  void _handleAppForegrounded() {
    _isInBackground = false;

    if (!_isTracking) return;

    // Resume position updates
    _positionStream?.resume();

    // Immediately trigger sync of pending locations
    _syncStoredLocations(force: true);

    // Also ensure background service is stopped
    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
    }
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

  Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    throw TimeoutException(
      'Could not establish network connection within timeout',
    );
  }
}
