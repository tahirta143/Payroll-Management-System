import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==================== MAIN REPORT MODEL ====================

class EmployeeMonthlyReport {
  final Employee employee;
  final String month;
  final Settings settings;
  final Salary salary;
  final List<dynamic> advances;
  final SalarySummary salarySummary;
  final List<DayRecord> days;

  EmployeeMonthlyReport({
    required this.employee,
    required this.month,
    required this.settings,
    required this.salary,
    required this.advances,
    required this.salarySummary,
    required this.days,
  });

  factory EmployeeMonthlyReport.fromJson(Map<String, dynamic> json) {
    return EmployeeMonthlyReport(
      employee: Employee.fromJson(json['employee']),
      month: json['month'],
      settings: Settings.fromJson(json['settings']),
      salary: Salary.fromJson(json['salary']),
      advances: json['advances'] ?? [],
      salarySummary: SalarySummary.fromJson(json['salary_summary']),
      days: (json['days'] as List)
          .map((day) => DayRecord.fromJson(day))
          .toList(),
    );
  }

  // Calculate attendance statistics
  AttendanceStats get statistics {
    return AttendanceStats.fromDayRecords(days);
  }
}

// ==================== EMPLOYEE MODEL ====================

class Employee {
  final int id;
  final String name;
  final String empId;
  final dynamic machineCode;
  final int departmentId;
  final String departmentName;
  final int dutyShiftId;
  final String dutyShiftName;
  final String shiftStart;
  final String shiftEnd;

  Employee({
    required this.id,
    required this.name,
    required this.empId,
    this.machineCode,
    required this.departmentId,
    required this.departmentName,
    required this.dutyShiftId,
    required this.dutyShiftName,
    required this.shiftStart,
    required this.shiftEnd,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      empId: json['emp_id'],
      machineCode: json['machine_code'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      dutyShiftId: json['duty_shift_id'],
      dutyShiftName: json['duty_shift_name'],
      shiftStart: json['shift_start'],
      shiftEnd: json['shift_end'],
    );
  }
}

// ==================== SETTINGS MODEL ====================

class Settings {
  final String maxLateTime;
  final int halfDayDeductionPercent;
  final int fullDayDeductionPercent;
  final String overtimeStartAfter;
  final int overtimeRate;

  Settings({
    required this.maxLateTime,
    required this.halfDayDeductionPercent,
    required this.fullDayDeductionPercent,
    required this.overtimeStartAfter,
    required this.overtimeRate,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      maxLateTime: json['max_late_time'],
      halfDayDeductionPercent: json['half_day_deduction_percent'],
      fullDayDeductionPercent: json['full_day_deduction_percent'],
      overtimeStartAfter: json['overtime_start_after'],
      overtimeRate: json['overtime_rate'],
    );
  }
}

// ==================== SALARY MODEL ====================

class Salary {
  final int id;
  final int netSalary;
  final int grossSalary;
  final bool allowOvertime;
  final bool lateComingDeduction;

  Salary({
    required this.id,
    required this.netSalary,
    required this.grossSalary,
    required this.allowOvertime,
    required this.lateComingDeduction,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      id: json['id'],
      netSalary: json['net_salary'],
      grossSalary: json['gross_salary'],
      allowOvertime: json['allow_overtime'],
      lateComingDeduction: json['late_coming_deduction'],
    );
  }
}

// ==================== SALARY SUMMARY MODEL ====================

class SalarySummary {
  final int baseNetSalary;
  final int halfDayCount;
  final int halfDayDeductionPercent;
  final int halfDayDeductionTotal;
  final int fullAbsentCount;
  final int fullDayDeductionPercent;
  final int fullDayDeductionTotal;
  final int overtimeMinutesTotal;
  final int overtimeRate;
  final int overtimeAmountTotal;
  final int advanceAmountTotal;
  final int netPayableBeforeAdvance;
  final int netPayable;

  SalarySummary({
    required this.baseNetSalary,
    required this.halfDayCount,
    required this.halfDayDeductionPercent,
    required this.halfDayDeductionTotal,
    required this.fullAbsentCount,
    required this.fullDayDeductionPercent,
    required this.fullDayDeductionTotal,
    required this.overtimeMinutesTotal,
    required this.overtimeRate,
    required this.overtimeAmountTotal,
    required this.advanceAmountTotal,
    required this.netPayableBeforeAdvance,
    required this.netPayable,
  });

  factory SalarySummary.fromJson(Map<String, dynamic> json) {
    return SalarySummary(
      baseNetSalary: json['base_net_salary'],
      halfDayCount: json['half_day_count'],
      halfDayDeductionPercent: json['half_day_deduction_percent'],
      halfDayDeductionTotal: json['half_day_deduction_total'],
      fullAbsentCount: json['full_absent_count'],
      fullDayDeductionPercent: json['full_day_deduction_percent'],
      fullDayDeductionTotal: json['full_day_deduction_total'],
      overtimeMinutesTotal: json['overtime_minutes_total'],
      overtimeRate: json['overtime_rate'],
      overtimeAmountTotal: json['overtime_amount_total'],
      advanceAmountTotal: json['advance_amount_total'],
      netPayableBeforeAdvance: json['net_payable_before_advance'],
      netPayable: json['net_payable'],
    );
  }
}

// ==================== DAY RECORD MODEL ====================

class DayRecord {
  final String date;
  final String weekday;
  final String status;
  final String? timeIn;
  final String? timeOut;
  final int? durationMinutes;
  final String? durationLabel;
  final int lateMinutes;
  final String? lateLabel;
  final int earlyMinutes;
  final String? earlyLabel;
  final int overtimeMinutes;
  final String? overtimeLabel;
  final int overtimePayableMinutes;
  final int overtimeAmount;
  final bool isHalfDay;
  final int halfDayDeductionAmount;
  final bool isFullAbsent;
  final int fullDayDeductionAmount;
  final dynamic leave;
  final Holiday? holiday;
  final Absent? absent;

  DayRecord({
    required this.date,
    required this.weekday,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.durationMinutes,
    this.durationLabel,
    required this.lateMinutes,
    this.lateLabel,
    required this.earlyMinutes,
    this.earlyLabel,
    required this.overtimeMinutes,
    this.overtimeLabel,
    required this.overtimePayableMinutes,
    required this.overtimeAmount,
    required this.isHalfDay,
    required this.halfDayDeductionAmount,
    required this.isFullAbsent,
    required this.fullDayDeductionAmount,
    this.leave,
    this.holiday,
    this.absent,
  });

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      date: json['date'],
      weekday: json['weekday'],
      status: json['status'],
      timeIn: json['time_in'],
      timeOut: json['time_out'],
      durationMinutes: json['duration_minutes'],
      durationLabel: json['duration_label'],
      lateMinutes: json['late_minutes'] ?? 0,
      lateLabel: json['late_label'],
      earlyMinutes: json['early_minutes'] ?? 0,
      earlyLabel: json['early_label'],
      overtimeMinutes: json['overtime_minutes'] ?? 0,
      overtimeLabel: json['overtime_label'],
      overtimePayableMinutes: json['overtime_payable_minutes'] ?? 0,
      overtimeAmount: json['overtime_amount'] ?? 0,
      isHalfDay: json['is_half_day'] ?? false,
      halfDayDeductionAmount: json['half_day_deduction_amount'] ?? 0,
      isFullAbsent: json['is_full_absent'] ?? false,
      fullDayDeductionAmount: json['full_day_deduction_amount'] ?? 0,
      leave: json['leave'],
      holiday: json['holiday'] != null ? Holiday.fromJson(json['holiday']) : null,
      absent: json['absent'] != null ? Absent.fromJson(json['absent']) : null,
    );
  }

  // Helper Methods
  String getStatusDisplay() {
    if (isFullAbsent) return 'Absent';
    if (holiday != null) return holiday!.reason;
    if (isHalfDay) return 'Half Day';
    if (lateMinutes > 0) return 'Late';
    if (status == 'present') return 'Present';
    return status;
  }

  Color getStatusColor() {
    if (isFullAbsent) return Colors.red;
    if (holiday != null) return Colors.blue;
    if (isHalfDay) return Colors.orange;
    if (lateMinutes > 0) return Colors.purple;
    if (status == 'present') return Colors.green;
    return Colors.grey;
  }

  IconData getStatusIcon() {
    if (isFullAbsent) return Icons.close;
    if (holiday != null) return Icons.celebration;
    if (isHalfDay) return Icons.access_time;
    if (lateMinutes > 0) return Icons.warning;
    if (status == 'present') return Icons.check_circle;
    return Icons.help;
  }

  bool get isPresent => status == 'present';

  String getFormattedDate() {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String getFormattedTimeIn() {
    if (timeIn == null) return '-';
    try {
      final parts = timeIn!.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      return timeIn!;
    }
  }

  String getFormattedTimeOut() {
    if (timeOut == null) return '-';
    try {
      final parts = timeOut!.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      return timeOut!;
    }
  }

  String getFormattedDuration() {
    return durationLabel ?? '-';
  }

  String getFormattedLate() {
    return lateLabel ?? (lateMinutes > 0 ? '${lateMinutes}m' : '-');
  }

  String getFormattedEarly() {
    return earlyLabel ?? (earlyMinutes > 0 ? '${earlyMinutes}m' : '-');
  }

  String getFormattedOvertime() {
    return overtimeLabel ?? (overtimeMinutes > 0 ? '${overtimeMinutes}m' : '-');
  }
}

// ==================== HOLIDAY MODEL ====================

class Holiday {
  final int id;
  final bool allDepartments;
  final dynamic departmentId;
  final String reason;

  Holiday({
    required this.id,
    required this.allDepartments,
    this.departmentId,
    required this.reason,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      allDepartments: json['all_departments'],
      departmentId: json['department_id'],
      reason: json['reason'],
    );
  }
}

// ==================== ABSENT MODEL ====================

class Absent {
  final int id;
  final String? reason;

  Absent({
    required this.id,
    this.reason,
  });

  factory Absent.fromJson(Map<String, dynamic> json) {
    return Absent(
      id: json['id'],
      reason: json['reason'],
    );
  }
}

// ==================== DEPARTMENT MODEL (For Dropdown) ====================

class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
    );
  }
}

// ==================== EMPLOYEE LIST ITEM MODEL (For Dropdown) ====================

// Add this class to your monthly_attandance_sheet.dart file
// or create a new file for these models

class EmployeeListItem {
  final int id;
  final String name;
  final String empId;
  final int departmentId;
  final String departmentName;

  EmployeeListItem({
    required this.id,
    required this.name,
    required this.empId,
    required this.departmentId,
    required this.departmentName,
  });

  factory EmployeeListItem.fromJson(Map<String, dynamic> json) {
    return EmployeeListItem(
      id: json['id'],
      name: json['name'],
      empId: json['emp_id'],
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'] ?? '',
    );
  }
}

// class Department {
//   final int id;
//   final String name;
//
//   Department({required this.id, required this.name});
//
//   factory Department.fromJson(Map<String, dynamic> json) {
//     return Department(
//       id: json['id'],
//       name: json['name'],
//     );
//   }
// }

// ==================== ATTENDANCE STATISTICS MODEL ====================

class AttendanceStats {
  final int totalRecords;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int halfDayCount;
  final int holidayCount;
  final int totalWorkingDays;
  final double attendancePercentage;

  AttendanceStats({
    required this.totalRecords,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.halfDayCount,
    required this.holidayCount,
    required this.totalWorkingDays,
    required this.attendancePercentage,
  });

  factory AttendanceStats.fromDayRecords(List<DayRecord> days) {
    int present = 0;
    int late = 0;
    int absent = 0;
    int halfDay = 0;
    int holiday = 0;

    for (var day in days) {
      if (day.holiday != null) {
        holiday++;
      } else if (day.isFullAbsent) {
        absent++;
      } else if (day.status == 'present') {
        present++;
        if (day.lateMinutes > 0) {
          late++;
        }
        if (day.isHalfDay) {
          halfDay++;
        }
      }
    }

    final totalWorkingDays = days.where((d) =>
    d.status == 'present' || d.isFullAbsent
    ).length;

    final attendancePercentage = totalWorkingDays > 0
        ? (present / totalWorkingDays * 100)
        : 0.0;

    return AttendanceStats(
      totalRecords: days.length,
      presentCount: present,
      lateCount: late,
      absentCount: absent,
      halfDayCount: halfDay,
      holidayCount: holiday,
      totalWorkingDays: totalWorkingDays,
      attendancePercentage: double.parse(attendancePercentage.toStringAsFixed(1)),
    );
  }
}