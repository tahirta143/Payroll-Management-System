import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/salary_slip_provider/salary_slip_provider.dart';

// Helper function to check if user is admin (can be used anywhere)
bool checkIfAdmin(String role) {
  if (role.isEmpty) return false;

  final lowerRole = role.toLowerCase();
  return lowerRole.contains('admin') ||
      lowerRole.contains('administrator') ||
      lowerRole.contains('superadmin') ||
      lowerRole.contains('super user');
}

class SalarySlipScreen extends StatefulWidget {
  const SalarySlipScreen({Key? key}) : super(key: key);

  @override
  State<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends State<SalarySlipScreen> {
  bool _isAdmin = false;
  int? _currentEmployeeId;
  String? _currentUserName;
  String? _userRole;
  bool _showDebugPanel = false;
  List<Map<String, dynamic>> _validEmployees = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserInfo();
    await _checkUserRoleDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SalarySlipProvider>().initialize();
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all relevant keys
    final userRole = prefs.getString('user_role') ?? 'employee';
    final employeeIdString = prefs.getString('employee_id') ?? '0';
    final userName = prefs.getString('user_name') ?? 'User';
    final employeeName = prefs.getString('employee_name') ?? 'User';
    final employeeCode = prefs.getString('employee_code') ?? '';

    // Parse employee ID safely
    int? employeeId;
    try {
      employeeId = int.tryParse(employeeIdString);
      if (employeeId == null && employeeIdString.isNotEmpty) {
        // Try to extract numbers from string
        final match = RegExp(r'\d+').firstMatch(employeeIdString);
        if (match != null) {
          employeeId = int.tryParse(match.group(0)!);
        }
      }
    } catch (e) {
      print('Error parsing employee ID: $e');
      employeeId = null;
    }

    // Check for admin - more flexible check
    final isAdmin = userRole.toLowerCase().contains('admin') ||
        userRole.toLowerCase().contains('administrator');

    setState(() {
      _userRole = userRole;
      _isAdmin = isAdmin;
      _currentEmployeeId = employeeId;
      _currentUserName = userName.isNotEmpty ? userName : employeeName;
    });
  }

  Future<void> _checkUserRoleDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    print('🔑 All SharedPreferences keys:');
    for (var key in allKeys) {
      if (key.contains('user') || key.contains('employee') || key.contains('role')) {
        print('   $key: ${prefs.getString(key)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final isLargeScreen = screenWidth >= 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Salary Slip',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF667EEA),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () {
                if (context.read<SalarySlipProvider>().salarySlip != null) {
                  _printSalarySlip();
                }
              },
              icon: Icon(Icons.print, color: Colors.white, size: isSmallScreen ? 22 : 24),
              tooltip: 'Print',
            ),
            IconButton(
              onPressed: () => context.read<SalarySlipProvider>().fetchSalarySlip(),
              icon: Icon(Icons.refresh, color: Colors.white, size: isSmallScreen ? 22 : 24),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
          ),
          child: Consumer<SalarySlipProvider>(
            builder: (context, provider, child) {
              // Filter and prepare valid employees
              _validEmployees = _getValidEmployees(provider.employees, provider.selectedEmployeeId);

              return Column(
                children: [
                  // Debug Panel
                  if (_showDebugPanel) _buildDebugPanel(provider, screenWidth),

                  // Filters Section
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
      ),
    );
  }

  // Helper to get valid employees and validate selected ID
  List<Map<String, dynamic>> _getValidEmployees(
      List<Map<String, dynamic>> employees,
      int? selectedEmployeeId
      ) {
    final validEmployees = employees.where((emp) {
      final hasId = emp.containsKey('id') && emp['id'] != null;
      final hasName = emp.containsKey('name') && emp['name'] != null;
      return hasId && hasName;
    }).toList();

    // If selectedEmployeeId is not in valid employees, reset it
    if (selectedEmployeeId != null &&
        !validEmployees.any((emp) => _getEmployeeId(emp) == selectedEmployeeId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SalarySlipProvider>().setSelectedEmployee(null);
      });
    }

    return validEmployees;
  }

  Widget _buildDebugPanel(SalarySlipProvider provider, double screenWidth) {
    final isSmallScreen = screenWidth < 600;

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
          Text('User Role: $_userRole', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Is Admin: $_isAdmin', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Employee ID: $_currentEmployeeId', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Valid Employees: ${_validEmployees.length}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          Text('Selected ID: ${provider.selectedEmployeeId}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  // Set as admin for testing
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_role', 'admin');
                  await prefs.setString('employee_id', '29');
                  await _loadUserInfo();
                  provider.initialize();
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
                  // Set as employee
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_role', 'employee');
                  await prefs.setString('employee_id', '29');
                  await _loadUserInfo();
                  provider.initialize();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                ),
                child: Text('Set as Employee', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selection
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: isSmallScreen ? 18 : 20,
                  color: const Color(0xFF667EEA)
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Text('Month:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 14 : 16,
                  )
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthPicker(context, provider),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            provider.selectedMonth.isNotEmpty
                                ? _formatMonth(provider.selectedMonth)
                                : 'Select Month (YYYY-MM)',
                            style: TextStyle(
                              color: provider.selectedMonth.isNotEmpty ? Colors.black : Colors.grey,
                              fontSize: isSmallScreen ? 13 : 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            size: isSmallScreen ? 18 : 20,
                            color: const Color(0xFF667EEA)
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Admin Section - Employee Selection
          if (_isAdmin && _validEmployees.isNotEmpty) ...[
            Text(
              'Select Employee',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF667EEA),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildEmployeeDropdown(provider, screenWidth, isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ],

          // User Info Section
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isAdmin
                    ? [const Color(0xFF667EEA).withOpacity(0.1), const Color(0xFF764BA2).withOpacity(0.1)]
                    : [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              border: Border.all(
                color: _isAdmin
                    ? const Color(0xFF667EEA).withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 40 : 50,
                  height: isSmallScreen ? 40 : 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isAdmin
                          ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                          : [Colors.green, Colors.blue],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAdmin ? 'Administrator Mode' : 'Employee Mode',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: _isAdmin ? const Color(0xFF667EEA) : Colors.green,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        _isAdmin
                            ? 'You can view salary slips for any employee'
                            : 'Viewing your own salary slip only',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isAdmin && provider.selectedEmployeeId != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                    ),
                    child: Text(
                      'ID: ${provider.selectedEmployeeId}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 20 : 24),

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
                elevation: 2,
                shadowColor: const Color(0xFF667EEA).withOpacity(0.3),
              ),
              child: provider.isLoading
                  ? SizedBox(
                height: isSmallScreen ? 20 : 22,
                width: isSmallScreen ? 20 : 22,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
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
                      fontWeight: FontWeight.w500,
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

  Widget _buildEmployeeDropdown(SalarySlipProvider provider, double screenWidth, bool isSmallScreen) {
    if (_validEmployees.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 14,
          horizontal: isSmallScreen ? 12 : 16,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.warning,
                size: isSmallScreen ? 16 : 18,
                color: Colors.orange
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: Text(
                'No employees found. Using current user.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Ensure selected value exists in the list
    final selectedValue = provider.selectedEmployeeId;
    final isValidSelection = selectedValue == null ||
        _validEmployees.any((emp) => _getEmployeeId(emp) == selectedValue);

    if (!isValidSelection) {
      // Reset invalid selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setSelectedEmployee(null);
      });
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: isValidSelection ? selectedValue : null,
          isExpanded: true,
          elevation: 2,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          icon: Container(
            margin: EdgeInsets.only(right: isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_drop_down,
              size: isSmallScreen ? 18 : 20,
              color: const Color(0xFF667EEA),
            ),
          ),
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            child: Text(
                'Select Employee',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isSmallScreen ? 13 : 14,
                )
            ),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                child: Text(
                  '-- Select Employee --',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ),
            ),
            ..._validEmployees.map((employee) {
              final id = _getEmployeeId(employee);
              final name = _getEmployeeName(employee);
              final empId = _getEmployeeCode(employee);
              final department = _getEmployeeDepartment(employee);
              final isCurrentUser = id == _currentEmployeeId;

              return DropdownMenuItem<int?>(
                value: id,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isSmallScreen ? 32 : 40,
                        height: isSmallScreen ? 32 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCurrentUser
                                ? [Colors.blue, Colors.green]
                                : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.substring(0, 1),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isCurrentUser ? Colors.blue : Colors.black87,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Row(
                              children: [
                                if (empId.isNotEmpty)
                                  // Text(
                                  //   'ID: $empId',
                                  //   style: TextStyle(
                                  //       fontSize: isSmallScreen ? 10 : 12,
                                  //       color: Colors.grey
                                  //   ),
                                  // ),
                                if (empId.isNotEmpty && department.isNotEmpty)
                                  // Padding(
                                  //   padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                                  //   child: Text('•',
                                  //       style: TextStyle(
                                  //         color: Colors.grey,
                                  //         fontSize: isSmallScreen ? 10 : 12,
                                  //       )
                                  //   ),
                                  // ),
                                if (department.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      department,
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 8 : 10,
                                          color: Colors.grey
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            print('👤 Selected employee: $value');
            provider.setSelectedEmployee(value);
          },
        ),
      ),
    );
  }

  // Helper methods to safely extract employee data
  int _getEmployeeId(Map<String, dynamic> employee) {
    try {
      if (employee['id'] is int) {
        return employee['id'] as int;
      } else if (employee['id'] is String) {
        return int.tryParse(employee['id'] as String) ?? 0;
      } else if (employee.containsKey('employee_id')) {
        final empId = employee['employee_id'];
        if (empId is int) return empId;
        if (empId is String) return int.tryParse(empId) ?? 0;
      }
    } catch (e) {
      print('Error getting employee ID: $e');
    }
    return 0;
  }

  String _getEmployeeName(Map<String, dynamic> employee) {
    try {
      if (employee['name'] is String) {
        return employee['name'] as String;
      } else if (employee.containsKey('employee_name')) {
        return employee['employee_name']?.toString() ?? 'Unknown';
      } else if (employee.containsKey('full_name')) {
        return employee['full_name']?.toString() ?? 'Unknown';
      }
    } catch (e) {
      print('Error getting employee name: $e');
    }
    return 'Unknown Employee';
  }

  String _getEmployeeCode(Map<String, dynamic> employee) {
    try {
      if (employee['emp_id'] is String) {
        return employee['emp_id'] as String;
      } else if (employee['employee_code'] is String) {
        return employee['employee_code'] as String;
      } else if (employee['code'] is String) {
        return employee['code'] as String;
      } else if (employee.containsKey('id')) {
        return 'EMP${_getEmployeeId(employee).toString().padLeft(3, '0')}';
      }
    } catch (e) {
      print('Error getting employee code: $e');
    }
    return '';
  }

  String _getEmployeeDepartment(Map<String, dynamic> employee) {
    try {
      if (employee['department'] is String) {
        return employee['department'] as String;
      } else if (employee['department_name'] is String) {
        return employee['department_name'] as String;
      } else if (employee['dept'] is String) {
        return employee['dept'] as String;
      }
    } catch (e) {
      print('Error getting employee department: $e');
    }
    return '';
  }

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
            if (_isAdmin && provider.selectedEmployeeId != null)
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

  // Show month picker (year and month only)
  Future<void> _showMonthPicker(BuildContext context, SalarySlipProvider provider) async {
    final now = DateTime.now();
    DateTime initialDate;

    try {
      if (provider.selectedMonth.isNotEmpty) {
        final parts = provider.selectedMonth.split('-');
        if (parts.length == 2) {
          initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        } else {
          initialDate = now;
        }
      } else {
        initialDate = now;
      }
    } catch (e) {
      initialDate = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final month = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      provider.setSelectedMonth(month);
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
}