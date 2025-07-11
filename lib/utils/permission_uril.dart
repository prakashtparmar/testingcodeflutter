// lib/services/notification_permission_handler.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionUtil {
  /// Checks if notification permission is required (Android 13+)
  Future<bool> get isNotificationPermissionRequired async {
    if (!await _isAndroid13OrHigher()) return false;
    return true;
  }

  /// Requests notification permission if needed
  Future<bool> requestNotificationPermission() async {
    if (!await _isAndroid13OrHigher()) return true;

    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      return false;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  /// Checks current permission status
  Future<bool> get hasNotificationPermission async {
    if (!await _isAndroid13OrHigher()) return true;
    return await Permission.notification.isGranted;
  }

  /// Private helper to check Android version
  Future<bool> _isAndroid13OrHigher() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.status;

    if (status.isPermanentlyDenied) {
      // User has permanently denied permission, need to open app settings
      return false;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  /// Checks current location permission status
  Future<bool> get hasLocationPermission async {
    return await Permission.location.isGranted;
  }

  /// Checks if location services are enabled (Android/iOS)
  /// Note: This requires additional platform-specific implementation
  Future<bool> get areLocationServicesEnabled async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  /// Requests both coarse and fine location permissions
  Future<bool> requestPreciseLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Checks if app has precise location permission
  Future<bool> get hasPreciseLocationPermission async {
    return await Permission.locationWhenInUse.isGranted;
  }
}
