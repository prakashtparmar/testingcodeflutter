import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SharedPrefHelper {
  static const String _userKey = 'logged_in_user';

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

  // Clear user
  static Future<void> clearUser() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_userKey);
  }
}
