class TalukaModel {
  int? id;
  String? name;
  int? cityId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  TalukaModel({
    this.id,
    this.name,
    this.cityId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  TalukaModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    cityId = json['city_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['city_id'] = cityId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TalukaModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
