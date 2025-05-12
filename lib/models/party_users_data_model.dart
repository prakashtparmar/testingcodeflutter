import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/country_model.dart';
import 'package:snap_check/models/party_users_pivot_model.dart';
import 'package:snap_check/models/state_model.dart';

class PartyUsersDataModel {
  int? id;
  String? name;
  String? addressLine1;
  String? addressLine2;
  int? cityId;
  int? stateId;
  int? countryId;
  String? pinCode;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  PartyUsersPivotModel? pivot;
  City? city;
  State? state;
  Country? country;

  PartyUsersDataModel({
    this.id,
    this.name,
    this.addressLine1,
    this.addressLine2,
    this.cityId,
    this.stateId,
    this.countryId,
    this.pinCode,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.pivot,
    this.city,
    this.state,
    this.country,
  });

  PartyUsersDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    addressLine1 = json['address_line_1'];
    addressLine2 = json['address_line_2'];
    cityId = json['city_id'];
    stateId = json['state_id'];
    countryId = json['country_id'];
    pinCode = json['pin_code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    pivot = json['pivot'] != null ? PartyUsersPivotModel.fromJson(json['pivot']) : null;
    city = json['city'] != null ? City.fromJson(json['city']) : null;
    state = json['state'] != null ? State.fromJson(json['state']) : null;
    country =
        json['country'] != null ? Country.fromJson(json['country']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['address_line_1'] = addressLine1;
    data['address_line_2'] = addressLine2;
    data['city_id'] = cityId;
    data['state_id'] = stateId;
    data['country_id'] = countryId;
    data['pin_code'] = pinCode;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (pivot != null) {
      data['pivot'] = pivot!.toJson();
    }
    if (city != null) {
      data['city'] = city!.toJson();
    }
    if (state != null) {
      data['state'] = state!.toJson();
    }
    if (country != null) {
      data['country'] = country!.toJson();
    }
    return data;
  }
}
