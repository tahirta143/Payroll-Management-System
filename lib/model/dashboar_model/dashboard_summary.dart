// dashboard_summary.dart - UPDATED
import 'package:flutter/cupertino.dart';

class DashboardSummary {
  final int totalEmployees;
  final int presentCount;
  final int leaveCount;
  final int shortLeaveCount;
  final int absentCount;
  final int lateComersCount;
  final String selectedDate;

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
    required this.selectedDate,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json, {String? requestedDate}) {
    debugPrint('=== Parsing JSON in DashboardSummary.fromJson ===');
    debugPrint('JSON keys: ${json.keys.toList()}');
    debugPrint('Requested date: $requestedDate');

    // Parse date from JSON or use requested date
    String dateFromApi = json['date']?.toString() ?? '';

    // Handle different field name formats
    final totalEmployees = json['total_employees'] ?? json['totalEmployees'] ?? 0;
    final presentCount = json['present_count'] ?? json['presentCount'] ?? 0;
    final leaveCount = json['leave_count'] ?? json['leaveCount'] ?? 0;
    final shortLeaveCount = json['short_leave_count'] ?? json['shortLeaveCount'] ?? 0;
    final absentCount = json['absent_count'] ?? json['absentCount'] ?? 0;
    final lateComersCount = json['late_comers_count'] ?? json['lateComersCount'] ?? 0;

    // Determine what date to use
    String finalSelectedDate;
    if (requestedDate != null && requestedDate.isNotEmpty) {
      // Use the requested date from the dashboard
      finalSelectedDate = requestedDate;
    } else if (dateFromApi.isNotEmpty) {
      // Use date from API
      finalSelectedDate = dateFromApi;
    } else {
      // Default to 'all'
      finalSelectedDate = 'all';
    }

    debugPrint('Parsed values:');
    debugPrint('- date from API: $dateFromApi');
    debugPrint('- total_employees: $totalEmployees');
    debugPrint('- present_count: $presentCount');
    debugPrint('- leave_count: $leaveCount');
    debugPrint('- short_leave_count: $shortLeaveCount');
    debugPrint('- absent_count: $absentCount');
    debugPrint('- late_comers_count: $lateComersCount');
    debugPrint('- final selectedDate: $finalSelectedDate');

    // Log the data validation (but don't enforce it as an error)
    final sum = presentCount + leaveCount + absentCount;
    debugPrint('Data validation:');
    debugPrint('- present + leave + absent = $sum');
    debugPrint('- total_employees = $totalEmployees');
    debugPrint('- Difference: ${sum - totalEmployees}');

    // IMPORTANT: For a specific date, sum may not equal totalEmployees
    // because some employees might not be marked yet or have other statuses
    if (finalSelectedDate != 'all' && finalSelectedDate != 'All Time') {
      debugPrint('⚠️ Date-specific data: sum may not equal total employees');
      debugPrint('   Some employees may not have been marked yet');
    }

    return DashboardSummary(
      totalEmployees: totalEmployees is int ? totalEmployees : int.tryParse(totalEmployees.toString()) ?? 0,
      presentCount: presentCount is int ? presentCount : int.tryParse(presentCount.toString()) ?? 0,
      leaveCount: leaveCount is int ? leaveCount : int.tryParse(leaveCount.toString()) ?? 0,
      shortLeaveCount: shortLeaveCount is int ? shortLeaveCount : int.tryParse(shortLeaveCount.toString()) ?? 0,
      absentCount: absentCount is int ? absentCount : int.tryParse(absentCount.toString()) ?? 0,
      lateComersCount: lateComersCount is int ? lateComersCount : int.tryParse(lateComersCount.toString()) ?? 0,
      selectedDate: finalSelectedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': selectedDate,
    'total_employees': totalEmployees,
    'present_count': presentCount,
    'leave_count': leaveCount,
    'short_leave_count': shortLeaveCount,
    'absent_count': absentCount,
    'late_comers_count': lateComersCount,
  };

  // UPDATED validation method - less strict for date-specific data
  List<String> validate({bool isDateSpecific = false}) {
    final errors = <String>[];

    if (totalEmployees < 0) {
      errors.add('Total employees cannot be negative');
    }

    // For date-specific data, the sum may not equal totalEmployees
    // because some employees may not have been marked yet
    if (!isDateSpecific) {
      final categorySum = presentCount + leaveCount + absentCount;
      if (categorySum != totalEmployees) {
        errors.add('Data inconsistency: Present($presentCount) + Leave($leaveCount) + Absent($absentCount) = $categorySum, but Total = $totalEmployees');
      }
    }

    if (lateComersCount < 0) {
      errors.add('Late comers cannot be negative');
    }

    if (shortLeaveCount < 0) {
      errors.add('Short leave cannot be negative');
    }

    // Check if late comers exceed present count (only if both are positive)
    if (lateComersCount > 0 && presentCount > 0 && lateComersCount > presentCount) {
      errors.add('Late comers ($lateComersCount) cannot exceed present count ($presentCount)');
    }

    // Check if short leave exceeds present count (only if both are positive)
    if (shortLeaveCount > 0 && presentCount > 0 && shortLeaveCount > presentCount) {
      errors.add('Short leave ($shortLeaveCount) cannot exceed present count ($presentCount)');
    }

    return errors;
  }

  // Add a method to check if all counts are zero (no data yet)
  // In your DashboardSummary model, update the isNoDataForDate getter

  bool get isNoDataForDate {
    // Check if this is a date-specific summary
    final isDateSpecific = selectedDate != 'all' &&
        selectedDate != 'All Time';

    if (!isDateSpecific) return false;

    // For date-specific data with all zeros, this means attendance not marked yet
    // But we should show the total employees count
    return presentCount == 0 &&
        leaveCount == 0 &&
        absentCount == 0 &&
        shortLeaveCount == 0 &&
        lateComersCount == 0;
  }

// Also update the toString method to include better debugging
  @override
  String toString() {
    final isDateSpecific = selectedDate != 'all' && selectedDate != 'All Time';
    final noData = isNoDataForDate;

    return '''
DashboardSummary {
  selectedDate: $selectedDate (${isDateSpecific ? 'Date-specific' : 'All-time'})
  totalEmployees: $totalEmployees,
  presentCount: $presentCount (${presentPercentage.toStringAsFixed(1)}%),
  leaveCount: $leaveCount (${leavePercentage.toStringAsFixed(1)}%),
  absentCount: $absentCount (${absentPercentage.toStringAsFixed(1)}%),
  shortLeaveCount: $shortLeaveCount (${shortLeavePercentage.toStringAsFixed(1)}%),
  lateComersCount: $lateComersCount (${lateComersPercentage.toStringAsFixed(1)}%),
  No Data Yet (all zeros): $noData,
  Status: ${noData ? 'Attendance not marked yet' : 'Data available'}
}''';
  }
}