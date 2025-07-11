class PostDayLogDataModel {
  int? id;
  int? tourPurposeId;
  int? vehicleTypeId;
  int? tourTypeId;
  int? partyId;
  String? placeVisit;
  String? openingKm;
  String? openingKmImage;
  String? closingKm;
  String? closingKmImage;
  String? note;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  PostDayLogDataModel({
    this.id,
    this.tourPurposeId,
    this.vehicleTypeId,
    this.tourTypeId,
    this.partyId,
    this.placeVisit,
    this.openingKm,
    this.openingKmImage,
    this.closingKm,
    this.closingKmImage,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  PostDayLogDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tourPurposeId = json['tour_purpose_id'];
    vehicleTypeId = json['vehicle_type_id'];
    tourTypeId = json['tour_type_id'];
    partyId = json['party_id'];
    placeVisit = json['place_visit'];
    openingKm = json['opening_km'];
    openingKmImage = json['opening_km_image'];
    closingKm = json['closing_km'];
    closingKmImage = json['closing_km_image'];
    note = json['note'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tour_purpose_id'] = tourPurposeId;
    data['vehicle_type_id'] = vehicleTypeId;
    data['tour_type_id'] = tourTypeId;
    data['party_id'] = partyId;
    data['place_visit'] = placeVisit;
    data['opening_km'] = openingKm;
    data['opening_km_image'] = openingKmImage;
    data['closing_km'] = closingKm;
    data['closing_km_image'] = closingKmImage;
    data['note'] = note;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
