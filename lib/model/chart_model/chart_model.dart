// attendance_model.dart
import 'dart:convert';

class ChartData {
  final String label;
  final DateTime? date;
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
    DateTime? parsedDate;

    try {
      // Try to parse date from label (for daily data)
      if (json['label'] != null) {
        parsedDate = DateTime.tryParse(json['label'].toString());
      }
      // Try to parse date from date field (for monthly data)
      if (parsedDate == null && json['date'] != null) {
        parsedDate = DateTime.tryParse(json['date'].toString());
      }
    } catch (e) {
      print('⚠️ Date parsing error: $e');
      parsedDate = null;
    }

    return ChartData(
      label: json['label']?.toString() ?? json['date']?.toString() ?? 'N/A',
      date: parsedDate,
      present: _safeParseInt(json['present']),
      absent: _safeParseInt(json['absent']),
      late: _safeParseInt(json['late']),
    );
  }

  // Helper method to safely parse integers from dynamic values
  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  // Helper method to convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _convertDynamicMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map;
    }

    if (map is Map<dynamic, dynamic>) {
      final convertedMap = <String, dynamic>{};
      map.forEach((key, value) {
        if (key is String) {
          convertedMap[key] = value;
        } else if (key != null) {
          convertedMap[key.toString()] = value;
        }
      });
      return convertedMap;
    }

    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'date': date?.toIso8601String(),
      'present': present,
      'absent': absent,
      'late': late,
    };
  }

  // Total attendance count
  int get total => present + absent + late;

  // Attendance percentage
  double get attendancePercentage {
    return total > 0 ? (present / total * 100) : 0;
  }

  // Late percentage
  double get latePercentage {
    return total > 0 ? (late / total * 100) : 0;
  }

  // Absent percentage
  double get absentPercentage {
    return total > 0 ? (absent / total * 100) : 0;
  }

  // Get formatted label based on granularity
  String getFormattedLabel(String granularity) {
    if (date == null) return label;

    if (granularity == 'day') {
      return '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    } else if (granularity == 'month') {
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${monthNames[date!.month - 1]} ${date!.year}';
    }

    return label;
  }

  @override
  String toString() {
    return 'ChartData{label: $label, present: $present, absent: $absent, late: $late}';
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
    final List<ChartData> chartDataList = [];

    // Safely parse the data list
    final dataList = json['data'];
    if (dataList is List) {
      for (var item in dataList) {
        try {
          // Convert item to Map<String, dynamic>
          final Map<String, dynamic> itemMap;

          if (item is Map<String, dynamic>) {
            itemMap = item;
          } else if (item is Map<dynamic, dynamic>) {
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            itemMap = {};
            item.forEach((key, value) {
              if (key is String) {
                itemMap[key] = value;
              } else if (key != null) {
                itemMap[key.toString()] = value;
              }
            });
          } else {
            // Skip if it's not a map
            continue;
          }

          chartDataList.add(ChartData.fromJson(itemMap));
        } catch (e) {
          print('⚠️ Error parsing chart data item: $e');
          print('⚠️ Item: $item');
        }
      }
    }

    return DashboardChartResponse(
      granularity: json['granularity']?.toString() ?? 'day',
      data: chartDataList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'granularity': granularity,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }

  // Get total statistics
  int get totalPresent => data.fold(0, (sum, item) => sum + item.present);
  int get totalAbsent => data.fold(0, (sum, item) => sum + item.absent);
  int get totalLate => data.fold(0, (sum, item) => sum + item.late);
  int get totalAll => totalPresent + totalAbsent + totalLate;

  // Check if it's daily or monthly data
  bool get isDaily => granularity.toLowerCase() == 'day';
  bool get isMonthly => granularity.toLowerCase() == 'month';

  // Get overall percentages
  double get overallAttendancePercentage {
    return totalAll > 0 ? (totalPresent / totalAll * 100) : 0;
  }

  double get overallLatePercentage {
    return totalAll > 0 ? (totalLate / totalAll * 100) : 0;
  }

  double get overallAbsentPercentage {
    return totalAll > 0 ? (totalAbsent / totalAll * 100) : 0;
  }

  // Get sorted data (by date)
  List<ChartData> get sortedData {
    final sorted = List<ChartData>.from(data);
    sorted.sort((a, b) {
      if (a.date == null || b.date == null) return 0;
      return a.date!.compareTo(b.date!);
    });
    return sorted;
  }

  // Get data for a specific month
  List<ChartData> getDataForMonth(DateTime month) {
    return data.where((item) {
      if (item.date == null) return false;
      return item.date!.year == month.year && item.date!.month == month.month;
    }).toList();
  }

  // Get data for a specific date
  ChartData? getDataForDate(DateTime date) {
    try {
      return data.firstWhere((item) {
        if (item.date == null) return false;
        return item.date!.year == date.year &&
            item.date!.month == date.month &&
            item.date!.day == date.day;
      });
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return 'DashboardChartResponse{granularity: $granularity, data: ${data.length} items}';
  }
}