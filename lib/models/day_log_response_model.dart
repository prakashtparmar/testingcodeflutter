import 'package:snap_check/models/day_log_data_model.dart';

class DayLogResponseModel {
  bool? success;
  DayLogDataModel? data;
  String? message;

  DayLogResponseModel({this.success, this.data, this.message});

  DayLogResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? DayLogDataModel.fromJson(json['data']) : null;
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
