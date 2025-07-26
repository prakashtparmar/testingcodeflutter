import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
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

      if (token == null || dayLogId == null) return false;

      try {
        final position = await Geolocator.getCurrentPosition();
        final batteryLevel = await Battery().batteryLevel;
        final response = await LocationApiService().sendLocation(
          token,
          dayLogId,
          position.latitude,
          position.longitude,
          batteryLevel,
          "${GpsStatus.enabled.value}",
        );

        return response?.success ?? false;
      } catch (e) {
        return false;
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundServiceStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    final token = await SharedPrefHelper.getToken();
    final dayLogId = await SharedPrefHelper.getActiveDayLogId();

    if (token == null || dayLogId == null) {
      service.stopSelf();
      return;
    }

    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
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
      final position = await Geolocator.getCurrentPosition();
      final batteryLevel = await Battery().batteryLevel;
      await LocationApiService().sendLocation(
        token,
        dayLogId,
        position.latitude,
        position.longitude,
        batteryLevel,
        "${GpsStatus.enabled.value}",
      );
    } catch (e) {
      service.stopSelf();
    }
  }
}
