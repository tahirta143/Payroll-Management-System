// In attendance_bar_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../model/employee_chart_data/employee_chart_data.dart';
// import '../../models/attendance_chart_model.dart';

class AttendanceBarChartWidget extends StatelessWidget {
  final AttendanceChartModel chartData;
  final bool isTablet;

  const AttendanceBarChartWidget({
    Key? key,
    required this.chartData,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎨 Rendering AttendanceBarChartWidget');
    print('🎨 Employee: ${chartData.employeeName}');
    print('🎨 Present: ${chartData.totalPresent}');
    print('🎨 Absent: ${chartData.totalAbsent}');
    print('🎨 Late: ${chartData.totalLate}');

    // Check if all values are zero
    bool allZeros = chartData.totalPresent == 0 &&
        chartData.totalAbsent == 0 &&
        chartData.totalLate == 0;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Attendance Overview',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chartData.employeeName} - ${_formatMonth(chartData.month)}',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total Days: ${chartData.totalDays}',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Chart or Empty State
          if (allZeros)
            Container(
              height: isTablet ? 250 : 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.chart_2,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Attendance Records',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance data found for ${_formatMonth(chartData.month)}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Present: ${chartData.totalPresent} | Absent: ${chartData.totalAbsent} | Late: ${chartData.totalLate}',
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: isTablet ? 250 : 200,
              child: _buildBarChart(),
            ),

          SizedBox(height: isTablet ? 20 : 16),

          // Summary Cards (always show)
          _buildSummaryCards(),

          SizedBox(height: isTablet ? 16 : 12),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  String _formatMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      if (parts.length == 2) {
        final month = int.parse(parts[0]);
        final year = parts[1];
        final date = DateTime(int.parse(year), month);
        return DateFormat('MMMM yyyy').format(date);
      }
      return monthStr;
    } catch (e) {
      return monthStr;
    }
  }

  Widget _buildBarChart() {
    // Use all data
    final displayData = chartData.data.length > 15
        ? chartData.data.sublist(chartData.data.length - 15)
        : chartData.data;

    // Find max value for Y axis (at least 1)
    double maxY = _getMaxY();
    if (maxY < 1) maxY = 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayIndex = group.x ~/ 3;
              if (dayIndex >= displayData.length) return null;

              final day = displayData[dayIndex];
              final barType = group.x % 3;

              String status = '';
              Color color = Colors.grey;
              double value = 0;

              if (barType == 0) {
                status = 'Present';
                color = Colors.green;
                value = (day.present ?? 0).toDouble();
              } else if (barType == 1) {
                status = 'Absent';
                color = Colors.red;
                value = (day.absent ?? 0).toDouble();
              } else {
                status = 'Late';
                color = Colors.orange;
                value = (day.late ?? 0).toDouble();
              }

              return BarTooltipItem(
                '${DateFormat('dd MMM').format(day.date!)}\n$status: ${value.toInt()}',
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt() ~/ 3;
                if (index >= 0 && index < displayData.length) {
                  if (value.toInt() % 3 == 0) {
                    final day = displayData[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd').format(day.date!),
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getYInterval(maxY),
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getYInterval(maxY),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFFE5E7EB),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(displayData.length * 3, (index) {
          final dayIndex = index ~/ 3;
          final barIndex = index % 3;
          final day = displayData[dayIndex];

          double value = 0;
          Color color = Colors.grey;

          switch (barIndex) {
            case 0: // Present
              value = (day.present ?? 0).toDouble();
              color = Colors.green;
              break;
            case 1: // Absent
              value = (day.absent ?? 0).toDouble();
              color = Colors.red;
              break;
            case 2: // Late
              value = (day.late ?? 0).toDouble();
              color = Colors.orange;
              break;
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                width: isTablet ? 8 : 6,
                borderRadius: BorderRadius.circular(2),
                color: value > 0 ? color : Colors.grey.withOpacity(0.2),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            color: Colors.green,
            label: 'Present',
            count: chartData.totalPresent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            color: Colors.red,
            label: 'Absent',
            count: chartData.totalAbsent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            color: Colors.orange,
            label: 'Late',
            count: chartData.totalLate,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required Color color,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'days',
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.green, 'Present'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.red, 'Absent'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.orange, 'Late'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 11,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  double _getMaxY() {
    double max = 1.0;
    for (var day in chartData.data) {
      max = max > (day.present ?? 0) ? max : (day.present ?? 0).toDouble();
      max = max > (day.absent ?? 0) ? max : (day.absent ?? 0).toDouble();
      max = max > (day.late ?? 0) ? max : (day.late ?? 0).toDouble();
    }
    return max;
  }

  double _getYInterval(double maxY) {
    if (maxY <= 1) return 1;
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    return (maxY / 4).ceilToDouble();
  }
}