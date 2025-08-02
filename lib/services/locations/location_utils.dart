import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static const double _locationChangeThreshold = 0.0001;
  static const Duration _minLocationSendInterval = Duration(seconds: 30);

  static bool shouldSendLocation(
    double newLat,
    double newLng,
    double? lastLat,
    double? lastLng,
    DateTime? lastSentTime,
  ) {
    final now = DateTime.now();
    final hasMovedSignificantly =
        lastLat == null ||
        lastLng == null ||
        (newLat - lastLat).abs() > _locationChangeThreshold ||
        (newLng - lastLng).abs() > _locationChangeThreshold;

    final shouldSendDueToTime =
        lastSentTime == null ||
        now.difference(lastSentTime) > _minLocationSendInterval;

    return hasMovedSignificantly || shouldSendDueToTime;
  }

  static Future<bool> isValidLocation(Position position) async {
    // Reject locations with accuracy worse than 50 meters
    if (position.accuracy > 50) return false;

    // Reject locations older than 2 minutes
    if (DateTime.now().difference(position.timestamp) > Duration(minutes: 2)) {
      return false;
    }

    // Additional checks for real devices
    if (position.speed > 0) {
      // If speed is available, use it to validate
      return position.speed < 50; // Reject if speed > 180 km/h (likely error)
    }

    return true;
  }

  static bool isLocationAccurate(Position position) {
    return position.accuracy <= 100; // meters
  }

  static bool isLocationFresh(Position position) {
    return DateTime.now().difference(position.timestamp) < Duration(minutes: 5);
  }
}
