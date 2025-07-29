import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/services/basic_service.dart';

class LocationApiService {
  Future<DayLogStoreLocationResponseModel?> sendLocation(
    String token,
    String dayLogId,
    double latitude,
    double longitude,
    int? batteryLevel,
    String gpsStatus,
    String? recordedAt,
  ) async {
    try {
      final payload = {
        "trip_id": dayLogId,
        "latitude": latitude,
        "longitude": longitude,
        "gps_status": gpsStatus,
        "battery_percentage": "$batteryLevel",
        "recorded_at": "$recordedAt",
      };

      return await BasicService().postDayLogLocations(token, payload);
    } catch (e) {
      return null;
    }
  }
}
