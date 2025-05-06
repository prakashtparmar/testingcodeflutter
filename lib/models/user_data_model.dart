import 'user_model.dart';

class UserDataModel {
  final User user;

  UserDataModel({required this.user});

  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    return UserDataModel(user: User.fromJson(json['user']));
  }

  Map<String, dynamic> toJson() => {'user': user.toJson()};
}
