import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static const double _locationChangeThreshold = 0.0001;
  static const Duration _minLocationSendInterval = Duration(minutes: 1);

  static bool shouldSendLocation(
    double newLat,
    double newLng,
    double? lastLat,
    double? lastLng,
    DateTime? lastSentTime,
  ) {
    final now = DateTime.now();
    if (lastSentTime == null) {
      return true;
    }
    final hasMovedSignificantly =
        lastLat == null ||
        lastLng == null ||
        (newLat - lastLat).abs() > _locationChangeThreshold ||
        (newLng - lastLng).abs() > _locationChangeThreshold;

    final shouldSendDueToTime = now.difference(lastSentTime) > _minLocationSendInterval;

    return hasMovedSignificantly || shouldSendDueToTime;
  }

  static Future<bool> isValidLocation(Position position) async {
    if (position.accuracy > 50) return false;

    if (DateTime.now().difference(position.timestamp) > Duration(minutes: 2)) {
      return false;
    }

    if (position.speed > 0) {
      return position.speed < 50;
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
