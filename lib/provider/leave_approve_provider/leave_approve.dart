import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

  // New getters
  List<Map<String, dynamic>> get allEmployees => _allEmployees;
  List<String> get payModes => _payModes;
  List<String> get leaveTypes => _leaveTypes;

  // Call this method after user logs in to set their role and ID
  Future<void> initializeUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('=== INITIALIZE USER ROLE ===');

      // 1. First, extract from userData
      final userDataString = prefs.getString('userData');
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final userData = jsonDecode(userDataString);
          print('userData: $userData');

          // Extract role
          _userRole = userData['role_label'] ?? 'user';
          print('Extracted role: "$_userRole"');

          // Extract user ID
          _currentUserId = userData['id'];
          print('Extracted user ID: $_currentUserId');

          // Extract name
          _currentEmployeeName = userData['name'];

          // Extract department ID
          if (userData['department'] != null) {
            if (userData['department'] is Map) {
              _currentDepartmentId = userData['department']['id'];
            } else {
              _currentDepartmentId = userData['department_id'];
            }
          }

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

        } catch (e) {
          print('Error parsing userData: $e');
        }
      }

      // 2. If still not set, try from storage
      if (_userRole == null) {
        _userRole = prefs.getString('user_role') ?? 'user';
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

      _currentEmployeeCode = prefs.getString('employee_code');

      // Check if user is admin
      final roleLower = _userRole!.toLowerCase().trim();
      _isAdmin = roleLower.contains('admin') ||
          roleLower.contains('super') ||
          roleLower.contains('manager');

      print('Final values:');
      print('User Role: "$_userRole"');
      print('Role (lowercase): "$roleLower"');
      print('User ID: $_currentUserId');
      print('User Name: $_currentEmployeeName');
      print('Department ID: $_currentDepartmentId');
      print('isAdmin: $_isAdmin');
      print('==============================');

      notifyListeners();
    } catch (e) {
      print('Error initializing user role: $e');
      _isAdmin = false;
      _userRole = 'user';
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

      String apiUrl = 'https://api.afaqmis.com/api/leaves';

      print('Fetching leaves from: $apiUrl');

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

          // Debug first leave
          if (_leaves.isNotEmpty) {
            print('First leave: ${_leaves.first.employeeName}, image: ${_leaves.first.imageUrl}');
          }
        }

        // If leaves don't have images, fetch from employees API
        if (_leaves.isNotEmpty && (_leaves.first.imageUrl == null || _leaves.first.imageUrl!.isEmpty)) {
          print('Fetching employee images for leaves...');
          final employeeImageMap = await fetchAllEmployees();

          // Update leaves with image URLs
          for (int i = 0; i < _leaves.length; i++) {
            final leave = _leaves[i];
            String? imageUrl;

            // Try to find image by employee code
            if (employeeImageMap.containsKey(leave.employeeCode)) {
              imageUrl = employeeImageMap[leave.employeeCode];
              print('Found image for ${leave.employeeName} by employeeCode');
            }
            // Try to find image by employee name
            else if (employeeImageMap.containsKey(leave.employeeName)) {
              imageUrl = employeeImageMap[leave.employeeName];
              print('Found image for ${leave.employeeName} by name');
            }
            // Try to find image by employee ID
            else if (employeeImageMap.containsKey(leave.employeeId.toString())) {
              imageUrl = employeeImageMap[leave.employeeId.toString()];
              print('Found image for ${leave.employeeName} by ID');
            }

            if (imageUrl != null) {
              // Update the leave with the image URL
              _leaves[i] = leave.copyWith(imageUrl: imageUrl);
            }
          }
        }

        // If user is not admin, filter to show only their leaves
        if (!_isAdmin && _currentUserId != null) {
          _leaves = _leaves.where((leave) => leave.employeeId == _currentUserId).toList();
          print('Filtered to ${_leaves.length} leaves for user ID: $_currentUserId');
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

        // Clear existing list
        _allEmployees.clear();

        // Process each employee
        for (var emp in employeesData) {
          try {
            final employeeMap = {
              'id': emp['id'] ?? 0,
              'name': emp['name']?.toString() ?? 'Unknown',
              'employee_code': emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '',
              'department_id': emp['department_id'] ??
                  (emp['department'] is Map ? emp['department']['id'] : null),
              'department_name': emp['department_name']?.toString() ??
                  (emp['department'] is Map ? emp['department']['name']?.toString() : 'Unknown'),
              'designation': emp['designation']?.toString() ??
                  (emp['designation_info'] is Map ? emp['designation_info']['name']?.toString() : ''),
              'image': emp['image']?.toString() ??
                  emp['image_url']?.toString() ??
                  emp['profile_image']?.toString(),
            };

            // Only add if we have at least name and employee code
            if (employeeMap['name'] != 'Unknown' && employeeMap['employee_code'].toString().isNotEmpty) {
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
        throw Exception('Failed to fetch employees: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in fetchAllEmployeesForDropdown: $e');
      print('Stack trace: $stackTrace');
      _allEmployees = [];
      _error = 'Failed to load employees: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Updated submitLeave method with employee selection and pay mode
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

      // Get department ID from selected employee or current user
      int? departmentId = selectedEmployee['department_id'] ?? _currentDepartmentId;

      // If still no department ID, try to extract it
      if (departmentId == null && selectedEmployee['department_id'] == null) {
        print('Warning: No department ID found for employee');
      }

      // Prepare the request body
      final requestBody = {
        'leave_id': _generateLeaveId(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'department_id': departmentId ?? 1, // Fallback to 1 if null
        'employee_id': selectedEmployeeId,
        'nature_of_leave': natureOfLeave,
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'days': days,
        'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
        'reason': reason ?? '',
        'submitted_by_role': _userRole,
        'submitted_by': _currentUserId,
        'status': 'pending', // Always submit as pending
      };

      print('Submitting leave request: $requestBody');

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

  // Overloaded submitLeave for non-admin users (they can only submit for themselves)
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
      if (_currentDepartmentId == null) {
        throw Exception('Department ID not found. Please login again.');
      }

      // Prepare the request body
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
        'submitted_by_role': _userRole,
        'submitted_by': _currentUserId,
        'status': 'pending', // Always submit as pending
      };

      print('Submitting leave request for self: $requestBody');

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
    _departments = ['All', ...departmentSet.toList()..sort()];

    // Extract unique employees
    final employeeSet = _leaves
        .where((leave) => leave.employeeName.isNotEmpty)
        .map((leave) => leave.employeeName)
        .toSet();
    _employees = ['All', ...employeeSet.toList()..sort()];

    print('Extracted ${_departments.length} departments and ${_employees.length} employees');
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
      final matchesDepartment = _selectedDepartmentFilter == 'All' ||
          leave.departmentName == _selectedDepartmentFilter;

      // Employee filter
      final matchesEmployee = _selectedEmployeeFilter == 'All' ||
          leave.employeeName == _selectedEmployeeFilter;

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
    _selectedDepartmentFilter = 'All';
    _selectedEmployeeFilter = 'All';
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
    print('========================');
  }
}