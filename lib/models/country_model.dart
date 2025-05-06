class Country {
  int? id;
  String? name;
  String? code;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Country({
    this.id,
    this.name,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Country.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
