import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/active_day_log_response_model.dart';
import 'package:snap_check/models/day_log_data_model.dart';
import 'package:snap_check/models/day_log_detail_response_model.dart';
import 'package:snap_check/models/day_log_response_model.dart';
import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/models/day_logs_data_model.dart';
import 'package:snap_check/models/leave_request_response_model.dart';
import 'package:snap_check/models/leave_types_response_model.dart';
import 'package:snap_check/models/leaves_response_model.dart';
import 'package:snap_check/models/locations_response_model.dart';
import 'package:snap_check/models/party_user_response_model.dart';
import 'package:snap_check/models/post_day_log_response_model.dart';
import 'package:snap_check/models/tour_details_response_model.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/service.dart';
import 'package:path/path.dart';

class BasicService extends Service {
  Future<LocationsResponseModel?> getLocations() async {
    final response = await http.get(
      Uri.parse(apiLocations),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    return LocationsResponseModel.fromJson(_handleResponse(response));
  }

  Future<TourDetailsResponseModel?> getTourDetails(String token) async {
    final response = await http.get(
      Uri.parse(apiTourDetails),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return TourDetailsResponseModel.fromJson(_handleResponse(response));
  }

  Future<DayLogResponseModel?> getDayLogs(String token) async {
    debugPrint(apiDayLogs);
    final response = await http.get(
      Uri.parse(apiDayLogs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return DayLogResponseModel.fromJson(_handleResponse(response));
  }

  Future<PartyUsersResponseModel?> getPartyUsers(String token) async {
    final response = await http.get(
      Uri.parse(apiPartyUsers),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return PartyUsersResponseModel.fromJson(_handleResponse(response));
  }

  Future<PostDayLogsResponseModel?> postDayLog(
    String token,
    XFile? imageFile,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse(apiDayLogs);
    final request = http.MultipartRequest('POST', uri);
    // Set headers (note: Content-Type will be set automatically)
    request.headers.addAll({
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Content-type": "application/json",
    });
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
    debugPrint(responseString.toString());
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
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return DayLogDetailResponseModel.fromJson(_handleResponse(response));
  }

  Future<DayLogStoreLocationResponseModel?> postDayLogLocations(
    String token,
    Map<String, Object> body,
  ) async {
    final response = await http.post(
      Uri.parse(apiDayLogStoreLocations),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    return DayLogStoreLocationResponseModel.fromJson(_handleResponse(response));
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
    debugPrint(responseString);
    return PostDayLogsResponseModel.fromJson(jsonDecode(responseString));
  }

  Future<LeavesResponseModel?> getLeaves(String token) async {
    final response = await http.get(
      Uri.parse(apiLeaves),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return LeavesResponseModel.fromJson(_handleResponse(response));
  }

  Future<LeaveTypeResponseModel?> getLeaveTypes(String token) async {
    final response = await http.get(
      Uri.parse(apiLeavesTypes),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return LeaveTypeResponseModel.fromJson(_handleResponse(response));
  }

  Future<LeaveRequestResponseModel?> postLeaveRequest(
    String token,
    Map<String, Object> body,
  ) async {
    final response = await http.post(
      Uri.parse(apiLeaveRequest),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    return LeaveRequestResponseModel.fromJson(_handleResponse(response));
  }

  Future<ActiveDayLogResponseModel?> getActiveDayLog(String token) async {
    final response = await http.get(
      Uri.parse(apiActiveDayLog),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return ActiveDayLogResponseModel.fromJson(_handleResponse(response));
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint('Response URL: ${response.request!.url.path}');
    debugPrint('Response Headers: ${response.request!.headers.values}');
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        return jsonDecode(response.body);

      case 401:
        throw UnauthorizedException();

      case 404:
        throw NotFoundException();

      case 500:
        throw ServerErrorException();

      default:
        throw UnknownApiException(
          response.statusCode,
          response.reasonPhrase ?? 'Unexpected error',
        );
    }
  }
}
