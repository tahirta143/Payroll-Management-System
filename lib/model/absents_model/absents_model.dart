class Absent {
  final int id;
  final String code;
  final int departmentId;
  final int employeeId;
  final String? designation;
  final DateTime absentDate;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String empId;
  final String? imageUrl;
  final String employeeName;
  final String departmentName;

  Absent({
    required this.id,
    required this.code,
    required this.departmentId,
    required this.employeeId,
    this.designation,
    required this.absentDate,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
    required this.empId,
    required this.employeeName,
    required this.departmentName,
    this.imageUrl,
  });

  factory Absent.fromJson(Map<String, dynamic> json) {
    return Absent(
      id: json['id'],
      code: json['code'],
      departmentId: json['department_id'],
      employeeId: json['employee_id'],
      designation: json['designation'],
      absentDate: DateTime.parse(json['absent_date']),
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      empId: json['emp_id'],
      employeeName: json['employee_name'],
      departmentName: json['department_name'],
      imageUrl: json['employee_image'] ??
          json['profile_image'] ??
          json['avatar'] ??
          json['photo'] ??
          json['image_url'] ??
          json['image'],
    );
  }

  // Add copyWith method
  Absent copyWith({
    int? id,
    String? code,
    int? departmentId,
    int? employeeId,
    String? designation,
    DateTime? absentDate,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? empId,
    String? imageUrl,
    String? employeeName,
    String? departmentName,
  }) {
    return Absent(
      id: id ?? this.id,
      code: code ?? this.code,
      departmentId: departmentId ?? this.departmentId,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      absentDate: absentDate ?? this.absentDate,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      empId: empId ?? this.empId,
      employeeName: employeeName ?? this.employeeName,
      departmentName: departmentName ?? this.departmentName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Check if absent is for a specific date
  bool isForDate(DateTime date) {
    return absentDate.year == date.year &&
        absentDate.month == date.month &&
        absentDate.day == date.day;
  }
}