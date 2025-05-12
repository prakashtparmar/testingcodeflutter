class PostDayLogErrorModel {
  List<String>? tourPurpose;
  List<String>? vehicleType;
  List<String>? tourType;
  List<String>? placeVisit;
  List<String>? openingKm;
  List<String>? openingKmImage;
  List<String>? partyId;

  PostDayLogErrorModel({
    this.tourPurpose,
    this.vehicleType,
    this.tourType,
    this.placeVisit,
    this.openingKm,
    this.openingKmImage,
    this.partyId,
  });

  PostDayLogErrorModel.fromJson(Map<String, dynamic> json) {
    tourPurpose = json['tour_purpose'].cast<String>();
    vehicleType = json['vehicle_type'].cast<String>();
    tourType = json['tour_type'].cast<String>();
    placeVisit = json['place_visit'].cast<String>();
    openingKm = json['opening_km'].cast<String>();
    openingKmImage = json['opening_km_image'].cast<String>();
    partyId = json['party_id'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tour_purpose'] = tourPurpose;
    data['vehicle_type'] = vehicleType;
    data['tour_type'] = tourType;
    data['place_visit'] = placeVisit;
    data['opening_km'] = openingKm;
    data['opening_km_image'] = openingKmImage;
    data['party_id'] = partyId;
    return data;
  }
}
