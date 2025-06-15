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
    firstName = (json['first_name'] as List?)?.cast<String>();
    lastName = (json['last_name'] as List?)?.cast<String>();
    addressLine1 = (json['address_line_1'] as List?)?.cast<String>();
    addressLine2 = (json['address_line_2'] as List?)?.cast<String>();
    talukaId = (json['taluka_id'] as List?)?.cast<String>();
    cityId = (json['city_id'] as List?)?.cast<String>();
    stateId = (json['state_id'] as List?)?.cast<String>();
    countryId = (json['country_id'] as List?)?.cast<String>();
    email = (json['email'] as List?)?.cast<String>();
    password = (json['password'] as List?)?.cast<String>();
    passwordConfirmation =
        (json['password_confirmation'] as List?)?.cast<String>();
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

  /// 🔥 Combine all error messages into one string
  String getAllMessages() {
    final List<String> allErrors = [];

    final List<List<String>?> fields = [
      firstName,
      lastName,
      addressLine1,
      addressLine2,
      talukaId,
      cityId,
      stateId,
      countryId,
      email,
      password,
      passwordConfirmation,
    ];

    for (var field in fields) {
      if (field != null) {
        allErrors.addAll(field);
      }
    }

    return allErrors.join('\n'); // You can also use ", " if you prefer inline
  }
}
