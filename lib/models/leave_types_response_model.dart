import 'package:snap_check/models/leave_type_model.dart';

class LeaveTypeResponseModel {
  bool? success;
  List<LeaveTypeModel>? data;
  String? message;

  LeaveTypeResponseModel({this.success, this.data, this.message});

  LeaveTypeResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <LeaveTypeModel>[];
      json['data'].forEach((v) {
        data!.add(LeaveTypeModel.fromJson(v));
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
