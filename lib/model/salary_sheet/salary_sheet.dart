import 'package:flutter/material.dart';

class Department {
  final int id;
  final String name;
  final String? code;
  final String? createdAt;

  Department({
    required this.id,
    required this.name,
    this.code,
    this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      createdAt: json['created_at']?.toString(), // Add this line
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class MonthlySalarySheet {
  final String month;
  final DateRange range;
  final int departmentId;
  final SalaryTotals totals;
  final List<SalaryRow> rows;

  MonthlySalarySheet({
    required this.month,
    required this.range,
    required this.departmentId,
    required this.totals,
    required this.rows,
  });

  factory MonthlySalarySheet.fromJson(Map<String, dynamic> json) {
    return MonthlySalarySheet(
      month: json['month']?.toString() ?? '',
      range: DateRange.fromJson(Map<String, dynamic>.from(json['range'] ?? {})),
      departmentId: _parseInt(json['department_id']),
      totals: SalaryTotals.fromJson(Map<String, dynamic>.from(json['totals'] ?? {})),
      rows: (json['rows'] as List<dynamic>?)
          ?.map((row) => SalaryRow.fromJson(Map<String, dynamic>.from(row ?? {})))
          .toList() ?? [],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class DateRange {
  final DateTime from;
  final DateTime to;

  DateRange({
    required this.from,
    required this.to,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: DateTime.parse(json['from']?.toString() ?? DateTime.now().toString()),
      to: DateTime.parse(json['to']?.toString() ?? DateTime.now().toString()),
    );
  }
}

class SalaryTotals {
  final double salarySum;
  final double totalSum;
  final int employeesCount;

  SalaryTotals({
    required this.salarySum,
    required this.totalSum,
    required this.employeesCount,
  });

  factory SalaryTotals.fromJson(Map<String, dynamic> json) {
    return SalaryTotals(
      salarySum: _parseDouble(json['salary_sum']),
      totalSum: _parseDouble(json['total_sum']),
      employeesCount: _parseInt(json['employees_count']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class SalaryRow {
  final String unit;
  final String employee;
  final String? designation;
  final DateTime joiningDate;
  final String? bank;
  final String? accountNo;
  final int late;
  final int leaves;
  final int days;
  final double salary;
  final double total;
  final SalaryRowMeta meta;

  SalaryRow({
    required this.unit,
    required this.employee,
    this.designation,
    required this.joiningDate,
    this.bank,
    this.accountNo,
    required this.late,
    required this.leaves,
    required this.days,
    required this.salary,
    required this.total,
    required this.meta,
  });

  factory SalaryRow.fromJson(Map<String, dynamic> json) {
    return SalaryRow(
      unit: json['unit']?.toString() ?? '',
      employee: json['employee']?.toString() ?? '',
      designation: json['designation']?.toString(),
      joiningDate: DateTime.parse(json['joining_date']?.toString() ?? DateTime.now().toString()),
      bank: json['bank']?.toString(),
      accountNo: json['account_no']?.toString(),
      late: _parseInt(json['late']),
      leaves: _parseInt(json['leaves']),
      days: _parseInt(json['days']),
      salary: _parseDouble(json['salary']),
      total: _parseDouble(json['total']),
      meta: SalaryRowMeta.fromJson(Map<String, dynamic>.from(json['_meta'] ?? {})),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper getters
  double get deductions => salary - total;
  String get formattedSalary => salary.toStringAsFixed(0);
  String get formattedTotal => total.toStringAsFixed(0);
  String get status => total > 0 ? 'Calculated' : 'Not Calculated';
  bool get isCalculated => total > 0;
}

class SalaryRowMeta {
  final int employeeId;
  final String empId;
  final double advanceTotal;
  final double overtimeTotal;
  final double halfDayDeductionTotal;
  final double fullDayDeductionTotal;

  SalaryRowMeta({
    required this.employeeId,
    required this.empId,
    required this.advanceTotal,
    required this.overtimeTotal,
    required this.halfDayDeductionTotal,
    required this.fullDayDeductionTotal,
  });

  factory SalaryRowMeta.fromJson(Map<String, dynamic> json) {
    return SalaryRowMeta(
      employeeId: _parseInt(json['employee_id']),
      empId: json['emp_id']?.toString() ?? '',
      advanceTotal: _parseDouble(json['advance_total']),
      overtimeTotal: _parseDouble(json['overtime_total']),
      halfDayDeductionTotal: _parseDouble(json['half_day_deduction_total']),
      fullDayDeductionTotal: _parseDouble(json['full_day_deduction_total']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}