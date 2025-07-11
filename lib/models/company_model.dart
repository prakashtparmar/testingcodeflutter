class CompanyModel {
  int? id;
  String? name;
  String? code;
  String? email;
  String? address;
  int? isActive;
  String? status;
  String? createdAt;
  String? updatedAt;

  CompanyModel(
      {this.id,
      this.name,
      this.code,
      this.email,
      this.address,
      this.isActive,
      this.status,
      this.createdAt,
      this.updatedAt});

  CompanyModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    email = json['email'];
    address = json['address'];
    isActive = json['is_active'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    data['email'] = email;
    data['address'] = address;
    data['is_active'] = isActive;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}