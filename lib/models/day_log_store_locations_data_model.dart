class DayLogStoreLocationsDataModel {
  int? id;
  int? dayLogId;
  double? latitude;
  double? longitude;
  String? createdAt;
  String? updatedAt;

  DayLogStoreLocationsDataModel({
    this.id,
    this.dayLogId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  DayLogStoreLocationsDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dayLogId = json['day_log_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['day_log_id'] = dayLogId;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
