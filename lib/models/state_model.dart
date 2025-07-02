import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/district_model.dart';

class StateModel {
  int? id;
  String? name;
  int? countryId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<CityModel>? cities;
  List<DistrictModel>? districts;

  StateModel({
    this.id,
    this.name,
    this.countryId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.cities,
  });

  StateModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    countryId = json['country_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['cities'] != null) {
      cities = <CityModel>[];
      json['cities'].forEach((v) {
        cities!.add(CityModel.fromJson(v));
      });
    }
    if (json['districts'] != null) {
      districts = <DistrictModel>[];
      json['districts'].forEach((v) {
        districts!.add(DistrictModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['country_id'] = countryId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (cities != null) {
      data['cities'] = cities!.map((v) => v.toJson()).toList();
    }
    if (districts != null) {
      data['districts'] = districts!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
