import 'package:snap_check/models/post_day_log_data_model.dart';

class PostDayLogsResponseModel {
  bool? success;
  PostDayLogDataModel? data;
  String? message;

  PostDayLogsResponseModel({this.success, this.data, this.message});

  factory PostDayLogsResponseModel.fromJson(Map<String, dynamic> json) {
    return PostDayLogsResponseModel(
      success: json['success'] == true,
      message: json['message'] as String?,
      data: json['data'] != null ? PostDayLogDataModel.fromJson(json['data']) : null,
    );
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
