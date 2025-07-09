import 'package:snap_check/models/day_log_store_locations_data_model.dart';

class DayLogStoreLocationResponseModel {
  bool? success;
  DayLogStoreLocationsDataModel? data;
  String? message;
  Errors? errors;

  DayLogStoreLocationResponseModel({
    this.success,
    this.data,
    this.message,
    this.errors,
  });

  DayLogStoreLocationResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? DayLogStoreLocationsDataModel.fromJson(json['data'])
            : null;
    message = json['message'];
    errors = json['errors'] != null ? Errors.fromJson(json['errors']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = message;
    if (errors != null) {
      data['errors'] = errors!.toJson();
    }
    return data;
  }
}

class Errors {
  List<String>? tripId;

  Errors({this.tripId});

  Errors.fromJson(Map<String, dynamic> json) {
    tripId = json['trip_id'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['trip_id'] = tripId;
    return data;
  }
}
