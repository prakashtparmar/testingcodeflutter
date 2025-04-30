import 'package:snap_check/models/login_data_model.dart';

class LoginResponseModel {
  final bool success;
  final String message;
  final DataModel? data;

  LoginResponseModel({required this.success, required this.message, this.data});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? DataModel.fromJson(json['data']) : null,
    );
  }
}
