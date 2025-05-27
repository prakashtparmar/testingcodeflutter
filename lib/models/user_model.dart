import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/country_model.dart';
import 'package:snap_check/models/role_model.dart';
import 'package:snap_check/models/state_model.dart';

class User {
  int? id;
  String? firstName;
  String? lastName;
  String? addressLine1;
  String? addressLine2;
  String? email;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  int? cityId;
  int? stateId;
  int? countryId;
  int? roleId;
  String? deletedAt;
  CityModel? city;
  StateModel? state;
  CountryModel? country;
  Role? role;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.addressLine1,
    this.addressLine2,
    this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.cityId,
    this.stateId,
    this.countryId,
    this.roleId,
    this.deletedAt,
    this.city,
    this.state,
    this.country,
    this.role,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    addressLine1 = json['address_line1'];
    addressLine2 = json['address_line2'];
    email = json['email'];
    emailVerifiedAt = json['email_verified_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    cityId = json['city_id'];
    stateId = json['state_id'];
    countryId = json['country_id'];
    roleId = json['role_id'];
    deletedAt = json['deleted_at'];
    city = json['city'] != null ? CityModel.fromJson(json['city']) : null;
    state = json['state'] != null ? StateModel.fromJson(json['state']) : null;
    country =
        json['country'] != null ? CountryModel.fromJson(json['country']) : null;
    role = json['role'] != null ? Role.fromJson(json['role']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['address_line1'] = addressLine1;
    data['address_line2'] = addressLine2;
    data['email'] = email;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['city_id'] = cityId;
    data['state_id'] = stateId;
    data['country_id'] = countryId;
    data['role_id'] = roleId;
    data['deleted_at'] = deletedAt;
    if (city != null) {
      data['city'] = city!.toJson();
    }
    if (state != null) {
      data['state'] = state!.toJson();
    }
    if (country != null) {
      data['country'] = country!.toJson();
    }
    if (role != null) {
      data['role'] = role!.toJson();
    }
    return data;
  }
}
