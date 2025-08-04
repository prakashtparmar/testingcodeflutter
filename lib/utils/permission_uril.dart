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
    final locationStatus = await Permission.location.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;
    final locationWhenInUseStatus = await Permission.locationWhenInUse.status;

    if (locationStatus.isPermanentlyDenied ||
        locationAlwaysStatus.isPermanentlyDenied ||
        locationWhenInUseStatus.isPermanentlyDenied) {
      // User has permanently denied permission, need to open app settings
      return false;
    }
    if (locationWhenInUseStatus.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      return result.isGranted;
    }
    if (locationStatus.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    if (locationAlwaysStatus.isDenied) {
      final result = await Permission.locationAlways.request();
      return result.isGranted;
    }
    return locationStatus.isGranted &&
        locationAlwaysStatus.isGranted &&
        locationWhenInUseStatus.isGranted;
  }

  /// Checks current location permission status
  Future<bool> get hasLocationPermission async {
    final location = await Permission.location.isGranted;
    final locationAlways = await Permission.locationAlways.isGranted;
    final locationWhenInUse = await Permission.locationWhenInUse.isGranted;
    final locationServiceEnabled =
        await Permission.location.serviceStatus.isEnabled;
    if (!locationServiceEnabled) return false;
    return location && locationAlways && locationWhenInUse;
  }
}
