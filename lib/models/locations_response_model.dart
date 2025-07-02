
import 'package:snap_check/models/state_model.dart';

class LocationsResponseModel {
  bool? success;
  List<StateModel>? data;
  String? message;

  LocationsResponseModel({this.success, this.data, this.message});

  LocationsResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <StateModel>[];
      json['data'].forEach((v) {
        data!.add( StateModel.fromJson(v));
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
