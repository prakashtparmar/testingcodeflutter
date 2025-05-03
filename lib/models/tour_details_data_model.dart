import 'package:snap_check/models/tour_details.dart';

class TourDetailsDataModel {
  List<TourDetails>? tourPurposes;
  List<TourDetails>? vehicleTypes;
  List<TourDetails>? tourTypes;

  TourDetailsDataModel({this.tourPurposes, this.vehicleTypes, this.tourTypes});

  TourDetailsDataModel.fromJson(Map<String, dynamic> json) {
    if (json['tourPurposes'] != null) {
      tourPurposes = <TourDetails>[];
      json['tourPurposes'].forEach((v) {
        tourPurposes!.add(TourDetails.fromJson(v));
      });
    }
    if (json['vehicleTypes'] != null) {
      vehicleTypes = <TourDetails>[];
      json['vehicleTypes'].forEach((v) {
        vehicleTypes!.add(TourDetails.fromJson(v));
      });
    }
    if (json['tourTypes'] != null) {
      tourTypes = <TourDetails>[];
      json['tourTypes'].forEach((v) {
        tourTypes!.add(TourDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tourPurposes != null) {
      data['tourPurposes'] = tourPurposes!.map((v) => v.toJson()).toList();
    }
    if (vehicleTypes != null) {
      data['vehicleTypes'] = vehicleTypes!.map((v) => v.toJson()).toList();
    }
    if (tourTypes != null) {
      data['tourTypes'] = tourTypes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
