import 'package:snap_check/models/country_model.dart';

class LocationsResponseModel {
  bool? success;
  List<CountryModel>? data;
  String? message;

  LocationsResponseModel({this.success, this.data, this.message});

  LocationsResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <CountryModel>[];
      json['data'].forEach((v) {
        data!.add( CountryModel.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = message;
    return data;
  }
}
