import 'package:snap_check/models/state_model.dart';

class CountryModel {
  int? id;
  String? name;
  String? code;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<StateModel>? states;

  CountryModel({
    this.id,
    this.name,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.states,
  });

  CountryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['states'] != null) {
      states = <StateModel>[];
      json['states'].forEach((v) {
        states!.add(StateModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (states != null) {
      data['states'] = states!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
