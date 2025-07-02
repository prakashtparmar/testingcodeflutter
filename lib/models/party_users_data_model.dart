
class PartyUsersDataModel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? address;
  int? companyId;
  int? userId;
  int? isActive;
  String? createdAt;
  String? updatedAt;

  PartyUsersDataModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.companyId,
    this.userId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  PartyUsersDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
    companyId = json['company_id'];
    userId = json['user_id'];
    isActive = json['is_active'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['address'] = address;
    data['company_id'] = companyId;
    data['user_id'] = userId;
    data['is_active'] = isActive;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
