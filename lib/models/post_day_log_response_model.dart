import 'package:snap_check/models/post_day_log_data_model.dart';
import 'package:snap_check/models/post_day_logs_error_model.dart';

class PostDayLogsResponseModel {
  bool? success;
  PostDayLogDataModel? data;
  String? message;
  PostDayLogErrorModel? errors;

  PostDayLogsResponseModel({
    this.success,
    this.data,
    this.message,
    this.errors,
  });

  PostDayLogsResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? PostDayLogDataModel.fromJson(json['data'])
            : null;
    message = json['message'];
    errors =
        json['errors'] != null
            ? PostDayLogErrorModel.fromJson(json['errors'])
            : null;
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
