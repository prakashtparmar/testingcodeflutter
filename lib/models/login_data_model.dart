import 'user_model.dart';

class LoginDataModel {
  final String token;
  final User user;

  LoginDataModel({required this.token, required this.user});

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(token: json['token'], user: User.fromJson(json['user']));
  }

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}
