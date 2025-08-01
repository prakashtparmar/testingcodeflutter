import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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

    await Workmanager().initialize(
      _backgroundTaskCallback,
      isInDebugMode: true,
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
        if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          final response = await LocationApiService().sendLocation(
            token,
            dayLogId,
            position.latitude,
            position.longitude,
            batteryLevel,
            "${GpsStatus.enabled.value}",
            apiFormat.format(DateTime.now()),
          );
          return response?.success ?? false;
        }

        return true;
      } catch (e) {
        return false;
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _syncPendingLocations(ServiceInstance service) async {
    try {
      final token = await SharedPrefHelper.getToken();
      final dayLogId = await SharedPrefHelper.getActiveDayLogId();

      if (token == null || dayLogId == null) return;

      final dbService = LocationDatabaseService();
      await dbService.initDatabase();

      final unsyncedLocations = await dbService.getUnsyncedLocations(
        int.tryParse(dayLogId) ?? 0,
      );

      if (unsyncedLocations.isEmpty) return;

      for (final location in unsyncedLocations) {
        await LocationApiService().sendLocation(
          token,
          dayLogId,
          location['latitude'],
          location['longitude'],
          location['battery_level'],
          location['gps_status'].toString(),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(location['recorded_at']),
          ),
        );

        await dbService.markLocationsAsSynced([location['id']]);
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    Timer? timer;
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    final connectivity = Connectivity();
    StreamSubscription? connectivitySub;

    // Initialize connectivity check
    final isConnected =
        await connectivity.checkConnectivity() != ConnectivityResult.none;

    // Listen for connectivity changes
    connectivitySub = connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncPendingLocations(service);
      }
    });
    // Listen for stop commands
    service.on('stopService').listen((event) {
      timer?.cancel();
      if (service is AndroidServiceInstance) {
        service.setAsBackgroundService();
        service.stopSelf();
      }
    });

    service.on('forceSync').listen((event) async {
      await _syncPendingLocations(service);
    });

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();

    if (token == null || dayLogId == null) {
      service.stopSelf();
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!await SharedPrefHelper.isTrackingActive()) {
          service.setAsBackgroundService();
          service.stopSelf();
          timer.cancel();
          return;
        }

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
      final DateFormat apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final position = await Geolocator.getCurrentPosition();
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
        await LocationApiService().sendLocation(
          token,
          dayLogId,
          position.latitude,
          position.longitude,
          batteryLevel,
          "${GpsStatus.enabled.value}",
          apiFormat.format(DateTime.now()),
        );
      }
    } catch (e) {
      service.stopSelf();
    }
  }
}
