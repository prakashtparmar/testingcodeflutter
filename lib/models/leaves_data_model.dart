import 'package:snap_check/models/leave_type_model.dart';
import 'package:snap_check/models/user_model.dart';

class LeavesDataModel {
  int? id;
  int? userId;
  int? leaveTypeId;
  String? startDate;
  String? endDate;
  String? status;
  int? approvedBy;
  String? reason;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  User? user;
  LaveTypeModel? leaveType;

  LeavesDataModel({
    this.id,
    this.userId,
    this.leaveTypeId,
    this.startDate,
    this.endDate,
    this.status,
    this.approvedBy,
    this.reason,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.user,
    this.leaveType,
  });

  LeavesDataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    leaveTypeId = json['leave_type_id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    status = json['status'];
    approvedBy = json['approved_by'];
    reason = json['reason'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    leaveType =
        json['leave_type'] != null
            ? LaveTypeModel.fromJson(json['leave_type'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['leave_type_id'] = leaveTypeId;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['approved_by'] = approvedBy;
    data['reason'] = reason;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (leaveType != null) {
      data['leave_type'] = leaveType!.toJson();
    }
    return data;
  }
}
