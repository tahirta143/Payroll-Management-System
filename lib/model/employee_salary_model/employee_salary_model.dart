

import '../attendance_model/attendance_model.dart';

class EmployeeSalary {
  final int id;
  final int employeeId;
  final double basicSalary;
  final double medicalAllowance;
  final double mobileAllowance;
  final double conveyanceAllowance;
  final double houseAllowance;
  final double utilityAllowance;
  final double miscellaneousAllowance;
  final double incomeTax;
  final double grossSalary;
  final double netSalary;
  final bool noTax;
  final bool salaryByCash;
  final bool salaryByCheque;
  final bool salaryByTransfer;
  final String? accountNumber;
  final bool allowOvertime;
  final bool lateComingDeduction;
  final double? salaryAtAppointment;
  final DateTime? lastIncrementDate;
  final double? incrementAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String employeeName;
  final String employeeCode;
  final int? bankId;
  final String? bankAccountNumber;
  final String? bankName;

  EmployeeSalary({
    required this.id,
    required this.employeeId,
    required this.basicSalary,
    required this.medicalAllowance,
    required this.mobileAllowance,
    required this.conveyanceAllowance,
    required this.houseAllowance,
    required this.utilityAllowance,
    required this.miscellaneousAllowance,
    required this.incomeTax,
    required this.grossSalary,
    required this.netSalary,
    required this.noTax,
    required this.salaryByCash,
    required this.salaryByCheque,
    required this.salaryByTransfer,
    this.accountNumber,
    required this.allowOvertime,
    required this.lateComingDeduction,
    this.salaryAtAppointment,
    this.lastIncrementDate,
    this.incrementAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.employeeName,
    required this.employeeCode,
    this.bankId,
    this.bankAccountNumber,
    this.bankName,
  });

  factory EmployeeSalary.fromJson(Map<String, dynamic> json) {
    return EmployeeSalary(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      basicSalary: double.tryParse(json['basic_salary']?.toString() ?? '0') ?? 0,
      medicalAllowance: double.tryParse(json['medical_allowance']?.toString() ?? '0') ?? 0,
      mobileAllowance: double.tryParse(json['mobile_allowance']?.toString() ?? '0') ?? 0,
      conveyanceAllowance: double.tryParse(json['conveyance_allowance']?.toString() ?? '0') ?? 0,
      houseAllowance: double.tryParse(json['house_allowance']?.toString() ?? '0') ?? 0,
      utilityAllowance: double.tryParse(json['utility_allowance']?.toString() ?? '0') ?? 0,
      miscellaneousAllowance: double.tryParse(json['miscellaneous_allowance']?.toString() ?? '0') ?? 0,
      incomeTax: double.tryParse(json['income_tax']?.toString() ?? '0') ?? 0,
      grossSalary: double.tryParse(json['gross_salary']?.toString() ?? '0') ?? 0,
      netSalary: double.tryParse(json['net_salary']?.toString() ?? '0') ?? 0,
      noTax: (json['no_tax'] ?? 0) == 1,
      salaryByCash: (json['salary_by_cash'] ?? 0) == 1,
      salaryByCheque: (json['salary_by_cheque'] ?? 0) == 1,
      salaryByTransfer: (json['salary_by_transfer'] ?? 0) == 1,
      accountNumber: json['account_number'],
      allowOvertime: (json['allow_overtime'] ?? 0) == 1,
      lateComingDeduction: (json['late_coming_deduction'] ?? 0) == 1,
      salaryAtAppointment: json['salary_at_appointment'] != null
          ? double.tryParse(json['salary_at_appointment'].toString())
          : null,
      lastIncrementDate: json['last_increment_date'] != null
          ? DateTime.tryParse(json['last_increment_date'])
          : null,
      incrementAmount: json['increment_amount'] != null
          ? double.tryParse(json['increment_amount'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      employeeName: json['employee_name'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      bankId: json['bank_id'],
      bankAccountNumber: json['bank_account_number'],
      bankName: json['bank_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'basic_salary': basicSalary.toStringAsFixed(2),
      'medical_allowance': medicalAllowance.toStringAsFixed(2),
      'mobile_allowance': mobileAllowance.toStringAsFixed(2),
      'conveyance_allowance': conveyanceAllowance.toStringAsFixed(2),
      'house_allowance': houseAllowance.toStringAsFixed(2),
      'utility_allowance': utilityAllowance.toStringAsFixed(2),
      'miscellaneous_allowance': miscellaneousAllowance.toStringAsFixed(2),
      'income_tax': incomeTax.toStringAsFixed(2),
      'gross_salary': grossSalary.toStringAsFixed(2),
      'net_salary': netSalary.toStringAsFixed(2),
      'no_tax': noTax ? 1 : 0,
      'salary_by_cash': salaryByCash ? 1 : 0,
      'salary_by_cheque': salaryByCheque ? 1 : 0,
      'salary_by_transfer': salaryByTransfer ? 1 : 0,
      'account_number': accountNumber,
      'allow_overtime': allowOvertime ? 1 : 0,
      'late_coming_deduction': lateComingDeduction ? 1 : 0,
      'salary_at_appointment': salaryAtAppointment?.toStringAsFixed(2),
      'last_increment_date': lastIncrementDate?.toIso8601String(),
      'increment_amount': incrementAmount?.toStringAsFixed(2),
    };
  }

  // Helper method to get payment method
  String get paymentMethod {
    List<String> methods = [];
    if (salaryByCash) methods.add('Cash');
    if (salaryByCheque) methods.add('Cheque');
    if (salaryByTransfer) methods.add('Bank Transfer');
    return methods.join(', ');
  }

  // Get total allowances
  double get totalAllowances {
    return medicalAllowance +
        mobileAllowance +
        conveyanceAllowance +
        houseAllowance +
        utilityAllowance +
        miscellaneousAllowance;
  }

  // Create empty salary for a new employee
  factory EmployeeSalary.emptyForEmployee(Employee employee) {
    return EmployeeSalary(
      id: 0,
      employeeId: employee.id,
      basicSalary: 0,
      medicalAllowance: 0,
      mobileAllowance: 0,
      conveyanceAllowance: 0,
      houseAllowance: 0,
      utilityAllowance: 0,
      miscellaneousAllowance: 0,
      incomeTax: 0,
      grossSalary: 0,
      netSalary: 0,
      noTax: false,
      salaryByCash: true,
      salaryByCheque: false,
      salaryByTransfer: false,
      accountNumber: null,
      allowOvertime: false,
      lateComingDeduction: false,
      salaryAtAppointment: null,
      lastIncrementDate: null,
      incrementAmount: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      employeeName: employee.name,
      employeeCode: employee.empId,
      bankId: null,
      bankAccountNumber: null,
      bankName: null,
    );
  }

  // Calculate gross salary
  double calculateGrossSalary() {
    return basicSalary + totalAllowances;
  }

  // Calculate net salary
  double calculateNetSalary() {
    return calculateGrossSalary() - incomeTax;
  }
}