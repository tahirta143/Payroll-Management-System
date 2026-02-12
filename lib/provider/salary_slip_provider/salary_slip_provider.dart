import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payroll_app/Utility/global_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/salary_slip_model/salary_slip_model.dart';

class SalarySlipProvider extends ChangeNotifier {
  SalarySlip? _salarySlip;
  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  String? _error;
  String _selectedMonth = '';
  int? _selectedEmployeeId;

  // 🔴 NEW: Store full employee list exactly like MonthlyReportProvider
  List<Employee> _employees = [];
  List<Employee> _allEmployees = []; // Full unfiltered list
  bool _isAdmin = false;
  int? _currentEmployeeId;

  // Getters
  SalarySlip? get salarySlip => _salarySlip;
  bool get isLoading => _isLoading;
  bool get isLoadingEmployees => _isLoadingEmployees;
  String? get error => _error;
  String get selectedMonth => _selectedMonth;
  int? get selectedEmployeeId => _selectedEmployeeId;
  List<Employee> get employees => _employees;
  List<Employee> get allEmployees => _allEmployees;
  bool get isAdmin => _isAdmin;
  int? get currentEmployeeId => _currentEmployeeId;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSelectedEmployee(int? employeeId) {
    _selectedEmployeeId = employeeId;
    notifyListeners();
  }

  // ==================== INITIALIZE ====================
  Future<void> initialize() async {
    debugPrint('🎬 ========== INITIALIZE SALARY SLIP PROVIDER ==========');

    try {
      await _loadUserInfo();

      if (_selectedMonth.isEmpty) {
        final now = DateTime.now();
        _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      }

      if (!_isAdmin && _currentEmployeeId != null) {
        _selectedEmployeeId = _currentEmployeeId;
        debugPrint('👨‍💼 Non-admin: Setting selected employee to $_currentEmployeeId');
      } else if (_isAdmin) {
        _selectedEmployeeId = null;
        // 🔴 FORCE LOAD EMPLOYEES FOR ADMIN - EXACTLY LIKE ATTENDANCE PROVIDER
        await loadEmployeesForAdmin();
      }

      debugPrint('✅ Provider initialized');
      debugPrint('   Is Admin: $_isAdmin');
      debugPrint('   Month: $_selectedMonth');
      debugPrint('   Employee ID: $_selectedEmployeeId');
      debugPrint('   Employees loaded: ${_employees.length}');
    } catch (e) {
      debugPrint('❌ Initialize error: $e');
    }

    notifyListeners();
  }

  // ==================== LOAD USER INFO ====================
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check admin role
      final userRole = prefs.getString('user_role')?.toLowerCase() ?? '';
      _isAdmin = userRole.contains('admin') ||
          userRole.contains('administrator') ||
          userRole == 'admin';

      // Get employee ID - first try int, then parse from string
      _currentEmployeeId = prefs.getInt('employee_id_int');

      if (_currentEmployeeId == null) {
        final empIdStr = prefs.getString('employee_id');
        _currentEmployeeId = empIdStr != null ? int.tryParse(empIdStr) : null;
      }

      debugPrint('📊 User Info Loaded:');
      debugPrint('   Role: $userRole');
      debugPrint('   Is Admin: $_isAdmin');
      debugPrint('   Current Employee ID: $_currentEmployeeId');
    } catch (e) {
      debugPrint('❌ Error loading user info: $e');
    }
  }

  // ==================== LOAD EMPLOYEES FOR ADMIN ====================
  // 🔴 EXACT COPY FROM MONTHLYREPORTPROVIDER
  Future<void> loadEmployeesForAdmin() async {
    if (!_isAdmin) return;

    debugPrint('👥 ========== FETCH EMPLOYEES FOR ADMIN ==========');
    _isLoadingEmployees = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final url = Uri.parse('${GlobalUrls.baseurl}/api/employees');
      debugPrint('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> employeesList = [];

        // 🔴 EXACT PARSING LOGIC FROM MONTHLYREPORTPROVIDER
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            employeesList = data['data'];
            debugPrint('✅ Found data key with ${employeesList.length} employees');
          } else if (data.containsKey('employees') && data['employees'] is List) {
            employeesList = data['employees'];
            debugPrint('✅ Found employees key with ${employeesList.length} employees');
          } else if (data.containsKey('results') && data['results'] is List) {
            employeesList = data['results'];
            debugPrint('✅ Found results key with ${employeesList.length} employees');
          }
        } else if (data is List) {
          employeesList = data;
          debugPrint('✅ Response is List with ${employeesList.length} employees');
        }

        debugPrint('📊 Raw employees from API: ${employeesList.length}');

        // Clear and parse employees
        _allEmployees = [];
        _employees = [];
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
            debugPrint('⚠️ Error parsing employee: $e');
          }
        }

        _allEmployees = uniqueEmployeesMap.values.toList();
        _employees = List.from(_allEmployees); // Display full list initially

        debugPrint('✅ Loaded ${_employees.length} unique employees');

        // 🔴 DEBUG: Print all employees
        debugPrint('=== ALL EMPLOYEES FROM API ===');
        for (var emp in _employees) {
          debugPrint('   ID: ${emp.id}, Name: ${emp.name}, Dept: ${emp.departmentName}');
        }

        // Add current user if missing
        await _addCurrentUserIfMissing();

      } else {
        debugPrint('❌ Failed: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        await _createFallbackEmployeeList();
      }
    } catch (e) {
      debugPrint('❌ Error fetching employees: $e');
      await _createFallbackEmployeeList();
    } finally {
      _isLoadingEmployees = false;
      notifyListeners();
    }
  }

  // ==================== GET TOKEN ====================
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        debugPrint('❌ No authentication token found');
        throw Exception('No authentication token found');
      }
      debugPrint('✅ Token found');
      return token;
    } catch (e) {
      debugPrint('❌ Failed to get token: $e');
      throw Exception('Failed to get token: $e');
    }
  }

  // ==================== PARSE EMPLOYEE ====================
  // 🔴 EXACT COPY FROM MONTHLYREPORTPROVIDER
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
      debugPrint('❌ Parse error: $e');
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

  // ==================== ADD CURRENT USER IF MISSING ====================
  Future<void> _addCurrentUserIfMissing() async {
    if (_currentEmployeeId == null) return;

    final exists = _employees.any((e) => e.id == _currentEmployeeId);
    if (!exists) {
      debugPrint('➕ Adding current user to employee list');

      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ??
          prefs.getString('employee_name') ??
          'Current User';

      final currentUser = Employee(
        id: _currentEmployeeId!,
        name: userName,
        empId: prefs.getString('employee_code') ?? 'EMP${_currentEmployeeId}',
        departmentId: 0,
        departmentName: 'Current Department',
        dutyShiftId: 1,
        dutyShiftName: 'Morning Shift',
        shiftStart: '09:00:00',
        shiftEnd: '18:00:00',
      );

      _employees.insert(0, currentUser);
      _allEmployees.insert(0, currentUser);
      debugPrint('✅ Added current user: ${currentUser.name}');
    }
  }

  // ==================== FALLBACK EMPLOYEE LIST ====================
  Future<void> _createFallbackEmployeeList() async {
    debugPrint('📋 Creating fallback employee list');

    _employees = [];

    // Add current user first
    if (_currentEmployeeId != null) {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ??
          prefs.getString('employee_name') ??
          'Current User';

      _employees.add(Employee(
        id: _currentEmployeeId!,
        name: userName,
        empId: prefs.getString('employee_code') ?? 'EMP${_currentEmployeeId}',
        departmentId: 0,
        departmentName: 'Current Department',
        dutyShiftId: 1,
        dutyShiftName: 'Morning Shift',
        shiftStart: '09:00:00',
        shiftEnd: '18:00:00',
      ));
    }

    // Add some test employees for admin
    if (_isAdmin) {
      _employees.addAll([
        Employee(
          id: 18,
          name: 'Mazhar Ahmed',
          empId: '456579865',
          departmentId: 1,
          departmentName: 'SKYLINK',
          dutyShiftId: 1,
          dutyShiftName: 'Morning Shift',
          shiftStart: '09:00:00',
          shiftEnd: '18:00:00',
        ),
        Employee(
          id: 29,
          name: 'Muhammad Afaq',
          empId: '3425435435',
          departmentId: 2,
          departmentName: 'INFINITY',
          dutyShiftId: 1,
          dutyShiftName: 'Morning Shift',
          shiftStart: '09:00:00',
          shiftEnd: '18:00:00',
        ),
        Employee(
          id: 16,
          name: 'Test Employee',
          empId: 'EMP016',
          departmentId: 3,
          departmentName: 'HR',
          dutyShiftId: 1,
          dutyShiftName: 'Morning Shift',
          shiftStart: '09:00:00',
          shiftEnd: '18:00:00',
        ),
      ]);
    }

    _allEmployees = List.from(_employees);
    debugPrint('✅ Created fallback list with ${_employees.length} employees');
  }

  // ==================== FETCH SALARY SLIP ====================
  Future<void> fetchSalarySlip() async {
    try {
      _isLoading = true;
      _error = null;
      _salarySlip = null;
      notifyListeners();

      final token = await _getToken();

      // Determine employee ID
      int employeeId;
      if (_isAdmin) {
        if (_selectedEmployeeId == null) {
          _error = 'Please select an employee';
          _isLoading = false;
          notifyListeners();
          return;
        }
        employeeId = _selectedEmployeeId!;
        debugPrint('👨‍💼 Admin: Using selected employee ID: $employeeId');
      } else {
        if (_currentEmployeeId == null) {
          _error = 'Employee ID not found';
          _isLoading = false;
          notifyListeners();
          return;
        }
        employeeId = _currentEmployeeId!;
        debugPrint('👨‍💼 Employee: Using own ID: $employeeId');
      }

      if (_selectedMonth.isEmpty) {
        _error = 'Please select a month';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _fetchApiSalarySlip(employeeId, token);
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchApiSalarySlip(int employeeId, String token) async {
    try {
      final url = '${GlobalUrls.baseurl}/api/salary-slip?month=$_selectedMonth&employee_id=$employeeId';
      debugPrint('🌐 Calling API: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _salarySlip = SalarySlip.fromJson(data);
        debugPrint('✅ Salary slip loaded for employee: $employeeId');
        _error = null;
      } else if (response.statusCode == 404) {
        _error = 'Salary slip not found for selected employee and month';
      } else {
        _error = 'Failed to load salary slip: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: Could not connect to server.';
      debugPrint('❌ Network error: $e');
    }
  }

  // ==================== UTILITY METHODS ====================
  void clearSalarySlip() {
    _salarySlip = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshEmployees() async {
    if (_isAdmin) {
      await loadEmployeesForAdmin();
    }
  }

  void clearFilters() {
    if (_isAdmin) {
      _selectedEmployeeId = null;
      _selectedMonth = _getCurrentMonth();
    } else {
      _selectedEmployeeId = _currentEmployeeId;
      _selectedMonth = _getCurrentMonth();
    }
    _salarySlip = null;
    _error = null;
    notifyListeners();
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ==================== DEBUG METHOD ====================
  Future<void> debugPrintState() async {
    debugPrint('🔍 ========== SALARY SLIP PROVIDER DEBUG ==========');
    debugPrint('Is Admin: $_isAdmin');
    debugPrint('Current Employee ID: $_currentEmployeeId');
    debugPrint('Selected Employee ID: $_selectedEmployeeId');
    debugPrint('Selected Month: $_selectedMonth');
    debugPrint('Employees Count: ${_employees.length}');
    debugPrint('Has Salary Slip: ${_salarySlip != null}');
    debugPrint('Is Loading: $_isLoading');
    debugPrint('Error: $_error');
    debugPrint('🔍 ========== END DEBUG ==========');
  }
}

// ==================== EMPLOYEE MODEL ====================
class Employee {
  final int id;
  final String name;
  final String empId;
  final String? machineCode;
  final int departmentId;
  final String departmentName;
  final int dutyShiftId;
  final String dutyShiftName;
  final String shiftStart;
  final String shiftEnd;

  Employee({
    required this.id,
    required this.name,
    required this.empId,
    this.machineCode,
    required this.departmentId,
    required this.departmentName,
    required this.dutyShiftId,
    required this.dutyShiftName,
    required this.shiftStart,
    required this.shiftEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emp_id': empId,
      'machine_code': machineCode,
      'department_id': departmentId,
      'department_name': departmentName,
      'duty_shift_id': dutyShiftId,
      'duty_shift_name': dutyShiftName,
      'shift_start': shiftStart,
      'shift_end': shiftEnd,
    };
  }
}