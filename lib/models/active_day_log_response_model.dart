import 'package:snap_check/models/active_day_log_data_model.dart';

class ActiveDayLogResponseModel {
  bool? success;
  ActiveDayLogDataModel? data;
  String? message;

  ActiveDayLogResponseModel({this.success, this.data, this.message});

  ActiveDayLogResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? ActiveDayLogDataModel.fromJson(json['data'])
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
