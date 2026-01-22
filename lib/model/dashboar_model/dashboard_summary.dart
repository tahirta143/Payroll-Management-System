// dashboard_summary.dart
import 'package:flutter/cupertino.dart';

class DashboardSummary {
  final int totalEmployees;
  final int presentCount;
  final int leaveCount;
  final int shortLeaveCount;
  final int absentCount;
  final int lateComersCount;
  final String month;

  // Calculated percentages
  double get presentPercentage {
    return totalEmployees > 0 ? (presentCount / totalEmployees) * 100 : 0;
  }

  double get leavePercentage {
    return totalEmployees > 0 ? (leaveCount / totalEmployees) * 100 : 0;
  }

  double get absentPercentage {
    return totalEmployees > 0 ? (absentCount / totalEmployees) * 100 : 0;
  }

  double get shortLeavePercentage {
    return totalEmployees > 0 ? (shortLeaveCount / totalEmployees) * 100 : 0;
  }

  double get lateComersPercentage {
    return totalEmployees > 0 ? (lateComersCount / totalEmployees) * 100 : 0;
  }

  DashboardSummary({
    required this.totalEmployees,
    required this.presentCount,
    required this.leaveCount,
    required this.shortLeaveCount,
    required this.absentCount,
    required this.lateComersCount,
    required this.month,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    debugPrint('=== Parsing JSON in DashboardSummary.fromJson ===');
    debugPrint('JSON keys: ${json.keys.toList()}');

    // Handle different field name formats
    final totalEmployees = json['total_employees'] ?? json['totalEmployees'] ?? 0;
    final presentCount = json['present_count'] ?? json['presentCount'] ?? 0;
    final leaveCount = json['leave_count'] ?? json['leaveCount'] ?? 0;
    final shortLeaveCount = json['short_leave_count'] ?? json['shortLeaveCount'] ?? 0;
    final absentCount = json['absent_count'] ?? json['absentCount'] ?? 0;
    final lateComersCount = json['late_comers_count'] ?? json['lateComersCount'] ?? 0;
    final month = json['month']?.toString() ?? 'all';

    debugPrint('Parsed values:');
    debugPrint('- total_employees: $totalEmployees');
    debugPrint('- present_count: $presentCount');
    debugPrint('- leave_count: $leaveCount');
    debugPrint('- short_leave_count: $shortLeaveCount');
    debugPrint('- absent_count: $absentCount');
    debugPrint('- late_comers_count: $lateComersCount');
    debugPrint('- month: $month');

    // Log the data validation
    final sum = presentCount + leaveCount + absentCount;
    debugPrint('Data validation:');
    debugPrint('- present + leave + absent = $sum');
    debugPrint('- total_employees = $totalEmployees');
    debugPrint('- Difference: ${sum - totalEmployees}');

    return DashboardSummary(
      totalEmployees: totalEmployees is int ? totalEmployees : int.tryParse(totalEmployees.toString()) ?? 0,
      presentCount: presentCount is int ? presentCount : int.tryParse(presentCount.toString()) ?? 0,
      leaveCount: leaveCount is int ? leaveCount : int.tryParse(leaveCount.toString()) ?? 0,
      shortLeaveCount: shortLeaveCount is int ? shortLeaveCount : int.tryParse(shortLeaveCount.toString()) ?? 0,
      absentCount: absentCount is int ? absentCount : int.tryParse(absentCount.toString()) ?? 0,
      lateComersCount: lateComersCount is int ? lateComersCount : int.tryParse(lateComersCount.toString()) ?? 0,
      month: month,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_employees': totalEmployees,
    'present_count': presentCount,
    'leave_count': leaveCount,
    'short_leave_count': shortLeaveCount,
    'absent_count': absentCount,
    'late_comers_count': lateComersCount,
    'month': month,
  };

  // Add validation method
  List<String> validate() {
    final errors = <String>[];

    if (totalEmployees <= 0) {
      errors.add('Total employees must be positive');
    }

    final categorySum = presentCount + leaveCount + absentCount;
    if (categorySum != totalEmployees) {
      errors.add('Data inconsistency: Present($presentCount) + Leave($leaveCount) + Absent($absentCount) = $categorySum, but Total = $totalEmployees');
    }

    if (lateComersCount > totalEmployees) {
      errors.add('Late comers ($lateComersCount) cannot exceed total employees ($totalEmployees)');
    }

    if (shortLeaveCount > totalEmployees) {
      errors.add('Short leave ($shortLeaveCount) cannot exceed total employees ($totalEmployees)');
    }

    return errors;
  }

  // Add toString for debugging
  @override
  String toString() {
    return '''
DashboardSummary {
  month: $month,
  totalEmployees: $totalEmployees,
  presentCount: $presentCount (${presentPercentage.toStringAsFixed(1)}%),
  leaveCount: $leaveCount (${leavePercentage.toStringAsFixed(1)}%),
  absentCount: $absentCount (${absentPercentage.toStringAsFixed(1)}%),
  shortLeaveCount: $shortLeaveCount (${shortLeavePercentage.toStringAsFixed(1)}%),
  lateComersCount: $lateComersCount (${lateComersPercentage.toStringAsFixed(1)}%),
  Errors: ${validate()}
}''';
  }
}