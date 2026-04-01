import 'dart:convert';

class ShortLeaveModel {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String leaveDate;
  final String fromTime;
  final String toTime;
  final int totalMinutes;
  final String leaveType;
  final bool isPaid;
  final String status;
  final String? reason;

  ShortLeaveModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.leaveDate,
    required this.fromTime,
    required this.toTime,
    required this.totalMinutes,
    required this.leaveType,
    required this.isPaid,
    required this.status,
    this.reason,
  });

  factory ShortLeaveModel.fromJson(Map<String, dynamic> json) {
    return ShortLeaveModel(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      leaveDate: json['leave_date'] ?? '',
      fromTime: json['from_time'] ?? '',
      toTime: json['to_time'] ?? '',
      totalMinutes: json['total_minutes'] ?? 0,
      leaveType: json['leave_type'] ?? '',
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true,
      status: json['status'] ?? 'pending',
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'leave_date': leaveDate,
      'from_time': fromTime,
      'to_time': toTime,
      'total_minutes': totalMinutes,
      'leave_type': leaveType,
      'is_paid': isPaid,
      'status': status,
      'reason': reason,
    };
  }

  ShortLeaveModel copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    String? leaveDate,
    String? fromTime,
    String? toTime,
    int? totalMinutes,
    String? leaveType,
    bool? isPaid,
    String? status,
    String? reason,
  }) {
    return ShortLeaveModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      leaveDate: leaveDate ?? this.leaveDate,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      leaveType: leaveType ?? this.leaveType,
      isPaid: isPaid ?? this.isPaid,
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }
}
