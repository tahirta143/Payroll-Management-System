import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:payroll_app/Utility/global_url.dart';
// import '../../model/employee_monthly_report/employee_monthly_report.dart';
import '../../model/monthly_attandance_sheet/monthly_attandance_sheet.dart';

class EmployeeReportProvider with ChangeNotifier {
  final String baseUrl = GlobalUrls.baseurl;

  EmployeeMonthlyReport? _report;
  List<Department> _departments = [];
  List<EmployeeListItem> _employees = [];
  List<EmployeeListItem> _allEmployees = [];

  bool _isLoading = false;
  bool _isDepartmentsLoading = false;
  bool _isEmployeesLoading = false;
  String? _error;
  String? _authToken;

  // Getters
  EmployeeMonthlyReport? get report => _report;
  List<Department> get departments => _departments;
  List<EmployeeListItem> get employees => _employees;
  bool get isLoading => _isLoading;
  bool get isDepartmentsLoading => _isDepartmentsLoading;
  bool get isEmployeesLoading => _isEmployeesLoading;
  String? get error => _error;

  // Set token
  void setToken(String? token) {
    _authToken = token;
  }

  // Get token from provider (same as AttendanceProvider)
  Future<String> _getToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken!;
    }
    throw Exception('No authentication token found');
  }

  // Headers (EXACT same as AttendanceProvider)
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==================== FETCH EMPLOYEE MONTHLY REPORT ====================

  Future<void> fetchEmployeeReport({
    required int employeeId,
    required String month,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _headers();
      final url = '$baseUrl/api/employee-monthly-report?employee_id=$employeeId&month=$month';
      debugPrint('📱 Fetching employee report: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📊 Report API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _report = EmployeeMonthlyReport.fromJson(jsonData);
        _error = null;
        debugPrint('✅ Report loaded for ${_report!.employee.name}');
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized - Please login again';
        _report = null;
      } else if (response.statusCode == 404) {
        _error = 'No attendance record found for this employee';
        _report = null;
      } else {
        _error = 'Failed to load report. Status: ${response.statusCode}';
        _report = null;
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      _report = null;
      debugPrint('❌ Error fetching report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== FETCH DEPARTMENTS (EXACT SAME AS ATTENDANCE PROVIDER) ====================

  Future<void> fetchDepartments() async {
    _isDepartmentsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _headers();
      final url = '$baseUrl/api/departments';
      debugPrint('📱 Fetching departments: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📊 Departments API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> departmentsList = [];

        // Parse response - EXACT same as AttendanceProvider
        if (data is Map) {
          if (data.containsKey('departments') && data['departments'] is List) {
            departmentsList = data['departments'] as List<dynamic>;
          } else if (data.containsKey('data') && data['data'] is List) {
            departmentsList = data['data'] as List<dynamic>;
          }
        } else if (data is List) {
          departmentsList = data;
        }

        _departments = [];

        for (var dept in departmentsList) {
          if (dept is Map<String, dynamic>) {
            try {
              // EXACT same parsing as AttendanceProvider
              final id = dept['id'] ?? dept['department_id'];
              final name = dept['name'] ?? dept['department_name'];

              if (id != null && name != null) {
                _departments.add(Department(
                  id: id is int ? id : int.tryParse(id.toString()) ?? 0,
                  name: name.toString().trim(),
                ));
              }
            } catch (e) {
              debugPrint('Error parsing department: $e');
              continue;
            }
          }
        }

        debugPrint('✅ Loaded ${_departments.length} departments');
        for (var dept in _departments) {
          debugPrint('Department: ${dept.id} - ${dept.name}');
        }

      } else if (response.statusCode == 401) {
        _error = 'Unauthorized - Please login again';
      } else {
        _error = 'Failed to load departments. Status: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching departments: $e';
      debugPrint('⚠️ Error fetching departments: $e');
    } finally {
      _isDepartmentsLoading = false;
      notifyListeners();
    }
  }

  // ==================== FETCH EMPLOYEES (EXACT SAME AS ATTENDANCE PROVIDER) ====================

  Future<void> fetchEmployees() async {
    _isEmployeesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _headers();
      final url = '$baseUrl/api/employees';
      debugPrint('📱 Fetching employees: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📊 Employees API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> employeesList = [];

        // Parse response - EXACT same as AttendanceProvider
        if (data is Map) {
          if (data.containsKey('employees') && data['employees'] is List) {
            employeesList = data['employees'] as List<dynamic>;
          } else if (data.containsKey('data') && data['data'] is List) {
            employeesList = data['data'] as List<dynamic>;
          }
        } else if (data is List) {
          employeesList = data;
        }

        _allEmployees = [];

        for (var emp in employeesList) {
          if (emp is Map<String, dynamic>) {
            try {
              // Use EXACT same parsing method as AttendanceProvider
              final employee = _parseEmployeeMap(emp);
              if (employee.id != 0) {
                _allEmployees.add(employee);
              }
            } catch (e) {
              debugPrint('Error parsing employee: $e');
              continue;
            }
          }
        }

        debugPrint('✅ Loaded ${_allEmployees.length} employees');

        // Debug: Print first few employees
        for (var emp in _allEmployees.take(5)) {
          debugPrint('Employee: ${emp.name}, ID: ${emp.id}, Dept: ${emp.departmentName} (${emp.departmentId})');
        }

        // Set initial employees list (all employees)
        _employees = List.from(_allEmployees);

      } else if (response.statusCode == 401) {
        _error = 'Unauthorized - Please login again';
      } else {
        _error = 'Failed to load employees. Status: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching employees: $e';
      debugPrint('⚠️ Error fetching employees: $e');
    } finally {
      _isEmployeesLoading = false;
      notifyListeners();
    }
  }

  // ==================== PARSE EMPLOYEE MAP (EXACT SAME AS ATTENDANCE PROVIDER) ====================

  EmployeeListItem _parseEmployeeMap(Map<String, dynamic> data) {
    try {
      // Parse ID - EXACT same as AttendanceProvider
      final id = _parseInt(data['id']) ??
          _parseInt(data['employee_id']) ??
          _parseInt(data['user_id']) ?? 0;

      // Parse Name - EXACT same as AttendanceProvider
      final name = data['name']?.toString() ??
          data['full_name']?.toString() ??
          data['employee_name']?.toString() ??
          data['first_name']?.toString() ??
          'Unknown';

      // Parse Employee ID - EXACT same as AttendanceProvider
      final empId = data['emp_id']?.toString() ??
          data['employee_code']?.toString() ??
          data['code']?.toString() ??
          data['staff_id']?.toString() ??
          'N/A';

      // Parse Department - EXACT same as AttendanceProvider
      String departmentName = 'Unknown Department';
      int departmentId = 0;

      if (data['department'] != null) {
        if (data['department'] is Map) {
          final deptMap = data['department'] as Map<String, dynamic>;
          departmentName = deptMap['name']?.toString() ?? 'Unknown Department';
          departmentId = deptMap['id'] ?? 0;
        } else if (data['department'] is String) {
          departmentName = data['department'] as String;
        }
      } else if (data['department_name'] != null) {
        departmentName = data['department_name'].toString();
      } else if (data['dept'] != null) {
        departmentName = data['dept'].toString();
      } else if (data['department_id'] != null) {
        departmentId = _parseInt(data['department_id']) ?? 0;
      }

      // Try to find department ID from departments list if we have name but no ID
      if (departmentId == 0 && departmentName.isNotEmpty && _departments.isNotEmpty) {
        final dept = _departments.firstWhere(
              (d) => d.name.trim().toLowerCase() == departmentName.trim().toLowerCase(),
          orElse: () => Department(id: 0, name: ''),
        );
        departmentId = dept.id;
      }

      return EmployeeListItem(
        id: id,
        name: name.trim(),
        empId: empId.trim(),
        departmentId: departmentId,
        departmentName: departmentName.trim(),
      );
    } catch (e) {
      debugPrint('Error in _parseEmployeeMap: $e');
      return EmployeeListItem(
        id: 0,
        name: 'Error',
        empId: 'N/A',
        departmentId: 0,
        departmentName: 'Error',
      );
    }
  }

  // ==================== FETCH BOTH DEPARTMENTS AND EMPLOYEES ====================

  Future<void> fetchDepartmentsAndEmployees() async {
    _isDepartmentsLoading = true;
    _isEmployeesLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First fetch departments
      await fetchDepartments();

      // Then fetch employees (departments list is needed for ID matching)
      await fetchEmployees();

      // Match department IDs with names
      _matchDepartmentIdsWithNames();

    } catch (e) {
      debugPrint('⚠️ Error in fetchDepartmentsAndEmployees: $e');
    } finally {
      _isDepartmentsLoading = false;
      _isEmployeesLoading = false;
      notifyListeners();
    }
  }

  // ==================== MATCH DEPARTMENT IDS WITH NAMES ====================

  void _matchDepartmentIdsWithNames() {
    if (_departments.isEmpty || _allEmployees.isEmpty) return;

    // Create department name to ID map
    final deptNameToId = <String, int>{};
    for (var dept in _departments) {
      deptNameToId[dept.name.trim().toLowerCase()] = dept.id;
    }

    // Update employees with missing department IDs
    for (var i = 0; i < _allEmployees.length; i++) {
      final emp = _allEmployees[i];
      if (emp.departmentId == 0 && emp.departmentName.isNotEmpty) {
        final deptId = deptNameToId[emp.departmentName.trim().toLowerCase()];
        if (deptId != null) {
          _allEmployees[i] = EmployeeListItem(
            id: emp.id,
            name: emp.name,
            empId: emp.empId,
            departmentId: deptId,
            departmentName: emp.departmentName,
          );
        }
      }
    }

    _employees = List.from(_allEmployees);
    debugPrint('✅ Matched department IDs with names');
  }

  // ==================== FILTER EMPLOYEES BY DEPARTMENT ====================

  void filterEmployeesByDepartment(int? departmentId) {
    debugPrint('🔍 Filtering by department ID: $departmentId');
    debugPrint('📊 Total all employees: ${_allEmployees.length}');

    if (_allEmployees.isEmpty) {
      _employees = [];
    } else if (departmentId == null) {
      _employees = List.from(_allEmployees);
      debugPrint('✅ Showing all employees: ${_employees.length}');
    } else {
      // Filter by department ID
      _employees = _allEmployees
          .where((emp) => emp.departmentId == departmentId)
          .toList();

      // If no matches by ID, try matching by department name
      if (_employees.isEmpty) {
        final dept = _departments.firstWhere(
              (d) => d.id == departmentId,
          orElse: () => Department(id: 0, name: ''),
        );

        if (dept.name.isNotEmpty) {
          _employees = _allEmployees
              .where((emp) =>
          emp.departmentName.trim().toLowerCase() == dept.name.trim().toLowerCase())
              .toList();
          debugPrint('🎯 Filtered by department name: ${_employees.length}');
        }
      } else {
        debugPrint('🎯 Filtered employees for dept $departmentId: ${_employees.length}');
      }
    }
    notifyListeners();
  }

  // ==================== HELPER METHODS ====================

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('SocketException')) {
      return 'No internet connection. Please check your network';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Request timeout. Please try again';
    } else if (errorStr.contains('401')) {
      return 'Unauthorized. Please login again';
    } else {
      return 'Error: $errorStr';
    }
  }

  // ==================== UTILITY METHODS ====================

  void clearReport() {
    _report = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _report = null;
    _departments = [];
    _employees = [];
    _allEmployees = [];
    _error = null;
    _isLoading = false;
    _isDepartmentsLoading = false;
    _isEmployeesLoading = false;
    notifyListeners();
  }
}