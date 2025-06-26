import 'package:snap_check/models/create_day_log_data_model.dart';
import 'package:snap_check/models/post_day_logs_error_model.dart';

class CreateDayLogResponseModel {
  bool? success;
  CreateDayLogDataModel? data;
  String? message;
  PostDayLogErrorModel? errors;

  CreateDayLogResponseModel({
    this.success,
    this.data,
    this.message,
    this.errors,
  });

  CreateDayLogResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? CreateDayLogDataModel.fromJson(json['data'])
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
