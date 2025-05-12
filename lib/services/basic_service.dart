import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snap_check/models/day_log_response_model.dart';
import 'package:snap_check/models/party_user_response_model.dart';
import 'package:snap_check/models/post_day_log_response_model.dart';
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
    debugPrint(apiDayLogs);
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

  Future<PostDayLogsResponseModel?> postDayLog(String token) async {
    final response = await http.post(
      Uri.parse(apiDayLogs),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        "Authorization": "Bearer $token",
      },
      body: ""
    );

    return PostDayLogsResponseModel.fromJson(jsonDecode(response.body));
  }
}
