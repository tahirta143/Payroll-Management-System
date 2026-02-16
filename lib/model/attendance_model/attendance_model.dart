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
  final String? imageUrl;

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
    this.imageUrl,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // Try to get image URL from various possible locations
    String? imageUrl;

    // Check if employee data is nested
    if (json['employee'] != null && json['employee'] is Map) {
      final employeeData = json['employee'] as Map<String, dynamic>;
      imageUrl = employeeData['image_url'] ??
          employeeData['profile_image'] ??
          employeeData['avatar'] ??
          employeeData['photo'] ??
          employeeData['image'];
    }

    // If not found in nested employee, try direct fields
    if (imageUrl == null) {
      imageUrl = json['employee_image'] ??
          json['profile_image'] ??
          json['avatar'] ??
          json['photo'] ??
          json['image_url'] ??
          json['image'];
    }

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
      imageUrl: imageUrl,  // Use the extracted imageUrl
      employeeName: json['employee_name'] ??
          (json['employee'] != null ? json['employee']['name'] ?? '' : ''),
      employeeMachineCode: json['employee_machine_code'],
      departmentName: json['department_name'] ??
          (json['department'] != null ? json['department']['name'] ?? '' : ''),
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

  // ✅ FIX: Present = timeIn exists (timeOut not required)
  bool get isPresent => timeIn.isNotEmpty;

  // ============ Calculate late minutes ============
  int get lateMinutes {
    if (lateMinutesStr != null) {
      return int.tryParse(lateMinutesStr!) ?? 0;
    }

    if (timeIn.isEmpty) return 0;

    try {
      final officeStart = DateTime(date.year, date.month, date.day, 9, 15);
      final timeInTime = _parseTime(timeIn);
      if (timeInTime.isAfter(officeStart)) {
        return timeInTime.difference(officeStart).inMinutes;
      }
      return 0;
    } catch (e) {
      print('Error calculating late minutes: $e');
      return 0;
    }
  }

  bool get isLate => lateMinutes > 0;

  bool get isLateAfterNineFifteen => lateMinutes > 15;

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

  Color get statusColor {
    if (!isPresent) return Colors.red;

    // Has timeIn but no timeOut yet = half day / still in office
    if (timeOut.isEmpty) return Colors.orange[800]!;

    if (isLate) {
      if (isLateAfterNineFifteen) return Colors.orange;
      return Colors.yellow[700]!;
    }

    if (overtimeMinutes > 0) return Colors.blue;
    return Colors.green;
  }

  String get status {
    if (!isPresent) return 'Absent';

    // Has timeIn but no timeOut
    if (timeOut.isEmpty) return 'In Office';

    if (isLate) {
      if (isLateAfterNineFifteen) {
        final minutes = lateMinutes;
        if (minutes >= 60) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          return mins > 0 ? 'Late (${hours}h ${mins}m)' : 'Late (${hours}h)';
        }
        return 'Late (${minutes}m)';
      }
      return 'Late';
    }

    if (overtimeMinutes > 0) return 'On Time + OT';
    return 'On Time';
  }

  String get detailedStatus {
    if (!isPresent) return 'Absent';
    if (timeOut.isEmpty) return 'In Office';

    if (isLate) {
      final minutes = lateMinutes;
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        return mins > 0 ? 'Late (${hours}h ${mins}m)' : 'Late (${hours}h)';
      }
      return 'Late (${minutes}m)';
    }

    if (overtimeMinutes > 0) {
      final minutes = overtimeMinutes;
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        return mins > 0 ? 'On Time + OT (${hours}h ${mins}m)' : 'On Time + OT (${hours}h)';
      }
      return 'On Time + OT (${minutes}m)';
    }

    return 'On Time';
  }

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

  String get formattedLateTime {
    if (!isLate) return '';
    final minutes = lateMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m late' : '${hours}h late';
    }
    return '${minutes}m late';
  }

  bool get isAfterNineFifteen {
    if (timeIn.isEmpty) return false;
    try {
      final timeInTime = _parseTime(timeIn);
      final nineFifteen = DateTime(date.year, date.month, date.day, 9, 15);
      return timeInTime.isAfter(nineFifteen);
    } catch (e) {
      return false;
    }
  }

  int get lateMinutesAfterNineFifteen {
    if (!isAfterNineFifteen) return 0;
    final minutes = lateMinutes;
    return minutes > 15 ? minutes - 15 : 0;
  }

  DateTime _parseTime(String time) {
    try {
      final parts = time.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );
    } catch (e) {
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }

  Map<String, dynamic> get timeAnalysis => {
    'isLate': isLate,
    'lateMinutes': lateMinutes,
    'isAfterNineFifteen': isAfterNineFifteen,
    'lateMinutesAfterNineFifteen': lateMinutesAfterNineFifteen,
    'formattedLateTime': formattedLateTime,
    'status': status,
    'detailedStatus': detailedStatus,
  };
}

// DTO for creating/updating attendance
class AttendanceCreateDTO {
  final DateTime date;
  final int employeeId;
  final int dutyShiftId;
  final int departmentId;
  final String timeIn;
  final String timeOut;
  final String? machineCode;

  AttendanceCreateDTO({
    required this.date,
    required this.employeeId,
    required this.dutyShiftId,
    required this.departmentId,
    required this.timeIn,
    required this.timeOut,
    this.machineCode,
  });

  Map<String, dynamic> toJson() => {
    'date': DateFormat('yyyy-MM-dd').format(date),
    'employee_id': employeeId,
    'duty_shift_id': dutyShiftId,
    'department_id': departmentId,
    'time_in': timeIn,
    'time_out': timeOut,
    'machine_code': machineCode ?? '',
  };
}

// Employee model
class Employee {
  final int id;
  final String name;
  final String empId;
  final String? imageUrl;
  final String department;
  final int? departmentId;

  Employee({
    required this.id,
    required this.name,
    required this.empId,
    this.imageUrl,
    required this.department,
    this.departmentId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? json['employee_id'] ?? 0,
      name: json['name'] ?? json['employee_name'] ?? '',
      empId: json['emp_id'] ?? json['employee_code'] ?? '',
      imageUrl: json['image_url'] ??
          json['profile_image'] ??
          json['avatar'] ??
          json['photo'] ??
          json['image'],

      department: json['department'] ?? json['department_name'] ?? '',
      departmentId: json['department_id'] ?? 0,
    );
  }

}

// Department model
class Department {
  final int id;
  final String name;
  final String? description;

  Department({
    required this.id,
    required this.name,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    description: json['description'] ?? json['dept_description'] ?? '',
  );
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

  factory DutyShift.fromJson(Map<String, dynamic> json) => DutyShift(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    startTime: json['start_time'] ?? '09:00',
    endTime: json['end_time'] ?? '18:00',
    description: json['description'],
  );
}

enum AttendanceMode { add, edit, view }
