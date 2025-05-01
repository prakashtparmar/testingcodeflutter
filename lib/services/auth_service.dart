import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snap_check/models/login_response_model.dart';
import 'package:snap_check/models/user_model.dart';
import 'package:snap_check/screens/login_screen.dart';
import 'package:snap_check/services/share_pref.dart';

class AuthService {
  final String baseUrl =
      'http://localhost:8000/api'; // Replace with your backend URL

  Future<LoginResponseModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
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
      Uri.parse('$baseUrl/register'),
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
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send password reset email');
    }
  }

  Future<void> signOut(String token) async {
    // For stateless REST APIs, sign out is often just deleting token locally
    // Implement as needed
    debugPrint(token);
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      SharedPrefHelper.clearUser();
    } else {
      throw Exception(response.body);
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
