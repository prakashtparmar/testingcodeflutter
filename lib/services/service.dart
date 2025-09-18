import 'package:flutter/services.dart';

class Service {
  final String baseUrl = 'http://trackag.in/api';
  // final String baseUrl = 'http://43.204.216.121:8000/api';
  // final String baseUrl = 'http://3.7.254.144:8000/api';
  late final String apiLogin,
      apiRegister,
      apiResetPassword,
      apiLogout,
      apiTourDetails,
      apiDayLogs,
      apiStartTrip,
      apiUserDetail,
      apiPartyUsers,
      apiDayLogStoreLocations,
      apiDayLogCloseDayLog,
      apiLocations,
      apiLeaves,
      apiLeavesTypes,
      apiChangePassword,
      apiLeaveRequest,
      apiActiveDayLog,
      apiTripDetail,
      apiFailedJob;

  // Constructor to initialize apiLogin
  Service() {
    apiLogin = "$baseUrl/login"; // Proper URL concatenation
    apiRegister = "$baseUrl/register"; // Proper URL concatenation
    apiResetPassword = "$baseUrl/reset-password"; // Proper URL concatenation
    apiLogout = "$baseUrl/logout"; // Proper URL concatenation
    apiTourDetails = "$baseUrl/tourDetails"; // Proper URL concatenation
    apiDayLogs = "$baseUrl/trips"; // Proper URL concatenation
    apiStartTrip = "$baseUrl/trips/store"; // Proper URL concatenation
    apiUserDetail = "$baseUrl/profile"; // Proper URL concatenation
    apiPartyUsers = "$baseUrl/trip/customers"; // Proper URL concatenation
    apiDayLogStoreLocations =
        "$baseUrl/trips/log-point"; // Proper URL concatenation
    apiDayLogCloseDayLog = "$baseUrl/trip/close"; // Proper URL concatenation
    apiLocations = "$baseUrl/locations"; // Proper URL concatenation
    apiLeaves = "$baseUrl/leaves"; // Proper URL concatenation
    apiLeavesTypes = "$baseUrl/leavesTypes"; // Proper URL concatenation
    apiChangePassword = "$baseUrl/changePassword"; // Proper URL concatenation
    apiLeaveRequest = "$baseUrl/leaves"; // Proper URL concatenation
    apiActiveDayLog = "$baseUrl/trip/active"; // Proper URL concatenation
    apiTripDetail = "$baseUrl/trip/ID/detail"; // Proper URL concatenation
    apiFailedJob = "$baseUrl/failedJobs"; // Proper URL concatenation
  }

  // Battery optimization integration
  static const MethodChannel _batteryChannel = MethodChannel('location_tracker');

  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _batteryChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _batteryChannel.invokeMethod('isIgnoringBatteryOptimizations');
      return (result == true);
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }
}
