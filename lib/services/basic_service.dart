import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/active_day_log_response_model.dart';
import 'package:snap_check/models/day_log_detail_response_model.dart';
import 'package:snap_check/models/day_log_response_model.dart';
import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/models/leave_request_response_model.dart';
import 'package:snap_check/models/leave_types_response_model.dart';
import 'package:snap_check/models/leaves_response_model.dart';
import 'package:snap_check/models/locations_response_model.dart';
import 'package:snap_check/models/party_user_response_model.dart';
import 'package:snap_check/models/post_day_log_response_model.dart';
import 'package:snap_check/models/start_trip_response_model.dart';
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

    return LocationsResponseModel.fromJson(_handleResponse("", response));
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

    return TourDetailsResponseModel.fromJson(_handleResponse("", response));
  }

  Future<DayLogResponseModel?> getDayLogs(String token) async {
    final response = await http.get(
      Uri.parse(apiDayLogs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return DayLogResponseModel.fromJson(_handleResponse("", response));
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

    return PartyUsersResponseModel.fromJson(_handleResponse("", response));
  }

  Future<StartTripResponseModel?> postDayLog(
    String token,
    XFile? imageFile,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse(apiStartTrip);
    final request = http.MultipartRequest('POST', uri);
    // Set headers (note: Content-Type will be set automatically)
    request.headers.addAll({
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });
    // Add text fields (like date, place, km, etc.)

    // Add fields one by one
    fields.forEach((key, value) {
      request.fields[key] = value;
    });
    // Add image file (optional)
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'start_km_photo', // key expected by your backend
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );
    }
    // Send the request
    final response = await request.send();
    final responseFormat = await response.stream.bytesToString();

    return StartTripResponseModel.fromJson(jsonDecode(responseFormat));
  }

  Future<DayLogDetailResponseModel?> getDayLogDetail(
    String token,
    int dayLog,
  ) async {
    final response = await http.get(
      Uri.parse(apiTripDetail.replaceAll("ID", dayLog.toString())),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    return DayLogDetailResponseModel.fromJson(_handleResponse("", response));
  }

  Future<DayLogStoreLocationResponseModel?> postDayLogLocations(
    String token,
    Map<String, dynamic> fields,
  ) async {
    final response = await http.post(
      Uri.parse(apiDayLogStoreLocations),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(fields),
    );

    return DayLogStoreLocationResponseModel.fromJson(
      _handleResponse(jsonEncode(fields), response),
    );
  }

  Future<PostDayLogsResponseModel?> postCloseDay(
    String token,
    XFile? imageFile,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse(apiDayLogCloseDayLog);
    final request = http.MultipartRequest('POST', uri);
    // Set headers (note: Content-Type will be set automatically)
    request.headers.addAll({"Accept": "application/json"});
    request.headers.addAll({"Authorization": "Bearer $token"});
    // Add text fields (like date, place, km, etc.)
    request.fields.addAll(fields);
    // Add image file (optional)
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'end_km_photo', // key expected by your backend
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );
    }
    // Send the request
    final response = await request.send();
    final responseFormat = await response.stream.bytesToString();

    return PostDayLogsResponseModel.fromJson(jsonDecode(responseFormat));
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

    return LeavesResponseModel.fromJson(_handleResponse("",response));
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

    return LeaveTypeResponseModel.fromJson(_handleResponse("",response));
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

    return LeaveRequestResponseModel.fromJson(
      _handleResponse(jsonEncode(body), response),
    );
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

    return ActiveDayLogResponseModel.fromJson(_handleResponse("",response));
  }

  Future<LeaveRequestResponseModel?> postFailedJob(
    Map<String, Object> body,
  ) async {
    final response = await http.post(
      Uri.parse(apiFailedJob),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    return LeaveRequestResponseModel.fromJson(
      _handleResponse(jsonEncode(body), response),
    );
  }

  dynamic _handleResponse(String? request, http.Response response) {
    debugPrint('Response URL: ${response.request!.url.path}');
    debugPrint('Response Requests: $request');
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
