class Service {
  final String baseUrl =
      'http://10.0.2.2:8000/api'; // Replace with your backend URL
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
      apiLocations;

  // Constructor to initialize apiLogin
  Service() {
    apiLogin = "$baseUrl/login"; // Proper URL concatenation
    apiRegister = "$baseUrl/register"; // Proper URL concatenation
    apiResetPassword = "$baseUrl/reset-password"; // Proper URL concatenation
    apiLogout = "$baseUrl/logout"; // Proper URL concatenation
    apiTourDetails = "$baseUrl/tourDetails"; // Proper URL concatenation
    apiDayLogs = "$baseUrl/dayLogs"; // Proper URL concatenation
    apiUserDetail = "$baseUrl/userDetail"; // Proper URL concatenation
    apiPartyUsers = "$baseUrl/partyUsers"; // Proper URL concatenation
    apiDayLogStoreLocations =
        "$baseUrl/dayLogs/storeLocations"; // Proper URL concatenation
    apiDayLogCloseDayLog =
        "$baseUrl/dayLogs/closeDayLog"; // Proper URL concatenation
    apiLocations = "$baseUrl/locations"; // Proper URL concatenation
  }
}
