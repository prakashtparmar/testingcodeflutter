import 'package:snap_check/models/party_users_data_model.dart';

class PartyUsersResponseModel {
  bool? success;
  List<PartyUsersDataModel>? data;
  String? message;

  PartyUsersResponseModel({this.success, this.data, this.message});

  PartyUsersResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <PartyUsersDataModel>[];
      json['data'].forEach((v) {
        data!.add(PartyUsersDataModel.fromJson(v));
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
