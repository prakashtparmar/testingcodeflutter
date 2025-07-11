import 'user_model.dart';

class LoginDataModel {
  final String? token;
  final User? user;
  final String? error;

  LoginDataModel({this.token, this.user, this.error});

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error') && json['error'] != null) {
      // Error response
      return LoginDataModel(error: json['error']);
    } else {
      // Success response
      return LoginDataModel(
        token: json['token'],
        user: json['user'] != null ? User.fromJson(json['user']) : null,
      );
    }
  }

  Map<String, dynamic> toJson() => {
    if (token != null) 'token': token,
    if (user != null) 'user': user!.toJson(),
    if (error != null) 'error': error,
  };
}
