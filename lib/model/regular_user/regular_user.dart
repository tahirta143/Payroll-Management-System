// lib/models/non_admin_dashboard_summary.dart

class NonAdminDashboardSummary {
  final String type;
  final String employeeId;
  final String employeeName;
  final String month;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int shortLeaveCount;
  final int lateCount;

  // Calculated fields
  final double presentPercentage;
  final double absentPercentage;
  final double leavePercentage;
  final double latePercentage;
  final int totalDays;

  NonAdminDashboardSummary({
    required this.type,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.shortLeaveCount,
    required this.lateCount,
    required this.presentPercentage,
    required this.absentPercentage,
    required this.leavePercentage,
    required this.latePercentage,
    required this.totalDays,
  });

  factory NonAdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    int present = json['present_count'] ?? 0;
    int absent = json['absent_count'] ?? 0;
    int leave = json['leave_count'] ?? 0;
    int late = json['late_count'] ?? 0;
    int shortLeave = json['short_leave_count'] ?? 0;
    int total = present + absent + leave;

    return NonAdminDashboardSummary(
      type: json['type'] ?? 'employee',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      month: json['month'] ?? '',
      presentCount: present,
      absentCount: absent,
      leaveCount: leave,
      shortLeaveCount: shortLeave,
      lateCount: late,
      presentPercentage: total > 0 ? (present / total) * 100 : 0,
      absentPercentage: total > 0 ? (absent / total) * 100 : 0,
      leavePercentage: total > 0 ? (leave / total) * 100 : 0,
      latePercentage: present > 0 ? (late / present) * 100 : 0,
      totalDays: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'month': month,
      'present_count': presentCount,
      'absent_count': absentCount,
      'leave_count': leaveCount,
      'short_leave_count': shortLeaveCount,
      'late_count': lateCount,
      'present_percentage': presentPercentage,
      'absent_percentage': absentPercentage,
      'leave_percentage': leavePercentage,
      'late_percentage': latePercentage,
      'total_days': totalDays,
    };
  }

  bool get isNoDataForDate => presentCount == 0 && absentCount == 0 && leaveCount == 0;
}