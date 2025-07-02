import 'package:snap_check/models/user_model.dart';

class ActiveDayLogDataModel {
  int? id;
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
  String? placeToVisit;
  String? closenote;
  String? startingKm;
  String? endKm;
  String? startKmPhoto;
  String? endKmPhoto;
  String? status;
  String? approvalStatus;
  User? approvedBy;
  String? approvalReason;
  String? approvedAt;
  String? createdAt;
  String? updatedAt;
  int? travelMode;
  int? purpose;
  int? tourType;

  ActiveDayLogDataModel({
    this.id,
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
    this.placeToVisit,
    this.closenote,
    this.startingKm,
    this.endKm,
    this.startKmPhoto,
    this.endKmPhoto,
    this.status,
    this.approvalStatus,
    this.approvedBy,
    this.approvalReason,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.travelMode,
    this.purpose,
    this.tourType,
  });

  ActiveDayLogDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
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
    placeToVisit = json['place_to_visit'];
    closenote = json['closenote'];
    startingKm = json['starting_km'];
    endKm = json['end_km'];
    startKmPhoto = json['start_km_photo'];
    endKmPhoto = json['end_km_photo'];
    status = json['status'];
    approvalStatus = json['approval_status'];
    approvedBy = json['approved_by'];
    approvalReason = json['approval_reason'];
    approvedAt = json['approved_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    travelMode = json['travel_mode'];
    purpose = json['purpose'];
    tourType = json['tour_type'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
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
    data['place_to_visit'] = placeToVisit;
    data['closenote'] = closenote;
    data['starting_km'] = startingKm;
    data['end_km'] = endKm;
    data['start_km_photo'] = startKmPhoto;
    data['end_km_photo'] = endKmPhoto;
    data['status'] = status;
    data['approval_status'] = approvalStatus;
    data['approved_by'] = approvedBy;
    data['approval_reason'] = approvalReason;
    data['approved_at'] = approvedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['travel_mode'] = travelMode;
    data['purpose'] = purpose;
    data['tour_type'] = tourType;
    return data;
  }
}
