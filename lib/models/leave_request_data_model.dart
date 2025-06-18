import 'package:snap_check/models/user_model.dart';

class LeaveRequestDataModel {
  int? userId;
  String? leaveTypeId;
  String? startDate;
  String? endDate;
  String? status;
  User? approvedBy;
  String? reason;
  String? updatedAt;
  String? createdAt;
  int? id;

  LeaveRequestDataModel({
    this.userId,
    this.leaveTypeId,
    this.startDate,
    this.endDate,
    this.status,
    this.approvedBy,
    this.reason,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  LeaveRequestDataModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    leaveTypeId = json['leave_type_id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    status = json['status'];
    approvedBy = json['approved_by'];
    reason = json['reason'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['leave_type_id'] = leaveTypeId;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['approved_by'] = approvedBy;
    data['reason'] = reason;
    data['updated_at'] = updatedAt;
    data['created_at'] = createdAt;
    data['id'] = id;
    return data;
  }
}
