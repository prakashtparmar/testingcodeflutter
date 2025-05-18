import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/day_log_detail_response_model.dart';
import 'package:snap_check/models/day_log_response_model.dart';
import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/models/party_user_response_model.dart';
import 'package:snap_check/models/post_day_log_response_model.dart';
import 'package:snap_check/models/tour_details_response_model.dart';
import 'package:snap_check/services/service.dart';
import 'package:path/path.dart';

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
    debugPrint(apiDayLogs);
    final response = await http.get(
      Uri.parse(apiDayLogs),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );
    debugPrint(response.body);

    return DayLogResponseModel.fromJson(jsonDecode(response.body));
  }

  Future<PartyUsersResponseModel?> getPartyUsers(String token) async {
    final response = await http.get(
      Uri.parse(apiPartyUsers),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return PartyUsersResponseModel.fromJson(jsonDecode(response.body));
  }

  Future<PostDayLogsResponseModel?> postDayLog(
    String token,
    XFile? imageFile,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse(apiDayLogs);
    final request = http.MultipartRequest('POST', uri);
    // Set headers (note: Content-Type will be set automatically)
    request.headers.addAll({"Authorization": "Bearer $token"});
    // Add text fields (like date, place, km, etc.)
    request.fields.addAll(fields);
    // Add image file (optional)
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'opening_km_image', // key expected by your backend
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );
    }
    // Send the request
    final response = await request.send();
    final responseString = await response.stream.bytesToString();

    return PostDayLogsResponseModel.fromJson(jsonDecode(responseString));
  }

  Future<DayLogDetailResponseModel?> getDayLogDetail(
    String token,
    int dayLog,
  ) async {
    final response = await http.get(
      Uri.parse('$apiDayLogs/$dayLog'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return DayLogDetailResponseModel.fromJson(jsonDecode(response.body));
  }

  Future<DayLogStoreLocationResponseModel?> postDayLogLocations(
    String token,
    Map<String, Object> body,
  ) async {
    final response = await http.post(
      Uri.parse(apiDayLogStoreLocations),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    return DayLogStoreLocationResponseModel.fromJson(jsonDecode(response.body));
  }

  Future<PostDayLogsResponseModel?> postCloseDay(
    String token,
    XFile? imageFile,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse(apiDayLogCloseDayLog);
    final request = http.MultipartRequest('POST', uri);
    // Set headers (note: Content-Type will be set automatically)
    request.headers.addAll({"Authorization": "Bearer $token"});
    // Add text fields (like date, place, km, etc.)
    request.fields.addAll(fields);
    // Add image file (optional)
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'closing_km_image', // key expected by your backend
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );
    }
    // Send the request
    final response = await request.send();
    final responseString = await response.stream.bytesToString();

    return PostDayLogsResponseModel.fromJson(jsonDecode(responseString));
  }
}
