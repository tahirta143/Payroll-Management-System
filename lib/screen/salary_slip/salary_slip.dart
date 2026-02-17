import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/salary_slip_provider/salary_slip_provider.dart';

class SalarySlipScreen extends StatefulWidget {
  const SalarySlipScreen({Key? key}) : super(key: key);

  @override
  State<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends State<SalarySlipScreen> {
  bool _showDebugPanel = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SalarySlipProvider>();
      await provider.initialize();

      // 🔴 FORCE LOAD EMPLOYEES FOR ADMIN
      if (provider.isAdmin) {
        await provider.loadEmployeesForAdmin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Consumer<SalarySlipProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 8),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Salary Slip',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                      const Spacer(),
                      // Print button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (provider.salarySlip != null) {
                              _printSalarySlip();
                            }
                          },
                          icon: Icon(
                            Icons.print,
                            color: const Color(0xFF667EEA),
                            size: isSmallScreen ? 20 : 22,
                          ),
                          tooltip: 'Print',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Refresh button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _refreshData(context),
                          icon: Icon(
                            Icons.refresh,
                            color: const Color(0xFF667EEA),
                            size: isSmallScreen ? 20 : 22,
                          ),
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                ),

                // Debug Panel (hidden by default)
                if (_showDebugPanel) _buildDebugPanel(provider, screenWidth, isSmallScreen),

                // Filters Section - Now in a row like attendance screen
                _buildFilters(provider, screenWidth, isSmallScreen),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Loading/Error/Salary Slip
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      isSmallScreen ? 12 : 16,
                      0,
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: isSmallScreen ? 8 : 15,
                          offset: Offset(0, isSmallScreen ? 4 : 6),
                        ),
                      ],
                    ),
                    child: _buildContent(provider, screenWidth, isSmallScreen),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebugPanel(SalarySlipProvider provider, double screenWidth, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isSmallScreen ? 6 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Debug Panel',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Is Admin: ${provider.isAdmin}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Current Employee ID: ${provider.currentEmployeeId}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Selected Employee ID: ${provider.selectedEmployeeId}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Total Employees: ${provider.employees.length}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_role', 'admin');
                  await prefs.setInt('employee_id_int', 29);
                  await provider.initialize();
                  if (provider.isAdmin) {
                    await provider.loadEmployeesForAdmin();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                ),
                child: Text('Set as Admin', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_role', 'employee');
                  await prefs.setInt('employee_id_int', 29);
                  await provider.initialize();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                ),
                child: Text('Set as Employee', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              ElevatedButton(
                onPressed: () => provider.debugPrintState(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  backgroundColor: Colors.grey,
                ),
                child: Text('Log State', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ FILTERS SECTION - UPDATED TO ROW LAYOUT ============
  Widget _buildFilters(SalarySlipProvider provider, double screenWidth, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isSmallScreen ? 8 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter Row - Month and Employee in a row like attendance screen
          Row(
            children: [
              // Month Filter
              Expanded(
                child: _buildMonthFilter(provider, isSmallScreen),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),

              // Employee Filter (Admin only)
              if (provider.isAdmin)
                Expanded(
                  child: _buildEmployeeFilter(provider, isSmallScreen),
                ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Fetch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () => provider.fetchSalarySlip(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)
                ),
                backgroundColor: const Color(0xFF667EEA),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search,
                      size: isSmallScreen ? 18 : 20,
                      color: Colors.white
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Text(
                    'Get Salary Slip',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Month Filter Dropdown
  Widget _buildMonthFilter(SalarySlipProvider provider, bool isSmallScreen) {
    // Generate list of months (last 12 months)
    final List<Map<String, String>> months = [];
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthValue = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthDisplay = _formatMonth(monthValue);
      months.add({'value': monthValue, 'display': monthDisplay});
    }

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedMonth.isNotEmpty ? provider.selectedMonth : null,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: const Color(0xFF667EEA),
            ),
          ),
          elevation: 2,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Select Month',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey,
              ),
            ),
          ),
          onChanged: (String? value) {
            if (value != null) {
              provider.setSelectedMonth(value);
            }
          },
          items: [
            ...months.map((month) {
              return DropdownMenuItem<String>(
                value: month['value'],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    month['display']!,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Employee Filter Dropdown (for Admin) - Sorted Alphabetically
  Widget _buildEmployeeFilter(SalarySlipProvider provider, bool isSmallScreen) {
    if (provider.isLoadingEmployees) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Sort employees alphabetically by name
    final sortedEmployees = List.from(provider.employees)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.employees.isEmpty
              ? Colors.grey[300]!
              : const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: provider.selectedEmployeeId,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: provider.employees.isEmpty
                  ? Colors.grey[400]
                  : const Color(0xFF667EEA),
            ),
          ),
          elevation: 2,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              provider.employees.isEmpty ? 'No Employees' : 'Select Employee',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: provider.employees.isEmpty ? Colors.grey[500] : Colors.grey,
              ),
            ),
          ),
          onChanged: provider.employees.isEmpty
              ? null
              : (int? value) {
            if (value != null) {
              provider.setSelectedEmployee(value);
            }
          },
          items: provider.employees.isEmpty
              ? []
              : [
            ...sortedEmployees.map((employee) {
              return DropdownMenuItem<int?>(
                value: employee.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: employee.id == provider.currentEmployeeId
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: employee.id == provider.currentEmployeeId
                                ? const Color(0xFF667EEA)
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (employee.id == provider.currentEmployeeId)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Iconsax.tick_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ============ CONTENT SECTION ============
  Widget _buildContent(SalarySlipProvider provider, double screenWidth, bool isSmallScreen) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
            SizedBox(height: 16),
            Text(
              'Fetching salary slip...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Colors.orange[700],
                size: isSmallScreen ? 48 : 64
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              provider.error!,
              style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.red
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => provider.fetchSalarySlip(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Try Again',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16)
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                OutlinedButton(
                  onPressed: () => provider.clearSalarySlip(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF667EEA)),
                  ),
                  child: Text('Clear',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16)
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (provider.salarySlip == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: isSmallScreen ? 48 : 64,
                color: Colors.grey[400]
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Select filters and fetch salary slip',
              style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            if (provider.selectedMonth.isNotEmpty)
              Text(
                'Month: ${_formatMonth(provider.selectedMonth)}',
                style: TextStyle(
                  color: const Color(0xFF667EEA),
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            if (provider.isAdmin && provider.selectedEmployeeId != null)
              Text(
                'Employee ID: ${provider.selectedEmployeeId}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
          ],
        ),
      );
    }

    return _buildSalarySlipDetails(provider.salarySlip!, screenWidth, isSmallScreen);
  }

  // ============ UTILITY METHODS ============
  Future<void> _refreshData(BuildContext context) async {
    final provider = context.read<SalarySlipProvider>();

    if (provider.isAdmin) {
      await provider.loadEmployeesForAdmin();
    }

    if (provider.selectedEmployeeId != null || !provider.isAdmin) {
      await provider.fetchSalarySlip();
    }
  }

  String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final monthNumber = int.parse(parts[1]);
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${monthNames[monthNumber - 1]} $year';
      }
    } catch (e) {
      return month;
    }
    return month;
  }

  void _printSalarySlip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Salary Slip'),
        content: const Text('Salary slip printing functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============ SALARY SLIP DETAILS WIDGET ============
  Widget _buildSalarySlipDetails(salarySlip, double screenWidth, bool isSmallScreen) {
    final useVerticalLayout = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: isSmallScreen ? 6 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'SALARY SLIP',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Period: ${salarySlip.range.from} to ${salarySlip.range.to}',
                  style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white70
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  'Month: ${_formatMonth(salarySlip.month)}',
                  style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white70
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Employee Details Card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: isSmallScreen ? 6 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Details',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF667EEA),
                  ),
                ),
                const Divider(color: Colors.grey),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildDetailRow('Employee ID', salarySlip.employee.empId, isSmallScreen),
                _buildDetailRow('Name', salarySlip.employee.name, isSmallScreen),
                _buildDetailRow('Department', salarySlip.employee.departmentName, isSmallScreen),
                _buildDetailRow('Designation', salarySlip.employee.designationName, isSmallScreen),
                _buildDetailRow('Shift', salarySlip.employee.dutyShiftName, isSmallScreen),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Earnings and Deductions Cards
          if (useVerticalLayout) ...[
            // Vertical layout for small screens
            Column(
              children: [
                // Earnings Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: isSmallScreen ? 6 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildAmountRow('Basic Salary', salarySlip.salaryStructure.basicSalary, isSmallScreen),
                      _buildAmountRow('House Allowance', salarySlip.salaryStructure.houseAllowance, isSmallScreen),
                      _buildAmountRow('Medical Allowance', salarySlip.salaryStructure.medicalAllowance, isSmallScreen),
                      _buildAmountRow('Conveyance', salarySlip.salaryStructure.conveyanceAllowance, isSmallScreen),
                      _buildAmountRow('Utility', salarySlip.salaryStructure.utilityAllowance, isSmallScreen),
                      _buildAmountRow('Mobile', salarySlip.salaryStructure.mobileAllowance, isSmallScreen),
                      _buildAmountRow('Miscellaneous', salarySlip.salaryStructure.miscellaneousAllowance, isSmallScreen),
                      const Divider(color: Colors.grey, thickness: 2),
                      _buildAmountRow('Gross Salary', salarySlip.salaryStructure.grossSalary, isSmallScreen, isTotal: true),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Attendance Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: isSmallScreen ? 6 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildSummaryRow('Present Days', salarySlip.attendanceSummary.presentDays.toString(), isSmallScreen),
                      _buildSummaryRow('Leave Days', salarySlip.attendanceSummary.leaveDays.toString(), isSmallScreen),
                      _buildSummaryRow('Holidays', salarySlip.attendanceSummary.holidayDays.toString(), isSmallScreen),
                      _buildSummaryRow('Absent Days', salarySlip.attendanceSummary.absentDays.toString(), isSmallScreen),
                      _buildSummaryRow('Late Days', salarySlip.attendanceSummary.lateDays.toString(), isSmallScreen),
                      _buildSummaryRow('Half Days', salarySlip.attendanceSummary.halfDayCount.toString(), isSmallScreen),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Deductions Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: isSmallScreen ? 6 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deductions',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildAmountRow('Income Tax', salarySlip.salaryStructure.incomeTax, isSmallScreen),
                      _buildAmountRow('Half Day Deduction', salarySlip.payrollCalculation.halfDayDeductionTotal, isSmallScreen),
                      _buildAmountRow('Full Day Deduction', salarySlip.payrollCalculation.fullDayDeductionTotal, isSmallScreen),
                      _buildAmountRow('Overtime', salarySlip.payrollCalculation.overtimeAmountTotal, isSmallScreen),
                      const Divider(color: Colors.grey, thickness: 2),
                      _buildAmountRow(
                        'Total Deductions',
                        salarySlip.salaryStructure.incomeTax +
                            salarySlip.payrollCalculation.halfDayDeductionTotal +
                            salarySlip.payrollCalculation.fullDayDeductionTotal,
                        isSmallScreen,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Horizontal layout for larger screens
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: isSmallScreen ? 6 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earnings',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF667EEA),
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        _buildAmountRow('Basic Salary', salarySlip.salaryStructure.basicSalary, isSmallScreen),
                        _buildAmountRow('House Allowance', salarySlip.salaryStructure.houseAllowance, isSmallScreen),
                        _buildAmountRow('Medical Allowance', salarySlip.salaryStructure.medicalAllowance, isSmallScreen),
                        _buildAmountRow('Conveyance', salarySlip.salaryStructure.conveyanceAllowance, isSmallScreen),
                        _buildAmountRow('Utility', salarySlip.salaryStructure.utilityAllowance, isSmallScreen),
                        _buildAmountRow('Mobile', salarySlip.salaryStructure.mobileAllowance, isSmallScreen),
                        _buildAmountRow('Miscellaneous', salarySlip.salaryStructure.miscellaneousAllowance, isSmallScreen),
                        const Divider(color: Colors.grey, thickness: 2),
                        _buildAmountRow('Gross Salary', salarySlip.salaryStructure.grossSalary, isSmallScreen, isTotal: true),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: isSmallScreen ? 6 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                            const Divider(color: Colors.grey),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            _buildSummaryRow('Present Days', salarySlip.attendanceSummary.presentDays.toString(), isSmallScreen),
                            _buildSummaryRow('Leave Days', salarySlip.attendanceSummary.leaveDays.toString(), isSmallScreen),
                            _buildSummaryRow('Holidays', salarySlip.attendanceSummary.holidayDays.toString(), isSmallScreen),
                            _buildSummaryRow('Absent Days', salarySlip.attendanceSummary.absentDays.toString(), isSmallScreen),
                            _buildSummaryRow('Late Days', salarySlip.attendanceSummary.lateDays.toString(), isSmallScreen),
                            _buildSummaryRow('Half Days', salarySlip.attendanceSummary.halfDayCount.toString(), isSmallScreen),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: isSmallScreen ? 6 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deductions',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                            const Divider(color: Colors.grey),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            _buildAmountRow('Income Tax', salarySlip.salaryStructure.incomeTax, isSmallScreen),
                            _buildAmountRow('Half Day Deduction', salarySlip.payrollCalculation.halfDayDeductionTotal, isSmallScreen),
                            _buildAmountRow('Full Day Deduction', salarySlip.payrollCalculation.fullDayDeductionTotal, isSmallScreen),
                            _buildAmountRow('Overtime', salarySlip.payrollCalculation.overtimeAmountTotal, isSmallScreen),
                            const Divider(color: Colors.grey, thickness: 2),
                            _buildAmountRow(
                              'Total Deductions',
                              salarySlip.salaryStructure.incomeTax +
                                  salarySlip.payrollCalculation.halfDayDeductionTotal +
                                  salarySlip.payrollCalculation.fullDayDeductionTotal,
                              isSmallScreen,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Net Payable Card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: isSmallScreen ? 6 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Payable Amount',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        'After all deductions and additions',
                        style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.white70
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  'PKR ${salarySlip.payrollCalculation.netPayable.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, bool isSmallScreen, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isSmallScreen ? (isTotal ? 14 : 13) : (isTotal ? 16 : 14),
                color: isTotal ? Colors.black87 : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'PKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isSmallScreen ? (isTotal ? 14 : 13) : (isTotal ? 16 : 14),
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }
}