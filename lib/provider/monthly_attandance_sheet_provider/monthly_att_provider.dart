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
        // List all keys for debugging
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


  // Add this method to your MonthlyReportProvider for debugging
  Future<void> debugPrintSharedPreferences() async {
    print('🔍 ========== DEBUG SHARED PREFERENCES ==========');
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (var key in allKeys) {
        var value = prefs.get(key);
        // Truncate long strings for readability
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
  // ==================== INITIALIZE FROM AUTH ====================
  Future<void> initializeFromAuth() async {
    print('🚀 ========== INITIALIZE FROM AUTH START ==========');
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get token
      _token = await _getToken();
      print('✅ Token obtained');

      // Get user role - AuthProvider saves as 'user_role'
      final userRole = prefs.getString('user_role')?.toLowerCase() ?? '';
      print('👤 User role: "$userRole"');

      _isAdmin = userRole.contains('admin') ||
          userRole.contains('administrator') ||
          userRole == 'admin';
      print('👑 Is Admin: $_isAdmin');

      // Get employee ID for non-admin - AuthProvider saves as 'employee_id'
      if (!_isAdmin) {
        // Try multiple possible key names that AuthProvider might be using
        final employeeIdStr = prefs.getString('employee_id') ??
            prefs.getString('employee_code') ??
            prefs.getString('emp_id') ??
            prefs.getString('user_id') ??
            '';

        _currentEmployeeId = int.tryParse(employeeIdStr);
        _selectedEmployeeId = _currentEmployeeId;
        print('👨‍💼 Employee ID from prefs: "$employeeIdStr"');
        print('👨‍💼 Parsed Employee ID: $_currentEmployeeId');

        // If employee ID is still null, try to get from userData JSON
        if (_currentEmployeeId == null) {
          final userDataString = prefs.getString('userData');
          if (userDataString != null) {
            try {
              final userData = jsonDecode(userDataString);
              final empId = userData['employee_id'] ??
                  userData['emp_id'] ??
                  userData['id'] ??
                  userData['user_id'] ??
                  '';
              _currentEmployeeId = int.tryParse(empId.toString());
              _selectedEmployeeId = _currentEmployeeId;
              print('👨‍💼 Employee ID from userData: $_currentEmployeeId');
            } catch (e) {
              print('❌ Error parsing userData: $e');
            }
          }
        }
      }

      // Get user name - AuthProvider saves as 'user_name'
      _currentUserName = prefs.getString('user_name') ??
          prefs.getString('employee_name') ??
          prefs.getString('name') ??
          'User';
      print('📛 User Name: $_currentUserName');

      // Load data based on role
      if (_isAdmin) {
        print('🔄 Admin: Loading employees and departments...');
        await Future.wait([
          fetchEmployees(),
          fetchDepartments(),
        ]);
        print('✅ Admin data loaded - Employees: ${_employees.length}, Departments: ${_departments.length}');
      } else if (_currentEmployeeId != null) {
        print('🔄 NON-ADMIN: Loading report for employee ID: $_currentEmployeeId');
        // IMPORTANT: Load the report immediately
        await loadReport(
          employeeId: _currentEmployeeId,
          month: _selectedMonth,
        );
        print('✅ Report loaded for non-admin user');
      } else {
        print('❌ CRITICAL: Non-admin user but no employee ID found!');
        // Try to load user data from SharedPreferences for debugging
        final allKeys = prefs.getKeys();
        print('📋 All SharedPreferences keys: $allKeys');
        for (var key in allKeys) {
          print('  $key: ${prefs.get(key)}');
        }
      }

    } catch (e) {
      print('❌ Error: $e');
      _setError('Failed to initialize: ${e.toString()}');
    } finally {
      _setLoading(false);
      print('🏁 ========== INITIALIZE FROM AUTH END ==========');
    }
  }
  // ==================== FETCH EMPLOYEES ====================
  // In your MonthlyReportProvider class, replace the fetchEmployees method:

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

        // Handle different response formats
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

        _employees = [];
        final Map<int, Employee> uniqueEmployeesMap = {}; // Add this line

        for (var item in employeesList) {
          try {
            final employee = _parseEmployee(item);
            if (employee.id != 0) {
              // Only add if ID is not already present
              if (!uniqueEmployeesMap.containsKey(employee.id)) {
                uniqueEmployeesMap[employee.id] = employee;
              }
            }
          } catch (e) {
            print('⚠️ Error parsing employee: $e');
          }
        }

        _employees = uniqueEmployeesMap.values.toList(); // Convert map to list
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

        // Handle different response formats
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

      // Parse ID
      int id = 0;
      if (json['id'] != null) {
        id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
      } else if (json['employee_id'] != null) {
        id = json['employee_id'] is int ? json['employee_id'] : int.tryParse(json['employee_id'].toString()) ?? 0;
      }

      // Parse Name
      String name = json['name']?.toString() ??
          json['full_name']?.toString() ??
          json['employee_name']?.toString() ??
          'Unknown';

      // Parse Employee ID
      String empId = json['emp_id']?.toString() ??
          json['employee_code']?.toString() ??
          json['code']?.toString() ??
          'N/A';

      // Parse Department
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

      // Default shift values
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
        _currentReport = MonthlyReport.fromJson(data);
        print('✅ Report loaded for ${_currentReport!.employee.name}');
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
    }
    notifyListeners();
  }

  Future<void> _filterEmployeesByDepartment(int departmentId) async {
    if (_employees.isNotEmpty) {
      final filtered = _employees
          .where((e) => e.departmentId == departmentId)
          .toList();

      if (filtered.isNotEmpty) {
        _employees = filtered;
      }

      if (_selectedEmployeeId != null &&
          !_employees.any((e) => e.id == _selectedEmployeeId)) {
        _selectedEmployeeId = null;
      }
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
    _selectedEmployeeId = _isAdmin ? null : _currentEmployeeId;
    _selectedDepartmentId = null;
    _selectedMonth = _getCurrentMonth();

    if (_isAdmin) {
      fetchEmployees();
      fetchDepartments();
    } else if (_currentEmployeeId != null) {
      loadReport();
    }

    _clearError();
    notifyListeners();
  }

  // ==================== UTILITY METHODS ====================
  Future<void> loadReportForCurrentUser() async {
    if (!_isAdmin && _currentEmployeeId != null) {
      _selectedEmployeeId = _currentEmployeeId;
      await loadReport();
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
        .where((day) => day.status == 'present')
        .toList() ?? [];
  }

  List<AttendanceDay> getAbsentDays() {
    return _currentReport?.days
        .where((day) => day.status == 'absent')
        .toList() ?? [];
  }

  List<AttendanceDay> getHolidayDays() {
    return _currentReport?.days
        .where((day) => day.status == 'holiday')
        .toList() ?? [];
  }

  int getTotalWorkingDays() {
    return _currentReport?.days
        .where((day) =>
    day.status == 'present' ||
        day.status == 'absent' ||
        day.isHalfDay)
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
    _departments = [];
    _selectedEmployeeId = _isAdmin ? null : _currentEmployeeId;
    _selectedDepartmentId = null;
    _selectedMonth = _getCurrentMonth();
    _error = null;
    notifyListeners();
  }
}