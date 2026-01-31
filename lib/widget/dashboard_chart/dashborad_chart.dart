// chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../../provider/chart_provider/chart_provider.dart';
import '../../model/chart_model/chart_model.dart';

class ChartWidget extends StatefulWidget {
  final bool showLegend;
  final DashboardChartResponse? chartData;
  final String chartTitle;
  final bool showGridLines;
  final Color presentColor;
  final Color absentColor;
  final Color lateColor;
  final double chartHeight;
  final bool showDateSelector;
  final bool showMonthSelector;
  final bool autoRefresh;
  final bool showDataLabels;
  final bool useGroupedBars;
  final double barWidth;

  const ChartWidget({
    super.key,
    this.showLegend = true,
    this.chartData,
    this.chartTitle = 'Attendance Chart',
    this.showGridLines = true,
    this.presentColor = Colors.green,
    this.absentColor = Colors.red,
    this.lateColor = Colors.orange,
    this.chartHeight = 300,
    this.showDateSelector = true,
    this.showMonthSelector = true,
    this.autoRefresh = true,
    this.showDataLabels = false,
    this.useGroupedBars = false,
    this.barWidth = 0.6,
  });

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  late ChartProvider _provider;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _provider = context.read<ChartProvider>();
      // Initialize if needed
      if (!_provider.hasData && !_provider.isLoading && widget.autoRefresh) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _refreshData();
          }
        });
      }
    }
  }

  Future<void> _refreshData() async {
    final provider = context.read<ChartProvider>();
    if (!provider.isLoading && !provider.hasData) {
      await provider.fetchAttendanceData();
    }
  }

  void _selectDate(BuildContext context) async {
    final provider = context.read<ChartProvider>();
    final initialDate = provider.selectedDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      provider.setSelectedDate(selectedDate);
      provider.setChartType('daily');
      await provider.fetchAttendanceData();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ChartProvider>(
      builder: (context, provider, child) {
        _provider = provider;

        return Card(
          elevation: 4,
          color: Colors.white,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and controls
                _buildHeader(provider),
                const SizedBox(height: 16),

                // Statistics Summary
                _buildSummaryStats(provider),
                const SizedBox(height: 16),

                // Loading indicator or chart
                if (provider.isLoading)
                  _buildLoadingIndicator()
                else if (provider.error != null)
                  _buildErrorWidget(provider.error!)
                else if (!provider.hasData)
                    _buildEmptyState()
                  else
                    _buildChart(provider),

                // Legend
                if (widget.showLegend && provider.hasData && !provider.isLoading)
                  _buildLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ChartProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.chartTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 0),
            ],
          ),
        ),

        // Controls
        Row(
          children: [
            // Chart Type Toggle
            // _buildChartTypeToggle(provider),
            const SizedBox(width: 8),

            // Date/Month Selector
            if (widget.showDateSelector && provider.chartType == 'daily')
              _buildDateSelector(),
            if (widget.showMonthSelector && provider.chartType == 'monthly')
              _buildMonthSelector(),

            // Refresh Button
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: provider.isLoading ? Colors.grey : Colors.blue,
              ),
              onPressed: provider.isLoading ? null : _refreshData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildDateSelector() {
    return IconButton(
      icon: const Icon(Icons.calendar_today, size: 20),
      onPressed: () => _selectDate(context),
      tooltip: 'Select Date',
    );
  }

  Widget _buildMonthSelector() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.calendar_month, size: 20),
      onSelected: (value) async {
        final date = DateTime.parse(value);
        _provider.setSelectedMonth(date);
        await _provider.fetchAttendanceData();
      },
      itemBuilder: (context) {
        return _provider.availableMonthsFormatted.map((month) {
          return PopupMenuItem<String>(
            value: month['value'],
            child: Text(month['label']!),
          );
        }).toList();
      },
      tooltip: 'Select Month',
    );
  }

  Widget _buildSummaryStats(ChartProvider provider) {
    final stats = provider.stats;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            label: 'Present',
            value: '${stats['present']}',
            icon: Icons.check_circle,
            color: widget.presentColor,
            percentage: stats['attendanceRate'],
          ),
          _verticalDivider(),
          _statItem(
            label: 'Absent',
            value: '${stats['absent']}',
            icon: Icons.cancel,
            color: widget.absentColor,
          ),
          _verticalDivider(),
          _statItem(
            label: 'Late',
            value: '${stats['late']}',
            icon: Icons.schedule,
            color: widget.lateColor,
            percentage: stats['lateRate'],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    double? percentage,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (percentage != null)
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildChart(ChartProvider provider) {
    final chartData = provider.chartVisualizationData;
    final isDaily = provider.chartType == 'daily';
    final labels = chartData['labels'] as List<String>;

    // Determine if we should show data labels
    final showLabels = widget.showDataLabels && labels.length <= 10;

    // Determine chart type based on data size
    final useLineChart = labels.length > 15;
    final useGroupedBars = widget.useGroupedBars && labels.length <= 7;

    return SizedBox(
      height: widget.chartHeight,
      child: SfCartesianChart(
        margin: const EdgeInsets.all(10),
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          labelRotation: isDaily ? -45 : 0,
          majorGridLines: widget.showGridLines
              ? const MajorGridLines(width: 1, color: Color(0xFFE0E0E0))
              : const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 1, color: Colors.grey),
          labelStyle: TextStyle(
            fontSize: isDaily ? 10 : 12,
            color: Colors.grey.shade700,
          ),
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          interval: useLineChart ? 20 : 10,
          majorGridLines: widget.showGridLines
              ? const MajorGridLines(width: 1, color: Color(0xFFF0F0F0))
              : const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 1, color: Colors.grey),
          labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        series: _buildChartSeries(chartData, isDaily, useLineChart, useGroupedBars, showLabels),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.series.name : point.y',
          header: 'point.x\n',
          canShowMarker: true,
        ),
        legend: widget.showLegend
            ? Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: const TextStyle(fontSize: 12),
        )
            : const Legend(isVisible: false), // Provide non-null Legend
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          enableMouseWheelZooming: true,
        ),
      ),
    );
  }

  List<CartesianSeries> _buildChartSeries(
      Map<String, dynamic> chartData,
      bool isDaily,
      bool useLineChart,
      bool useGroupedBars,
      bool showLabels) {
    final labels = chartData['labels'] as List<String>;
    final present = chartData['present'] as List<int>;
    final absent = chartData['absent'] as List<int>;
    final late = chartData['late'] as List<int>;

    final data = _prepareChartData(labels, present, absent, late);

    if (useLineChart) {
      // Use line chart for large datasets
      return [
        LineSeries<int, String>(
          dataSource: present,
          xValueMapper: (data, index) => index < labels.length ? labels[index] : '',
          yValueMapper: (data, index) => data,
          name: 'Present',
          color: widget.presentColor,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: 4,
            height: 4,
          ),
          width: 2,
        ),
        LineSeries<int, String>(
          dataSource: absent,
          xValueMapper: (data, index) => index < labels.length ? labels[index] : '',
          yValueMapper: (data, index) => data,
          name: 'Absent',
          color: widget.absentColor,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: 4,
            height: 4,
          ),
          width: 2,
        ),
        LineSeries<int, String>(
          dataSource: late,
          xValueMapper: (data, index) => index < labels.length ? labels[index] : '',
          yValueMapper: (data, index) => data,
          name: 'Late',
          color: widget.lateColor,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: 4,
            height: 4,
          ),
          width: 2,
        ),
      ];
    } else if (useGroupedBars) {
      // Use grouped bars (side by side)
      return [
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: data,
          xValueMapper: (data, _) => data['label'] as String,
          yValueMapper: (data, _) => data['present'] as int,
          name: 'Present',
          color: widget.presentColor,
          width: 0.15,
          spacing: 0.2,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: showLabels
              ? DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          )
              : const DataLabelSettings(isVisible: false), // Non-null default
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: data,
          xValueMapper: (data, _) => data['label'] as String,
          yValueMapper: (data, _) => data['absent'] as int,
          name: 'Absent',
          color: widget.absentColor,
          width: 0.15,
          spacing: 0.2,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: showLabels
              ? DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          )
              : const DataLabelSettings(isVisible: false),
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: data,
          xValueMapper: (data, _) => data['label'] as String,
          yValueMapper: (data, _) => data['late'] as int,
          name: 'Late',
          color: widget.lateColor,
          width: 0.15,
          spacing: 0.2,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: showLabels
              ? DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          )
              : const DataLabelSettings(isVisible: false),
        ),
      ];
    } else {
      // Use standard vertical bars
      return [
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: data,
          xValueMapper: (data, _) => data['label'] as String,
          yValueMapper: (data, _) => data['present'] as int,
          name: 'Present',
          color: widget.presentColor,
          width: widget.barWidth,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: showLabels
              ? DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          )
              : const DataLabelSettings(isVisible: false),
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: data,
          xValueMapper: (data, _) => data['label'] as String,
          yValueMapper: (data, _) => data['absent'] as int,
          name: 'Absent',
          color: widget.absentColor,
          width: widget.barWidth,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: showLabels
              ? DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          )
              : const DataLabelSettings(isVisible: false),
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: data,
          xValueMapper: (data, _) => data['label'] as String,
          yValueMapper: (data, _) => data['late'] as int,
          name: 'Late',
          color: widget.lateColor,
          width: widget.barWidth,
          borderRadius: BorderRadius.circular(4),
          dataLabelSettings: showLabels
              ? DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          )
              : const DataLabelSettings(isVisible: false),
        ),
      ];
    }
  }
  List<Map<String, dynamic>> _prepareChartData(
      List<String> labels, List<int> present, List<int> absent, List<int> late) {
    final List<Map<String, dynamic>> data = [];
    for (int i = 0; i < labels.length; i++) {
      data.add({
        'label': labels[i],
        'present': present[i],
        'absent': absent[i],
        'late': late[i],
      });
    }
    return data;
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _legendItem('Present', widget.presentColor),
          _legendItem('Absent', widget.absentColor),
          _legendItem('Late', widget.lateColor),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: widget.chartHeight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading attendance data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      height: widget.chartHeight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.chartHeight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Attendance Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _provider.chartType == 'daily'
                  ? 'No attendance records found for selected date'
                  : 'No attendance records found for selected month',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}