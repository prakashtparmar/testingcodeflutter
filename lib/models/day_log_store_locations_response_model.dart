import 'package:snap_check/models/day_log_store_locations_data_model.dart';

class DayLogStoreLocationResponseModel {
  bool? success;
  List<DayLogStoreLocationsDataModel>? data;
  String? message;

  DayLogStoreLocationResponseModel({this.success, this.data, this.message});

  DayLogStoreLocationResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <DayLogStoreLocationsDataModel>[];
      json['data'].forEach((v) {
        data!.add(DayLogStoreLocationsDataModel.fromJson(v));
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
