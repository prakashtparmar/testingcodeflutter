class PartyUsersPivotModel {
  int? userId;
  int? partyId;
  String? createdAt;
  String? updatedAt;

  PartyUsersPivotModel({this.userId, this.partyId, this.createdAt, this.updatedAt});

  PartyUsersPivotModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    partyId = json['party_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['party_id'] = partyId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
