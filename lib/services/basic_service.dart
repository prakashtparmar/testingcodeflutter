import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snap_check/models/day_log_response_model.dart';
import 'package:snap_check/models/tour_details_response_model.dart';
import 'package:snap_check/services/service.dart';

class BasicService extends Service {
  Future<TourDetailsResponseModel?> getTourDetails() async {
    final response = await http.get(
      Uri.parse(apiTourDetails),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return TourDetailsResponseModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  Future<DayLogResponseModel?> getDayLogs(String token) async {
    final response = await http.get(
      Uri.parse(apiDayLogs),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return DayLogResponseModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }
}
