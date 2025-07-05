import 'package:snap_check/models/day_log_store_locations_data_model.dart';

class DayLogStoreLocationResponseModel {
  bool? success;
  DayLogStoreLocationsDataModel? data;
  String? message;

  DayLogStoreLocationResponseModel({this.success, this.data, this.message});

  DayLogStoreLocationResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? DayLogStoreLocationsDataModel.fromJson(json['data'])
            : null;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = message;
    return data;
  }
}
