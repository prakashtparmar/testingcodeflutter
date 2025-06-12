import 'package:snap_check/models/leaves_data_model.dart';

class LeavesResponseModel {
  bool? success;
  List<LeavesDataModel>? data;
  String? message;

  LeavesResponseModel({this.success, this.data, this.message});

  LeavesResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <LeavesDataModel>[];
      json['data'].forEach((v) {
        data!.add(LeavesDataModel.fromJson(v));
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
