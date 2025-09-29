import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:snap_check/services/locations/location_database_service.dart';
import 'package:snap_check/services/locations/new_location_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'location_api_service.dart';

@pragma('vm:entry-point')
class LocationBackgroundService {
  static const String _backgroundTaskName = 'locationBackgroundTask';
  final LocationApiService _apiService = LocationApiService();

  @pragma('vm:entry-point')
  Future<void> setup() async {
    // Initialize database service
    await LocationDatabaseService().initDatabase();

    await Workmanager().initialize(_backgroundTaskCallback, isInDebugMode: false);
    // Also schedule a periodic fallback task in case the foreground service
    // is killed by the system; this will still capture a snapshot and queue it
    // to the local DB, then try to sync when network is available.
    try {
      await Workmanager().registerPeriodicTask(
        '$_backgroundTaskName-periodic',
        _backgroundTaskName,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.not_required),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
    } catch (_) {}

    final userData = await SharedPrefHelper.loadUser();
    final name = userData?.name?.trim() ?? "";
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_tracker',
        initialNotificationTitle: 'Hello,$name',
        initialNotificationContent: 'Day Started',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      final token = await SharedPrefHelper.getToken();
      final dayLogId = await SharedPrefHelper.getActiveDayLogId();
      final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      if (token == null || dayLogId == null) return false;

      try {
        final position = await Geolocator.getCurrentPosition();
        final batteryLevel = await Battery().batteryLevel;
        // Initialize database
        final dbService = LocationDatabaseService();
        await dbService.initDatabase();
        // Store in database
        await dbService.saveLocation({
          'tripId': int.tryParse(dayLogId),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'gps_status': "${GpsStatus.enabled.value}",
          'battery_percentage': batteryLevel,
          'recorded_at': DateTime.now().millisecondsSinceEpoch,
        });
        // Try to send if connected
        if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
          final response = await LocationApiService().sendLocation(
            token,
            dayLogId,
            position.latitude,
            position.longitude,
            batteryLevel,
            "${GpsStatus.enabled.value}",
            apiFormat.format(DateTime.now()),
          );
          if (response?.success == true) {
            try {
              final lastId = await dbService.getLastInsertId();
              if (lastId != null) {
                await dbService.markLocationsAsSynced([lastId]);
              }
            } catch (_) {}
            return true;
          }
          return false;
        }

        return true;
      } catch (e) {
        return false;
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _sendLocationInBackground(ServiceInstance service,
      String token,
      String dayLogId,
      Position position,
      ) async {
    try {
      final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final batteryLevel = await Battery().batteryLevel;

      // Store in database first
      final dbService = LocationDatabaseService();
      await dbService.initDatabase();

      await dbService.saveLocation({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'gps_status': "${GpsStatus.enabled.value}",
        'battery_percentage': batteryLevel,
        'tripId': int.tryParse(dayLogId),
        'recorded_at': DateTime.now().millisecondsSinceEpoch,
      });
      // Try to send to API if connected
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
        final resp = await LocationApiService().sendLocation(
          token,
          dayLogId,
          position.latitude,
          position.longitude,
          batteryLevel,
          "${GpsStatus.enabled.value}",
          apiFormat.format(DateTime.now()),
        );
        if (resp?.success == true) {
          final lastId = await dbService.getLastInsertId();
          if (lastId != null) {
            await dbService.markLocationsAsSynced([lastId]);
          }
        }
      }
    } catch (e) {
      service.stopSelf();
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    final connectivity = Connectivity();
    StreamSubscription? connectivitySub;

    // Listen for connectivity changes to sync pending data
    connectivitySub = connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncPendingLocations(service);
      }
    });

    // Stop service listener
    service.on('stopService').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setAsBackgroundService();
        service.stopSelf();
      }
    });

    // Force sync listener
    service.on('forceSync').listen((event) async {
      await _syncPendingLocations(service);
    });

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();
    final userData = await SharedPrefHelper.loadUser();
    final name = userData?.name?.trim() ?? "";

    if (token == null || dayLogId == null) {
      service.stopSelf();
      return;
    }

    double? lastLat;
    double? lastLng;

    // Start location stream with 300-meter movement filter
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 300, // 100 meters movement filter
      ),
    ).listen((Position position) async {
      if (!await SharedPrefHelper.isTrackingActive()) {
        service.stopSelf();
        return;
      }

      // Show notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Hello, $name',
          content: 'Day Started',
        );
      }

      // Distance check for safety
      if (lastLat != null && lastLng != null) {
        final distance = Geolocator.distanceBetween(
          lastLat!,
          lastLng!,
          position.latitude,
          position.longitude,
        );

        if (distance < 300) return; // Ignore if not moved enough
      }

      lastLat = position.latitude;
      lastLng = position.longitude;

      // Store & Send location
      await _handleLocationUpdate(service, token, dayLogId, position);
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _handleLocationUpdate(
      ServiceInstance service,
      String token,
      String dayLogId,
      Position position,
      ) async {
    final dbService = LocationDatabaseService();
    await dbService.initDatabase();

    final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final batteryLevel = await Battery().batteryLevel;

    // Save in local DB first
    final locationData = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'gps_status': "${GpsStatus.enabled.value}",
      'battery_percentage': batteryLevel,
      'tripId': int.tryParse(dayLogId),
      'recorded_at': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
    };
    await dbService.saveLocation(locationData);

    // If online → Try to send this immediately + pending ones
    if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
      await _syncPendingLocations(service);
    }
  }

  /// Sync all pending offline locations to the server
  @pragma('vm:entry-point')
  static Future<void> _syncPendingLocations(ServiceInstance service) async {
    final dbService = LocationDatabaseService();
    await dbService.initDatabase();

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();
    if (token == null || dayLogId == null) return;

    final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Get all unsynced locations
    final pendingLocations = await dbService.getUnsyncedLocations(int.tryParse(dayLogId) ?? 0);

    for (var location in pendingLocations) {
      final resp = await LocationApiService().sendLocation(
        token,
        dayLogId,
        location['latitude'],
        location['longitude'],
        location['battery_percentage'],
        location['gps_status'],
        apiFormat.format(
          DateTime.fromMillisecondsSinceEpoch(location['recorded_at']),
        ),
      );

      // Mark as synced if success
      if (resp?.success == true) {
        await dbService.markLocationsAsSynced([location['id']]);
      }
    }
  }

}
