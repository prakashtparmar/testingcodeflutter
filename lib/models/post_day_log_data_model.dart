class PostDayLogDataModel {
  String? tourPurposeId;
  String? vehicleTypeId;
  String? tourTypeId;
  String? placeVisit;
  String? openingKm;
  String? openingKmImage;
  String? partyId;
  String? updatedAt;
  String? createdAt;
  int? id;

  PostDayLogDataModel({
    this.tourPurposeId,
    this.vehicleTypeId,
    this.tourTypeId,
    this.placeVisit,
    this.openingKm,
    this.openingKmImage,
    this.partyId,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  PostDayLogDataModel.fromJson(Map<String, dynamic> json) {
    tourPurposeId = json['tour_purpose_id'];
    vehicleTypeId = json['vehicle_type_id'];
    tourTypeId = json['tour_type_id'];
    placeVisit = json['place_visit'];
    openingKm = json['opening_km'];
    openingKmImage = json['opening_km_image'];
    partyId = json['party_id'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tour_purpose_id'] = tourPurposeId;
    data['vehicle_type_id'] = vehicleTypeId;
    data['tour_type_id'] = tourTypeId;
    data['place_visit'] = placeVisit;
    data['opening_km'] = openingKm;
    data['opening_km_image'] = openingKmImage;
    data['party_id'] = partyId;
    data['updated_at'] = updatedAt;
    data['created_at'] = createdAt;
    data['id'] = id;
    return data;
  }
}
