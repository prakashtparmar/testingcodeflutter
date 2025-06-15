import 'package:snap_check/models/user_model.dart';

class RegisterResponseModel {
  String? message;
  Errors? errors;
  User? data;

  RegisterResponseModel({this.message, this.errors});

  RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? User.fromJson(json['data']) : null;

    errors = json['errors'] != null ? Errors.fromJson(json['errors']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (errors != null) {
      data['errors'] = errors!.toJson();
    }
    return data;
  }
}

class Errors {
  List<String>? firstName;
  List<String>? lastName;
  List<String>? addressLine1;
  List<String>? addressLine2;
  List<String>? talukaId;
  List<String>? cityId;
  List<String>? stateId;
  List<String>? countryId;
  List<String>? email;
  List<String>? password;
  List<String>? passwordConfirmation;

  Errors({
    this.firstName,
    this.lastName,
    this.addressLine1,
    this.addressLine2,
    this.talukaId,
    this.cityId,
    this.stateId,
    this.countryId,
    this.email,
    this.password,
    this.passwordConfirmation,
  });

  Errors.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'].cast<String>();
    lastName = json['last_name'].cast<String>();
    addressLine1 = json['address_line_1'].cast<String>();
    addressLine2 = json['address_line_2'].cast<String>();
    talukaId = json['taluka_id'].cast<String>();
    cityId = json['city_id'].cast<String>();
    stateId = json['state_id'].cast<String>();
    countryId = json['country_id'].cast<String>();
    email = json['email'].cast<String>();
    password = json['password'].cast<String>();
    passwordConfirmation = json['password_confirmation'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['address_line_1'] = addressLine1;
    data['address_line_2'] = addressLine2;
    data['taluka_id'] = talukaId;
    data['city_id'] = cityId;
    data['state_id'] = stateId;
    data['country_id'] = countryId;
    data['email'] = email;
    data['password'] = password;
    data['password_confirmation'] = passwordConfirmation;
    return data;
  }
}
