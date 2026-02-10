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
          json['image'],
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

  // ============ Calculate late minutes ============
  int get lateMinutes {
    // If API already provides late minutes, use it
    if (lateMinutesStr != null) {
      return int.tryParse(lateMinutesStr!) ?? 0;
    }

    if (timeIn.isEmpty) return 0;

    try {
      // Office start time is 9:00 AM
      final officeStart = DateTime(
        date.year,
        date.month,
        date.day,
        9,   // hour
        15,   // minute
      );

      final timeInTime = _parseTime(timeIn);

      // Calculate if checking in after 9:00 AM
      if (timeInTime.isAfter(officeStart)) {
        return timeInTime.difference(officeStart).inMinutes;
      }
      return 0;
    } catch (e) {
      print('Error calculating late minutes: $e');
      return 0;
    }
  }

  // Check if employee is late (after 9:00 AM)
  bool get isLate {
    return lateMinutes > 0;
  }

  // Check if late after 9:15 AM
  bool get isLateAfterNineFifteen {
    return lateMinutes > 15; // 9:15 AM is 15 minutes after 9:00 AM
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
    if (!isPresent) {
      // If has timeIn but no timeOut, it's half day
      if (timeIn.isNotEmpty && timeOut.isEmpty) {
        return Colors.orange[800]!;
      }
      return Colors.red;
    }

    if (isLate) {
      if (isLateAfterNineFifteen) {
        return Colors.orange; // Late after 9:15
      }
      return Colors.yellow[700]!; // Late before 9:15
    }

    if (overtimeMinutes > 0) return Colors.blue; // On Time + OT
    return Colors.green; // On Time
  }

  // ============ Get status text ============
  String get status {
    if (!isPresent) {
      if (timeIn.isNotEmpty && timeOut.isEmpty) {
        return 'Half Day';
      }
      return 'Absent';
    }

    if (isLate) {
      // If late after 9:15 AM, show exact minutes
      if (isLateAfterNineFifteen) {
        final minutes = lateMinutes;
        if (minutes >= 60) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          if (mins > 0) {
            return 'Late (${hours}h ${mins}m)';
          }
          return 'Late (${hours}h)';
        }
        return 'Late (${minutes}m)';
      }
      // If late but before 9:15 AM
      return 'Late';
    }

    if (overtimeMinutes > 0) {
      return 'On Time + OT';
    }

    return 'On Time';
  }

  // Get detailed status (always shows minutes if late)
  String get detailedStatus {
    if (!isPresent) {
      if (timeIn.isNotEmpty && timeOut.isEmpty) {
        return 'Half Day';
      }
      return 'Absent';
    }

    if (isLate) {
      final minutes = lateMinutes;
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        if (mins > 0) {
          return 'Late (${hours}h ${mins}m)';
        }
        return 'Late (${hours}h)';
      }
      return 'Late (${minutes}m)';
    }

    if (overtimeMinutes > 0) {
      final minutes = overtimeMinutes;
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        if (mins > 0) {
          return 'On Time + OT (${hours}h ${mins}m)';
        }
        return 'On Time + OT (${hours}h)';
      }
      return 'On Time + OT (${minutes}m)';
    }

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

  // Get formatted late time for display
  String get formattedLateTime {
    if (!isLate) return '';

    final minutes = lateMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return '${hours}h ${mins}m late';
      }
      return '${hours}h late';
    }
    return '${minutes}m late';
  }

  // Check exact time after 9:15 AM
  bool get isAfterNineFifteen {
    if (timeIn.isEmpty) return false;

    try {
      final timeInTime = _parseTime(timeIn);
      final nineFifteen = DateTime(
        date.year,
        date.month,
        date.day,
        9,   // hour
        15,  // minute
      );

      return timeInTime.isAfter(nineFifteen);
    } catch (e) {
      return false;
    }
  }

  // Get late minutes after 9:15 (if any)
  int get lateMinutesAfterNineFifteen {
    if (!isAfterNineFifteen) return 0;

    final minutes = lateMinutes;
    if (minutes > 15) {
      return minutes - 15; // Minutes after 9:15
    }
    return 0;
  }

  // Helper method to parse time string
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
      // If parsing fails, return office start time
      return DateTime(
        date.year,
        date.month,
        date.day,
        9,   // hour
        0,   // minute
      );
    }
  }

  // Get check-in time analysis
  Map<String, dynamic> get timeAnalysis {
    return {
      'isLate': isLate,
      'lateMinutes': lateMinutes,
      'isAfterNineFifteen': isAfterNineFifteen,
      'lateMinutesAfterNineFifteen': lateMinutesAfterNineFifteen,
      'formattedLateTime': formattedLateTime,
      'status': status,
      'detailedStatus': detailedStatus,
    };
  }
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

  Map<String, dynamic> toJson() {
    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'employee_id': employeeId,
      'duty_shift_id': dutyShiftId,
      'department_id': departmentId,
      'time_in': timeIn,
      'time_out': timeOut,
      'machine_code': machineCode ?? '',
    };
  }
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

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
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