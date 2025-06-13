import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/country_model.dart';
import 'package:snap_check/models/designation_model.dart';
import 'package:snap_check/models/role_model.dart';
import 'package:snap_check/models/state_model.dart';
import 'package:snap_check/models/taluka_model.dart';

class User {
  int? id;
  String? firstName;
  String? lastName;
  String? mobile;
  String? dob;
  String? emergencyContactNo;
  String? gender;
  String? maritalStatus;
  String? addressLine1;
  String? addressLine2;
  int? designationId;
  int? managerId;
  int? roleId;
  int? talukaId;
  int? cityId;
  int? stateId;
  int? countryId;
  String? email;
  String? lastLoginAt;
  String? lastLogoutAt;
  String? fcmToken;
  bool? allowTracking;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? fullName;
  String? fullAddress;
  CityModel? city;
  StateModel? state;
  CountryModel? country;
  Role? role;
  DesignationModel? designation;
  User? manager;
  TalukaModel? taluka;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.mobile,
    this.dob,
    this.emergencyContactNo,
    this.gender,
    this.maritalStatus,
    this.addressLine1,
    this.addressLine2,
    this.designationId,
    this.managerId,
    this.roleId,
    this.talukaId,
    this.cityId,
    this.stateId,
    this.countryId,
    this.email,
    this.lastLoginAt,
    this.lastLogoutAt,
    this.fcmToken,
    this.allowTracking,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.fullName,
    this.fullAddress,
    this.city,
    this.state,
    this.country,
    this.role,
    this.designation,
    this.manager,
    this.taluka,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    mobile = json['mobile'];
    dob = json['dob'];
    emergencyContactNo = json['emergency_contact_no'];
    gender = json['gender'];
    maritalStatus = json['marital_status'];
    addressLine1 = json['address_line_1'];
    addressLine2 = json['address_line_2'];
    designationId = json['designation_id'];
    managerId = json['manager_id'];
    roleId = json['role_id'];
    talukaId = json['taluka_id'];
    cityId = json['city_id'];
    stateId = json['state_id'];
    countryId = json['country_id'];
    email = json['email'];
    lastLoginAt = json['last_login_at'];
    lastLogoutAt = json['last_logout_at'];
    fcmToken = json['fcm_token'];
    allowTracking = json['allow_tracking'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    fullName = json['full_name'];
    fullAddress = json['full_address'];
    city = json['city'] != null ? CityModel.fromJson(json['city']) : null;
    state = json['state'] != null ? StateModel.fromJson(json['state']) : null;
    country =
        json['country'] != null ? CountryModel.fromJson(json['country']) : null;
    role = json['role'] != null ? Role.fromJson(json['role']) : null;
    designation =
        json['designation'] != null
            ? DesignationModel.fromJson(json['designation'])
            : null;
    manager =
        json['manager'] != null ? User.fromJson(json['manager']) : null;
    taluka =
        json['taluka'] != null ? TalukaModel.fromJson(json['taluka']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['mobile'] = mobile;
    data['dob'] = dob;
    data['emergency_contact_no'] = emergencyContactNo;
    data['gender'] = gender;
    data['marital_status'] = maritalStatus;
    data['address_line_1'] = addressLine1;
    data['address_line_2'] = addressLine2;
    data['designation_id'] = designationId;
    data['manager_id'] = managerId;
    data['role_id'] = roleId;
    data['taluka_id'] = talukaId;
    data['city_id'] = cityId;
    data['state_id'] = stateId;
    data['country_id'] = countryId;
    data['email'] = email;
    data['last_login_at'] = lastLoginAt;
    data['last_logout_at'] = lastLogoutAt;
    data['fcm_token'] = fcmToken;
    data['allow_tracking'] = allowTracking;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['full_name'] = fullName;
    data['full_address'] = fullAddress;
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
    if (designation != null) {
      data['designation'] = designation!.toJson();
    }
    if (manager != null) {
      data['manager'] = manager!.toJson();
    }
    if (taluka != null) {
      data['taluka'] = taluka!.toJson();
    }
    return data;
  }
}
