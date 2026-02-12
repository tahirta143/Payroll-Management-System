// lib/providers/monthly_attandance_sheet_provider/monthly_att_provider.dart

import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/monthly_attandance_sheet/monthly_attandance_sheet.dart';
import '../../Utility/global_url.dart';

class MonthlyReportProvider extends ChangeNotifier {
  static const String baseUrl = GlobalUrls.baseurl;

  // User info
  bool _isAdmin = false;
  int? _currentEmployeeId;
  String? _currentUserName;
  String? _token;

  // Data State
  MonthlyReport? _currentReport;
  List<Employee> _employees = [];
  List<Employee> _allEmployees = []; // 🔴 NEW: Store full unfiltered employee list
  List<Department> _departments = [];

  // UI State
  bool _isLoading = false;
  String? _error;

  // Filters
  String _selectedMonth = _getCurrentMonth();
  int? _selectedEmployeeId;
  int? _selectedDepartmentId;

  // Getters
  bool get isAdmin => _isAdmin;
  int? get currentEmployeeId => _currentEmployeeId;
  String? get currentUserName => _currentUserName;
  MonthlyReport? get currentReport => _currentReport;
  List<Employee> get employees => _employees;
  List<Employee> get allEmployees => _allEmployees; // 🔴 NEW: Getter for full list
  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedMonth => _selectedMonth;
  int? get selectedEmployeeId => _selectedEmployeeId;
  int? get selectedDepartmentId => _selectedDepartmentId;

  static String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ==================== GET TOKEN ====================
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        print('❌ No authentication token found in SharedPreferences');
        final allKeys = prefs.getKeys();
        print('📋 Available SharedPreferences keys: $allKeys');
        throw Exception('No authentication token found');
      }
      print('✅ Token found: ${token.substring(0, Math.min(20, token.length))}...');
      return token;
    } catch (e) {
      print('❌ Failed to get token: $e');
      throw Exception('Failed to get token: $e');
    }
  }

  // ==================== INITIALIZE FROM AUTH ====================
// ==================== INITIALIZE FROM AUTH ====================
  Future<void> initializeFromAuth() async {
    print('🚀 ========== INITIALIZE FROM AUTH START ==========');
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();

      _token = await _getToken();
      print('✅ Token obtained');

      final userRole = prefs.getString('user_role')?.toLowerCase() ?? '';
      print('👤 User role: "$userRole"');

      _isAdmin = userRole.contains('admin') ||
          userRole.contains('administrator') ||
          userRole == 'admin';
      print('👑 Is Admin: $_isAdmin');

      if (!_isAdmin) {
        // 🔴🔴🔴 SIRF YAHI RAKHO - BAQI SAB HATADO

        // 1. PEHLE employee_id_int LOAD KARO
        _currentEmployeeId = prefs.getInt('employee_id_int');
        print('📊 employee_id_int from prefs: $_currentEmployeeId');

        // 2. AGAR NULL HAI TOH STRING SE PARSE KARO
        if (_currentEmployeeId == null) {
          final empIdStr = prefs.getString('employee_id');
          _currentEmployeeId = empIdStr != null ? int.tryParse(empIdStr) : null;
          print('📊 employee_id string from prefs: $_currentEmployeeId');
        }

        // 3. CRITICAL: selectedEmployeeId SET KARO
        _selectedEmployeeId = _currentEmployeeId;

        // 4. USER NAME LOAD KARO
        _currentUserName = prefs.getString('user_name') ??
            prefs.getString('employee_name') ??
            'User';

        print('👨‍💼 FINAL Current Employee ID: $_currentEmployeeId');
        print('👨‍💼 FINAL Selected Employee ID: $_selectedEmployeeId');
        print('📛 User Name: $_currentUserName');

        // 5. REPORT LOAD KARO
        if (_currentEmployeeId != null) {
          print('🔄 Loading report for employee ID: $_currentEmployeeId');
          await loadReport(employeeId: _currentEmployeeId);
        } else {
          print('❌ CRITICAL: No employee ID found!');
          _setError('Employee ID not found. Please contact administrator.');
        }
      } else {
        // Admin user initialization
        print('🔄 Admin: Loading employees and departments...');
        await Future.wait([
          fetchEmployees(),
          fetchDepartments(),
        ]);
      }
    } catch (e) {
      print('❌ Error in initializeFromAuth: $e');
      _setError('Failed to initialize: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
      print('🏁 ========== INITIALIZE FROM AUTH END ==========');
    }
  }
  // ==================== FETCH EMPLOYEES ====================
  Future<void> fetchEmployees() async {
    if (!_isAdmin) return;

    print('👥 ========== FETCH EMPLOYEES ==========');

    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/api/employees');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> employeesList = [];

        if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            employeesList = data['data'];
            print('✅ Found data key');
          } else if (data.containsKey('employees') && data['employees'] is List) {
            employeesList = data['employees'];
            print('✅ Found employees key');
          } else if (data.containsKey('results') && data['results'] is List) {
            employeesList = data['results'];
            print('✅ Found results key');
          }
        } else if (data is List) {
          employeesList = data;
          print('✅ Response is List');
        }

        print('📊 Raw employees: ${employeesList.length}');

        _allEmployees = []; // 🔴 Clear full list
        _employees = [];    // 🔴 Clear displayed list
        final Map<int, Employee> uniqueEmployeesMap = {};

        for (var item in employeesList) {
          try {
            final employee = _parseEmployee(item);
            if (employee.id != 0) {
              if (!uniqueEmployeesMap.containsKey(employee.id)) {
                uniqueEmployeesMap[employee.id] = employee;
              }
            }
          } catch (e) {
            print('⚠️ Error parsing employee: $e');
          }
        }

        _allEmployees = uniqueEmployeesMap.values.toList(); // 🔴 Store full list
        _employees = List.from(_allEmployees); // 🔴 Display full list initially
        print('✅ Loaded ${_employees.length} unique employees');
        notifyListeners();
      } else {
        print('❌ Failed: ${response.statusCode}');
        _setError('Failed to load employees');
      }
    } catch (e) {
      print('❌ Error: $e');
      _setError('Failed to load employees: $e');
    }
  }

  // ==================== FETCH DEPARTMENTS ====================
  Future<void> fetchDepartments() async {
    if (!_isAdmin) return;

    print('🏢 ========== FETCH DEPARTMENTS ==========');

    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/api/departments');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> departmentsList = [];

        if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            departmentsList = data['data'];
            print('✅ Found data key');
          } else if (data.containsKey('departments') && data['departments'] is List) {
            departmentsList = data['departments'];
            print('✅ Found departments key');
          } else if (data.containsKey('results') && data['results'] is List) {
            departmentsList = data['results'];
            print('✅ Found results key');
          }
        } else if (data is List) {
          departmentsList = data;
          print('✅ Response is List');
        }

        print('📊 Raw departments: ${departmentsList.length}');

        _departments = [];
        for (var item in departmentsList) {
          try {
            final department = Department(
              id: item['id'] ?? 0,
              name: item['name']?.toString() ??
                  item['department_name']?.toString() ??
                  'Unknown',
            );
            if (department.id != 0 && department.name != 'Unknown') {
              _departments.add(department);
            }
          } catch (e) {
            print('⚠️ Error parsing department: $e');
          }
        }

        print('✅ Loaded ${_departments.length} departments');
        notifyListeners();
      } else {
        print('❌ Failed: ${response.statusCode}');
        _setError('Failed to load departments');
      }
    } catch (e) {
      print('❌ Error: $e');
      _setError('Failed to load departments: $e');
    }
  }

  // ==================== PARSE EMPLOYEE ====================
  Employee _parseEmployee(dynamic data) {
    try {
      final Map<String, dynamic> json = data is Map
          ? Map<String, dynamic>.from(data)
          : {};

      int id = 0;
      if (json['id'] != null) {
        id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
      } else if (json['employee_id'] != null) {
        id = json['employee_id'] is int ? json['employee_id'] : int.tryParse(json['employee_id'].toString()) ?? 0;
      }

      String name = json['name']?.toString() ??
          json['full_name']?.toString() ??
          json['employee_name']?.toString() ??
          'Unknown';

      String empId = json['emp_id']?.toString() ??
          json['employee_code']?.toString() ??
          json['code']?.toString() ??
          'N/A';

      String departmentName = 'Unknown Department';
      int departmentId = 0;

      if (json['department'] != null) {
        if (json['department'] is Map) {
          final deptMap = json['department'] as Map;
          departmentName = deptMap['name']?.toString() ?? 'Unknown';
          departmentId = deptMap['id'] ?? 0;
        } else if (json['department'] is String) {
          departmentName = json['department'] as String;
        }
      } else if (json['department_name'] != null) {
        departmentName = json['department_name'].toString();
      } else if (json['dept_name'] != null) {
        departmentName = json['dept_name'].toString();
      }

      if (json['department_id'] != null) {
        departmentId = json['department_id'] is int
            ? json['department_id']
            : int.tryParse(json['department_id'].toString()) ?? 0;
      }

      int dutyShiftId = 1;
      String dutyShiftName = 'Morning Shift';
      String shiftStart = '09:00:00';
      String shiftEnd = '18:00:00';

      return Employee(
        id: id,
        name: name.trim(),
        empId: empId.trim(),
        machineCode: json['machine_code']?.toString(),
        departmentId: departmentId,
        departmentName: departmentName.trim(),
        dutyShiftId: dutyShiftId,
        dutyShiftName: dutyShiftName,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      );
    } catch (e) {
      print('❌ Parse error: $e');
      return Employee(
        id: 0,
        name: 'Error',
        empId: 'N/A',
        departmentId: 0,
        departmentName: 'Error',
        dutyShiftId: 1,
        dutyShiftName: 'Morning Shift',
        shiftStart: '09:00:00',
        shiftEnd: '18:00:00',
      );
    }
  }

  // ==================== LOAD REPORT ====================
  Future<void> loadReport({
    int? employeeId,
    String? month,
  }) async {
    print('📊 ========== LOAD REPORT ==========');

    _setLoading(true);
    _clearError();

    final targetEmployeeId = employeeId ?? _selectedEmployeeId;
    final targetMonth = month ?? _selectedMonth;

    if (targetEmployeeId == null) {
      _setError('Please select an employee');
      _setLoading(false);
      return;
    }

    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/api/employee-monthly-report')
          .replace(queryParameters: {
        'employee_id': targetEmployeeId.toString(),
        'month': targetMonth,
      });

      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cleanReportData(data);
        _currentReport = MonthlyReport.fromJson(data);
        print('✅ Report loaded for ${_currentReport!.employee.name}');
        _printReportSummary();
        _setError(null);
      } else {
        _setError('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to load report: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== CLEAN REPORT DATA ====================
  void _cleanReportData(Map<String, dynamic> data) {
    if (data['days'] != null && data['days'] is List) {
      for (var day in data['days']) {
        if (day['status'] != null) {
          String status = day['status'].toString().toLowerCase();
          if (status == 'half_day' || status == 'half day') {
            day['status'] = 'present';
            day['is_half_day'] = false;
            day['half_day_deduction_amount'] = 0;
          }
        }
        day.remove('is_half_day');
        day.remove('half_day_deduction_amount');
        day.remove('half_day_deduction_percent');
      }
    }

    if (data['salary_summary'] != null) {
      data['salary_summary'].remove('half_day_count');
      data['salary_summary'].remove('half_day_deduction_percent');
      data['salary_summary'].remove('half_day_deduction_total');
      data['salary_summary']['half_day_count'] = 0;
    }

    if (data['settings'] != null) {
      data['settings'].remove('max_late_time');
      data['settings'].remove('half_day_deduction_percent');
    }
  }

  // ==================== PRINT REPORT SUMMARY ====================
  void _printReportSummary() {
    if (_currentReport == null) return;
    print('📋 ========== REPORT SUMMARY ==========');
    print('Employee: ${_currentReport!.employee.name}');
    print('Month: ${_currentReport!.month}');
    final presentCount = getPresentDays().length;
    final absentCount = getAbsentDays().length;
    final holidayCount = getHolidayDays().length;
    print('Present Days: $presentCount');
    print('Absent Days: $absentCount');
    print('Holiday Days: $holidayCount');
    print('Base Salary: ${_currentReport!.salary.netSalary}');
    print('Absent Deduction: ${_currentReport!.salarySummary.fullDayDeductionTotal}');
    print('Net Payable: ${_currentReport!.salarySummary.netPayable}');
    print('📋 =====================================');
  }

  // ==================== FILTER METHODS ====================
  void setSelectedMonth(String month) {
    _selectedMonth = month;
    if (!_isAdmin && _currentEmployeeId != null) {
      loadReport();
    }
    notifyListeners();
  }

  void setSelectedEmployeeId(int? employeeId) {
    _selectedEmployeeId = employeeId;
    notifyListeners();
  }

  void setSelectedDepartmentId(int? departmentId) {
    _selectedDepartmentId = departmentId;
    if (departmentId != null && _isAdmin) {
      _filterEmployeesByDepartment(departmentId);
    } else if (departmentId == null && _isAdmin) {
      // 🔴 NEW: Reset to show all employees when "All Departments" is selected
      _resetToAllEmployees();
    }
    notifyListeners();
  }

  // 🔴 NEW: Filter employees by department using the full list
  Future<void> _filterEmployeesByDepartment(int departmentId) async {
    print('🔍 Filtering employees by department: $departmentId');

    // Use _allEmployees as the source, fallback to _employees if _allEmployees is empty
    final List<Employee> sourceList = _allEmployees.isNotEmpty ? _allEmployees : _employees;

    if (sourceList.isEmpty) {
      print('⚠️ No employees to filter');
      return;
    }

    final filtered = sourceList
        .where((e) => e.departmentId == departmentId)
        .toList();

    print('📊 Found ${filtered.length} employees in department $departmentId');

    // Update the displayed employees list
    _employees = filtered;

    // Clear selected employee if not in filtered list
    if (_selectedEmployeeId != null &&
        !_employees.any((e) => e.id == _selectedEmployeeId)) {
      _selectedEmployeeId = null;
    }

    notifyListeners();
  }

  // 🔴 NEW: Reset to show all employees
  void _resetToAllEmployees() {
    print('🔄 Resetting to show all employees');
    if (_allEmployees.isNotEmpty) {
      _employees = List.from(_allEmployees);
      print('📊 Showing all ${_employees.length} employees');
      notifyListeners();
    }
  }

  void applyFilters() {
    if (_selectedEmployeeId != null) {
      loadReport();
    } else {
      _setError('Please select an employee');
    }
  }

  void clearFilters() {
    if (_isAdmin) {
      _selectedEmployeeId = null;
      _selectedDepartmentId = null;
      _resetToAllEmployees();
      fetchDepartments();
    } else {
      // For non-admin, always keep their own employee ID
      _selectedEmployeeId = _currentEmployeeId;
      _selectedDepartmentId = null;
      _selectedMonth = _getCurrentMonth();
      // Reload their report
      if (_currentEmployeeId != null) {
        loadReport(employeeId: _currentEmployeeId);
      }
    }
    _clearError();
    notifyListeners();
  }

  // ==================== UTILITY METHODS ====================
  Future<void> loadReportForCurrentUser() async {
    print('🔄 loadReportForCurrentUser called');
    print('📊 Is Admin: $_isAdmin');
    print('📊 Current Employee ID: $_currentEmployeeId');
    print('📊 Selected Employee ID: $_selectedEmployeeId');

    if (!_isAdmin) {
      if (_currentEmployeeId != null) {
        // Make sure selectedEmployeeId is set
        _selectedEmployeeId = _currentEmployeeId;
        print('📊 Setting selectedEmployeeId to: $_selectedEmployeeId');
        await loadReport(employeeId: _currentEmployeeId);
      } else {
        print('❌ No employee ID available for non-admin user');
        _setError('Employee ID not available');
      }
    }
  }

  Future<void> refreshData() async {
    if (_isAdmin) {
      await Future.wait([
        fetchEmployees(),
        fetchDepartments(),
      ]);
    }
    if (_selectedEmployeeId != null) {
      await loadReport();
    }
  }

  List<AttendanceDay> getPresentDays() {
    return _currentReport?.days
        .where((day) => day.status.toLowerCase() == 'present')
        .toList() ?? [];
  }

  List<AttendanceDay> getAbsentDays() {
    return _currentReport?.days
        .where((day) => day.status.toLowerCase() == 'absent')
        .toList() ?? [];
  }

  List<AttendanceDay> getHolidayDays() {
    return _currentReport?.days
        .where((day) => day.status.toLowerCase() == 'holiday')
        .toList() ?? [];
  }

  int getTotalWorkingDays() {
    return _currentReport?.days
        .where((day) =>
    day.status.toLowerCase() == 'present' ||
        day.status.toLowerCase() == 'absent')
        .length ?? 0;
  }

  // ==================== PRIVATE METHODS ====================
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearData() {
    _currentReport = null;
    _employees = [];
    _allEmployees = []; // 🔴 Clear full list as well
    _departments = [];
    _selectedEmployeeId = _isAdmin ? null : _currentEmployeeId;
    _selectedDepartmentId = null;
    _selectedMonth = _getCurrentMonth();
    _error = null;
    notifyListeners();
  }

  // ==================== DEBUG METHOD ====================
  Future<void> debugPrintSharedPreferences() async {
    print('🔍 ========== DEBUG SHARED PREFERENCES ==========');
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (var key in allKeys) {
        var value = prefs.get(key);
        if (value is String && value.length > 100) {
          value = '${value.substring(0, 100)}...';
        }
        print('  $key: $value');
      }
    } catch (e) {
      print('❌ Error reading SharedPreferences: $e');
    }
    print('🔍 ========== END DEBUG ==========');
  }
}

