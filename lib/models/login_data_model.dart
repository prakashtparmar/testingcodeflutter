import 'user_model.dart';

class DataModel {
  final String token;
  final User user;

  DataModel({required this.token, required this.user});

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(token: json['token'], user: User.fromJson(json['user']));
  }

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}
