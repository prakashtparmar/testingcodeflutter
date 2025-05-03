class Service {
  final String baseUrl =
      'http://localhost:8000/api'; // Replace with your backend URL
  late final String apiLogin,
      apiRegister,
      apiResetPassword,
      apiLogout,
      apiTourDetails,
      apiDayLogs;

  // Constructor to initialize apiLogin
  Service() {
    apiLogin = "$baseUrl/login"; // Proper URL concatenation
    apiRegister = "$baseUrl/register"; // Proper URL concatenation
    apiResetPassword = "$baseUrl/reset-password"; // Proper URL concatenation
    apiLogout = "$baseUrl/logout"; // Proper URL concatenation
    apiTourDetails = "$baseUrl/tourDetails"; // Proper URL concatenation
    apiDayLogs = "$baseUrl/dayLogs"; // Proper URL concatenation
  }
}
