class Service {
  final String baseUrl =
      'http://10.0.2.2:8000/api'; // Replace with your backend URL
  // 'http://127.0.0.1:8000/api'; // Replace with your backend URL
  late final String apiLogin,
      apiRegister,
      apiResetPassword,
      apiLogout,
      apiTourDetails,
      apiDayLogs,
      apiUserDetail,
      apiPartyUsers,
      apiDayLogStoreLocations,
      apiDayLogCloseDayLog,
      apiLocations,
      apiLeaves,
      apiLeavesTypes,
      apiChangePassword,
      apiLeaveRequest,
      apiActiveDayLog;

  // Constructor to initialize apiLogin
  Service() {
    apiLogin = "$baseUrl/login"; // Proper URL concatenation
    apiRegister = "$baseUrl/register"; // Proper URL concatenation
    apiResetPassword = "$baseUrl/reset-password"; // Proper URL concatenation
    apiLogout = "$baseUrl/logout"; // Proper URL concatenation
    apiTourDetails = "$baseUrl/tourDetails"; // Proper URL concatenation
    apiDayLogs = "$baseUrl/trips"; // Proper URL concatenation
    apiUserDetail = "$baseUrl/userDetail"; // Proper URL concatenation
    apiPartyUsers = "$baseUrl/partyUsers"; // Proper URL concatenation
    apiDayLogStoreLocations =
        "$baseUrl/dayLogs/storeLocations"; // Proper URL concatenation
    apiDayLogCloseDayLog =
        "$baseUrl/dayLogs/closeDayLog"; // Proper URL concatenation
    apiLocations = "$baseUrl/locations"; // Proper URL concatenation
    apiLeaves = "$baseUrl/leaves"; // Proper URL concatenation
    apiLeavesTypes = "$baseUrl/leavesTypes"; // Proper URL concatenation
    apiChangePassword = "$baseUrl/changePassword"; // Proper URL concatenation
    apiLeaveRequest = "$baseUrl/leaves"; // Proper URL concatenation
    apiActiveDayLog = "$baseUrl/trip/active"; // Proper URL concatenation
  }
}
