import 'package:snap_check/models/taluka_model.dart';

class DistrictModel {
  int? id;
  String? name;
  int? stateId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<TalukaModel>? tehsils;

  DistrictModel({
    this.id,
    this.name,
    this.stateId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  DistrictModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    stateId = json['state_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['tehsils'] != null) {
      tehsils = <TalukaModel>[];
      json['tehsils'].forEach((v) {
        tehsils!.add(TalukaModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['state_id'] = stateId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (tehsils != null) {
      data['tehsils'] = tehsils!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
