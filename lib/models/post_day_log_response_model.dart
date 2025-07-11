import 'package:snap_check/models/post_day_log_data_model.dart';

class PostDayLogsResponseModel {
  bool? success;
  PostDayLogDataModel? data;
  String? message;

  PostDayLogsResponseModel({this.success, this.data, this.message});

  PostDayLogsResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? PostDayLogDataModel.fromJson(json['data'])
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
