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

  // For admin user - list of employees
  List<Map<String, dynamic>> _employees = [];

  // Getters
  SalarySlip? get salarySlip => _salarySlip;
  bool get isLoading => _isLoading;
  bool get isLoadingEmployees => _isLoadingEmployees;
  String? get error => _error;
  String get selectedMonth => _selectedMonth;
  int? get selectedEmployeeId => _selectedEmployeeId;
  List<Map<String, dynamic>> get employees => _employees;

  // Set selected month
  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Set selected employee (for admin only)
  void setSelectedEmployee(int? employeeId) {
    _selectedEmployeeId = employeeId;
    notifyListeners();
  }

  // Check if user is admin
  Future<bool> _isAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? 'employee';
    return userRole.toLowerCase().contains('admin');
  }

  // Get current logged-in employee ID
  // Update the _getCurrentEmployeeId() method in SalarySlipProvider:
  // Get current logged-in employee ID
  Future<int> _getCurrentEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try 'employee_id' (String then int)
    String? employeeIdStr = prefs.getString('employee_id');
    if (employeeIdStr != null && employeeIdStr.isNotEmpty) {
      final id = int.tryParse(employeeIdStr);
      if (id != null) {
        print('✅ Found employee ID in SharedPreferences[employee_id] (String): $id');
        return id;
      }
    }
    
    // 2. Try 'employee_id' as int? (some apps save it as int)
    /* 
       Note: SharedPreferences throws if you try to getInt on a String value 
       or getString on an int value. So we have to be careful. 
       Ideally, we should know the type. But assuming mixed usage:
    */
    try {
        final employeeIdInt = prefs.getInt('employee_id');
        if (employeeIdInt != null) {
            print('✅ Found employee ID in SharedPreferences[employee_id] (int): $employeeIdInt');
            return employeeIdInt;
        }
    } catch (_) {}

    // 3. Try 'emp_id' (String then int)
    String? empIdStr = prefs.getString('emp_id');
    if (empIdStr != null && empIdStr.isNotEmpty) {
      final id = int.tryParse(empIdStr);
      if (id != null) {
        print('✅ Found employee ID in SharedPreferences[emp_id] (String): $id');
        return id;
      }
    }
    
    try {
        final empIdInt = prefs.getInt('emp_id');
        if (empIdInt != null) {
            print('✅ Found employee ID in SharedPreferences[emp_id] (int): $empIdInt');
            return empIdInt;
        }
    } catch (_) {}

    // 4. Try userData json
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        // Check employee_id first
        if (userData['employee_id'] != null) {
             final val = userData['employee_id'];
             if (val is int) return val;
             if (val is String) {
                 final parsed = int.tryParse(val);
                 if (parsed != null) return parsed;
             }
        }
        // Then emp_id
        if (userData['emp_id'] != null) {
             final val = userData['emp_id'];
             if (val is int) return val;
             if (val is String) {
                 final parsed = int.tryParse(val);
                 if (parsed != null) return parsed;
             }
        }
        // Finally id (which might be user id, but if others fail...)
        if (userData['id'] != null) {
             final val = userData['id'];
             if (val is int) return val;
             if (val is String) {
                 final parsed = int.tryParse(val);
                 if (parsed != null) return parsed;
             }
        }
      } catch (e) {
        print('❌ Error parsing userData: $e');
      }
    }

    // 5. Fallback to 'user_id' (last resort)
    final userId = prefs.getInt('user_id');
    if (userId != null) {
        print('⚠️ Using user_id as fallback: $userId');
        return userId;
    }

    print('❌ Warning: Could not find employee ID, defaulting to 0');
    return 0;
  }

  // Load employees for admin dropdown - UPDATED METHOD
  Future<void> loadEmployeesForDropdown() async {
    try {
      final isAdmin = await _isAdminUser();

      _isLoadingEmployees = true;
      notifyListeners();

      if (isAdmin) {
        // For admin, fetch employees from API using the same endpoint as attendance
        await _fetchEmployeesFromAPI();
      } else {
        // For non-admin, just load current user
        await _loadCurrentEmployeeOnly();
      }

    } catch (e) {
      debugPrint('Error loading employees: $e');
      await _createDefaultEmployeesList();
    } finally {
      _isLoadingEmployees = false;
      notifyListeners();
    }
  }

  // Fetch employees from API - USING THE SAME METHOD AS ATTENDANCE
  Future<void> _fetchEmployeesFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        await _createDefaultEmployeesList();
        return;
      }

      // Use the employees endpoint (same as in AttendanceProvider)
      final url = '${GlobalUrls.baseurl}/api/employees';
      debugPrint('🌐 Fetching employees from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📊 Employees API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('📋 Employees API response keys: ${responseData.keys}');

        List<dynamic> employeesList = [];

        // Extract employees list from response (same parsing logic as AttendanceProvider)
        if (responseData is Map && responseData.containsKey('employees')) {
          employeesList = responseData['employees'] as List<dynamic>;
        } else if (responseData is List) {
          employeesList = responseData;
        }

        debugPrint('📋 Found ${employeesList.length} employees in API response');

        if (employeesList.isNotEmpty) {
          _employees = employeesList.map((emp) {
            return _parseEmployeeMap(emp);
          }).where((emp) => emp['id'] != 0 && emp['name'] != 'Unknown').toList();

          debugPrint('✅ Loaded ${_employees.length} employees from API');

          // Add current user if not in list
          await _addCurrentUserIfMissing();

          // Sort by name
          _employees.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

          return;
        } else {
          debugPrint('❌ No employees found in API response');
        }
      } else {
        debugPrint('❌ Employees API failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      // If API fails, try fallback method
      await _fetchEmployeesFromSalaryData(token);

    } catch (e) {
      debugPrint('❌ Error fetching employees from API: $e');
      await _createDefaultEmployeesList();
    }
  }

  // Parse employee map (same method as in AttendanceProvider)
  Map<String, dynamic> _parseEmployeeMap(dynamic data) {
    try {
      if (data is! Map<String, dynamic>) {
        return {'id': 0, 'name': 'Unknown', 'emp_id': 'N/A', 'department': 'Unknown'};
      }

      // Extract ID from multiple possible fields
      int id = _parseInt(data['id']) ??
          _parseInt(data['employee_id']) ??
          _parseInt(data['user_id']) ?? 0;

      // Extract name from multiple possible fields
      String name = data['name']?.toString() ??
          data['full_name']?.toString() ??
          data['employee_name']?.toString() ??
          data['first_name']?.toString() ??
          'Unknown';

      // Extract employee code from multiple possible fields
      String empId = data['emp_id']?.toString() ??
          data['employee_code']?.toString() ??
          data['code']?.toString() ??
          data['staff_id']?.toString() ??
          'N/A';

      // Extract department
      String department = 'Unknown Department';

      if (data['department'] != null) {
        if (data['department'] is Map) {
          final deptMap = data['department'] as Map<String, dynamic>;
          department = deptMap['name']?.toString() ?? 'Unknown Department';
        } else if (data['department'] is String) {
          department = data['department'] as String;
        }
      } else if (data['department_name'] != null) {
        department = data['department_name'].toString();
      } else if (data['dept'] != null) {
        department = data['dept'].toString();
      }

      // Clean up the data
      name = name.trim();
      empId = empId.trim();
      department = department.trim();

      return {
        'id': id,
        'name': name,
        'emp_id': empId,
        'department': department,
      };
    } catch (e) {
      debugPrint('Error in _parseEmployeeMap: $e');
      return {
        'id': 0,
        'name': 'Error',
        'emp_id': 'N/A',
        'department': 'Error',
      };
    }
  }

  // Helper to parse integer from dynamic value
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Load only current employee for non-admin
  Future<void> _loadCurrentEmployeeOnly() async {
    final currentEmployee = await _getCurrentEmployeeInfo();
    if (currentEmployee['id'] != 0) {
      _employees = [currentEmployee];
      // Set as selected
      _selectedEmployeeId = currentEmployee['id'];
      debugPrint('📋 Loaded current employee only: ${currentEmployee['name']}');
    } else {
      await _createDefaultEmployeesList();
    }
  }

  // Get current employee info
  Future<Map<String, dynamic>> _getCurrentEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = await _getCurrentEmployeeId();

    // Try to get name from multiple sources
    String employeeName = prefs.getString('employee_name') ??
        prefs.getString('user_name') ??
        'Current User';

    // Try to get employee code from multiple sources
    String empCode = prefs.getString('employee_code') ??
        prefs.getString('emp_code') ??
        'EMP${employeeId.toString().padLeft(3, '0')}';

    // Try to get department
    String department = prefs.getString('department_name') ??
        prefs.getString('department') ??
        'Department';

    return {
      'id': employeeId,
      'name': employeeName,
      'emp_id': empCode,
      'department': department,
    };
  }

  // Add current user to list if missing
  Future<void> _addCurrentUserIfMissing() async {
    final currentUser = await _getCurrentEmployeeInfo();

    if (currentUser['id'] != 0 && !_employees.any((e) => e['id'] == currentUser['id'])) {
      _employees.insert(0, currentUser); // Add at beginning
      debugPrint('➕ Added current user to employees list');
    }
  }

  // Alternative: Fetch employees from salary data (fallback)
  Future<void> _fetchEmployeesFromSalaryData(String token) async {
    try {
      debugPrint('🔄 Trying fallback: fetching employees from salary data');

      List<Map<String, dynamic>> fetchedEmployees = [];

      // Always include current user
      final currentUser = await _getCurrentEmployeeInfo();
      if (currentUser['id'] != 0) {
        fetchedEmployees.add(currentUser);
      }

      // Try known employee IDs
      const testEmployeeIds = [29, 30, 31, 16, 10];
      final recentMonths = _getRecentMonths(2);

      for (final month in recentMonths) {
        for (final empId in testEmployeeIds) {
          // Skip if already in list
          if (fetchedEmployees.any((e) => e['id'] == empId)) {
            continue;
          }

          try {
            final url = '${GlobalUrls.baseurl}/api/salary-slip?month=$month&employee_id=$empId';
            final response = await http.get(
              Uri.parse(url),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (response.statusCode == 200) {
              final data = json.decode(response.body);

              if (data['employee'] != null) {
                final empData = data['employee'];
                fetchedEmployees.add({
                  'id': empId,
                  'name': empData['name']?.toString() ?? 'Employee $empId',
                  'emp_id': empData['emp_id']?.toString() ?? 'EMP${empId.toString().padLeft(3, '0')}',
                  'department': empData['department_name']?.toString() ?? 'Unknown',
                });

                debugPrint('✅ Found employee: ${empData['name']} (ID: $empId)');
              }
            }
          } catch (e) {
            // Skip errors and continue
            continue;
          }

          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Stop if we have enough employees
        if (fetchedEmployees.length >= 3) {
          break;
        }
      }

      if (fetchedEmployees.isNotEmpty) {
        // Sort by name
        fetchedEmployees.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        _employees = fetchedEmployees;
        debugPrint('✅ Loaded ${_employees.length} employees from salary data');
      } else {
        await _createDefaultEmployeesList();
      }

    } catch (e) {
      debugPrint('Error fetching from salary data: $e');
      await _createDefaultEmployeesList();
    }
  }

  // Create default employees list
  Future<void> _createDefaultEmployeesList() async {
    final currentUser = await _getCurrentEmployeeInfo();

    _employees = [
      if (currentUser['id'] != 0) currentUser,
      {'id': 29, 'name': 'Muhammad Afaq', 'emp_id': '3425435435', 'department': 'INFINITY'},
      {'id': 30, 'name': 'Syed Ahmed', 'emp_id': 'EMP030', 'department': 'Department'},
      {'id': 16, 'name': 'Employee 16', 'emp_id': 'EMP016', 'department': 'HR'},
      {'id': 10, 'name': 'Employee 10', 'emp_id': 'EMP010', 'department': 'IT'},
    ];

    // Sort by name
    _employees.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    debugPrint('📋 Created default list of ${_employees.length} employees');
  }

  // Get recent months
  List<String> _getRecentMonths(int count) {
    final List<String> months = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final date = DateTime(now.year, now.month - i);
      final month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months.add(month);
    }

    return months;
  }

  // Fetch salary slip - MAIN METHOD
  Future<void> fetchSalarySlip() async {
    try {
      _isLoading = true;
      _error = null;
      _salarySlip = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final isAdmin = await _isAdminUser();

      // Check token
      if (token.isEmpty) {
        _error = 'Authentication required. Please login first.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Determine which employee ID to use
      int employeeId;
      if (isAdmin && _selectedEmployeeId != null && _selectedEmployeeId != 0) {
        employeeId = _selectedEmployeeId!;
        debugPrint('👨‍💼 Admin: Using selected employee ID: $employeeId');
      } else {
        employeeId = await _getCurrentEmployeeId();
        debugPrint('👤 Employee: Using current employee ID: $employeeId');

        if (employeeId == 0) {
          _error = 'Your employee ID is not set. Please login again.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Check month
      if (_selectedMonth.isEmpty) {
        _error = 'Please select a month first';
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('🚀 Fetching salary slip:');
      debugPrint('   Employee ID: $employeeId');
      debugPrint('   Month: $_selectedMonth');
      debugPrint('   User is Admin: $isAdmin');

      // Fetch from API
      await _fetchApiSalarySlip(employeeId, token);

    } catch (e) {
      _error = 'Unexpected error: ${e.toString()}';
      debugPrint('❌ Error in fetchSalarySlip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch from API
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
        _handleSuccessfulResponse(response.body, employeeId);
      } else {
        _handleErrorResponse(response, employeeId);
      }
    } catch (e) {
      _error = 'Network error: Could not connect to server.';
      debugPrint('❌ Network error: $e');
    }
  }

  // Handle successful response
  void _handleSuccessfulResponse(String responseBody, int employeeId) {
    try {
      debugPrint('✅ API call successful!');

      final responseData = json.decode(responseBody);

      // Debug: Show response structure
      debugPrint('📋 Response keys: ${(responseData as Map).keys.join(', ')}');

      // Check if response has expected structure
      if (responseData.containsKey('month') &&
          responseData.containsKey('employee') &&
          responseData.containsKey('payroll_calculation')) {

        try {
          _salarySlip = SalarySlip.fromJson(responseData);
          debugPrint('🎉 Successfully parsed salary slip for ${_salarySlip!.employee.name}');
          debugPrint('💰 Net payable: PKR ${_salarySlip!.payrollCalculation.netPayable.toStringAsFixed(2)}');
          debugPrint('📅 Month: ${_salarySlip!.month}');
          debugPrint('👤 Employee: ${_salarySlip!.employee.name} (${_salarySlip!.employee.empId})');

          // Log some details for debugging
          debugPrint('📊 Present days: ${_salarySlip!.attendanceSummary.presentDays}');
          debugPrint('💵 Basic salary: ${_salarySlip!.salaryStructure.basicSalary}');

        } catch (e) {
          _error = 'Error parsing salary slip data: ${e.toString()}';
          debugPrint('❌ Parse error: $e');
          debugPrint('Response data: $responseData');
        }
      } else {
        _error = 'Invalid response format: Missing required fields';
        debugPrint('❌ Response missing required fields');
        debugPrint('Available fields: ${responseData.keys.join(', ')}');
      }
    } catch (e) {
      _error = 'Error processing response: ${e.toString()}';
      debugPrint('❌ JSON processing error: $e');
    }
  }

  // Handle error responses
  void _handleErrorResponse(http.Response response, int employeeId) {
    debugPrint('Response body: ${response.body}');

    switch (response.statusCode) {
      case 404:
        _error = '❌ Salary slip not found\n\n'
            'Employee ID: $employeeId\n'
            'Month: $_selectedMonth\n\n'
            '💡 **Try this:**\n'
            '• Employee 29 with month 2026-02\n'
            '• Employee 30 with month 2026-02\n\n'
            '⚠️ **Possible reasons:**\n'
            '• No salary record for this employee/month\n'
            '• Salary processing is incomplete';
        break;
      case 401:
        _error = '🔐 Authentication failed\n\nPlease login again.';
        break;
      case 403:
        _error = '⛔ Access denied\n\nYou are not authorized to view this salary slip.';
        break;
      case 500:
        _error = '⚙️ Server error\n\nPlease try again later or contact support.';
        break;
      default:
        _error = 'Error ${response.statusCode}: ${response.body}';
    }
  }

  // Clear data
  void clearSalarySlip() {
    _salarySlip = null;
    _error = null;
    notifyListeners();
  }

  // Initialize provider
  Future<void> initialize() async {
    debugPrint('🎬 Initializing SalarySlipProvider...');

    // Set default month to current month
    if (_selectedMonth.isEmpty) {
      final now = DateTime.now();
      _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }

    // Set default employee ID to current user
    if (_selectedEmployeeId == null) {
      _selectedEmployeeId = await _getCurrentEmployeeId();
    }

    // Load employees for dropdown
    await loadEmployeesForDropdown();

    debugPrint('✅ Provider initialized');
    debugPrint('   Month: $_selectedMonth');
    debugPrint('   Employee ID: $_selectedEmployeeId');
    debugPrint('   Total employees: ${_employees.length}');

    // Debug print employee list
    for (var emp in _employees) {
      debugPrint('   - ${emp['name']} (ID: ${emp['id']})');
    }
  }
}