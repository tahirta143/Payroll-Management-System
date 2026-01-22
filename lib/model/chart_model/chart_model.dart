// attendance_model.dart
class ChartData {
  final String label;
  final String? date; // Optional for monthly data
  final int present;
  final int absent;
  final int late;

  ChartData({
    required this.label,
    this.date,
    required this.present,
    required this.absent,
    required this.late,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'].toString(),
      date: json['date']?.toString(),
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
    );
  }

  // Total attendance count
  int get total => present + absent + late;

  // Attendance percentage
  double get attendancePercentage {
    return total > 0 ? (present / total * 100) : 0;
  }
}

class DashboardChartResponse {
  final String granularity;
  final List<ChartData> data;

  DashboardChartResponse({
    required this.granularity,
    required this.data,
  });

  factory DashboardChartResponse.fromJson(Map<String, dynamic> json) {
    return DashboardChartResponse(
      granularity: json['granularity'],
      data: (json['data'] as List)
          .map((item) => ChartData.fromJson(item))
          .toList(),
    );
  }

  // Get total statistics
  int get totalPresent => data.fold(0, (sum, item) => sum + item.present);
  int get totalAbsent => data.fold(0, (sum, item) => sum + item.absent);
  int get totalLate => data.fold(0, (sum, item) => sum + item.late);
  int get totalAll => totalPresent + totalAbsent + totalLate;

  // Check if it's daily or monthly data
  bool get isDaily => granularity == 'day';
  bool get isMonthly => granularity == 'month';
}