import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SharedPrefHelper {
  static const String _userKey = 'logged_in_user';
  static const String _tokenKey = 'token';
  static const String _activeDayLogId = 'activeDayLogId';
  static const String _isTrackingActive = 'isTrackingActive';

  // Save user
  static Future<void> saveUser(User user) async {
    final pref = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await pref.setString(_userKey, userJson);
  }

  // Load user
  static Future<User?> loadUser() async {
    final pref = await SharedPreferences.getInstance();
    final userString = pref.getString(_userKey);
    if (userString == null) return null;

    final userMap = jsonDecode(userString);
    return User.fromJson(userMap);
  }

  static Future<void> saveToken(String token) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final pref = await SharedPreferences.getInstance();
    final tokenString = pref.getString(_tokenKey);
    if (tokenString == null) return null;
    return tokenString;
  }

  static Future<void> saveActiveDayLogId(String activeDayLogId) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_activeDayLogId, activeDayLogId);
  }

  static Future<String?> getActiveDayLogId() async {
    final pref = await SharedPreferences.getInstance();
    final activeDayLogId = pref.getString(_activeDayLogId);
    if (activeDayLogId == null) return null;
    return activeDayLogId;
  }

  // Clear activeDayLog
  static Future<void> clearActiveDayLog() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_activeDayLogId);
  }

  // Clear user
  static Future<void> clearToken() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_tokenKey);
  }

  // Clear user
  static Future<void> clearUser() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_userKey);
    await pref.remove(_tokenKey);
  }

  static Future<bool> isTrackingActive() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(_isTrackingActive) ?? false;
  }

  static Future<void> setTrackingActive(bool isTrackingActive) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(_isTrackingActive, isTrackingActive);
  }
}
