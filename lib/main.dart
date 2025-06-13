import 'package:flutter/material.dart';
import 'package:snap_check/screens/add_day_log_screen.dart';
import 'package:snap_check/screens/day_log_list_screen.dart';
import 'package:snap_check/screens/forgot_password_screen.dart';
import 'package:snap_check/screens/home_screen.dart';
import 'package:snap_check/screens/leave_request_screen.dart';
import 'package:snap_check/screens/leaves_list_screen.dart';
import 'package:snap_check/screens/login_screen.dart';
import 'package:snap_check/screens/setting_screen.dart';
import 'package:snap_check/screens/signup_screen.dart';
import 'package:snap_check/screens/splash_screen.dart';
import 'package:snap_check/screens/user_detail_screen.dart';
import 'package:snap_check/theme/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final ThemeMode _themeMode = ThemeMode.system;
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode, // system / light / dark
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/forgot': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/settings': (context) => SettingsScreen(),
        '/dayLogs': (context) => DayLogsListScreen(),
        '/addDayLog': (context) => AddDayLogScreen(),
        '/userDetail': (context) => UserDetailScreen(),
        '/leaves': (context) => LeavesListScreen(),
        '/leaveRequest': (context) => LeaveRequestScreen(),
      },
    );
  }
}
