import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snap_check/models/change_password_response_model.dart';
import 'package:snap_check/models/login_response_model.dart';
import 'package:snap_check/models/register_response_model.dart';
import 'package:snap_check/models/user_response_model.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/service.dart';
import 'package:snap_check/services/share_pref.dart';

class AuthService extends Service {
  Future<LoginResponseModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(apiLogin),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    debugPrint(response.body);
    return LoginResponseModel.fromJson(jsonDecode(response.body));
  }

  Future<RegisterResponseModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String firstName,
    required String lastName,
    required String addressLine1,
    required String addressLine2,
    required int talukaId,
    required int cityId,
    required int stateId,
    required int countryId,
  }) async {
    final response = await http.post(
      Uri.parse(apiRegister),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'first_name': firstName,
        'last_name': lastName,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'taluka_id': talukaId,
        'city_id': cityId,
        'state_id': stateId,
        'country_id': countryId,
      }),
    );

    return RegisterResponseModel.fromJson(_handleResponse(response));
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final response = await http.post(
      Uri.parse(apiResetPassword),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send password reset email');
    }
  }

  Future<bool> signOut(String token) async {
    // For stateless REST APIs, sign out is often just deleting token locally
    // Implement as needed
    debugPrint(token);
    final response = await http.post(
      Uri.parse(apiLogout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      SharedPrefHelper.clearUser();
      return true;
    } else {
      return false;
    }
  }

  Future<UserResponseModel?> fetchUserDetail(String token) async {
    final response = await http.post(
      Uri.parse(apiUserDetail),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return UserResponseModel.fromJson(_handleResponse(response));
  }

  Future<UserResponseModel> postUserDetail({
    required String token,
    required String firstName,
    required String lastName,
    required String addressLine1,
    required String addressLine2,
    required int talukaId,
    required int cityId,
    required int stateId,
    required int countryId,
    required String? gender,
  }) async {
    final response = await http.put(
      Uri.parse(apiUserDetail),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'taluka_id': talukaId,
        'city_id': cityId,
        'state_id': stateId,
        'country_id': countryId,
        'gender': gender,
      }),
    );

    return UserResponseModel.fromJson(_handleResponse(response));
  }

  Future<ChangePasswordResponseModel> postChangePassword({
    required String token,
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse(apiChangePassword),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': oldPassword,
        'new_password': password,
        'new_password_confirmation': passwordConfirmation,
      }),
    );

    return ChangePasswordResponseModel.fromJson(_handleResponse(response));
  }

  // Common response handler
  dynamic _handleResponse(http.Response response) {
    debugPrint('Response URL: ${response.request!.url.path}');
    debugPrint('Response Method: ${response.request!.method}');
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    switch (response.statusCode) {
      case 200:
      case 422:
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
