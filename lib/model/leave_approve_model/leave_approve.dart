class ApproveLeave {
  final int id;
  final String leaveId;
  final DateTime date;
  final String? code;
  final int departmentId;
  final int employeeId;
  final String? designation;
  final String natureOfLeave;
  final DateTime fromDate;
  final DateTime toDate;
  final int days;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String employeeName;
  final String employeeCode;
  final String? imageUrl;
  final String departmentName;
  String status;
  final String payMode; // Add this field

  ApproveLeave({
    required this.id,
    required this.leaveId,
    required this.date,
    this.code,
    this.imageUrl,
    required this.departmentId,
    required this.employeeId,
    this.designation,
    required this.natureOfLeave,
    required this.fromDate,
    required this.toDate,
    required this.days,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
    required this.employeeName,
    required this.employeeCode,
    required this.departmentName,
    required this.status,
    required this.payMode, // Add this
  });

  factory ApproveLeave.fromJson(Map<String, dynamic> json) {
    // Parse status, default to 'pending' if not provided
    String parseStatus(dynamic status) {
      if (status == null) return 'pending';
      final statusStr = status.toString().toLowerCase();

      // Handle different status formats from API
      if (statusStr == 'pending' || statusStr == '0') return 'pending';
      if (statusStr == 'approved' || statusStr == '1') return 'approved';
      if (statusStr == 'rejected' || statusStr == '2') return 'rejected';

      return statusStr;
    }

    // Parse pay mode
    String parsePayMode(dynamic payMode) {
      if (payMode == null) return 'with_pay';
      final payModeStr = payMode.toString().toLowerCase();
      return payModeStr;
    }

    // Helper function to parse DateTime safely
    DateTime parseDateTime(dynamic date) {
      if (date == null) return DateTime.now();
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    // Helper function to parse integers safely
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    // Helper function to parse strings safely
    String parseString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    return ApproveLeave(
      id: parseInt(json['id']),
      leaveId: parseString(json['leave_id']),
      date: parseDateTime(json['date']),
      code: json['code']?.toString(),
      departmentId: parseInt(json['department_id']),
      employeeId: parseInt(json['employee_id']),
      designation: json['designation']?.toString(),
      natureOfLeave: parseString(json['nature_of_leave']),
      fromDate: parseDateTime(json['from_date']),
      toDate: parseDateTime(json['to_date']),
      days: parseInt(json['days']),
      reason: json['reason']?.toString(),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      employeeName: parseString(json['employee_name']),
      employeeCode: parseString(json['employee_code']),
      departmentName: parseString(json['department_name']),
      status: parseStatus(json['status']),
      payMode: parsePayMode(json['pay_mode']), // Add this
      imageUrl: json['employee_image'] ??
          json['profile_image'] ??
          json['avatar'] ??
          json['photo'] ??
          json['image_url'] ??
          json['image'], // Add this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leave_id': leaveId,
      'date': date.toIso8601String(),
      'code': code,
      'department_id': departmentId,
      'employee_id': employeeId,
      'designation': designation,
      'nature_of_leave': natureOfLeave,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'days': days,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'employee_name': employeeName,
      'employee_code': employeeCode,
      'department_name': departmentName,
      'status': status,
      'pay_mode': payMode, // Add this
    };
  }

  ApproveLeave copyWith({
    String? status,
    String? payMode,
    String? imageUrl,
  }) {
    return ApproveLeave(
      id: id,
      leaveId: leaveId,
      date: date,
      code: code,
      departmentId: departmentId,
      employeeId: employeeId,
      designation: designation,
      natureOfLeave: natureOfLeave,
      fromDate: fromDate,
      toDate: toDate,
      days: days,
      reason: reason,
      createdAt: createdAt,
      updatedAt: updatedAt,
      employeeName: employeeName,
      employeeCode: employeeCode,
      departmentName: departmentName,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      payMode: payMode ?? this.payMode, // Add this
    );
  }
}