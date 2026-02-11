// lib/models/attendance_models.dart
class Employee {
  final int id;
  final String name;
  final String empId;
  final String? machineCode;
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      empId: json['emp_id'] ?? '',
      machineCode: json['machine_code'],
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'] ?? '',
      dutyShiftId: json['duty_shift_id'] ?? 0,
      dutyShiftName: json['duty_shift_name'] ?? '',
      shiftStart: json['shift_start'] ?? '',
      shiftEnd: json['shift_end'] ?? '',
    );
  }
}

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
      maxLateTime: json['max_late_time'] ?? '09:15:00',
      halfDayDeductionPercent: json['half_day_deduction_percent'] ?? 1,
      fullDayDeductionPercent: json['full_day_deduction_percent'] ?? 5,
      overtimeStartAfter: json['overtime_start_after'] ?? '18:15:00',
      overtimeRate: json['overtime_rate'] ?? 200,
    );
  }
}

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
      id: json['id'] ?? 0,
      netSalary: json['net_salary'] ?? 0,
      grossSalary: json['gross_salary'] ?? 0,
      allowOvertime: json['allow_overtime'] ?? false,
      lateComingDeduction: json['late_coming_deduction'] ?? false,
    );
  }
}

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
      baseNetSalary: json['base_net_salary'] ?? 0,
      halfDayCount: json['half_day_count'] ?? 0,
      halfDayDeductionPercent: json['half_day_deduction_percent'] ?? 0,
      halfDayDeductionTotal: json['half_day_deduction_total'] ?? 0,
      fullAbsentCount: json['full_absent_count'] ?? 0,
      fullDayDeductionPercent: json['full_day_deduction_percent'] ?? 0,
      fullDayDeductionTotal: json['full_day_deduction_total'] ?? 0,
      overtimeMinutesTotal: json['overtime_minutes_total'] ?? 0,
      overtimeRate: json['overtime_rate'] ?? 0,
      overtimeAmountTotal: json['overtime_amount_total'] ?? 0,
      advanceAmountTotal: json['advance_amount_total'] ?? 0,
      netPayableBeforeAdvance: json['net_payable_before_advance'] ?? 0,
      netPayable: json['net_payable'] ?? 0,
    );
  }
}

class Holiday {
  final int id;
  final bool allDepartments;
  final int? departmentId;
  final String reason;

  Holiday({
    required this.id,
    required this.allDepartments,
    this.departmentId,
    required this.reason,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] ?? 0,
      allDepartments: json['all_departments'] ?? false,
      departmentId: json['department_id'],
      reason: json['reason'] ?? '',
    );
  }
}

class AttendanceDay {
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
  final dynamic absent;

  AttendanceDay({
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

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    return AttendanceDay(
      date: json['date'] ?? '',
      weekday: json['weekday'] ?? '',
      status: json['status'] ?? '',
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
      absent: json['absent'],
    );
  }
}

class MonthlyReport {
  final Employee employee;
  final String month;
  final Settings settings;
  final Salary salary;
  final List<dynamic> advances;
  final SalarySummary salarySummary;
  final List<AttendanceDay> days;

  MonthlyReport({
    required this.employee,
    required this.month,
    required this.settings,
    required this.salary,
    required this.advances,
    required this.salarySummary,
    required this.days,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      employee: Employee.fromJson(json['employee'] ?? {}),
      month: json['month'] ?? '',
      settings: Settings.fromJson(json['settings'] ?? {}),
      salary: Salary.fromJson(json['salary'] ?? {}),
      advances: json['advances'] ?? [],
      salarySummary: SalarySummary.fromJson(json['salary_summary'] ?? {}),
      days: (json['days'] as List? ?? [])
          .map((day) => AttendanceDay.fromJson(day))
          .toList(),
    );
  }
}

class Department {
  final int id;
  final String name;

  Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ??
          json['department_name']?.toString() ??
          'Unknown Department',
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? employeeId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      employeeId: json['employee_id'],
    );
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
}