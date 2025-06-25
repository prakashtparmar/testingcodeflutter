// background_service.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      initialNotificationTitle: 'Location Service',
      initialNotificationContent: 'Tracking your location',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Initialize service control flags
  bool shouldRun = true;

  // Setup service stop listener
  service.on('stopService').listen((event) {
    shouldRun = false;
    service.stopSelf();
  });

  // Main service loop
  while (shouldRun) {
    try {
      // Check for required data before proceeding
      final tokenData = await SharedPrefHelper.getToken();
      final activeDayLogId = await SharedPrefHelper.getActiveDayLogId();

      if (tokenData == null ||
          tokenData.isEmpty ||
          activeDayLogId == null ||
          activeDayLogId.isEmpty) {
        debugPrint("Missing required data - stopping service");
        shouldRun = false;
        service.stopSelf();
        break;
      }

      // Update notification if Android
      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Location Service",
          content: "Tracking your location",
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Prepare and send location data
      final response = await _sendLocationData(
        tokenData,
        activeDayLogId,
        position.latitude,
        position.longitude,
      );

      if (response?.success != true) {
        debugPrint("Failed to send location data");
        // Consider implementing retry logic here
      }
    } catch (e) {
      debugPrint("Error in location service: ${e.toString()}");
      // Implement error recovery or service stop after multiple failures
    }

    // Wait for 5 seconds before next iteration
    await Future.delayed(Duration(seconds: 5));
  }
}

Future<DayLogStoreLocationResponseModel?> _sendLocationData(
  String token,
  String dayLogId,
  double latitude,
  double longitude,
) async {
  try {
    final List<Map<String, double>> collectedLocations = [
      {"latitude": latitude, "longitude": longitude},
    ];

    Map<String, Object> body = {
      "day_log_id": dayLogId,
      "locations": collectedLocations,
    };

    return await BasicService().postDayLogLocations(token, body);
  } catch (e) {
    debugPrint("Error sending location data: $e");
    return null;
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// Add this function to control the service from your UI
Future<void> stopLocationService() async {
  final service = FlutterBackgroundService();
  bool isRunning = await service.isRunning();

  if (isRunning) {
    service.invoke('stopService');
  }
}
