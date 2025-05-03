import 'package:snap_check/models/tour_details_data_model.dart';

class TourDetailsResponseModel {
  bool? success;
  TourDetailsDataModel? data;
  String? message;

  TourDetailsResponseModel({this.success, this.data, this.message});

  TourDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data =
        json['data'] != null
            ? TourDetailsDataModel.fromJson(json['data'])
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
