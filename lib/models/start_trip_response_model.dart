class StartTripResponseModel {
  bool? success;
  StartTripDataModel? data;
  String? message;

  StartTripResponseModel({this.success, this.data, this.message});

  StartTripResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? StartTripDataModel.fromJson(json['data']) : null;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = message;
    return data;
  }
}

class StartTripDataModel {
  int? userId;
  int? companyId;
  String? tripDate;
  String? startTime;
  String? endTime;
  String? startLat;
  String? startLng;
  String? endLat;
  String? endLng;
  String? totalDistanceKm;
  TravelMode? travelMode;
  TravelMode? purpose;
  TravelMode? tourType;
  String? placeToVisit;
  String? startingKm;
  String? endKm;
  String? startKmPhoto;
  String? endKmPhoto;
  String? status;
  String? approvalStatus;
  String? updatedAt;
  String? createdAt;
  int? id;
  Company? company;
  UserModel? approvedByUser;
  UserModel? user;

  StartTripDataModel({
    this.userId,
    this.companyId,
    this.tripDate,
    this.startTime,
    this.endTime,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.totalDistanceKm,
    this.travelMode,
    this.purpose,
    this.tourType,
    this.placeToVisit,
    this.startingKm,
    this.endKm,
    this.startKmPhoto,
    this.endKmPhoto,
    this.status,
    this.approvalStatus,
    this.updatedAt,
    this.createdAt,
    this.id,
    this.company,
    this.approvedByUser,
    this.user,
  });

  StartTripDataModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    companyId = json['company_id'];
    tripDate = json['trip_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    startLat = json['start_lat'];
    startLng = json['start_lng'];
    endLat = json['end_lat'];
    endLng = json['end_lng'];
    totalDistanceKm = json['total_distance_km'];
    travelMode =
        json['travel_mode'] != null
            ? TravelMode.fromJson(json['travel_mode'])
            : null;
    purpose =
        json['purpose'] != null
            ? TravelMode.fromJson(json['purpose'])
            : null;
    tourType =
        json['tour_type'] != null
            ? TravelMode.fromJson(json['tour_type'])
            : null;
    placeToVisit = json['place_to_visit'];
    startingKm = json['starting_km'];
    endKm = json['end_km'];
    startKmPhoto = json['start_km_photo'];
    endKmPhoto = json['end_km_photo'];
    status = json['status'];
    approvalStatus = json['approval_status'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
    company =
        json['company'] != null ? Company.fromJson(json['company']) : null;
    approvedByUser = json['approved_by_user'];
    user = json['user'] != null ? UserModel.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['company_id'] = companyId;
    data['trip_date'] = tripDate;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['start_lat'] = startLat;
    data['start_lng'] = startLng;
    data['end_lat'] = endLat;
    data['end_lng'] = endLng;
    data['total_distance_km'] = totalDistanceKm;
    if (travelMode != null) {
      data['travel_mode'] = travelMode!.toJson();
    }
    if (purpose != null) {
      data['purpose'] = purpose!.toJson();
    }
    if (tourType != null) {
      data['tour_type'] = tourType!.toJson();
    }
    data['place_to_visit'] = placeToVisit;
    data['starting_km'] = startingKm;
    data['end_km'] = endKm;
    data['start_km_photo'] = startKmPhoto;
    data['end_km_photo'] = endKmPhoto;
    data['status'] = status;
    data['approval_status'] = approvalStatus;
    data['updated_at'] = updatedAt;
    data['created_at'] = createdAt;
    data['id'] = id;
    if (company != null) {
      data['company'] = company!.toJson();
    }
    data['approved_by_user'] = approvedByUser;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class TravelMode {
  int? id;
  int? companyId;
  String? name;
  String? createdAt;
  String? updatedAt;

  TravelMode({
    this.id,
    this.companyId,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  TravelMode.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['name'] = name;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Company {
  int? id;
  String? name;
  String? code;
  String? email;
  String? address;
  int? isActive;
  String? status;
  String? createdAt;
  String? updatedAt;

  Company({
    this.id,
    this.name,
    this.code,
    this.email,
    this.address,
    this.isActive,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Company.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    email = json['email'];
    address = json['address'];
    isActive = json['is_active'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    data['email'] = email;
    data['address'] = address;
    data['is_active'] = isActive;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class UserModel {
  int? id;
  String? name;
  String? role;
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
  String? latitude;
  String? longitude;
  String? pincodeId;
  int? companyId;
  String? userLevel;
  String? depo;
  String? postalAddress;
  String? status;

  UserModel({
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

  UserModel.fromJson(Map<String, dynamic> json) {
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
