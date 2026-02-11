import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import '../../model/employee_monthly_report/employee_monthly_report.dart';
import '../../model/monthly_attandance_sheet/monthly_attandance_sheet.dart';
// import '../../provider/employee_report_provider.dart';
import '../../provider/monthly_attandance_sheet_provider/monthly_att_provider.dart'; // CORRECT IMPORT

class EmployeeReportScreen extends StatefulWidget {
  final String? token;
  const EmployeeReportScreen({Key? key, this.token}) : super(key: key);

  @override
  State<EmployeeReportScreen> createState() => _EmployeeReportScreenState();
}

class _EmployeeReportScreenState extends State<EmployeeReportScreen> {
  int? _selectedDepartmentId;
  int? _selectedEmployeeId;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<EmployeeReportProvider>(context, listen: false);

    // Set token first
    provider.setToken(widget.token);

    // Then fetch departments and employees
    await provider.fetchDepartmentsAndEmployees();

    print('Departments: ${provider.departments.length}');
    print('Employees: ${provider.employees.length}');
  }

  void _fetchReport() {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = Provider.of<EmployeeReportProvider>(context, listen: false);
    provider.fetchEmployeeReport(
      employeeId: _selectedEmployeeId!,
      month: _selectedMonth,
    ); // token is already set in provider
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });

      // Refresh data for new month
      final provider = Provider.of<EmployeeReportProvider>(context, listen: false);
      await provider.fetchDepartmentsAndEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Monthly Report',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider = Provider.of<EmployeeReportProvider>(context, listen: false);
              await provider.fetchDepartmentsAndEmployees();
              if (_selectedEmployeeId != null) {
                provider.fetchEmployeeReport(
                  employeeId: _selectedEmployeeId!,
                  month: _selectedMonth,
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<EmployeeReportProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildFiltersSection(provider),
              const Divider(height: 1),
              Expanded(
                child: _buildReportContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(EmployeeReportProvider provider) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector
          InkWell(
            onTap: _selectMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF667EEA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Month',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM yyyy').format(
                              DateFormat('yyyy-MM').parse(_selectedMonth),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Department Dropdown
          if (provider.isDepartmentsLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (provider.departments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.error ?? 'No departments available',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonFormField<int?>(
                value: _selectedDepartmentId,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business, color: Color(0xFF667EEA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...provider.departments.map((dept) {
                    return DropdownMenuItem<int?>(
                      value: dept.id,
                      child: Text(dept.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartmentId = value;
                    _selectedEmployeeId = null;
                  });
                  provider.filterEmployeesByDepartment(value);
                },
              ),
            ),
          const SizedBox(height: 16),

          // Employee Dropdown
          if (provider.isEmployeesLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (provider.employees.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDepartmentId == null
                          ? 'No employees available'
                          : 'No employees in this department',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonFormField<int?>(
                value: _selectedEmployeeId,
                decoration: const InputDecoration(
                  labelText: 'Employee',
                  prefixIcon: Icon(Icons.person, color: Color(0xFF667EEA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: provider.employees.map((emp) {
                  return DropdownMenuItem<int?>(
                    value: emp.id,
                    child: Text('${emp.name} (${emp.empId})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEmployeeId = value;
                  });
                },
                hint: const Text(
                  'Select Employee',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Fetch Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (provider.isLoading ||
                  _selectedEmployeeId == null ||
                  provider.employees.isEmpty)
                  ? null
                  : _fetchReport,
              icon: provider.isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.search),
              label: Text(
                provider.isLoading ? 'Loading Report...' : 'Generate Report',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(EmployeeReportProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF667EEA)),
            SizedBox(height: 16),
            Text(
              'Loading report...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.error != null && provider.report == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearError();
                _loadInitialData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.report == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 64,
                color: Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Report Generated',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _selectedEmployeeId == null
                    ? 'Please select an employee and click "Generate Report"'
                    : 'No attendance data found for the selected employee',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEmployeeInfo(provider.report!),
          _buildStatisticsCards(provider.report!),
          _buildSalarySummary(provider.report!),
          _buildAttendanceTable(provider.report!),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  // ... rest of your existing methods (_buildEmployeeInfo, _buildStatisticsCards,
  // _buildSalarySummary, _buildAttendanceTable, _buildInfoChip, _buildStatCard,
  // _buildSummaryRow, _buildLegendItem, _getDayColor, _formatNumber) remain exactly the same

  Widget _buildEmployeeInfo(EmployeeMonthlyReport report) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF5A67D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.employee.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${report.employee.empId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white30, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                icon: Icons.business,
                label: 'Department',
                value: report.employee.departmentName,
              ),
              _buildInfoChip(
                icon: Icons.access_time,
                label: 'Shift',
                value: '${report.employee.shiftStart.substring(0, 5)} - ${report.employee.shiftEnd.substring(0, 5)}',
              ),
              _buildInfoChip(
                icon: Icons.calendar_today,
                label: 'Month',
                value: DateFormat('MMM yyyy').format(DateTime.parse('${report.month}-01')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(EmployeeMonthlyReport report) {
    final stats = report.statistics;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: [
          _buildStatCard(
            title: 'Present',
            value: '${stats.presentCount}',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatCard(
            title: 'Late',
            value: '${stats.lateCount}',
            icon: Icons.warning,
            color: Colors.orange,
          ),
          _buildStatCard(
            title: 'Absent',
            value: '${stats.absentCount}',
            icon: Icons.cancel,
            color: Colors.red,
          ),
          _buildStatCard(
            title: 'Half Day',
            value: '${stats.halfDayCount}',
            icon: Icons.access_time,
            color: Colors.purple,
          ),
          _buildStatCard(
            title: 'Holiday',
            value: '${stats.holidayCount}',
            icon: Icons.celebration,
            color: Colors.blue,
          ),
          _buildStatCard(
            title: 'Working',
            value: '${stats.totalWorkingDays}',
            icon: Icons.work,
            color: Colors.teal,
          ),
          _buildStatCard(
            title: 'Attendance',
            value: '${stats.attendancePercentage}%',
            icon: Icons.percent,
            color: const Color(0xFF667EEA),
          ),
          _buildStatCard(
            title: 'Total Days',
            value: '${stats.totalRecords}',
            icon: Icons.calendar_month,
            color: Colors.brown,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySummary(EmployeeMonthlyReport report) {
    final summary = report.salarySummary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.currency_rupee,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Salary Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Base Salary', 'Rs. ${_formatNumber(summary.baseNetSalary)}'),
          _buildSummaryRow('Half Days', '${summary.halfDayCount} days',
              value2: '- Rs. ${_formatNumber(summary.halfDayDeductionTotal)}', isNegative: true),
          _buildSummaryRow('Full Absents', '${summary.fullAbsentCount} days',
              value2: '- Rs. ${_formatNumber(summary.fullDayDeductionTotal)}', isNegative: true),
          if (summary.overtimeAmountTotal > 0)
            _buildSummaryRow('Overtime', 'Rs. ${_formatNumber(summary.overtimeAmountTotal)}'),
          if (summary.advanceAmountTotal > 0)
            _buildSummaryRow('Advance', '- Rs. ${_formatNumber(summary.advanceAmountTotal)}', isNegative: true),
          const Divider(height: 30, thickness: 1),
          _buildSummaryRow(
            'Net Payable',
            'Rs. ${_formatNumber(summary.netPayable)}',
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {
    String? value2,
    bool isNegative = false,
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
          Row(
            children: [
              if (value2 != null) ...[
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isBold ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value2,
                  style: TextStyle(
                    fontSize: isBold ? 16 : 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                ),
              ] else
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isBold ? 16 : 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: isNegative ? Colors.red : (isTotal ? Colors.green : Colors.black87),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(EmployeeMonthlyReport report) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEDF2F7)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_chart,
                    color: Color(0xFF667EEA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Daily Attendance Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${report.days.length} Days',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 20,
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              headingRowHeight: 48,
              dataRowHeight: 56,
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Time In', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Time Out', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Late', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Early', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Overtime', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: report.days.map((day) {
                return DataRow(
                  cells: [
                    DataCell(Text(day.getFormattedDate())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDayColor(day.weekday).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          day.weekday.substring(0, 3),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getDayColor(day.weekday),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(day.getFormattedTimeIn())),
                    DataCell(Text(day.getFormattedTimeOut())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          day.getFormattedDuration(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        day.getFormattedLate(),
                        style: TextStyle(
                          color: day.lateMinutes > 0 ? Colors.orange[800] : Colors.grey,
                          fontWeight: day.lateMinutes > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        day.getFormattedEarly(),
                        style: TextStyle(
                          color: day.earlyMinutes > 0 ? Colors.blue[800] : Colors.grey,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        day.getFormattedOvertime(),
                        style: TextStyle(
                          color: day.overtimeMinutes > 0 ? Colors.green[800] : Colors.grey,
                          fontWeight: day.overtimeMinutes > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: day.getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: day.getStatusColor().withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              day.getStatusIcon(),
                              size: 12,
                              color: day.getStatusColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              day.getStatusDisplay(),
                              style: TextStyle(
                                color: day.getStatusColor(),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Present', Colors.green),
                _buildLegendItem('Late', Colors.orange),
                _buildLegendItem('Absent', Colors.red),
                _buildLegendItem('Half Day', Colors.purple),
                _buildLegendItem('Holiday', Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getDayColor(String weekday) {
    switch (weekday.toLowerCase()) {
      case 'sunday':
      case 'saturday':
        return Colors.red;
      case 'friday':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatNumber(int number) {
    return NumberFormat('#,##0').format(number);
  }
}