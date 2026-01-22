// chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../model/chart_model/chart_model.dart';

class ChartWidget extends StatelessWidget {
  final DashboardChartResponse? chartData;
  final String chartTitle;
  final bool showLegend;
  final bool showGridLines;
  final Color presentColor;
  final Color absentColor;
  final Color lateColor;
  final double chartHeight;

  const ChartWidget({
    super.key,
    required this.chartData,
    this.chartTitle = 'Attendance Chart',
    this.showLegend = true,
    this.showGridLines = true,
    this.presentColor = Colors.green,
    this.absentColor = Colors.red,
    this.lateColor = Colors.orange,
    this.chartHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData == null || chartData!.data.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              chartTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Statistics Summary
            _buildSummaryStats(),
            const SizedBox(height: 16),

            // Chart
            SizedBox(
              height: chartHeight,
              child: chartData!.isDaily
                  ? _buildDailyChart()
                  : _buildMonthlyChart(),
            ),

            // Legend
            if (showLegend) _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        title: AxisTitle(text: 'Days'),
        labelRotation: -45,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Count'),
        minimum: 0,
      ),
      series: <CartesianSeries>[
        StackedColumnSeries<ChartData, String>(
          dataSource: chartData!.data,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.present,
          name: 'Present',
          color: presentColor,
        ),
        StackedColumnSeries<ChartData, String>(
          dataSource: chartData!.data,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.absent,
          name: 'Absent',
          color: absentColor,
        ),
        StackedColumnSeries<ChartData, String>(
          dataSource: chartData!.data,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.late,
          name: 'Late',
          color: lateColor,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget _buildMonthlyChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        title: AxisTitle(text: 'Months'),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Count'),
        minimum: 0,
      ),
      series: <CartesianSeries>[
        ColumnSeries<ChartData, String>(
          dataSource: chartData!.data,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.present,
          name: 'Present',
          color: presentColor,
        ),
        ColumnSeries<ChartData, String>(
          dataSource: chartData!.data,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.absent,
          name: 'Absent',
          color: absentColor,
        ),
        ColumnSeries<ChartData, String>(
          dataSource: chartData!.data,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.late,
          name: 'Late',
          color: lateColor,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget _buildSummaryStats() {
    final totalPresent = chartData!.totalPresent;
    final totalAbsent = chartData!.totalAbsent;
    final totalLate = chartData!.totalLate;
    final totalAll = totalPresent + totalAbsent + totalLate;
    final percentage = totalAll > 0
        ? ((totalPresent / totalAll) * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('Total', '$totalAll', Colors.blue),
        _statItem('Present', '$totalPresent', presentColor),
        _statItem('Absent', '$totalAbsent', absentColor),
        _statItem('Late', '$totalLate', lateColor),
        _statItem('Percentage', '$percentage%', Colors.green),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Present', presentColor),
          const SizedBox(width: 20),
          _legendItem('Absent', absentColor),
          const SizedBox(width: 20),
          _legendItem('Late', lateColor),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Container(
        height: chartHeight,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No attendance data available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Select a month or view all time data',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}