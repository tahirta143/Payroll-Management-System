class AttendanceChartModel {
  final String granularity;
  final String employeeId;
  final String employeeName;
  final String month;
  final List<DailyAttendance> data;

  AttendanceChartModel({
    required this.granularity,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.data,
  });

  factory AttendanceChartModel.fromJson(Map<String, dynamic> json) {
    return AttendanceChartModel(
      granularity: json['granularity'] ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      month: json['month'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((item) => DailyAttendance.fromJson(item))
          .toList(),
    );
  }

  // Calculate total present days
  int get totalPresent {
    return data.fold(0, (sum, item) => sum + (item.present ?? 0));
  }

  // Calculate total absent days
  int get totalAbsent {
    return data.fold(0, (sum, item) => sum + (item.absent ?? 0));
  }

  // Calculate total late days
  int get totalLate {
    return data.fold(0, (sum, item) => sum + (item.late ?? 0));
  }
// Add this to your AttendanceChartModel class
  bool get hasData {
    return totalPresent > 0 || totalAbsent > 0 || totalLate > 0;
  }
  // Calculate total days (count of days with data)
  int get totalDays {
    return data.length;
  }

  // Calculate attendance percentage
  double get attendancePercentage {
    if (totalDays == 0) return 0;
    return (totalPresent / totalDays) * 100;
  }

  // Get summary map for chart widget
  Map<String, int> get chartSummary {
    return {
      'present': totalPresent,
      'absent': totalAbsent,
      'late': totalLate,
    };
  }
}

class DailyAttendance {
  final String label;
  final int? present;
  final int? absent;
  final int? late;
  final DateTime? date;

  DailyAttendance({
    required this.label,
    this.present,
    this.absent,
    this.late,
    DateTime? date,
  }) : date = date ?? _parseDate(label);

  factory DailyAttendance.fromJson(Map<String, dynamic> json) {
    return DailyAttendance(
      label: json['label'] ?? '',
      present: json['present'] != null ? (json['present'] as num).toInt() : 0,
      absent: json['absent'] != null ? (json['absent'] as num).toInt() : 0,
      late: json['late'] != null ? (json['late'] as num).toInt() : 0,
    );
  }

  static DateTime _parseDate(String label) {
    try {
      return DateTime.parse(label);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Check if this day has any attendance data
  bool get hasData {
    return (present ?? 0) > 0 || (absent ?? 0) > 0 || (late ?? 0) > 0;
  }

  // Get status for this day
  String get status {
    if ((present ?? 0) > 0) return 'Present';
    if ((absent ?? 0) > 0) return 'Absent';
    if ((late ?? 0) > 0) return 'Late';
    return 'No Data';
  }
}