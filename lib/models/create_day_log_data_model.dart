import 'package:snap_check/models/company_model.dart';
import 'package:snap_check/models/tour_details.dart';
import 'package:snap_check/models/user_model.dart';

class CreateDayLogDataModel {
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
  TourDetails? travelMode;
  TourDetails? purpose;
  TourDetails? tourType;
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
  CompanyModel? company;
  User? approvedByUser;
  User? user;

  CreateDayLogDataModel({
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

  CreateDayLogDataModel.fromJson(Map<String, dynamic> json) {
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
            ? TourDetails.fromJson(json['travel_mode'])
            : null;
    purpose =
        json['purpose'] != null ? TourDetails.fromJson(json['purpose']) : null;
    tourType =
        json['tour_type'] != null
            ? TourDetails.fromJson(json['tour_type'])
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
        json['company'] != null ? CompanyModel.fromJson(json['company']) : null;
    approvedByUser = json['approved_by_user'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
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
