class LeaveTypeModel {
  int? id;
  String? name;
  int? maxDaysPerYear;
  String? paidType;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  LeaveTypeModel({
    this.id,
    this.name,
    this.maxDaysPerYear,
    this.paidType,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    maxDaysPerYear = json['max_days_per_year'];
    paidType = json['paid_type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['max_days_per_year'] = maxDaysPerYear;
    data['paid_type'] = paidType;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
