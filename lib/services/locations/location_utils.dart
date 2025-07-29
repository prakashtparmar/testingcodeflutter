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
    if (position.accuracy > 100) return false;
    if (DateTime.now().difference(position.timestamp) > Duration(minutes: 5)) {
      return false;
    }
    return true;
  }

  static bool isLocationAccurate(Position position) {
    return position.accuracy <= 100; // meters
  }

  static bool isLocationFresh(Position position) {
    return position.timestamp != null &&
        DateTime.now().difference(position.timestamp!) < Duration(minutes: 5);
  }
}
