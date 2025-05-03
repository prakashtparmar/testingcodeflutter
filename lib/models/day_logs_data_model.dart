import 'package:snap_check/models/tour_details.dart';

class DayLogsDataModel {
  int? id;
  int? tourPurposeId;
  int? vehicleTypeId;
  int? tourTypeId;
  String? placeVisit;
  int? partyId;
  String? openingKm;
  String? openingKmImage;
  String? closingKm;
  String? closingKmImage;
  String? note;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  TourDetails? tourPurpose;
  TourDetails? vehicleType;
  TourDetails? tourType;

  DayLogsDataModel({
    this.id,
    this.tourPurposeId,
    this.vehicleTypeId,
    this.tourTypeId,
    this.placeVisit,
    this.partyId,
    this.openingKm,
    this.openingKmImage,
    this.closingKm,
    this.closingKmImage,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.tourPurpose,
    this.vehicleType,
    this.tourType,
  });

  DayLogsDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tourPurposeId = json['tour_purpose_id'];
    vehicleTypeId = json['vehicle_type_id'];
    tourTypeId = json['tour_type_id'];
    placeVisit = json['place_visit'];
    partyId = json['party_id'];
    openingKm = json['opening_km'];
    openingKmImage = json['opening_km_image'];
    closingKm = json['closing_km'];
    closingKmImage = json['closing_km_image'];
    note = json['note'];
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
    data['tour_purpose_id'] = tourPurposeId;
    data['vehicle_type_id'] = vehicleTypeId;
    data['tour_type_id'] = tourTypeId;
    data['place_visit'] = placeVisit;
    data['party_id'] = partyId;
    data['opening_km'] = openingKm;
    data['opening_km_image'] = openingKmImage;
    data['closing_km'] = closingKm;
    data['closing_km_image'] = closingKmImage;
    data['note'] = note;
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
