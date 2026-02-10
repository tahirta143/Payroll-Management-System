// Helper function to convert dynamic to Map<String, dynamic>
Map<String, dynamic> convertDynamicToMap(dynamic data) {
  if (data == null) return {};

  if (data is Map<String, dynamic>) {
    return data;
  } else if (data is Map) {
    Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (key is String) {
        result[key] = value;
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }
  return {};
}

class SalarySlip {
  final String month;
  final DateRange range;
  final Employee employee;
  final SettingsUsed settingsUsed;
  final SalaryStructure salaryStructure;
  final List<dynamic> advances;
  final AttendanceSummary attendanceSummary;
  final PayrollCalculation payrollCalculation;

  SalarySlip({
    required this.month,
    required this.range,
    required this.employee,
    required this.settingsUsed,
    required this.salaryStructure,
    required this.advances,
    required this.attendanceSummary,
    required this.payrollCalculation,
  });

  factory SalarySlip.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return SalarySlip(
      month: data['month'] ?? '',
      range: DateRange.fromJson(data['range']),
      employee: Employee.fromJson(data['employee']),
      settingsUsed: SettingsUsed.fromJson(data['settings_used']),
      salaryStructure: SalaryStructure.fromJson(data['salary_structure']),
      advances: data['advances'] is List ? data['advances'] : [],
      attendanceSummary: AttendanceSummary.fromJson(data['attendance_summary']),
      payrollCalculation: PayrollCalculation.fromJson(data['payroll_calculation']),
    );
  }
}

class DateRange {
  final String from;
  final String to;

  DateRange({
    required this.from,
    required this.to,
  });

  factory DateRange.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return DateRange(
      from: data['from'] ?? '',
      to: data['to'] ?? '',
    );
  }
}

class Employee {
  final int id;
  final String empId;
  final String name;
  final String? machineCode;
  final String joiningDate;
  final int departmentId;
  final String departmentName;
  final int designationId;
  final String designationName;
  final int dutyShiftId;
  final String dutyShiftName;
  final String shiftStart;
  final String shiftEnd;
  final String? bankName;
  final String? accountNumber;

  Employee({
    required this.id,
    required this.empId,
    required this.name,
    this.machineCode,
    required this.joiningDate,
    required this.departmentId,
    required this.departmentName,
    required this.designationId,
    required this.designationName,
    required this.dutyShiftId,
    required this.dutyShiftName,
    required this.shiftStart,
    required this.shiftEnd,
    this.bankName,
    this.accountNumber,
  });

  factory Employee.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return Employee(
      id: data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0,
      empId: data['emp_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      machineCode: data['machine_code']?.toString(),
      joiningDate: data['joining_date']?.toString() ?? '',
      departmentId: data['department_id'] is int ? data['department_id'] : int.tryParse(data['department_id'].toString()) ?? 0,
      departmentName: data['department_name']?.toString() ?? '',
      designationId: data['designation_id'] is int ? data['designation_id'] : int.tryParse(data['designation_id'].toString()) ?? 0,
      designationName: data['designation_name']?.toString() ?? '',
      dutyShiftId: data['duty_shift_id'] is int ? data['duty_shift_id'] : int.tryParse(data['duty_shift_id'].toString()) ?? 0,
      dutyShiftName: data['duty_shift_name']?.toString() ?? '',
      shiftStart: data['shift_start']?.toString() ?? '',
      shiftEnd: data['shift_end']?.toString() ?? '',
      bankName: data['bank_name']?.toString(),
      accountNumber: data['account_number']?.toString(),
    );
  }
}

class SettingsUsed {
  final String maxLateTime;
  final double halfDayDeductionPercent;
  final double fullDayDeductionPercent;
  final String overtimeStartAfter;
  final double overtimeRate;

  SettingsUsed({
    required this.maxLateTime,
    required this.halfDayDeductionPercent,
    required this.fullDayDeductionPercent,
    required this.overtimeStartAfter,
    required this.overtimeRate,
  });

  factory SettingsUsed.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return SettingsUsed(
      maxLateTime: data['max_late_time']?.toString() ?? '',
      halfDayDeductionPercent: double.tryParse(data['half_day_deduction_percent'].toString()) ?? 0.0,
      fullDayDeductionPercent: double.tryParse(data['full_day_deduction_percent'].toString()) ?? 0.0,
      overtimeStartAfter: data['overtime_start_after']?.toString() ?? '',
      overtimeRate: double.tryParse(data['overtime_rate'].toString()) ?? 0.0,
    );
  }
}

class SalaryStructure {
  final int id;
  final double basicSalary;
  final double medicalAllowance;
  final double mobileAllowance;
  final double conveyanceAllowance;
  final double houseAllowance;
  final double utilityAllowance;
  final double miscellaneousAllowance;
  final double incomeTax;
  final bool noTax;
  final double grossSalary;
  final double netSalary;
  final bool salaryByCash;
  final bool salaryByCheque;
  final bool salaryByTransfer;
  final String? accountNumber;
  final bool allowOvertime;
  final bool lateComingDeduction;

  SalaryStructure({
    required this.id,
    required this.basicSalary,
    required this.medicalAllowance,
    required this.mobileAllowance,
    required this.conveyanceAllowance,
    required this.houseAllowance,
    required this.utilityAllowance,
    required this.miscellaneousAllowance,
    required this.incomeTax,
    required this.noTax,
    required this.grossSalary,
    required this.netSalary,
    required this.salaryByCash,
    required this.salaryByCheque,
    required this.salaryByTransfer,
    this.accountNumber,
    required this.allowOvertime,
    required this.lateComingDeduction,
  });

  factory SalaryStructure.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return SalaryStructure(
      id: data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0,
      basicSalary: double.tryParse(data['basic_salary'].toString()) ?? 0.0,
      medicalAllowance: double.tryParse(data['medical_allowance'].toString()) ?? 0.0,
      mobileAllowance: double.tryParse(data['mobile_allowance'].toString()) ?? 0.0,
      conveyanceAllowance: double.tryParse(data['conveyance_allowance'].toString()) ?? 0.0,
      houseAllowance: double.tryParse(data['house_allowance'].toString()) ?? 0.0,
      utilityAllowance: double.tryParse(data['utility_allowance'].toString()) ?? 0.0,
      miscellaneousAllowance: double.tryParse(data['miscellaneous_allowance'].toString()) ?? 0.0,
      incomeTax: double.tryParse(data['income_tax'].toString()) ?? 0.0,
      noTax: data['no_tax'] is bool ? data['no_tax'] : (data['no_tax']?.toString().toLowerCase() == 'true'),
      grossSalary: double.tryParse(data['gross_salary'].toString()) ?? 0.0,
      netSalary: double.tryParse(data['net_salary'].toString()) ?? 0.0,
      salaryByCash: data['salary_by_cash'] is bool ? data['salary_by_cash'] : (data['salary_by_cash']?.toString().toLowerCase() == 'true'),
      salaryByCheque: data['salary_by_cheque'] is bool ? data['salary_by_cheque'] : (data['salary_by_cheque']?.toString().toLowerCase() == 'true'),
      salaryByTransfer: data['salary_by_transfer'] is bool ? data['salary_by_transfer'] : (data['salary_by_transfer']?.toString().toLowerCase() == 'true'),
      accountNumber: data['account_number']?.toString(),
      allowOvertime: data['allow_overtime'] is bool ? data['allow_overtime'] : (data['allow_overtime']?.toString().toLowerCase() == 'true'),
      lateComingDeduction: data['late_coming_deduction'] is bool ? data['late_coming_deduction'] : (data['late_coming_deduction']?.toString().toLowerCase() == 'true'),
    );
  }
}

class AttendanceSummary {
  final int monthDays;
  final int presentDays;
  final int leaveDays;
  final int holidayDays;
  final int absentDays;
  final int lateDays;
  final int halfDayCount;
  final int fullAbsentCount;
  final int overtimeMinutesTotal;
  final double overtimeAmountTotal;

  AttendanceSummary({
    required this.monthDays,
    required this.presentDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDayCount,
    required this.fullAbsentCount,
    required this.overtimeMinutesTotal,
    required this.overtimeAmountTotal,
  });

  factory AttendanceSummary.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return AttendanceSummary(
      monthDays: data['month_days'] is int ? data['month_days'] : int.tryParse(data['month_days'].toString()) ?? 0,
      presentDays: data['present_days'] is int ? data['present_days'] : int.tryParse(data['present_days'].toString()) ?? 0,
      leaveDays: data['leave_days'] is int ? data['leave_days'] : int.tryParse(data['leave_days'].toString()) ?? 0,
      holidayDays: data['holiday_days'] is int ? data['holiday_days'] : int.tryParse(data['holiday_days'].toString()) ?? 0,
      absentDays: data['absent_days'] is int ? data['absent_days'] : int.tryParse(data['absent_days'].toString()) ?? 0,
      lateDays: data['late_days'] is int ? data['late_days'] : int.tryParse(data['late_days'].toString()) ?? 0,
      halfDayCount: data['half_day_count'] is int ? data['half_day_count'] : int.tryParse(data['half_day_count'].toString()) ?? 0,
      fullAbsentCount: data['full_absent_count'] is int ? data['full_absent_count'] : int.tryParse(data['full_absent_count'].toString()) ?? 0,
      overtimeMinutesTotal: data['overtime_minutes_total'] is int ? data['overtime_minutes_total'] : int.tryParse(data['overtime_minutes_total'].toString()) ?? 0,
      overtimeAmountTotal: double.tryParse(data['overtime_amount_total'].toString()) ?? 0.0,
    );
  }
}

class PayrollCalculation {
  final double baseNetSalary;
  final double halfDayDeductionTotal;
  final double fullDayDeductionTotal;
  final double overtimeAmountTotal;
  final double advanceAmountTotal;
  final double netPayableBeforeAdvance;
  final double netPayable;

  PayrollCalculation({
    required this.baseNetSalary,
    required this.halfDayDeductionTotal,
    required this.fullDayDeductionTotal,
    required this.overtimeAmountTotal,
    required this.advanceAmountTotal,
    required this.netPayableBeforeAdvance,
    required this.netPayable,
  });

  factory PayrollCalculation.fromJson(dynamic json) {
    final data = convertDynamicToMap(json);

    return PayrollCalculation(
      baseNetSalary: double.tryParse(data['base_net_salary'].toString()) ?? 0.0,
      halfDayDeductionTotal: double.tryParse(data['half_day_deduction_total'].toString()) ?? 0.0,
      fullDayDeductionTotal: double.tryParse(data['full_day_deduction_total'].toString()) ?? 0.0,
      overtimeAmountTotal: double.tryParse(data['overtime_amount_total'].toString()) ?? 0.0,
      advanceAmountTotal: double.tryParse(data['advance_amount_total'].toString()) ?? 0.0,
      netPayableBeforeAdvance: double.tryParse(data['net_payable_before_advance'].toString()) ?? 0.0,
      netPayable: double.tryParse(data['net_payable'].toString()) ?? 0.0,
    );
  }
}