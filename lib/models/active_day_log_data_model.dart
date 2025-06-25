import 'package:snap_check/models/tour_details.dart';
import 'package:snap_check/models/user_model.dart';

class ActiveDayLogDataModel {
  int? id;
  int? userId;
  int? tourPurposeId;
  int? vehicleTypeId;
  int? tourTypeId;
  int? partyId;
  String? placeVisit;
  String? openingKm;
  String? openingKmImage;
  String? openingKmLatitude;
  String? openingKmLongitude;
  String? closingKm;
  String? closingKmImage;
  String? closingKmLatitude;
  String? closingKmLongitude;
  String? note;
  String? approvalStatus;
  User? approvedBy;
  String? approvalReason;
  String? approvedAt;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  TourDetails? tourPurpose;
  TourDetails? vehicleType;
  TourDetails? tourType;

  ActiveDayLogDataModel({
    this.id,
    this.userId,
    this.tourPurposeId,
    this.vehicleTypeId,
    this.tourTypeId,
    this.partyId,
    this.placeVisit,
    this.openingKm,
    this.openingKmImage,
    this.openingKmLatitude,
    this.openingKmLongitude,
    this.closingKm,
    this.closingKmImage,
    this.closingKmLatitude,
    this.closingKmLongitude,
    this.note,
    this.approvalStatus,
    this.approvedBy,
    this.approvalReason,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.tourPurpose,
    this.vehicleType,
    this.tourType,
  });

  ActiveDayLogDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    tourPurposeId = json['tour_purpose_id'];
    vehicleTypeId = json['vehicle_type_id'];
    tourTypeId = json['tour_type_id'];
    partyId = json['party_id'];
    placeVisit = json['place_visit'];
    openingKm = json['opening_km'];
    openingKmImage = json['opening_km_image'];
    openingKmLatitude = json['opening_km_latitude'];
    openingKmLongitude = json['opening_km_longitude'];
    closingKm = json['closing_km'];
    closingKmImage = json['closing_km_image'];
    closingKmLatitude = json['closing_km_latitude'];
    closingKmLongitude = json['closing_km_longitude'];
    note = json['note'];
    approvalStatus = json['approval_status'];
    approvedBy = json['approved_by'];
    approvalReason = json['approval_reason'];
    approvedAt = json['approved_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    tourPurpose =
        json['tour_purpose'] != null
            ? TourDetails.fromJson(json['tour_purpose'])
            : null;
    vehicleType =
        json['vehicle_type'] != null
            ? TourDetails.fromJson(json['vehicle_type'])
            : null;
    tourType =
        json['tour_type'] != null
            ? TourDetails.fromJson(json['tour_type'])
            : null;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['tour_purpose_id'] = tourPurposeId;
    data['vehicle_type_id'] = vehicleTypeId;
    data['tour_type_id'] = tourTypeId;
    data['party_id'] = partyId;
    data['place_visit'] = placeVisit;
    data['opening_km'] = openingKm;
    data['opening_km_image'] = openingKmImage;
    data['opening_km_latitude'] = openingKmLatitude;
    data['opening_km_longitude'] = openingKmLongitude;
    data['closing_km'] = closingKm;
    data['closing_km_image'] = closingKmImage;
    data['closing_km_latitude'] = closingKmLatitude;
    data['closing_km_longitude'] = closingKmLongitude;
    data['note'] = note;
    data['approval_status'] = approvalStatus;
    data['approved_by'] = approvedBy;
    data['approval_reason'] = approvalReason;
    data['approved_at'] = approvedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (tourPurpose != null) {
      data['tour_purpose'] = tourPurpose!.toJson();
    }
    if (vehicleType != null) {
      data['vehicle_type'] = vehicleType!.toJson();
    }
    if (tourType != null) {
      data['tour_type'] = tourType!.toJson();
    }
    return data;
  }
}
