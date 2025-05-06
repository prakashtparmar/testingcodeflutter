
import 'package:snap_check/models/user_data_model.dart';

class UserResponseModel {
  final bool success;
  final String message;
  final UserDataModel? data;

  UserResponseModel({required this.success, required this.message, this.data});

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserDataModel.fromJson(json['data']) : null,
    );
  }
}
