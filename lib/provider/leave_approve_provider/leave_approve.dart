import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utility/global_url.dart';
import '../../model/leave_approve_model/leave_approve.dart';

class LeaveProvider extends ChangeNotifier {
  List<ApproveLeave> _leaves = [];
  List<ApproveLeave> _filteredLeaves = [];
  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';
  String _searchQuery = '';
  String _selectedDepartmentFilter = 'All';
  String _selectedEmployeeFilter = 'All';
  String _selectedStatusFilter = 'All';
  List<String> _departments = ['All'];
  List<String> _employees = ['All'];
  final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  // User role management
  bool _isAdmin = false;
  int? _currentUserId;
  int? _currentDepartmentId;
  String? _currentEmployeeCode;
  String? _currentEmployeeName;
  String? _userRole;

  // New properties for employee dropdown and pay mode
  List<Map<String, dynamic>> _allEmployees = [];
  final List<String> _payModes = ['With Pay', 'Without Pay'];
  final List<String> _leaveTypes = [
    'sick_leave',
    'annual_leave',
    'casual_leave',
    'emergency_leave',
    'maternity_leave',
    'paternity_leave',
    'study_leave',
    'compensatory_leave',
    'urgent_work'
  ];

  // Debug mode
  bool _debugMode = true;

  List<ApproveLeave> get leaves => _filteredLeaves;
  List<ApproveLeave> get allLeaves => _leaves;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get successMessage => _successMessage;
  String get searchQuery => _searchQuery;
  String get selectedDepartmentFilter => _selectedDepartmentFilter;
  String get selectedEmployeeFilter => _selectedEmployeeFilter;
  String get selectedStatusFilter => _selectedStatusFilter;
  List<String> get departments => _departments;
  List<String> get employees => _employees;
  List<String> get statusOptions => _statusOptions;
  bool get isAdmin => _isAdmin;
  int? get currentUserId => _currentUserId;
  int? get currentDepartmentId => _currentDepartmentId;
  String? get userRole => _userRole;
  String? get currentEmployeeName => _currentEmployeeName;
  String? get currentEmployeeCode => _currentEmployeeCode;

  // New getters
  List<Map<String, dynamic>> get allEmployees => _allEmployees;
  List<String> get payModes => _payModes;
  List<String> get leaveTypes => _leaveTypes;

  // Call this method after user logs in to set their role and ID
  Future<void> initializeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('=== INITIALIZE USER DATA ===');

      // Get user data
      final userDataString = prefs.getString('userData');
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final userData = jsonDecode(userDataString);
          print('userData: $userData');

          // Extract user info
          _currentUserId = userData['id'];
          _currentEmployeeName = userData['name']?.toString() ?? '';
          _currentEmployeeCode = userData['employee_code']?.toString() ?? '';
          _userRole = userData['role_label']?.toString() ?? 'user';

          // NORMALIZE THE ROLE - CRITICAL FIX
          if (_userRole!.toLowerCase().contains('attendence') ||
              _userRole!.toLowerCase().contains('attendance') ||
              _userRole!.toLowerCase().contains('employee') ||
              _userRole!.toLowerCase().contains('staff') ||
              _userRole!.toLowerCase().contains('user')) {
            _userRole = 'employee'; // Normalize to 'employee'
            print('Normalized role from "${userData['role_label']}" to "$_userRole"');
          }

          // Extract department ID
          if (userData['department'] != null) {
            if (userData['department'] is Map) {
              _currentDepartmentId = userData['department']['id'];
            } else {
              _currentDepartmentId = userData['department_id'];
            }
          }

          // If department ID is still null, try to get it from department_id field
          if (_currentDepartmentId == null && userData['department_id'] != null) {
            _currentDepartmentId = userData['department_id'];
          }

          // Determine if admin
          final roleLower = _userRole!.toLowerCase().trim();
          _isAdmin = roleLower.contains('admin') ||
              roleLower.contains('super') ||
              roleLower.contains('manager');

          // Save for future use
          await prefs.setString('user_role', _userRole!);
          if (_currentUserId != null) {
            await prefs.setInt('user_id', _currentUserId!);
          }
          if (_currentEmployeeName != null) {
            await prefs.setString('employee_name', _currentEmployeeName!);
          }
          if (_currentDepartmentId != null) {
            await prefs.setInt('department_id', _currentDepartmentId!);
          }
          if (_currentEmployeeCode != null) {
            await prefs.setString('employee_code', _currentEmployeeCode!);
          }

        } catch (e) {
          print('Error parsing userData: $e');
        }
      }

      // If still not set, try from storage
      if (_userRole == null) {
        _userRole = prefs.getString('user_role') ?? 'employee'; // Default to employee
      }
      if (_currentUserId == null) {
        _currentUserId = prefs.getInt('user_id');
      }
      if (_currentEmployeeName == null) {
        _currentEmployeeName = prefs.getString('employee_name');
      }
      if (_currentDepartmentId == null) {
        _currentDepartmentId = prefs.getInt('department_id');
      }
      if (_currentEmployeeCode == null) {
        _currentEmployeeCode = prefs.getString('employee_code');
      }

      // Re-check admin status
      final roleLower = _userRole!.toLowerCase().trim();
      _isAdmin = roleLower.contains('admin') ||
          roleLower.contains('super') ||
          roleLower.contains('manager');

      print('Final values:');
      print('User Role: "$_userRole"');
      print('User ID: $_currentUserId');
      print('User Name: "$_currentEmployeeName"');
      print('User Code: "$_currentEmployeeCode"');
      print('Department ID: $_currentDepartmentId');
      print('isAdmin: $_isAdmin');
      print('==============================');

      notifyListeners();
    } catch (e) {
      print('Error initializing user data: $e');
      _isAdmin = false;
      _userRole = 'employee'; // Default to employee
    }
  }

  // Generate a unique leave_id
  String _generateLeaveId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = (1000 + DateTime.now().microsecond % 9000).toString();
    return 'LV${timestamp.substring(timestamp.length - 8)}$random';
  }

  Future<void> fetchLeaves() async {
    try {
      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Initialize user data first
      await initializeUserData();

      String apiUrl = 'https://api.afaqmis.com/api/leaves';

      print('=== FETCH LEAVES ===');
      print('Fetching from: $apiUrl');
      print('User is admin: $_isAdmin');
      print('Current user ID: $_currentUserId');
      print('Current user name: "$_currentEmployeeName"');
      print('Current department ID: $_currentDepartmentId');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Response data type: ${responseData.runtimeType}');

        List<dynamic> leaveList = [];

        // Handle different API response formats
        if (responseData is Map) {
          print('=== API RESPONSE STRUCTURE ===');
          responseData.forEach((key, value) {
            print('Key: "$key", Type: ${value.runtimeType}');
            if (value is List) {
              print('  List length: ${value.length}');
            }
          });

          if (responseData.containsKey('data')) {
            if (responseData['data'] is List) {
              leaveList = responseData['data'];
            } else if (responseData['data'] is Map) {
              if (responseData['data'].containsKey('leaves')) {
                leaveList = responseData['data']['leaves'] ?? [];
              }
            }
          } else if (responseData.containsKey('leaves')) {
            leaveList = responseData['leaves'];
          } else if (responseData.containsKey('result')) {
            leaveList = responseData['result'];
          }
        } else if (responseData is List) {
          leaveList = responseData;
        }

        print('Parsed ${leaveList.length} leaves from API');

        if (leaveList.isEmpty) {
          print('No leaves found in response');
          _leaves = [];
        } else {
          // Convert to ApproveLeave objects
          _leaves = leaveList.map((json) => ApproveLeave.fromJson(json)).toList();
          print('Successfully created ${_leaves.length} ApproveLeave objects');

          // Debug: Print all leaves
          print('=== DEBUG: ALL LEAVES FROM API ===');
          for (var i = 0; i < min(_leaves.length, 10); i++) {
            final leave = _leaves[i];
            print('Leave ${i + 1}:');
            print('  ID: ${leave.id}');
            print('  Employee ID: ${leave.employeeId}');
            print('  Employee Name: "${leave.employeeName}"');
            print('  Employee Code: "${leave.employeeCode}"');
            print('  Status: ${leave.status}');
            print('  Department ID: ${leave.departmentId}');
            if (leave.employeeId == _currentUserId) {
              print('  ✓ THIS IS CURRENT USER (ID: $_currentUserId)');
            }
          }
        }

        // If user is not admin, filter to show only their leaves
        if (!_isAdmin && _currentUserId != null) {
          print('=== FILTERING LEAVES FOR NON-ADMIN USER ===');
          print('Current user ID: $_currentUserId');
          print('Current user name: "$_currentEmployeeName"');
          final originalCount = _leaves.length;

          if (!_debugMode) {
            // Production filtering
            _leaves = _leaves.where((leave) => leave.employeeId == _currentUserId).toList();
            print('Filtered from $originalCount to ${_leaves.length} leaves for user ID: $_currentUserId');

            // Also filter by employee name as additional check
            if (_leaves.isEmpty && _currentEmployeeName != null) {
              print('Trying to filter by employee name: "$_currentEmployeeName"');
              _leaves = _leaves.where((leave) =>
              leave.employeeName.toLowerCase().contains(_currentEmployeeName!.toLowerCase()) ||
                  (_currentEmployeeCode != null && leave.employeeCode.toLowerCase().contains(_currentEmployeeCode!.toLowerCase()))
              ).toList();
              print('After name filtering: ${_leaves.length} leaves');
            }
          } else {
            // Debug mode: Show debug info but don't filter
            print('DEBUG MODE: Showing all leaves for debugging');
            print('Total leaves: ${_leaves.length}');

            // Count user's leaves
            int userLeavesCount = _leaves.where((leave) => leave.employeeId == _currentUserId).length;
            print('User has $userLeavesCount leaves in total list');

            // Show user's leaves
            print('=== USER LEAVES ===');
            for (var leave in _leaves.where((leave) => leave.employeeId == _currentUserId)) {
              print('  - ${leave.employeeName} (ID: ${leave.employeeId}) - Status: ${leave.status}');
            }
          }
        }

        // Extract unique departments and employees
        _extractFilters();

        // Apply current filters
        _applyFilters();

        print('Final leaves count: ${_leaves.length}, filtered: ${_filteredLeaves.length}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to load leaves: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      _leaves = [];
      _filteredLeaves = [];
      print('Error in fetchLeaves: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method to fetch employee images
  Future<Map<String, String>> fetchAllEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) return {};

      final url = Uri.parse('${GlobalUrls.baseurl}/api/employees');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> employeesData = responseData['employees'] ?? [];

        // Create a map of employee codes to image URLs
        final Map<String, String> employeeImageMap = {};

        for (var emp in employeesData) {
          final empCode = emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '';
          final empName = emp['name']?.toString() ?? emp['employee_name']?.toString() ?? '';
          final empId = emp['id']?.toString() ?? emp['employee_id']?.toString() ?? '';

          // Try to get image URL from various possible fields
          final imageUrl = emp['image_url']?.toString() ??
              emp['profile_image']?.toString() ??
              emp['avatar']?.toString() ??
              emp['photo']?.toString() ??
              emp['image']?.toString();

          if (empCode.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
            employeeImageMap[empCode] = imageUrl;
          }
          if (empName.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
            employeeImageMap[empName] = imageUrl;
          }
          if (empId.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
            employeeImageMap[empId] = imageUrl;
          }
        }

        print('Fetched ${employeeImageMap.length} employee images');
        return employeeImageMap;
      }
    } catch (e) {
      print('Error fetching employee images: $e');
    }

    return {};
  }

  // NEW: Method to fetch all employees for dropdown
  Future<void> fetchAllEmployeesForDropdown() async {
    try {
      print('=== FETCHING EMPLOYEES FOR DROPDOWN ===');
      print('User is admin: $_isAdmin');
      print('Current user ID: $_currentUserId');
      print('Current user name: "$_currentEmployeeName"');
      print('Current department ID: $_currentDepartmentId');

      // Always clear existing list first
      _allEmployees.clear();

      // For non-admin users, add only themselves
      if (!_isAdmin) {
        print('Non-admin user: Adding only current user to dropdown');

        if (_currentUserId != null && _currentEmployeeName != null) {
          _allEmployees.add({
            'id': _currentUserId!,
            'name': _currentEmployeeName!,
            'employee_code': _currentEmployeeCode ?? '',
            'department_id': _currentDepartmentId ?? 1,
            'department_name': 'My Department',
            'designation': 'Employee',
            'image': null,
          });
          print('Added current user to dropdown: "$_currentEmployeeName", Dept ID: $_currentDepartmentId');
        } else {
          print('Warning: Current user data not available for non-admin');
        }

        notifyListeners();
        return;
      }

      // For admin users, fetch all employees from API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('https://api.afaqmis.com/api/employees');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> employeesData = responseData['employees'] ?? [];

        print('Found ${employeesData.length} employees in API response');

        // Process each employee
        for (var emp in employeesData) {
          try {
            // Extract department ID - handle multiple formats
            int? departmentId;

            if (emp['department_id'] != null) {
              departmentId = int.tryParse(emp['department_id'].toString());
            } else if (emp['department'] != null) {
              if (emp['department'] is Map) {
                departmentId = int.tryParse(emp['department']['id']?.toString() ?? '');
              } else {
                departmentId = int.tryParse(emp['department'].toString());
              }
            } else if (emp['dept_id'] != null) {
              departmentId = int.tryParse(emp['dept_id'].toString());
            }

            final employeeMap = {
              'id': emp['id'] ?? 0,
              'name': emp['name']?.toString() ?? 'Unknown',
              'employee_code': emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '',
              'department_id': departmentId ?? 1,
              'department_name': emp['department_name']?.toString() ??
                  (emp['department'] is Map ? emp['department']['name']?.toString() : 'Unknown Department'),
              'designation': emp['designation']?.toString() ??
                  (emp['designation_info'] is Map ? emp['designation_info']['name']?.toString() : ''),
              'image': emp['image']?.toString() ??
                  emp['image_url']?.toString() ??
                  emp['profile_image']?.toString(),
            };

            // Only add if we have at least name
            if (employeeMap['name'] != 'Unknown') {
              _allEmployees.add(employeeMap);
            }
          } catch (e) {
            print('Error processing employee: $e, data: $emp');
          }
        }

        print('Successfully loaded ${_allEmployees.length} employees for dropdown');
        notifyListeners();
      } else {
        print('Failed to fetch employees: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch employees: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in fetchAllEmployeesForDropdown: $e');
      print('Stack trace: $stackTrace');

      // Fallback: Add current user even if there's an error
      if (_currentUserId != null && _currentEmployeeName != null) {
        _allEmployees.add({
          'id': _currentUserId!,
          'name': _currentEmployeeName!,
          'employee_code': _currentEmployeeCode ?? '',
          'department_id': _currentDepartmentId ?? 1,
          'department_name': 'My Department',
          'designation': 'Employee',
          'image': null,
        });
        notifyListeners();
      }

      _error = 'Failed to load employees: $e';
      notifyListeners();
    }
  }

  // Submit leave for admin (selecting employee)
  Future<bool> submitLeave({
    required int selectedEmployeeId,
    required String natureOfLeave,
    required DateTime fromDate,
    required DateTime toDate,
    required int days,
    required String payMode,
    String? reason,
  }) async {
    try {
      // Only admin can submit leave for other employees
      if (!_isAdmin) {
        throw Exception('Only admin users can submit leaves for other employees');
      }

      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Find selected employee
      final selectedEmployee = _allEmployees.firstWhere(
            (emp) => emp['id'] == selectedEmployeeId,
        orElse: () => {},
      );

      if (selectedEmployee.isEmpty) {
        throw Exception('Selected employee not found');
      }

      // Get department ID from selected employee
      int? departmentId = selectedEmployee['department_id'] ?? 1;

      // Prepare the request body
      final requestBody = {
        'leave_id': _generateLeaveId(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'department_id': departmentId,
        'employee_id': selectedEmployeeId,
        'nature_of_leave': natureOfLeave,
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'days': days,
        'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
        'reason': reason ?? '',
        'submitted_by_role': 'admin', // Fixed role
        'submitted_by': _currentUserId,
        'status': 'pending',
      };

      print('Admin submitting leave request: $requestBody');

      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Submit leave response status: ${response.statusCode}');
      print('Submit leave response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the leaves list to include the new leave
        await fetchLeaves();

        _successMessage = 'Leave request submitted successfully!';
        return true;
      } else if (response.statusCode == 500) {
        print('=== SERVER ERROR 500 DETAILS ===');
        print('Request Body: $requestBody');
        print('Response Body: ${response.body}');

        throw Exception('Server error: Please try again or contact administrator.');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ??
            errorData['error'] ??
            'Failed to submit leave request: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _error = e.toString();
      print('Error submitting leave: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit leave for non-admin users (they can only submit for themselves)
  Future<bool> submitLeaveForSelf({
    required String natureOfLeave,
    required DateTime fromDate,
    required DateTime toDate,
    required int days,
    required String payMode,
    String? reason,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Check if we have all required user data
      if (_currentUserId == null) {
        throw Exception('User ID not found. Please login again.');
      }

      // If department ID is not set, try to get it from user data
      if (_currentDepartmentId == null) {
        print('Warning: Department ID not found, trying to extract from user data...');

        final userDataString = prefs.getString('userData');
        if (userDataString != null) {
          try {
            final userData = jsonDecode(userDataString);
            if (userData['department'] != null) {
              if (userData['department'] is Map) {
                _currentDepartmentId = userData['department']['id'];
              } else {
                _currentDepartmentId = userData['department_id'];
              }
              print('Extracted department ID from userData: $_currentDepartmentId');
            }
          } catch (e) {
            print('Error extracting department from userData: $e');
          }
        }

        // If still not set, use default
        if (_currentDepartmentId == null) {
          _currentDepartmentId = 1; // Default department ID
          print('Using default department ID: $_currentDepartmentId');
        }
      }

      // Prepare the request body - CRITICAL FIX: Use 'employee' role instead of _userRole
      final requestBody = {
        'leave_id': _generateLeaveId(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'department_id': _currentDepartmentId,
        'employee_id': _currentUserId,
        'nature_of_leave': natureOfLeave,
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'days': days,
        'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
        'reason': reason ?? '',
        'submitted_by_role': 'employee', // FIXED: Changed from _userRole to 'employee'
        'submitted_by': _currentUserId,
        'status': 'pending',
      };

      print('Non-admin submitting leave request for self: $requestBody');

      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Submit leave response status: ${response.statusCode}');
      print('Submit leave response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the leaves list to include the new leave
        await fetchLeaves();

        _successMessage = 'Leave request submitted successfully!';
        return true;
      } else if (response.statusCode == 500) {
        print('=== SERVER ERROR 500 DETAILS ===');
        print('Request Body: $requestBody');
        print('Response Body: ${response.body}');

        // Try to parse error
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Server Error 500';

          if (errorMessage.toLowerCase().contains('role') ||
              errorMessage.toLowerCase().contains('permission')) {
            throw Exception('Permission denied. Please contact administrator.');
          } else {
            throw Exception('Server error: $errorMessage');
          }
        } catch (e) {
          throw Exception('Server error occurred. Please try again.');
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ??
            errorData['error'] ??
            'Failed to submit leave request: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _error = e.toString();
      print('Error submitting leave: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _extractFilters() {
    // Extract unique departments
    final departmentSet = _leaves
        .where((leave) => leave.departmentName.isNotEmpty)
        .map((leave) => leave.departmentName)
        .toSet();

    // For non-admin users, if no departments found, add their department
    if (!_isAdmin && departmentSet.isEmpty && _currentEmployeeName != null) {
      _departments = ['All', 'My Department'];
      _selectedDepartmentFilter = 'My Department';
    } else {
      // Use Set to ensure uniqueness, then convert to List
      final uniqueDepartments = departmentSet.toList()..sort();
      _departments = ['All', ...uniqueDepartments];

      // If non-admin, also add "My Department" option
      if (!_isAdmin && _currentEmployeeName != null && !_departments.contains('My Department')) {
        _departments.add('My Department');
      }
    }

    // Extract unique employees - only for admin
    if (_isAdmin) {
      final employeeSet = _leaves
          .where((leave) => leave.employeeName.isNotEmpty)
          .map((leave) => leave.employeeName)
          .toSet();
      _employees = ['All', ...employeeSet.toList()..sort()];
    } else {
      // For non-admin, show only themselves
      _employees = ['All', _currentEmployeeName ?? 'My Leaves'];
      _selectedEmployeeFilter = _currentEmployeeName ?? 'My Leaves';
    }

    print('Extracted ${_departments.length} departments and ${_employees.length} employees');
    print('Departments: $_departments');
    print('Employees: $_employees');
  }

  void _applyFilters() {
    _filteredLeaves = _leaves.where((leave) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          leave.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          leave.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (leave.leaveId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (leave.reason != null && leave.reason!.toLowerCase().contains(_searchQuery.toLowerCase()));

      // Department filter
      bool matchesDepartment;
      if (!_isAdmin && _selectedDepartmentFilter == 'My Department') {
        // For non-admin, if they have "My Department" selected, show all their leaves
        matchesDepartment = true;
      } else {
        matchesDepartment = _selectedDepartmentFilter == 'All' ||
            leave.departmentName == _selectedDepartmentFilter;
      }

      // Employee filter
      bool matchesEmployee;
      if (!_isAdmin) {
        // For non-admin, only show their own leaves
        matchesEmployee = leave.employeeId == _currentUserId ||
            (_currentEmployeeName != null &&
                leave.employeeName.toLowerCase().contains(_currentEmployeeName!.toLowerCase()));
      } else {
        matchesEmployee = _selectedEmployeeFilter == 'All' ||
            leave.employeeName == _selectedEmployeeFilter;
      }

      // Status filter - normalize comparison
      final leaveStatus = leave.status.toLowerCase();
      final selectedStatus = _selectedStatusFilter.toLowerCase();

      bool matchesStatus;
      if (_selectedStatusFilter == 'All') {
        matchesStatus = true;
      } else {
        switch (selectedStatus) {
          case 'pending':
            matchesStatus = leaveStatus == 'pending' || leaveStatus.contains('pending');
            break;
          case 'approved':
            matchesStatus = leaveStatus == 'approved' || leaveStatus.contains('approved');
            break;
          case 'rejected':
            matchesStatus = leaveStatus == 'rejected' || leaveStatus.contains('rejected');
            break;
          default:
            matchesStatus = leaveStatus == selectedStatus;
        }
      }

      return matchesSearch && matchesDepartment && matchesEmployee && matchesStatus;
    }).toList();

    print('Applied filters: ${_filteredLeaves.length} leaves match');
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setDepartmentFilter(String department) {
    _selectedDepartmentFilter = department;
    _applyFilters();
    notifyListeners();
  }

  void setEmployeeFilter(String employee) {
    _selectedEmployeeFilter = employee;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  Future<void> approveLeave(int leaveId) async {
    try {
      // Check if user is admin
      if (!_isAdmin) {
        throw Exception('Only admin users can approve leaves');
      }

      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      print('=== APPROVE LEAVE ===');
      print('Leave ID to approve: $leaveId');

      // Try multiple methods
      bool success = false;

      // Method 1: PATCH to status endpoint
      print('Method 1: Trying PATCH to /status...');
      try {
        final response = await http.patch(
          Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'status': 'approved',
            'approved_by': _currentUserId,
            'approved_at': DateTime.now().toIso8601String(),
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('PATCH to /status worked!');
          success = true;
        }
      } catch (e) {
        print('PATCH error: $e');
      }

      // Method 2: PUT to main endpoint
      if (!success) {
        print('Method 2: Trying PUT to main endpoint...');
        try {
          final response = await http.put(
            Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'status': 'approved',
              'approval_status': 'approved',
              'approved_by': _currentUserId,
              'approved_at': DateTime.now().toIso8601String(),
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('PUT worked!');
            success = true;
          }
        } catch (e) {
          print('PUT error: $e');
        }
      }

      // Method 3: POST to approve endpoint
      if (!success) {
        print('Method 3: Trying POST to /approve...');
        try {
          final response = await http.post(
            Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/approve'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'action': 'approve',
              'approved_by': _currentUserId,
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('POST to /approve worked!');
            success = true;
          }
        } catch (e) {
          print('POST error: $e');
        }
      }

      if (success) {
        // Update the leave status locally
        final index = _leaves.indexWhere((leave) => leave.id == leaveId);
        if (index != -1) {
          _leaves[index] = _leaves[index].copyWith(status: 'approved');
          print('Updated local leave status to: ${_leaves[index].status}');
          _applyFilters();
        }

        _successMessage = 'Leave approved successfully!';

        // Refresh leaves list
        await fetchLeaves();
      } else {
        throw Exception('All approve methods failed');
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      print('Error in approveLeave: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectLeave(int leaveId) async {
    try {
      // Check if user is admin
      if (!_isAdmin) {
        throw Exception('Only admin users can reject leaves');
      }

      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      print('=== REJECT LEAVE ===');
      print('Leave ID to reject: $leaveId');

      // Try multiple methods
      bool success = false;

      // Method 1: PATCH to status endpoint
      print('Method 1: Trying PATCH to /status...');
      try {
        final response = await http.patch(
          Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'status': 'rejected',
            'rejected_by': _currentUserId,
            'rejected_at': DateTime.now().toIso8601String(),
            'rejection_reason': 'Rejected by admin',
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('PATCH to /status worked!');
          success = true;
        }
      } catch (e) {
        print('PATCH error: $e');
      }

      // Method 2: PUT to main endpoint
      if (!success) {
        print('Method 2: Trying PUT to main endpoint...');
        try {
          final response = await http.put(
            Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'status': 'rejected',
              'approval_status': 'rejected',
              'rejected_by': _currentUserId,
              'rejected_at': DateTime.now().toIso8601String(),
              'rejection_reason': 'Rejected by admin',
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('PUT worked!');
            success = true;
          }
        } catch (e) {
          print('PUT error: $e');
        }
      }
      // Method 3: POST to reject endpoint
      if (!success) {
        print('Method 3: Trying POST to /reject...');
        try {
          final response = await http.post(
            Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/reject'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'action': 'reject',
              'rejected_by': _currentUserId,
              'rejection_reason': 'Rejected by admin',
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('POST to /reject worked!');
            success = true;
          }
        } catch (e) {
          print('POST error: $e');
        }
      }

      if (success) {
        // Update the leave status locally
        final index = _leaves.indexWhere((leave) => leave.id == leaveId);
        if (index != -1) {
          _leaves[index] = _leaves[index].copyWith(status: 'rejected');
          print('Updated local leave status to: ${_leaves[index].status}');
          _applyFilters();
        }

        _successMessage = 'Leave rejected successfully!';

        // Refresh leaves list
        await fetchLeaves();
      } else {
        throw Exception('All reject methods failed');
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      print('Error in rejectLeave: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Statistics
  int get pendingCount => _leaves.where((leave) => leave.status.toLowerCase() == 'pending' || leave.status.toLowerCase().contains('pending')).length;
  int get approvedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'approved' || leave.status.toLowerCase().contains('approved')).length;
  int get rejectedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'rejected' || leave.status.toLowerCase().contains('rejected')).length;
  int get totalDays => _leaves.fold(0, (sum, leave) => sum + leave.days);

  void clearFilters() {
    _searchQuery = '';
    if (_isAdmin) {
      _selectedDepartmentFilter = 'All';
      _selectedEmployeeFilter = 'All';
    } else {
      _selectedEmployeeFilter = _currentEmployeeName ?? 'My Leaves';
    }
    _selectedStatusFilter = 'All';
    _applyFilters();
    notifyListeners();
  }

  void clearMessages() {
    _error = '';
    _successMessage = '';
    notifyListeners();
  }

  // Debug method
  Future<void> debugUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== DEBUG USER INFO ===');
    print('Stored user_role: "${prefs.getString('user_role')}"');
    print('Stored user_id: ${prefs.getInt('user_id')}');
    print('Stored department_id: ${prefs.getInt('department_id')}');
    print('Stored token exists: ${prefs.getString('token') != null}');

    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        print('userData:');
        print('  id: ${userData['id']}');
        print('  name: "${userData['name']}"');
        print('  role_label: "${userData['role_label']}"');
        print('  department: ${userData['department']}');
        print('  department_id: ${userData['department_id']}');
      } catch (e) {
        print('Error parsing userData: $e');
      }
    }

    print('Current provider state:');
    print('  _userRole: "$_userRole"');
    print('  _isAdmin: $_isAdmin');
    print('  _currentUserId: $_currentUserId');
    print('  _currentEmployeeName: "$_currentEmployeeName"');
    print('  _currentDepartmentId: $_currentDepartmentId');
    print('  All employees count: ${_allEmployees.length}');
    print('  Leaves count: ${_leaves.length}');
    print('  Filtered leaves count: ${_filteredLeaves.length}');
    print('========================');
  }

  // Toggle debug mode
  void toggleDebugMode() {
    _debugMode = !_debugMode;
    print('Debug mode: $_debugMode');
    notifyListeners();
  }
}