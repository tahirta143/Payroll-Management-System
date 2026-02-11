import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:payroll_app/Utility/global_url.dart';
import 'package:payroll_app/screen/attendance/attendance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/attendance_model/attendance_model.dart';
import '../../model/model_provider/user_model.dart';
import '../../screen/attendance/add_edit_attendance_screen.dart';

class AttendanceProvider extends ChangeNotifier {
  // Attendance Data
  List<Attendance> _attendance = [];
  List<Attendance> _filteredAttendance = [];
  List<Employee> _employees = [];
  List<Department> _departments = [];
  List<DutyShift> _dutyShifts = [];

  // Loading States
  bool _isLoading = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingEmployees = false;
  bool _isLoadingDepartments = false;
  bool _isLoadingDutyShifts = false;

  // Error
  String _error = '';

  // Filtering
  String _searchQuery = '';
  String _selectedDepartmentFilter = 'All';
  String _selectedEmployeeFilter = '';
  String _selectedMonthFilter = 'All';
  List<String> _departmentNames = ['All'];
  List<String> _availableMonths = ['All'];

  // User Data
  UserRole _userRole = UserRole.user;
  String _userName = '';
  int _userId = 0;
  String _employeeCode = '';

  // Getters
  List<Attendance> get attendance => _filteredAttendance;
  List<Attendance> get allAttendance => _attendance;
  List<Employee> get employees => _employees;
  List<Department> get departments => _departments;
  List<DutyShift> get dutyShifts => _dutyShifts;
  bool get isLoading => _isLoading;
  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingEmployees => _isLoadingEmployees;
  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isLoadingDutyShifts => _isLoadingDutyShifts;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedDepartmentFilter => _selectedDepartmentFilter;
  String get selectedEmployeeFilter => _selectedEmployeeFilter;
  String get selectedMonthFilter => _selectedMonthFilter;
  List<String> get departmentNames => _departmentNames;
  List<String> get availableMonths => _availableMonths;

  // User Role Getters
  UserRole get userRole => _userRole;
  String get userName => _userName;
  int get userId => _userId;
  String get employeeCode => _employeeCode;
  bool get isAdmin => _userRole == UserRole.admin;
  bool get isUser => _userRole == UserRole.user;

  // Statistics - Only show for admin
  // Update ALL statistics getters to work for both admin and staff
  int get totalPresent => _attendance.where((a) => a.isPresent).length;
  int get totalLate => _attendance.where((a) => a.lateMinutes > 0).length;
  int get totalAbsent {
    // Count records where both timeIn and timeOut are empty or status contains 'absent'
    return _attendance.where((a) {
      return (a.timeIn.isEmpty && a.timeOut.isEmpty) ||
          a.status.toLowerCase().contains('absent');
    }).length;
  }

  int get totalOvertime => _attendance.where((a) => a.overtimeMinutes > 0).length;
  // Get employees by selected department - FIXED VERSION
  List<Employee> get filteredEmployees {
    if (_selectedDepartmentFilter == 'All' || _selectedDepartmentFilter.isEmpty) {
      return []; // Empty when "All" departments is selected
    } else {
      // Debug: Print all employees and their departments
      print('=== FILTERING EMPLOYEES ===');
      print('Selected department: $_selectedDepartmentFilter');
      print('Total employees: ${_employees.length}');

      // Clean and normalize the selected department
      final selectedDept = _selectedDepartmentFilter.trim().toLowerCase();

      final filtered = _employees.where((employee) {
        // Clean and normalize employee department
        final employeeDept = employee.department?.trim().toLowerCase() ?? '';

        // Multiple matching strategies
        bool matches = false;

        // 1. Exact match (case-insensitive)
        if (employeeDept == selectedDept) {
          matches = true;
        }
        // 2. Contains match (partial)
        else if (employeeDept.contains(selectedDept) || selectedDept.contains(employeeDept)) {
          matches = true;
        }
        // 3. Check for common department variations
        else if (_isDepartmentMatch(selectedDept, employeeDept)) {
          matches = true;
        }

        if (matches) {
          print('Found employee: ${employee.name} in ${employee.department} (cleaned: $employeeDept)');
        }
        return matches;
      }).toList();

      print('Filtered employees count: ${filtered.length}');
      return filtered;
    }
  }

  // Helper method to check department matches with common variations
  bool _isDepartmentMatch(String selectedDept, String employeeDept) {
    if (selectedDept.isEmpty || employeeDept.isEmpty) return false;

    // Common department abbreviations and variations
    final departmentVariations = {
      'it': ['information technology', 'tech', 'technical', 'software', 'development'],
      'hr': ['human resources', 'personnel', 'recruitment'],
      'finance': ['accounting', 'accounts', 'treasury'],
      'marketing': ['sales', 'advertising', 'promotion'],
      'operations': ['production', 'manufacturing', 'logistics'],
      'admin': ['administration', 'administrative', 'office'],
      'support': ['customer service', 'helpdesk', 'service'],
    };

    // Check if both departments match any common variation
    for (var entry in departmentVariations.entries) {
      final key = entry.key;
      final variations = entry.value;

      // Check if selected department matches the key or any variation
      final selectedMatches = selectedDept == key ||
          variations.any((v) => selectedDept.contains(v) || v.contains(selectedDept));

      // Check if employee department matches the key or any variation
      final employeeMatches = employeeDept == key ||
          variations.any((v) => employeeDept.contains(v) || v.contains(employeeDept));

      if (selectedMatches && employeeMatches) {
        return true;
      }
    }

    return false;
  }

  // Get token from shared preferences
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }
      return token;
    } catch (e) {
      throw Exception('Failed to get authentication token: $e');
    }
  }

  // Initialize user data from SharedPreferences
  Future<void> _initializeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get basic user info with fallbacks
      _userName = prefs.getString('employee_name') ??
          prefs.getString('user_name') ??
          '';
      _userId = prefs.getInt('user_id') ?? 0;
      _employeeCode = prefs.getString('employee_code') ?? '';

      // Try multiple sources for role
      String roleString = 'user';

      // 1. Direct user_role field
      final directRole = prefs.getString('user_role');
      if (directRole != null && directRole.isNotEmpty) {
        roleString = directRole;
      }
      // 2. Check userData JSON
      else {
        final userDataString = prefs.getString('userData');
        if (userDataString != null && userDataString.isNotEmpty) {
          try {
            final userData = json.decode(userDataString) as Map<String, dynamic>;
            final possibleRoleFields = [
              'role_label',
              'role',
              'user_type',
              'type',
              'role_name',
              'roleName'
            ];

            for (var field in possibleRoleFields) {
              if (userData[field] != null && userData[field].toString().isNotEmpty) {
                roleString = userData[field].toString();
                break;
              }
            }
          } catch (e) {
            print('Error parsing userData: $e');
          }
        }
      }

      // Convert to lowercase for comparison
      roleString = roleString.toLowerCase();

      // Check if user is admin
      final adminKeywords = [
        'admin',
        'administrator',
        'super admin',
        'superadmin',
        'super_admin',
        'manager',
        'super_user',
        'administration'
      ];

      final isAdminUser = adminKeywords.any((keyword) => roleString.contains(keyword));

      if (isAdminUser) {
        _userRole = UserRole.admin;
      } else {
        _userRole = UserRole.user;
      }

    } catch (e) {
      print('Error initializing user data: $e');
      _userRole = UserRole.user; // Default to user on error
    }
  }

  // FETCH ALL DATA - Main method to load everything
  Future<void> fetchAllData() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Initialize user data first
      await _initializeUserData();

      // Check if user is admin
      if (isAdmin) {
        // For admin: fetch all data
        await Future.wait([
          fetchAttendance(),
          fetchEmployees(),
          fetchDepartments(),
          fetchDutyShifts(),
        ]);
      } else {
        // For staff: fetch only their own attendance and basic info
        await Future.wait([
          fetchAttendance(), // This will now handle staff filtering
          fetchEmployees(), // Still fetch employees for reference
        ]);
      }

    } catch (e) {
      _error = 'Failed to load data: $e';
      print('Error fetching all data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // GET - Fetch all attendance (handles both admin and staff)
  Future<void> fetchAttendance() async {
    try {
      _isLoadingAttendance = true;
      _error = '';
      notifyListeners();

      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> attendanceList = [];

        if (data is Map) {
          if (data.containsKey('attendance')) {
            attendanceList = data['attendance'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            attendanceList = data['data'] as List<dynamic>;
          }
        } else if (data is List) {
          attendanceList = data;
        }

        // Parse all attendance
        _attendance = attendanceList
            .map((json) => Attendance.fromJson(json))
            .toList();

        // SORT attendance by date ASCENDING (oldest first)
        _attendance.sort((a, b) => a.date.compareTo(b.date));

        // DEBUG: Print date information
        print('=== ATTENDANCE DATES DEBUG ===');
        if (_attendance.isNotEmpty) {
          print('Total attendance records: ${_attendance.length}');
          for (int i = 0; i < min(5, _attendance.length); i++) {
            final record = _attendance[i];
            print('Record $i: Date = ${record.date}');
            print('  Formatted: ${_formatMonthForFilter(record.date)}');
          }
        }

        // Extract unique months for filtering
        _extractMonthsFromData();

        // If user is not admin, filter to show only their own attendance
        if (!isAdmin) {
          await _filterStaffAttendance();
        }

        // Extract unique departments and employees
        _extractFilters();

        // Apply current filters
        _applyFilters();

        print('=== ATTENDANCE FETCH COMPLETE ===');
        print('Total filtered records: ${_filteredAttendance.length}');
        print('Available months: ${_availableMonths.length}');
        if (_availableMonths.length > 1) {
          print('Month list: ${_availableMonths.sublist(1)}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden - You don\'t have permission to view attendance');
      } else {
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAttendance: $e');
      _error = e.toString();
      _attendance = [];
      _filteredAttendance = [];
      _availableMonths = ['All'];
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  // Method to filter attendance for staff users
  // Update the _filterStaffAttendance method
  Future<void> _filterStaffAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get employee ID from multiple sources
      final employeeId = prefs.getString('employee_id') ??
          prefs.getString('emp_id') ??
          prefs.getInt('user_id')?.toString() ??
          '';

      final employeeCode = prefs.getString('employee_code') ??
          prefs.getString('emp_code') ??
          '';

      final userName = prefs.getString('employee_name') ??
          prefs.getString('user_name') ??
          '';

      print('=== STAFF FILTERING DEBUG ===');
      print('Employee ID from prefs: $employeeId');
      print('Employee Code from prefs: $employeeCode');
      print('User Name from prefs: $userName');
      print('Total attendance records before filtering: ${_attendance.length}');

      if (employeeId.isEmpty && employeeCode.isEmpty) {
        print('No employee ID or code found for staff user');
        _attendance = [];
        return;
      }

      final List<Attendance> filteredList = [];

      for (final attendance in _attendance) {
        bool matches = false;

        // Method 1: Compare employeeId as string
        if (employeeId.isNotEmpty && attendance.employeeId.toString() == employeeId) {
          matches = true;
          print('Matched by employeeId: ${attendance.employeeId} == $employeeId');
        }
        // Method 2: Compare employee codes
        else if (employeeCode.isNotEmpty &&
            attendance.empId.isNotEmpty &&
            attendance.empId.toLowerCase() == employeeCode.toLowerCase()) {
          matches = true;
          print('Matched by empId: ${attendance.empId} == $employeeCode');
        }
        // Method 3: Compare by name (exact match)
        else if (userName.isNotEmpty &&
            attendance.employeeName.isNotEmpty &&
            attendance.employeeName.toLowerCase() == userName.toLowerCase()) {
          matches = true;
          print('Matched by name: ${attendance.employeeName} == $userName');
        }

        if (matches) {
          filteredList.add(attendance);
          print('Added record: ${attendance.employeeName} - ${attendance.date}');
        }
      }

      _attendance = filteredList;

      print('Staff attendance filtered: ${_attendance.length} records found');

      // If no matches found, print debug info
      if (_attendance.isEmpty) {
        print('=== NO MATCHES FOUND DEBUG ===');
        print('Trying alternative matching...');

        // Print first few records for debugging
        final sampleSize = min(5, _attendance.length);
        for (int i = 0; i < sampleSize; i++) {
          final record = _attendance[i];
          print('Record $i:');
          print('  Employee ID: ${record.employeeId}');
          print('  Emp Code: ${record.empId}');
          print('  Employee Name: ${record.employeeName}');
        }

        await _tryAlternativeMatching();
      }

    } catch (e) {
      print('Error filtering staff attendance: $e');
      _attendance = [];
    }
  }
  // ADD THIS METHOD: Fetch attendance for specific employee
  Future<void> fetchAttendanceForEmployee(String employeeId) async {
    try {
      _isLoadingAttendance = true;
      _error = '';
      notifyListeners();

      final token = await _getToken();

      // Try different endpoints based on employee ID format
      String endpoint;

      if (int.tryParse(employeeId) != null) {
        // If employeeId is numeric
        endpoint = '${GlobalUrls.baseurl}/api/attendance?employee_id=$employeeId';
      } else {
        // If employeeId is string (employee code)
        endpoint = '${GlobalUrls.baseurl}/api/attendance?emp_id=$employeeId';
      }

      print('Fetching attendance from: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> attendanceList = [];

        if (data is Map) {
          if (data.containsKey('attendance')) {
            attendanceList = data['attendance'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            attendanceList = data['data'] as List<dynamic>;
          } else if (data.containsKey('employee_attendance')) {
            attendanceList = data['employee_attendance'] as List<dynamic>;
          }
        } else if (data is List) {
          attendanceList = data;
        }

        if (attendanceList.isEmpty) {
          // Try alternative endpoints
          await _tryAlternativeEmployeeEndpoints(employeeId, token);
        } else {
          // Parse attendance
          _attendance = attendanceList
              .map((json) => Attendance.fromJson(json))
              .toList();

          // SORT attendance by date ASCENDING (oldest first)
          _attendance.sort((a, b) => a.date.compareTo(b.date));

          // Extract unique months for filtering
          _extractMonthsFromData();

          // Extract unique departments and employees
          _extractFilters();

          // Apply current filters
          _applyFilters();

          print('Employee attendance fetched successfully: ${_attendance.length} records');
        }
      } else if (response.statusCode == 404) {
        // Try alternative endpoints
        await _tryAlternativeEmployeeEndpoints(employeeId, token);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden - You don\'t have permission to view attendance');
      } else {
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAttendanceForEmployee: $e');
      _error = e.toString();
      _attendance = [];
      _filteredAttendance = [];
      _availableMonths = ['All'];
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  // Try alternative endpoints for employee attendance
  Future<void> _tryAlternativeEmployeeEndpoints(String employeeId, String token) async {
    final endpoints = [
      '${GlobalUrls.baseurl}/api/employees/$employeeId/attendance',
      '${GlobalUrls.baseurl}/api/employee/$employeeId/attendance',
      '${GlobalUrls.baseurl}/api/attendance/employee/$employeeId',
      '${GlobalUrls.baseurl}/api/attendance/emp/$employeeId',
      '${GlobalUrls.baseurl}/api/attendance?user_id=$employeeId',
    ];

    for (var endpoint in endpoints) {
      try {
        print('Trying alternative endpoint: $endpoint');

        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final dynamic data = json.decode(response.body);
          List<dynamic> attendanceList = [];

          if (data is Map) {
            if (data.containsKey('attendance')) {
              attendanceList = data['attendance'] as List<dynamic>;
            } else if (data.containsKey('data')) {
              attendanceList = data['data'] as List<dynamic>;
            } else if (data.containsKey('employee_attendance')) {
              attendanceList = data['employee_attendance'] as List<dynamic>;
            }
          } else if (data is List) {
            attendanceList = data;
          }

          if (attendanceList.isNotEmpty) {
            // Parse attendance
            _attendance = attendanceList
                .map((json) => Attendance.fromJson(json))
                .toList();

            // SORT attendance by date ASCENDING (oldest first)
            _attendance.sort((a, b) => a.date.compareTo(b.date));

            // Extract unique months for filtering
            _extractMonthsFromData();

            // Extract unique departments and employees
            _extractFilters();

            // Apply current filters
            _applyFilters();

            print('Found attendance via alternative endpoint: $endpoint');
            print('Total records: ${_attendance.length}');
            return;
          }
        }
      } catch (e) {
        print('Error trying endpoint $endpoint: $e');
        continue;
      }
    }

    // If all endpoints fail, throw error
    throw Exception('No attendance data found for employee ID: $employeeId');
  }

  // Method to extract months from attendance data
  void _extractMonthsFromData() {
    try {
      final monthsSet = <String>{};

      for (final attendance in _attendance) {
        final monthName = _formatMonthForFilter(attendance.date);
        if (monthName.isNotEmpty) {
          monthsSet.add(monthName);
        }
      }

      // Sort months chronologically (most recent first)
      final sortedMonths = monthsSet.toList()
        ..sort((a, b) {
          try {
            final dateA = _parseMonthFromFilter(a);
            final dateB = _parseMonthFromFilter(b);
            return dateB.compareTo(dateA); // Most recent first
          } catch (e) {
            return 0;
          }
        });

      _availableMonths = ['All', ...sortedMonths];

    } catch (e) {
      _availableMonths = ['All'];
    }
  }

  // Helper method to format date for month filter
  String _formatMonthForFilter(DateTime date) {
    try {
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  // Helper method to parse month from filter string
  DateTime _parseMonthFromFilter(String monthFilter) {
    try {
      return DateFormat('MMMM yyyy').parse(monthFilter);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Month Filter Setter
  void setMonthFilter(String month) {

      _selectedMonthFilter = month;
      _applyFilters();
      notifyListeners();

  }

  // Update the _applyFilters method
  // Update the _applyFilters method to ensure admin sees all data when no filters are selected
  void _applyFilters() {
    _filteredAttendance = _attendance.where((attendance) {
      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
              attendance.employeeName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              attendance.empId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              attendance.departmentName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

      // Department filter (only for admin)
      final matchesDepartment =
          !isAdmin || // If not admin, always true
              _selectedDepartmentFilter == 'All' ||
              attendance.departmentName == _selectedDepartmentFilter;

      // Employee filter (only for admin)
      final matchesEmployee =
          !isAdmin || // If not admin, always true
              _selectedDepartmentFilter == 'All' ||
              _selectedEmployeeFilter.isEmpty ||
              attendance.employeeName == _selectedEmployeeFilter;

      // Month filter (works for both admin and staff)
      bool matchesMonth = true;
      if (_selectedMonthFilter != 'All') {
        final recordMonth = _formatMonthForFilter(attendance.date);
        matchesMonth = recordMonth == _selectedMonthFilter;
      }

      return matchesSearch && matchesDepartment && matchesEmployee && matchesMonth;
    }).toList();

    // Debug: Print filter results
    print('=== FILTER DEBUG ===');
    print('Is Admin: $isAdmin');
    print('Total records: ${_attendance.length}');
    print('Filtered records: ${_filteredAttendance.length}');
    print('Search query: $_searchQuery');
    print('Department filter: $_selectedDepartmentFilter');
    print('Employee filter: $_selectedEmployeeFilter');
    print('Month filter: $_selectedMonthFilter');
  }
  // Department filter setter
  void setDepartmentFilter(String department) {
    if (isAdmin) {
      _selectedDepartmentFilter = department;
      _selectedEmployeeFilter = ''; // Reset employee filter when department changes
      _applyFilters();
      notifyListeners();
    }
  }

  // Employee filter setter
  void setEmployeeFilter(String employee) {
    if (isAdmin && employee.isNotEmpty) {
      _selectedEmployeeFilter = employee;
      _applyFilters();
      notifyListeners();
    }
  }

  // Try alternative matching methods when standard methods fail
  // Update the _tryAlternativeMatching method
  Future<void> _tryAlternativeMatching() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Handle both int and string employee IDs
      final additionalIds = <String>[];

      // Try to get int values
      final intId = prefs.getInt('employee_id');
      if (intId != null) {
        additionalIds.add(intId.toString());
      }

      final intEmpId = prefs.getInt('emp_id');
      if (intEmpId != null) {
        additionalIds.add(intEmpId.toString());
      }

      // Try to get string values
      final stringEmpId = prefs.getString('employee_id');
      if (stringEmpId != null && stringEmpId.isNotEmpty) {
        additionalIds.add(stringEmpId);
      }

      final stringId = prefs.getString('emp_id');
      if (stringId != null && stringId.isNotEmpty) {
        additionalIds.add(stringId);
      }

      final additionalCodes = [
        prefs.getString('emp_code'),
        prefs.getString('staff_id'),
      ].whereType<String>().where((code) => code.isNotEmpty).toList();

      print('=== ALTERNATIVE MATCHING DEBUG ===');
      print('Additional IDs to try: $additionalIds');
      print('Additional Codes to try: $additionalCodes');

      if (additionalIds.isNotEmpty || additionalCodes.isNotEmpty) {
        final List<Attendance> filteredList = [];

        for (final attendance in _attendance) {
          bool matches = false;

          // Try additional IDs (as strings)
          for (var id in additionalIds) {
            if (attendance.employeeId.toString() == id) {
              matches = true;
              print('Alternative match by ID: ${attendance.employeeId} == $id');
              break;
            }
          }

          if (!matches && attendance.empId.isNotEmpty) {
            for (var code in additionalCodes) {
              if (attendance.empId.toLowerCase() == code.toLowerCase()) {
                matches = true;
                print('Alternative match by code: ${attendance.empId} == $code');
                break;
              }
            }
          }

          if (matches) {
            filteredList.add(attendance);
          }
        }

        if (filteredList.isNotEmpty) {
          _attendance = filteredList;
          print('Alternative matching found ${filteredList.length} records');
        } else {
          print('Alternative matching found no records');
        }
      } else {
        print('No alternative IDs or codes to try');
      }
    } catch (e) {
      print('Error in alternative matching: $e');
    }
  }

  // GET - Fetch employees
  Future<void> fetchEmployees() async {
    try {
      _isLoadingEmployees = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> employeesList = [];

        if (data is Map && data.containsKey('employees')) {
          employeesList = data['employees'] as List<dynamic>;
        }

        _employees = [];

        if (employeesList.isNotEmpty) {
          for (var i = 0; i < employeesList.length; i++) {
            try {
              final item = employeesList[i];
              if (item is Map<String, dynamic>) {
                final employee = _parseEmployeeMap(item);
                if (employee.id != 0 && employee.name.isNotEmpty) {
                  _employees.add(employee);
                }
              }
            } catch (e) {
              print('Error parsing employee at index $i: $e');
            }
          }
        }

        // Debug: Print all employees
        print('=== ALL EMPLOYEES ===');
        for (var emp in _employees) {
          print('Employee: ${emp.name}, Department: ${emp.department}');
        }

        if (_employees.isEmpty) {
          _employees = [
            Employee(id: 1, name: 'John Doe', empId: 'EMP001', department: 'IT'),
            Employee(id: 2, name: 'Jane Smith', empId: 'EMP002', department: 'HR'),
          ];
        }

      } else {
        _employees = [
          Employee(id: 1, name: 'John Doe', empId: 'EMP001', department: 'IT'),
          Employee(id: 2, name: 'Jane Smith', empId: 'EMP002', department: 'HR'),
        ];
      }
    } catch (e) {
      print('Error fetching employees: $e');
      _employees = [
        Employee(id: 1, name: 'John Doe', empId: 'EMP001', department: 'IT'),
        Employee(id: 2, name: 'Jane Smith', empId: 'EMP002', department: 'HR'),
      ];
    } finally {
      _isLoadingEmployees = false;
      notifyListeners();
    }
  }

  // Helper method to parse employee from map
  // Update the _parseEmployeeMap method in your AttendanceProvider

// Helper method to parse employee from map
  Employee _parseEmployeeMap(Map<String, dynamic> data) {
    try {
      final id = _parseInt(data['id']) ??
          _parseInt(data['employee_id']) ??
          _parseInt(data['user_id']) ?? 0;

      final name = data['name']?.toString() ??
          data['full_name']?.toString() ??
          data['employee_name']?.toString() ??
          data['first_name']?.toString() ??
          'Unknown';

      final empId = data['emp_id']?.toString() ??
          data['employee_code']?.toString() ??
          data['code']?.toString() ??
          data['staff_id']?.toString() ??
          'N/A';

      // FIX: Handle department which might be a Map or a string
      String department = 'Unknown Department';

      if (data['department'] != null) {
        if (data['department'] is Map) {
          // Department is a Map, extract the name
          final deptMap = data['department'] as Map<String, dynamic>;
          department = deptMap['name']?.toString() ?? 'Unknown Department';
        } else if (data['department'] is String) {
          // Department is already a string
          department = data['department'] as String;
        }
      } else if (data['department_name'] != null) {
        // Try department_name field
        department = data['department_name'].toString();
      } else if (data['dept'] != null) {
        // Try dept field
        department = data['dept'].toString();
      } else if (data['department_id'] != null) {
        // Try department_id field
        department = data['department_id'].toString();
      }

      // Trim and clean department name
      department = department.trim();

      return Employee(
        id: id,
        name: name.trim(),
        empId: empId.trim(),
        department: department,
      );
    } catch (e) {
      print('Error in _parseEmployeeMap: $e');
      return Employee(
        id: 0,
        name: 'Error',
        empId: 'N/A',
        department: 'Error',
      );
    }
  }
  // Helper to parse integer from dynamic value
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // GET - Fetch departments
  Future<void> fetchDepartments() async {
    try {
      _isLoadingDepartments = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/departments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> departmentsList = [];

        if (data is Map) {
          if (data.containsKey('departments')) {
            departmentsList = data['departments'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            departmentsList = data['data'] as List<dynamic>;
          }
        } else if (data is List) {
          departmentsList = data;
        }

        _departments = departmentsList
            .map((d) => Department.fromJson(d))
            .toList();

        // Extract department names for dropdown
        final departmentSet = _departments
            .map((dept) => dept.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet();
        _departmentNames = ['All', ...departmentSet];

        // Debug: Print all departments
        print('=== ALL DEPARTMENTS ===');
        for (var dept in _departments) {
          print('Department: ${dept.name}');
        }

        if (_departments.isEmpty) {
          _departments = [
            Department(id: 1, name: 'IT', description: 'Information Technology'),
            Department(id: 2, name: 'HR', description: 'Human Resources'),
            Department(id: 3, name: 'Finance', description: 'Finance Department'),
            Department(id: 4, name: 'Operations', description: 'Operations Department'),
          ];
          _departmentNames = ['All', 'IT', 'HR', 'Finance', 'Operations'];
        }

      } else {
        _departments = [
          Department(id: 1, name: 'IT'),
          Department(id: 2, name: 'HR'),
          Department(id: 3, name: 'Finance'),
          Department(id: 4, name: 'Operations'),
        ];
        _departmentNames = ['All', 'IT', 'HR', 'Finance', 'Operations'];
      }
    } catch (e) {
      print('Error fetching departments: $e');
      _departments = [
        Department(id: 1, name: 'IT'),
        Department(id: 2, name: 'HR'),
        Department(id: 3, name: 'Finance'),
        Department(id: 4, name: 'Operations'),
      ];
      _departmentNames = ['All', 'IT', 'HR', 'Finance', 'Operations'];
    } finally {
      _isLoadingDepartments = false;
      notifyListeners();
    }
  }

  // GET - Fetch duty shifts
  Future<void> fetchDutyShifts() async {
    try {
      _isLoadingDutyShifts = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/duty-shifts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> dutyShiftsList = [];

        if (data is Map) {
          if (data.containsKey('duty_shifts')) {
            dutyShiftsList = data['duty_shifts'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            dutyShiftsList = data['data'] as List<dynamic>;
          }
        } else if (data is List) {
          dutyShiftsList = data;
        }

        _dutyShifts = dutyShiftsList.map((s) => DutyShift.fromJson(s)).toList();

        if (_dutyShifts.isEmpty) {
          _dutyShifts = [
            DutyShift(
              id: 1,
              name: 'Morning Shift',
              startTime: '09:00',
              endTime: '17:00',
              description: 'Regular office hours',
            ),
            DutyShift(
              id: 2,
              name: 'Evening Shift',
              startTime: '14:00',
              endTime: '22:00',
              description: 'Evening shift',
            ),
            DutyShift(
              id: 3,
              name: 'Night Shift',
              startTime: '22:00',
              endTime: '06:00',
              description: 'Night shift',
            ),
          ];
        }

      } else {
        _dutyShifts = [
          DutyShift(id: 1, name: 'Morning Shift', startTime: '09:00', endTime: '17:00'),
          DutyShift(id: 2, name: 'Evening Shift', startTime: '14:00', endTime: '22:00'),
          DutyShift(id: 3, name: 'Night Shift', startTime: '22:00', endTime: '06:00'),
        ];
      }
    } catch (e) {
      print('Error fetching duty shifts: $e');
      _dutyShifts = [
        DutyShift(id: 1, name: 'Morning Shift', startTime: '09:00', endTime: '17:00'),
        DutyShift(id: 2, name: 'Evening Shift', startTime: '14:00', endTime: '22:00'),
        DutyShift(id: 3, name: 'Night Shift', startTime: '22:00', endTime: '06:00'),
      ];
    } finally {
      _isLoadingDutyShifts = false;
      notifyListeners();
    }
  }

  // POST - Create new attendance (FIXED)
  Future<bool> createAttendance(AttendanceCreateDTO dto) async {
    if (!isAdmin) {
      _error = 'Only administrators can create attendance records';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.post(
        Uri.parse('${GlobalUrls.baseurl}/api/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(dto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAttendance = Attendance.fromJson(
          responseData['attendance'] ?? responseData['data'] ?? {},
        );
        _attendance.insert(0, newAttendance);
        _extractMonthsFromData();
        _applyFilters();

        return true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to create attendance';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error creating attendance: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PUT - Update attendance (FIXED)
  Future<bool> updateAttendance(int id, AttendanceCreateDTO dto) async {
    if (!isAdmin) {
      _error = 'Only administrators can update attendance records';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.put(
        Uri.parse('${GlobalUrls.baseurl}/api/attendance/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(dto.toJson()),
      );

      if (response.statusCode == 200) {
        final index = _attendance.indexWhere((a) => a.id == id);
        if (index != -1) {
          final responseData = json.decode(response.body);
          final updatedAttendance = Attendance.fromJson(
            responseData['attendance'] ?? responseData['data'] ?? {},
          );
          _attendance[index] = updatedAttendance;
          _extractMonthsFromData();
          _applyFilters();
        }

        return true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to update attendance';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error updating attendance: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // DELETE - Remove attendance (FIXED)
  Future<bool> deleteAttendance(int id) async {
    if (!isAdmin) {
      _error = 'Only administrators can delete attendance records';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('${GlobalUrls.baseurl}/api/attendance/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _attendance.removeWhere((attendance) => attendance.id == id);
        _extractMonthsFromData();
        _applyFilters();

        return true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to delete attendance';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error deleting attendance: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods for filtering
  void _extractFilters() {
    if (isAdmin) {
      // Extract unique departments from attendance
      final departmentSet = _attendance
          .map((attendance) => attendance.departmentName.trim())
          .where((dept) => dept.isNotEmpty)
          .toSet();

      // Combine with department list from API
      final allDepartments = {...departmentSet, ..._departments.map((d) => d.name.trim())};
      _departmentNames = ['All', ...allDepartments];
    } else {
      _departmentNames = ['All'];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    if (isAdmin) {
      _selectedDepartmentFilter = 'All';
      _selectedEmployeeFilter = '';
      _selectedMonthFilter = 'All';
    }
    _applyFilters();
    notifyListeners();
  }

  // Get attendance for specific date
  List<Attendance> getAttendanceByDate(DateTime date) {
    return _attendance.where((attendance) {
      return attendance.date.year == date.year &&
          attendance.date.month == date.month &&
          attendance.date.day == date.day;
    }).toList();
  }

  // Get attendance for specific employee
  List<Attendance> getAttendanceByEmployee(String employeeName) {
    return _attendance
        .where((attendance) => attendance.employeeName == employeeName)
        .toList();
  }

  // Get today's summary (only for admin)
  Map<String, dynamic> getTodaySummary() {
    if (!isAdmin) {
      return {
        'total': 0,
        'present': 0,
        'late': 0,
        'absent': 0,
        'onTime': 0,
      };
    }

    final today = DateTime.now();
    final todayAttendance = getAttendanceByDate(today);

    return {
      'total': todayAttendance.length,
      'present': todayAttendance.where((a) => a.isPresent).length,
      'late': todayAttendance.where((a) => a.lateMinutes > 0).length,
      'absent': todayAttendance.where((a) => !a.isPresent).length,
      'onTime': todayAttendance
          .where((a) => a.lateMinutes == 0 && a.isPresent)
          .length,
    };
  }

  // Navigation methods
  void navigateToAddScreen(BuildContext context) async {
    if (!isAdmin) {
      _showPermissionError(context, 'add attendance records');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await Future.wait([
        fetchEmployees(),
        fetchDepartments(),
        fetchDutyShifts(),
      ]);

      _isLoading = false;
      notifyListeners();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditAttendanceScreen(
            mode: AttendanceMode.add,
            onAttendanceSaved: () {
              fetchAttendance();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance added successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load data: $e';
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToEditScreen(BuildContext context, Attendance attendance) async {
    if (!isAdmin) {
      _showPermissionError(context, 'edit attendance records');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await Future.wait([
        fetchEmployees(),
        fetchDepartments(),
        fetchDutyShifts(),
      ]);

      _isLoading = false;
      notifyListeners();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditAttendanceScreen(
            mode: AttendanceMode.edit,
            attendance: attendance,
            onAttendanceSaved: () {
              fetchAttendance();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance updated successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load data: $e';
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToViewScreen(BuildContext context, Attendance attendance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(),
      ),
    );
  }

  void _showPermissionError(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Only administrators can $action'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}