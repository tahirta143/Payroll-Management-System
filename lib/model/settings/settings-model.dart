// lib/model/settings_model/attendance_settings_model.dart

class AttendanceSettings {
  final int id;
  final String maxLateTime;
  final String halfDayDeductionPercent;
  final String fullDayDeductionPercent;
  final String overtimeStartAfter;
  final String overtimeRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceSettings({
    required this.id,
    required this.maxLateTime,
    required this.halfDayDeductionPercent,
    required this.fullDayDeductionPercent,
    required this.overtimeStartAfter,
    required this.overtimeRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceSettings(
      id: json['id'] as int,
      maxLateTime: json['max_late_time'] as String,
      halfDayDeductionPercent: json['half_day_deduction_percent'] as String,
      fullDayDeductionPercent: json['full_day_deduction_percent'] as String,
      overtimeStartAfter: json['overtime_start_after'] as String,
      overtimeRate: json['overtime_rate'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'max_late_time': maxLateTime,
      'half_day_deduction_percent': halfDayDeductionPercent,
      'full_day_deduction_percent': fullDayDeductionPercent,
      'overtime_start_after': overtimeStartAfter,
      'overtime_rate': overtimeRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods to convert string percentages to double
  double get halfDayDeductionAsDouble => double.tryParse(halfDayDeductionPercent) ?? 0.0;
  double get fullDayDeductionAsDouble => double.tryParse(fullDayDeductionPercent) ?? 0.0;
  double get overtimeRateAsDouble => double.tryParse(overtimeRate) ?? 0.0;

  // Helper method to format time for display
  String get formattedMaxLateTime {
    try {
      final timeParts = maxLateTime.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      return maxLateTime;
    }
    return maxLateTime;
  }

  String get formattedOvertimeStart {
    try {
      final timeParts = overtimeStartAfter.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      return overtimeStartAfter;
    }
    return overtimeStartAfter;
  }

  String get formattedUpdatedAt {
    return '${updatedAt.day} ${_getMonthAbbreviation(updatedAt.month)} ${updatedAt.year}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

// Response wrapper model
class AttendanceSettingsResponse {
  final AttendanceSettings settings;

  AttendanceSettingsResponse({required this.settings});

  factory AttendanceSettingsResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceSettingsResponse(
      settings: AttendanceSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': settings.toJson(),
    };
  }
}