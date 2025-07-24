import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/services/basic_service.dart';

class LocationApiService {
  Future<DayLogStoreLocationResponseModel?> sendLocation(
    String token,
    String dayLogId,
    double latitude,
    double longitude,
    int? batteryLevel,
  ) async {
    try {
      final payload = {
        "trip_id": dayLogId,
        "latitude": latitude,
        "longitude": longitude,
        "gps_status": "1", // Assuming enabled
        if (batteryLevel != null) "battery_percentage": "$batteryLevel",
      };

      return await BasicService()
          .postDayLogLocations(token, payload)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return null;
    }
  }
}
