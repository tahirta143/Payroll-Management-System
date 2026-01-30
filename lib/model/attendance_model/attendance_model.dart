// import 'dart:ui';
//
// import 'package:flutter/material.dart';
//
// class Attendance {
//   final int id;
//   final DateTime date;
//   final int departmentId;
//   final int employeeId;
//   final int dutyShiftId;
//   final String? machineCode;
//   final String dutyShift;
//   final String timeIn;
//   final String timeOut;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final String empId;
//   final String employeeName;
//   final String? employeeMachineCode;
//   final String departmentName;
//   final String dutyShiftName;
//   final String dutyShiftStart;
//   final String dutyShiftEnd;
//
//   Attendance({
//     required this.id,
//     required this.date,
//     required this.departmentId,
//     required this.employeeId,
//     required this.dutyShiftId,
//     this.machineCode,
//     required this.dutyShift,
//     required this.timeIn,
//     required this.timeOut,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.empId,
//     required this.employeeName,
//     this.employeeMachineCode,
//     required this.departmentName,
//     required this.dutyShiftName,
//     required this.dutyShiftStart,
//     required this.dutyShiftEnd,
//   });
//
//   factory Attendance.fromJson(Map<String, dynamic> json) {
//     return Attendance(
//       id: json['id'],
//       date: DateTime.parse(json['date']),
//       departmentId: json['department_id'],
//       employeeId: json['employee_id'],
//       dutyShiftId: json['duty_shift_id'],
//       machineCode: json['machine_code'],
//       dutyShift: json['duty_shift'],
//       timeIn: json['time_in'],
//       timeOut: json['time_out'],
//       createdAt: DateTime.parse(json['created_at']),
//       updatedAt: DateTime.parse(json['updated_at']),
//       empId: json['emp_id'],
//       employeeName: json['employee_name'],
//       employeeMachineCode: json['employee_machine_code'],
//       departmentName: json['department_name'],
//       dutyShiftName: json['duty_shift_name'],
//       dutyShiftStart: json['duty_shift_start'],
//       dutyShiftEnd: json['duty_shift_end'],
//     );
//   }
//
//   // Calculate late minutes
//   int get lateMinutes {
//     final shiftStart = _parseTime(dutyShiftStart);
//     final timeInTime = _parseTime(timeIn);
//
//     if (timeInTime.isAfter(shiftStart)) {
//       return timeInTime.difference(shiftStart).inMinutes;
//     }
//     return 0;
//   }
//
//   // Calculate overtime minutes
//   int get overtimeMinutes {
//     final shiftEnd = _parseTime(dutyShiftEnd);
//     final timeOutTime = _parseTime(timeOut);
//
//     if (timeOutTime.isAfter(shiftEnd)) {
//       return timeOutTime.difference(shiftEnd).inMinutes;
//     }
//     return 0;
//   }
//
//   // Check if present
//   bool get isPresent => timeIn.isNotEmpty && timeOut.isNotEmpty;
//
//   // Get status color
//   Color get statusColor {
//     if (!isPresent) return Colors.red;
//     if (lateMinutes > 15) return Colors.orange;
//     if (lateMinutes > 0) return Colors.yellow[700]!;
//     return Colors.green;
//   }
//
//   // Get status text
//   String get status {
//     if (!isPresent) return 'Absent';
//     if (lateMinutes > 15) return 'Late (>15min)';
//     if (lateMinutes > 0) return 'Late';
//     if (overtimeMinutes > 0) return 'On Time + OT';
//     return 'On Time';
//   }
//
//   // Helper method to parse time string
//   DateTime _parseTime(String time) {
//     final parts = time.split(':');
//     return DateTime(
//       date.year,
//       date.month,
//       date.day,
//       int.parse(parts[0]),
//       int.parse(parts[1]),
//       int.parse(parts.length > 2 ? parts[2] : '0'),
//     );
//   }
// }

// models.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Attendance {
  final int id;
  final DateTime date;
  final int departmentId;
  final int employeeId;
  final int dutyShiftId;
  final String? machineCode;
  final String dutyShift;
  final String timeIn;
  final String timeOut;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String empId;
  final String employeeName;
  final String? employeeMachineCode;
  final String departmentName;
  final String dutyShiftName;
  final String dutyShiftStart;
  final String dutyShiftEnd;
  final String? lateMinutesStr;
  final String? overtimeMinutesStr;
  final String? imageUrl; // Add this line

  Attendance({
    required this.id,
    required this.date,
    required this.departmentId,
    required this.employeeId,
    required this.dutyShiftId,
    this.machineCode,
    required this.dutyShift,
    required this.timeIn,
    required this.timeOut,
    required this.createdAt,
    required this.updatedAt,
    required this.empId,
    required this.employeeName,
    this.employeeMachineCode,
    required this.departmentName,
    required this.dutyShiftName,
    required this.dutyShiftStart,
    required this.dutyShiftEnd,
    this.lateMinutesStr,
    this.overtimeMinutesStr,
    this.imageUrl, // Add this parameter
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      departmentId: json['department_id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      dutyShiftId: json['duty_shift_id'] ?? 0,
      machineCode: json['machine_code'],
      dutyShift: json['duty_shift'] ?? '',
      timeIn: json['time_in'] ?? '',
      timeOut: json['time_out'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      empId: json['emp_id'] ?? '',
      imageUrl: json['employee_image'] ??
          json['profile_image'] ??
          json['avatar'] ??
          json['photo'] ??
          json['image_url'] ??
          json['image'], // Parse image URL from API
      employeeName: json['employee_name'] ?? '',
      employeeMachineCode: json['employee_machine_code'],
      departmentName: json['department_name'] ?? '',
      dutyShiftName: json['duty_shift_name'] ?? '',
      dutyShiftStart: json['duty_shift_start'] ?? '09:00',
      dutyShiftEnd: json['duty_shift_end'] ?? '17:00',
      lateMinutesStr: json['late_minutes']?.toString(),
      overtimeMinutesStr: json['overtime_minutes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'department_id': departmentId,
      'employee_id': employeeId,
      'duty_shift_id': dutyShiftId,
      'machine_code': machineCode,
      'duty_shift': dutyShift,
      'time_in': timeIn,
      'time_out': timeOut,
      'emp_id': empId,
      'employee_name': employeeName,
      'employee_machine_code': employeeMachineCode,
      'department_name': departmentName,
      'duty_shift_name': dutyShiftName,
      'duty_shift_start': dutyShiftStart,
      'duty_shift_end': dutyShiftEnd,
    };
  }

  // Create a copyWith method for updates
  Attendance copyWith({
    int? id,
    DateTime? date,
    int? departmentId,
    int? employeeId,
    int? dutyShiftId,
    String? machineCode,
    String? dutyShift,
    String? timeIn,
    String? timeOut,
    String? empId,
    String? employeeName,
    String? employeeMachineCode,
    String? departmentName,
    String? dutyShiftName,
    String? dutyShiftStart,
    String? dutyShiftEnd,
  }) {
    return Attendance(
      id: id ?? this.id,
      date: date ?? this.date,
      departmentId: departmentId ?? this.departmentId,
      employeeId: employeeId ?? this.employeeId,
      dutyShiftId: dutyShiftId ?? this.dutyShiftId,
      machineCode: machineCode ?? this.machineCode,
      dutyShift: dutyShift ?? this.dutyShift,
      timeIn: timeIn ?? this.timeIn,
      timeOut: timeOut ?? this.timeOut,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      empId: empId ?? this.empId,
      employeeName: employeeName ?? this.employeeName,
      employeeMachineCode: employeeMachineCode ?? this.employeeMachineCode,
      departmentName: departmentName ?? this.departmentName,
      dutyShiftName: dutyShiftName ?? this.dutyShiftName,
      dutyShiftStart: dutyShiftStart ?? this.dutyShiftStart,
      dutyShiftEnd: dutyShiftEnd ?? this.dutyShiftEnd,
    );
  }

  // Calculate late minutes
  int get lateMinutes {
    if (lateMinutesStr != null) {
      return int.tryParse(lateMinutesStr!) ?? 0;
    }

    if (timeIn.isEmpty) return 0;

    try {
      final shiftStart = _parseTime(dutyShiftStart);
      final timeInTime = _parseTime(timeIn);

      if (timeInTime.isAfter(shiftStart)) {
        return timeInTime.difference(shiftStart).inMinutes;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Calculate overtime minutes
  int get overtimeMinutes {
    if (overtimeMinutesStr != null) {
      return int.tryParse(overtimeMinutesStr!) ?? 0;
    }

    if (timeOut.isEmpty) return 0;

    try {
      final shiftEnd = _parseTime(dutyShiftEnd);
      final timeOutTime = _parseTime(timeOut);

      if (timeOutTime.isAfter(shiftEnd)) {
        return timeOutTime.difference(shiftEnd).inMinutes;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Check if present
  bool get isPresent => timeIn.isNotEmpty && timeOut.isNotEmpty;

  // Get status color
  Color get statusColor {
    if (!isPresent) return Colors.red;
    if (lateMinutes > 15) return Colors.orange;
    if (lateMinutes > 0) return Colors.yellow[700]!;
    return Colors.green;
  }

  // Get status text
  String get status {
    if (!isPresent) return 'Absent';
    if (lateMinutes > 15) return 'Late (>15min)';
    if (lateMinutes > 0) return 'Late';
    if (overtimeMinutes > 0) return 'On Time + OT';
    return 'On Time';
  }

  // Get working hours
  String get workingHours {
    if (timeIn.isEmpty || timeOut.isEmpty) return 'N/A';

    try {
      final inTime = _parseTime(timeIn);
      final outTime = _parseTime(timeOut);
      final duration = outTime.difference(inTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper method to parse time string
  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }
}

// DTO for creating/updating attendance
// DTO for creating/updating attendance
class AttendanceCreateDTO {
  final DateTime date;
  final int employeeId;
  final int dutyShiftId;
  final int departmentId; // ADD THIS
  final String timeIn;
  final String timeOut;
  final String? machineCode;

  AttendanceCreateDTO({
    required this.date,
    required this.employeeId,
    required this.dutyShiftId,
    required this.departmentId, // ADD THIS
    required this.timeIn,
    required this.timeOut,
    this.machineCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'employee_id': employeeId, // Changed to snake_case
      'duty_shift_id': dutyShiftId, // Changed to snake_case
      'department_id': departmentId, // ADD THIS
      'time_in': timeIn, // Changed to snake_case
      'time_out': timeOut, // Changed to snake_case
      'machine_code': machineCode ?? '', // Changed to snake_case
    };
  }
}

// Employee model
// In your Employee model
class Employee {
  final int id;
  final String name;
  final String empId;
  final String? imageUrl;
  final String department; // department name
  final int? departmentId; // department ID

  Employee({
    required this.id,
    required this.name,
    required this.empId,
    this.imageUrl, // Add this
    required this.department,
    this.departmentId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? json['employee_id'] ?? 0,
      name: json['name'] ?? json['employee_name'] ?? '',
      empId: json['emp_id'] ?? json['employee_code'] ?? '',
      imageUrl: json['image_url'] ?? // Add image URL parsing
          json['profile_image'] ??
          json['avatar'] ??
          json['photo'] ??
          json['image'],
      department: json['department'] ?? json['department_name'] ?? '',
      departmentId: json['department_id'] ?? 0,
    );
  }
}

// In your Department model
class Department {
  final int id; // This should be used as departmentId
  final String name;
  final String? description; // Optional

  Department({
    required this.id,
    required this.name,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0, // This is your department_id
      name: json['name'] ?? '',
      description: json['description'] ?? json['dept_description'] ?? '',
    );
  }
}

// DutyShift model
class DutyShift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String? description;

  DutyShift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  factory DutyShift.fromJson(Map<String, dynamic> json) {
    return DutyShift(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? '09:00',
      endTime: json['end_time'] ?? '17:00',
      description: json['description'],
    );
  }
}

// Attendance Mode enum
enum AttendanceMode { add, edit, view }