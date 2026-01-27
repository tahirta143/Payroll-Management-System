import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String _selectedEmployeeFilter = 'All';
  List<String> _departmentNames = ['All'];
  List<String> _employeeNames = ['All'];

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
  List<String> get departmentNames => _departmentNames;
  List<String> get employeeNames => _employeeNames;

  // User Role Getters
  UserRole get userRole => _userRole;
  String get userName => _userName;
  int get userId => _userId;
  String get employeeCode => _employeeCode;
  bool get isAdmin => _userRole == UserRole.admin;
  bool get isUser => _userRole == UserRole.user;

  // Statistics - Only show for admin
  int get totalPresent => isAdmin ? _attendance.where((a) => a.isPresent).length : 0;
  int get totalLate => isAdmin ? _attendance.where((a) => a.lateMinutes > 0).length : 0;
  int get totalAbsent => isAdmin ? _attendance.where((a) => !a.isPresent).length : 0;
  int get totalOvertime => isAdmin ? _attendance.where((a) => a.overtimeMinutes > 0).length : 0;

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

  // Debug method to print all SharedPreferences
  Future<void> _debugSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('=== SHARED PREFERENCES DEBUG ===');

      final keys = prefs.getKeys();
      for (var key in keys) {
        final value = prefs.get(key);
        print('$key: $value (type: ${value.runtimeType})');
      }

      // Check specific user-related keys
      print('\n=== SPECIFIC USER KEYS ===');
      final specificKeys = ['user_id', 'employee_id', 'emp_id', 'employee_code',
        'employee_name', 'user_name', 'user_role', 'userData'];
      for (var key in specificKeys) {
        final value = prefs.get(key);
        print('$key: $value');
      }
    } catch (e) {
      print('Error debugging SharedPreferences: $e');
    }
  }

  // Initialize user data from SharedPreferences
  Future<void> _initializeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('=== INITIALIZING USER DATA ===');

      // Debug SharedPreferences first
      await _debugSharedPreferences();

      // Get basic user info with fallbacks
      _userName = prefs.getString('employee_name') ??
          prefs.getString('user_name') ??
          '';
      _userId = prefs.getInt('user_id') ?? 0;
      _employeeCode = prefs.getString('employee_code') ?? '';

      print('Loaded user data:');
      print('  - User Name: $_userName');
      print('  - User ID: $_userId (type: ${_userId.runtimeType})');
      print('  - Employee Code: "$_employeeCode"');

      // Try multiple sources for role, in order of preference
      String roleString = 'user';

      // 1. Direct user_role field (most reliable)
      final directRole = prefs.getString('user_role');
      if (directRole != null && directRole.isNotEmpty) {
        roleString = directRole;
        print('Found role from user_role: "$roleString"');
      }
      // 2. Check userData JSON
      else {
        final userDataString = prefs.getString('userData');
        if (userDataString != null && userDataString.isNotEmpty) {
          try {
            final userData = json.decode(userDataString) as Map<String, dynamic>;
            // Check multiple possible role field names
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
                print('Found role from userData[$field]: "$roleString"');
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
      print('Final role string: "$roleString"');

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
        print('User role: ADMIN');
      } else {
        _userRole = UserRole.user;
        print('User role: USER');
      }

      print('=== USER DATA LOADED ===');
      print('Name: $_userName');
      print('ID: $_userId');
      print('Employee Code: $_employeeCode');
      print('Final UserRole: $_userRole');

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

      // DEBUG: Print current state
      print('=== FETCHING DATA WITH ROLE: $_userRole ===');
      print('Is Admin: $isAdmin');
      print('User ID: $_userId');

      // Fetch all data in parallel
      await Future.wait([
        fetchAttendance(),
        fetchEmployees(),
        fetchDepartments(),
        fetchDutyShifts(),
      ]);

      print('=== ALL DATA FETCHED SUCCESSFULLY ===');
      print('Final Status - Is Admin: $isAdmin');
      print('Attendance records: ${_attendance.length}');
    } catch (e) {
      _error = 'Failed to load data: $e';
      print('Error fetching all data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // GET - Fetch all attendance - FIXED VERSION
  Future<void> fetchAttendance() async {
    try {
      _isLoadingAttendance = true;
      _error = '';
      notifyListeners();

      print('=== FETCHING ATTENDANCE ===');
      print('Current User Role: $_userRole');
      print('Is Admin: $isAdmin');
      print('User ID: $_userId');
      print('Employee Code: $_employeeCode');

      final token = await _getToken();

      final response = await http.get(
        Uri.parse('https://api.afaqmis.com/api/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Attendance API Status: ${response.statusCode}');

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

        print('Raw attendance records: ${attendanceList.length}');

        // Debug: Print first record structure
        if (attendanceList.isNotEmpty) {
          print('=== FIRST RECORD STRUCTURE ===');
          final firstRecord = attendanceList[0];
          if (firstRecord is Map) {
            firstRecord.forEach((key, value) {
              print('  $key: $value (type: ${value.runtimeType})');
            });
          }
        }

        // Parse all attendance
        _attendance = attendanceList
            .map((json) => Attendance.fromJson(json))
            .toList();

        // DEBUG: Print first few records details
        if (_attendance.isNotEmpty) {
          print('=== PARSED ATTENDANCE RECORDS ===');
          for (int i = 0; i < min(3, _attendance.length); i++) {
            final record = _attendance[i];
            print('Record $i:');
            print('  - ID: ${record.id}');
            print('  - Employee ID: ${record.employeeId} (type: ${record.employeeId.runtimeType})');
            print('  - Employee Name: ${record.employeeName}');
            print('  - Employee Code: "${record.empId}"');
            print('  - Department: ${record.departmentName}');
          }
        }

        // If user is not admin, filter to show only their own attendance
        if (!isAdmin && _userId != 0) {
          print('=== FILTERING FOR NON-ADMIN USER ===');
          print('User ID to match: $_userId (type: ${_userId.runtimeType})');
          print('User Name to match: "$_userName"');
          print('Employee Code to match: "$_employeeCode"');

          final originalCount = _attendance.length;
          int matchCount = 0;

          // Create a list to store filtered records
          final List<Attendance> filteredList = [];

          for (final attendance in _attendance) {
            bool matches = false;
            String matchReason = '';

            // Method 1: Compare employeeId as int
            if (attendance.employeeId == _userId) {
              matches = true;
              matchReason = 'employeeId match';
            }
            // Method 2: Compare as strings (in case of type mismatch)
            else if (attendance.employeeId.toString() == _userId.toString()) {
              matches = true;
              matchReason = 'employeeId string match';
            }
            // Method 3: Compare employee codes
            else if (_employeeCode.isNotEmpty &&
                attendance.empId.isNotEmpty &&
                attendance.empId.toLowerCase() == _employeeCode.toLowerCase()) {
              matches = true;
              matchReason = 'employeeCode match';
            }
            // Method 4: Compare by name (partial match as fallback)
            else if (_userName.isNotEmpty &&
                attendance.employeeName.isNotEmpty &&
                attendance.employeeName.toLowerCase().contains(_userName.toLowerCase())) {
              matches = true;
              matchReason = 'name partial match';
            }

            if (matches) {
              matchCount++;
              print('✓ Match $matchCount: ${attendance.employeeName}');
              print('  - Reason: $matchReason');
              print('  - Record Employee ID: ${attendance.employeeId}');
              print('  - Record Employee Code: "${attendance.empId}"');
              print('  - Record Name: ${attendance.employeeName}');
              filteredList.add(attendance);
            }
          }

          _attendance = filteredList;
          print('Filtered from $originalCount to ${_attendance.length} records for user');
          print('Total matches found: $matchCount');

          // If no matches found, try alternative matching strategies
          if (_attendance.isEmpty) {
            print('⚠️ No matches found with standard methods, trying alternatives...');
            await _tryAlternativeMatching();
          }
        } else if (isAdmin) {
          print('Admin user - showing ALL ${_attendance.length} records');
        }

        // Extract unique departments and employees
        _extractFilters();

        // Apply current filters
        _applyFilters();

        print('=== ATTENDANCE FETCH COMPLETE ===');
        print('Total filtered records: ${_filteredAttendance.length}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden - You don\'t have permission to view attendance');
      } else {
        print('Response body: ${response.body}');
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAttendance: $e');
      _error = e.toString();
      _attendance = [];
      _filteredAttendance = [];
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  // Try alternative matching methods when standard methods fail
  Future<void> _tryAlternativeMatching() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get additional identifiers
      final additionalIds = [
        prefs.getInt('employee_id'),
        prefs.getInt('emp_id'),
      ].whereType<int>().toList();

      final additionalCodes = [
        prefs.getString('emp_code'),
        prefs.getString('employee_id'), // Sometimes stored as string
        prefs.getString('staff_id'),
      ].whereType<String>().where((code) => code.isNotEmpty).toList();

      print('=== TRYING ALTERNATIVE MATCHING ===');
      print('Additional IDs to try: $additionalIds');
      print('Additional codes to try: $additionalCodes');

      if (additionalIds.isNotEmpty || additionalCodes.isNotEmpty) {
        final List<Attendance> filteredList = [];

        for (final attendance in _attendance) {
          bool matches = false;

          // Try additional IDs
          for (var id in additionalIds) {
            if (attendance.employeeId == id) {
              matches = true;
              print('✓ Alternative match by ID $id: ${attendance.employeeName}');
              break;
            }
          }

          // Try additional codes
          if (!matches && attendance.empId.isNotEmpty) {
            for (var code in additionalCodes) {
              if (attendance.empId.toLowerCase() == code.toLowerCase()) {
                matches = true;
                print('✓ Alternative match by code $code: ${attendance.employeeName}');
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
          print('Found ${filteredList.length} records with alternative matching');
        }
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

      print('=== FETCHING EMPLOYEES ===');
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('https://api.afaqmis.com/api/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Employees API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> employeesList = [];

        if (data is Map && data.containsKey('employees')) {
          employeesList = data['employees'] as List<dynamic>;
        }

        // Clear existing employees
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

        print('Successfully parsed ${_employees.length} employees');

        // If no employees were parsed, use fallback
        if (_employees.isEmpty) {
          print('No employees parsed, using fallback data');
          _employees = [
            Employee(id: 1, name: 'John Doe', empId: 'EMP001', department: 'IT'),
            Employee(id: 2, name: 'Jane Smith', empId: 'EMP002', department: 'HR'),
          ];
        }

        print('=== EMPLOYEES FETCH SUCCESSFUL ===');
      } else {
        print('Employees API Error ${response.statusCode}: ${response.body}');
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

      final department = data['department']?.toString() ??
          data['department_name']?.toString() ??
          data['dept']?.toString() ??
          data['department_id']?.toString() ??
          'Unknown Department';

      return Employee(
        id: id,
        name: name,
        empId: empId,
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

      print('=== FETCHING DEPARTMENTS ===');
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('https://api.afaqmis.com/api/departments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Departments API Status: ${response.statusCode}');

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

        print('Number of departments: ${departmentsList.length}');

        _departments = departmentsList
            .map((d) => Department.fromJson(d))
            .toList();

        if (_departments.isEmpty) {
          print('No departments from API, using fallback data');
          _departments = [
            Department(id: 1, name: 'IT', description: 'Information Technology'),
            Department(id: 2, name: 'HR', description: 'Human Resources'),
            Department(id: 3, name: 'Finance', description: 'Finance Department'),
            Department(id: 4, name: 'Operations', description: 'Operations Department'),
          ];
        }

        print('Fetched ${_departments.length} departments');
        print('=== DEPARTMENTS FETCH SUCCESSFUL ===');
      } else {
        print('Departments response body: ${response.body}');
        throw Exception('Failed to fetch departments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching departments: $e');
      _departments = [
        Department(id: 1, name: 'IT'),
        Department(id: 2, name: 'HR'),
        Department(id: 3, name: 'Finance'),
        Department(id: 4, name: 'Operations'),
      ];
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

      print('=== FETCHING DUTY SHIFTS ===');
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('https://api.afaqmis.com/api/duty-shifts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Duty Shifts API Status: ${response.statusCode}');

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

        print('Number of duty shifts: ${dutyShiftsList.length}');

        _dutyShifts = dutyShiftsList.map((s) => DutyShift.fromJson(s)).toList();

        if (_dutyShifts.isEmpty) {
          print('No duty shifts from API, using fallback data');
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

        print('Fetched ${_dutyShifts.length} duty shifts');
        print('=== DUTY SHIFTS FETCH SUCCESSFUL ===');
      } else {
        print('Duty Shifts response body: ${response.body}');
        throw Exception('Failed to fetch duty shifts: ${response.statusCode}');
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

  // POST - Create new attendance (only admin)
  Future<bool> createAttendance(AttendanceCreateDTO dto) async {
    if (!isAdmin) {
      _error = 'Only administrators can create attendance records';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('=== CREATING ATTENDANCE ===');
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(dto.toJson()),
      );

      print('Create Attendance Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAttendance = Attendance.fromJson(
          responseData['attendance'] ?? responseData['data'] ?? {},
        );
        _attendance.insert(0, newAttendance);
        _applyFilters();

        print('Attendance created successfully');
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

  // PUT - Update attendance (only admin)
  Future<bool> updateAttendance(int id, AttendanceCreateDTO dto) async {
    if (!isAdmin) {
      _error = 'Only administrators can update attendance records';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('=== UPDATING ATTENDANCE ID: $id ===');
      final token = await _getToken();

      final response = await http.put(
        Uri.parse('https://api.afaqmis.com/api/attendance/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(dto.toJson()),
      );

      print('Update Attendance Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final index = _attendance.indexWhere((a) => a.id == id);
        if (index != -1) {
          final responseData = json.decode(response.body);
          final updatedAttendance = Attendance.fromJson(
            responseData['attendance'] ?? responseData['data'] ?? {},
          );
          _attendance[index] = updatedAttendance;
          _applyFilters();
        }

        print('Attendance updated successfully');
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

  // DELETE - Remove attendance (only admin)
  Future<bool> deleteAttendance(int id) async {
    if (!isAdmin) {
      _error = 'Only administrators can delete attendance records';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('=== DELETING ATTENDANCE ID: $id ===');
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('https://api.afaqmis.com/api/attendance/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Delete Attendance Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _attendance.removeWhere((attendance) => attendance.id == id);
        _applyFilters();

        print('Attendance deleted successfully');
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
    // Only extract filters if user is admin
    if (isAdmin) {
      // Extract unique departments
      final departmentSet = _attendance
          .map((attendance) => attendance.departmentName)
          .where((dept) => dept.isNotEmpty)
          .toSet();
      _departmentNames = ['All', ...departmentSet];

      // Extract unique employees
      final employeeSet = _attendance
          .map((attendance) => attendance.employeeName)
          .where((emp) => emp.isNotEmpty)
          .toSet();
      _employeeNames = ['All', ...employeeSet];

      print('Extracted ${_departmentNames.length} departments and ${_employeeNames.length} employees');
    } else {
      // For regular users, show only their own data in filters
      _departmentNames = ['All'];
      _employeeNames = ['All'];
    }
  }

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
              _selectedEmployeeFilter == 'All' ||
              attendance.employeeName == _selectedEmployeeFilter;

      return matchesSearch && matchesDepartment && matchesEmployee;
    }).toList();

    print('Filtered attendance: ${_filteredAttendance.length} records');
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setDepartmentFilter(String department) {
    if (isAdmin) {
      _selectedDepartmentFilter = department;
      _applyFilters();
      notifyListeners();
    }
  }

  void setEmployeeFilter(String employee) {
    if (isAdmin) {
      _selectedEmployeeFilter = employee;
      _applyFilters();
      notifyListeners();
    }
  }

  void clearFilters() {
    _searchQuery = '';
    if (isAdmin) {
      _selectedDepartmentFilter = 'All';
      _selectedEmployeeFilter = 'All';
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

  // Navigation methods with permission checks
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

  // DEBUG: Add a method to manually check admin status
  void checkAdminStatus() {
    print('=== CHECKING ADMIN STATUS ===');
    print('Current userRole: $_userRole');
    print('isAdmin getter: $isAdmin');
    print('User ID: $_userId');
    print('User Name: $_userName');
    print('Employee Code: $_employeeCode');
  }

  // Method to manually test attendance filtering
  void testAttendanceFiltering() async {
    print('=== TESTING ATTENDANCE FILTERING ===');
    await _initializeUserData();
    print('Test Complete');
  }
}