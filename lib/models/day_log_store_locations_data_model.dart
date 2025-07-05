class DayLogStoreLocationsDataModel {
  String? tripId;
  double? latitude;
  double? longitude;
  String? batteryPercentage;
  String? recordedAt;
  String? updatedAt;
  String? createdAt;
  String? gpsStatus;
  int? id;

  DayLogStoreLocationsDataModel({
    this.tripId,
    this.latitude,
    this.longitude,
    this.batteryPercentage,
    this.recordedAt,
    this.updatedAt,
    this.createdAt,
    this.gpsStatus,
    this.id,
  });

  DayLogStoreLocationsDataModel.fromJson(Map<String, dynamic> json) {
    tripId = json['trip_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    batteryPercentage = json['battery_percentage'];
    recordedAt = json['recorded_at'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    gpsStatus = json['gps_status'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['trip_id'] = tripId;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['battery_percentage'] = batteryPercentage;
    data['recorded_at'] = recordedAt;
    data['updated_at'] = updatedAt;
    data['created_at'] = createdAt;
    data['gps_status'] = gpsStatus;
    data['id'] = id;
    return data;
  }
}
