import 'package:snap_check/models/day_log_detail_data_model.dart';

class DayLogDetailResponseModel {
  bool? success;
  DayLogDetailDataModel? data;
  String? message;

  DayLogDetailResponseModel({this.success, this.data, this.message});

  DayLogDetailResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? DayLogDetailDataModel.fromJson(json['data'])
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
