import 'package:snap_check/models/create_day_log_data_model.dart';

class CreateDayLogResponseModel {
  bool? success;
  CreateDayLogDataModel? data;
  String? message;

  CreateDayLogResponseModel({this.success, this.data, this.message});

  CreateDayLogResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? CreateDayLogDataModel.fromJson(json['data'])
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
