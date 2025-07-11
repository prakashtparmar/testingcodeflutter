import 'dart:ffi';

import 'package:snap_check/models/role_model.dart';

class User {
  int? id;
  String? name;
  Role? role;
  String? mobile;
  String? email;
  String? emailVerifiedAt;
  int? isActive;
  String? image;
  String? createdAt;
  String? updatedAt;
  String? lastSeen;
  String? userType;
  String? userCode;
  String? headquarter;
  String? dateOfBirth;
  String? joiningDate;
  String? emergencyContactNo;
  String? gender;
  String? maritalStatus;
  String? designationId;
  String? roleRights;
  String? reportingTo;
  bool? isSelfSale;
  bool? isMultiDayStartEndAllowed;
  bool? isAllowTracking;
  String? address;
  int? stateId;
  int? districtId;
  int? cityId;
  int? tehsilId;
  Double? latitude;
  Double? longitude;
  int? pincodeId;
  int? companyId;
  String? userLevel;
  String? depo;
  String? postalAddress;
  String? status;

  User({
    this.id,
    this.name,
    this.role,
    this.mobile,
    this.email,
    this.emailVerifiedAt,
    this.isActive,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.lastSeen,
    this.userType,
    this.userCode,
    this.headquarter,
    this.dateOfBirth,
    this.joiningDate,
    this.emergencyContactNo,
    this.gender,
    this.maritalStatus,
    this.designationId,
    this.roleRights,
    this.reportingTo,
    this.isSelfSale,
    this.isMultiDayStartEndAllowed,
    this.isAllowTracking,
    this.address,
    this.stateId,
    this.districtId,
    this.cityId,
    this.tehsilId,
    this.latitude,
    this.longitude,
    this.pincodeId,
    this.companyId,
    this.userLevel,
    this.depo,
    this.postalAddress,
    this.status,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    role = json['role'];
    mobile = json['mobile'];
    email = json['email'];
    emailVerifiedAt = json['email_verified_at'];
    isActive = json['is_active'];
    image = json['image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    lastSeen = json['last_seen'];
    userType = json['user_type'];
    userCode = json['user_code'];
    headquarter = json['headquarter'];
    dateOfBirth = json['date_of_birth'];
    joiningDate = json['joining_date'];
    emergencyContactNo = json['emergency_contact_no'];
    gender = json['gender'];
    maritalStatus = json['marital_status'];
    designationId = json['designation_id'];
    roleRights = json['role_rights'];
    reportingTo = json['reporting_to'];
    isSelfSale = json['is_self_sale'];
    isMultiDayStartEndAllowed = json['is_multi_day_start_end_allowed'];
    isAllowTracking = json['is_allow_tracking'];
    address = json['address'];
    stateId = json['state_id'];
    districtId = json['district_id'];
    cityId = json['city_id'];
    tehsilId = json['tehsil_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    pincodeId = json['pincode_id'];
    companyId = json['company_id'];
    userLevel = json['user_level'];
    depo = json['depo'];
    postalAddress = json['postal_address'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['role'] = role;
    data['mobile'] = mobile;
    data['email'] = email;
    data['email_verified_at'] = emailVerifiedAt;
    data['is_active'] = isActive;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['last_seen'] = lastSeen;
    data['user_type'] = userType;
    data['user_code'] = userCode;
    data['headquarter'] = headquarter;
    data['date_of_birth'] = dateOfBirth;
    data['joining_date'] = joiningDate;
    data['emergency_contact_no'] = emergencyContactNo;
    data['gender'] = gender;
    data['marital_status'] = maritalStatus;
    data['designation_id'] = designationId;
    data['role_rights'] = roleRights;
    data['reporting_to'] = reportingTo;
    data['is_self_sale'] = isSelfSale;
    data['is_multi_day_start_end_allowed'] = isMultiDayStartEndAllowed;
    data['is_allow_tracking'] = isAllowTracking;
    data['address'] = address;
    data['state_id'] = stateId;
    data['district_id'] = districtId;
    data['city_id'] = cityId;
    data['tehsil_id'] = tehsilId;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['pincode_id'] = pincodeId;
    data['company_id'] = companyId;
    data['user_level'] = userLevel;
    data['depo'] = depo;
    data['postal_address'] = postalAddress;
    data['status'] = status;
    return data;
  }
}
