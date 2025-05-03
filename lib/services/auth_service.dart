import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snap_check/models/login_response_model.dart';
import 'package:snap_check/models/user_model.dart';
import 'package:snap_check/services/service.dart';
import 'package:snap_check/services/share_pref.dart';

class AuthService extends Service {
  Future<LoginResponseModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(apiLogin),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return LoginResponseModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  Future<User?> registerWithEmailPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse(apiRegister),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final response = await http.post(
      Uri.parse(apiResetPassword),
      headers: {'Content-Type': 'application/json'},
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

  Future<User?> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('User not found');
    }
  }
}
