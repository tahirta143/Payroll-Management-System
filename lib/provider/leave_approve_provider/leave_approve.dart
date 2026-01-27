// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../model/leave_approve_model/leave_approve.dart';
//
// class LeaveProvider extends ChangeNotifier {
//   List<ApproveLeave> _leaves = [];
//   List<ApproveLeave> _filteredLeaves = [];
//   bool _isLoading = false;
//   String _error = '';
//   String _successMessage = '';
//   String _searchQuery = '';
//   String _selectedDepartmentFilter = 'All';
//   String _selectedEmployeeFilter = 'All';
//   String _selectedStatusFilter = 'All';
//   List<String> _departments = ['All'];
//   List<String> _employees = ['All'];
//   final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];
//
//   // User role management
//   bool _isAdmin = false;
//   int? _currentUserId;
//   int? _currentDepartmentId;
//   String? _currentEmployeeCode;
//   String? _currentEmployeeName;
//   String? _userRole;
//
//   List<ApproveLeave> get leaves => _filteredLeaves;
//   List<ApproveLeave> get allLeaves => _leaves;
//   bool get isLoading => _isLoading;
//   String get error => _error;
//   String get successMessage => _successMessage;
//   String get searchQuery => _searchQuery;
//   String get selectedDepartmentFilter => _selectedDepartmentFilter;
//   String get selectedEmployeeFilter => _selectedEmployeeFilter;
//   String get selectedStatusFilter => _selectedStatusFilter;
//   List<String> get departments => _departments;
//   List<String> get employees => _employees;
//   List<String> get statusOptions => _statusOptions;
//   bool get isAdmin => _isAdmin;
//   int? get currentUserId => _currentUserId;
//   int? get currentDepartmentId => _currentDepartmentId;
//   String? get userRole => _userRole;
//
//   // Call this method after user logs in to set their role and ID
//   Future<void> initializeUserRole() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       print('=== INITIALIZE USER ROLE ===');
//
//       // 1. First, extract from userData
//       final userDataString = prefs.getString('userData');
//       if (userDataString != null && userDataString.isNotEmpty) {
//         try {
//           final userData = jsonDecode(userDataString);
//           print('userData: $userData');
//
//           // Extract role
//           _userRole = userData['role_label'] ?? 'user';
//           print('Extracted role: "$_userRole"');
//
//           // Extract user ID
//           _currentUserId = userData['id'];
//           print('Extracted user ID: $_currentUserId');
//
//           // Extract name
//           _currentEmployeeName = userData['name'];
//
//           // Save for future use
//           await prefs.setString('user_role', _userRole!);
//           if (_currentUserId != null) {
//             await prefs.setInt('user_id', _currentUserId!);
//           }
//           if (_currentEmployeeName != null) {
//             await prefs.setString('employee_name', _currentEmployeeName!);
//           }
//
//         } catch (e) {
//           print('Error parsing userData: $e');
//         }
//       }
//
//       // 2. If still not set, try from storage
//       if (_userRole == null) {
//         _userRole = prefs.getString('user_role') ?? 'user';
//       }
//       if (_currentUserId == null) {
//         _currentUserId = prefs.getInt('user_id');
//       }
//       if (_currentEmployeeName == null) {
//         _currentEmployeeName = prefs.getString('employee_name');
//       }
//
//       _currentDepartmentId = prefs.getInt('department_id');
//       _currentEmployeeCode = prefs.getString('employee_code');
//
//       // Check if user is admin
//       final roleLower = _userRole!.toLowerCase().trim();
//       _isAdmin = roleLower.contains('admin');
//
//       print('Final values:');
//       print('User Role: "$_userRole"');
//       print('Role (lowercase): "$roleLower"');
//       print('User ID: $_currentUserId');
//       print('User Name: $_currentEmployeeName');
//       print('isAdmin: $_isAdmin');
//       print('==============================');
//
//       notifyListeners();
//     } catch (e) {
//       print('Error initializing user role: $e');
//       _isAdmin = false;
//       _userRole = 'user';
//     }
//   }
//
//   // Generate a unique leave_id
//   String _generateLeaveId() {
//     final now = DateTime.now();
//     final timestamp = now.millisecondsSinceEpoch.toString();
//     final random = (1000 + DateTime.now().microsecond % 9000).toString();
//     return 'LV${timestamp.substring(timestamp.length - 8)}$random';
//   }
//
//   Future<void> fetchLeaves() async {
//     try {
//       _isLoading = true;
//       _error = '';
//       _successMessage = '';
//       notifyListeners();
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('No authentication token found');
//       }
//
//       String apiUrl = 'https://api.afaqmis.com/api/leaves';
//
//       print('Fetching leaves from: $apiUrl');
//       print('User Role: $_userRole, isAdmin: $_isAdmin, User ID: $_currentUserId');
//
//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );
//
//       print('Response status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         print('Response data type: ${responseData.runtimeType}');
//
//         List<dynamic> leaveList = [];
//
//         // Handle different API response formats
//         if (responseData is Map) {
//           if (responseData.containsKey('data')) {
//             if (responseData['data'] is List) {
//               leaveList = responseData['data'];
//             } else if (responseData['data'] is Map) {
//               if (responseData['data'].containsKey('leaves')) {
//                 leaveList = responseData['data']['leaves'] ?? [];
//               }
//             }
//           } else if (responseData.containsKey('leaves')) {
//             leaveList = responseData['leaves'];
//           } else if (responseData.containsKey('result')) {
//             leaveList = responseData['result'];
//           }
//         } else if (responseData is List) {
//           leaveList = responseData;
//         }
//
//         print('Parsed ${leaveList.length} leaves from API');
//
//         if (leaveList.isEmpty) {
//           print('No leaves found in response');
//           _leaves = [];
//         } else {
//           // Convert to ApproveLeave objects
//           _leaves = leaveList.map((json) => ApproveLeave.fromJson(json)).toList();
//           print('Successfully created ${_leaves.length} ApproveLeave objects');
//
//           // Debug first leave
//           if (_leaves.isNotEmpty) {
//             print('First leave: ${_leaves.first.id}, status: ${_leaves.first.status}');
//           }
//         }
//
//         // If user is not admin, filter to show only their leaves
//         if (!_isAdmin && _currentUserId != null) {
//           _leaves = _leaves.where((leave) => leave.employeeId == _currentUserId).toList();
//           print('Filtered to ${_leaves.length} leaves for user ID: $_currentUserId');
//         }
//
//         // Extract unique departments and employees
//         _extractFilters();
//
//         // Apply current filters
//         _applyFilters();
//
//         print('Final leaves count: ${_leaves.length}, filtered: ${_filteredLeaves.length}');
//       } else if (response.statusCode == 401) {
//         throw Exception('Unauthorized - Please login again');
//       } else {
//         print('Error response body: ${response.body}');
//         throw Exception('Failed to load leaves: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       _error = e.toString();
//       _leaves = [];
//       _filteredLeaves = [];
//       print('Error in fetchLeaves: $e');
//       print('Stack trace: $stackTrace');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void _extractFilters() {
//     // Extract unique departments
//     final departmentSet = _leaves
//         .where((leave) => leave.departmentName.isNotEmpty)
//         .map((leave) => leave.departmentName)
//         .toSet();
//     _departments = ['All', ...departmentSet.toList()..sort()];
//
//     // Extract unique employees
//     final employeeSet = _leaves
//         .where((leave) => leave.employeeName.isNotEmpty)
//         .map((leave) => leave.employeeName)
//         .toSet();
//     _employees = ['All', ...employeeSet.toList()..sort()];
//
//     print('Extracted ${_departments.length} departments and ${_employees.length} employees');
//   }
//
//   void _applyFilters() {
//     _filteredLeaves = _leaves.where((leave) {
//       // Search filter
//       final matchesSearch = _searchQuery.isEmpty ||
//           leave.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           leave.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           leave.leaveId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           (leave.reason != null && leave.reason!.toLowerCase().contains(_searchQuery.toLowerCase()));
//
//       // Department filter
//       final matchesDepartment = _selectedDepartmentFilter == 'All' ||
//           leave.departmentName == _selectedDepartmentFilter;
//
//       // Employee filter
//       final matchesEmployee = _selectedEmployeeFilter == 'All' ||
//           leave.employeeName == _selectedEmployeeFilter;
//
//       // Status filter - normalize comparison
//       final leaveStatus = leave.status.toLowerCase();
//       final selectedStatus = _selectedStatusFilter.toLowerCase();
//
//       bool matchesStatus;
//       if (_selectedStatusFilter == 'All') {
//         matchesStatus = true;
//       } else {
//         switch (selectedStatus) {
//           case 'pending':
//             matchesStatus = leaveStatus == 'pending';
//             break;
//           case 'approved':
//             matchesStatus = leaveStatus == 'approved';
//             break;
//           case 'rejected':
//             matchesStatus = leaveStatus == 'rejected';
//             break;
//           default:
//             matchesStatus = leaveStatus == selectedStatus;
//         }
//       }
//
//       return matchesSearch && matchesDepartment && matchesEmployee && matchesStatus;
//     }).toList();
//
//     print('Applied filters: ${_filteredLeaves.length} leaves match');
//   }
//
//   void setSearchQuery(String query) {
//     _searchQuery = query;
//     _applyFilters();
//     notifyListeners();
//   }
//
//   void setDepartmentFilter(String department) {
//     _selectedDepartmentFilter = department;
//     _applyFilters();
//     notifyListeners();
//   }
//
//   void setEmployeeFilter(String employee) {
//     _selectedEmployeeFilter = employee;
//     _applyFilters();
//     notifyListeners();
//   }
//
//   void setStatusFilter(String status) {
//     _selectedStatusFilter = status;
//     _applyFilters();
//     notifyListeners();
//   }
//   Future<void> approveLeave(int leaveId) async {
//     try {
//       // Check if user is admin
//       if (!_isAdmin) {
//         throw Exception('Only admin users can approve leaves');
//       }
//
//       _isLoading = true;
//       _error = '';
//       _successMessage = '';
//       notifyListeners();
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('No authentication token found');
//       }
//
//       print('=== APPROVE LEAVE ===');
//       print('Leave ID to approve: $leaveId');
//
//       // Try PATCH method with just status (common for partial updates)
//       final apiUrl = 'https://api.afaqmis.com/api/leaves/$leaveId/status';
//       print('Trying PATCH to: $apiUrl');
//
//       final response = await http.patch(
//         Uri.parse(apiUrl),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode({
//           'status': 'approved',  // Most APIs only need status
//         }),
//       );
//
//       print('PATCH Response status: ${response.statusCode}');
//       print('PATCH Response body: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//         print('Success response: $responseData');
//
//         // Update the leave status locally
//         final index = _leaves.indexWhere((leave) => leave.id == leaveId);
//         if (index != -1) {
//           _leaves[index] = _leaves[index].copyWith(status: 'approved');
//           print('Updated local leave status to: ${_leaves[index].status}');
//           _applyFilters();
//         }
//
//         _successMessage = 'Leave approved successfully!';
//
//         // Refresh leaves list
//         await fetchLeaves();
//       } else if (response.statusCode == 400) {
//         // Try with different field names based on the error
//         final errorData = json.decode(response.body);
//         print('400 Error: $errorData');
//
//         // Try different field combinations
//         await _tryAlternativeApproveMethods(leaveId, token);
//       } else {
//         throw Exception('Failed to approve leave: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       _error = e.toString();
//       print('Error in approveLeave: $e');
//       print('Stack trace: $stackTrace');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> _tryAlternativeApproveMethods(int leaveId, String token) async {
//     print('Trying alternative approve methods...');
//
//     // Method 1: Try PUT with different field names
//     print('Method 1: Trying PUT with approval_status...');
//     try {
//       final response = await http.put(
//         Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'approval_status': 'approved',
//           'approved_at': DateTime.now().toIso8601String(),
//           'approved_by': _currentUserId,
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('PUT with approval_status worked!');
//         return;
//       }
//       print('PUT failed with: ${response.statusCode}');
//     } catch (e) {
//       print('PUT error: $e');
//     }
//
//     // Method 2: Try POST to approve endpoint
//     print('Method 2: Trying POST to /approve...');
//     try {
//       final response = await http.post(
//         Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/approval'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'action': 'approve',
//           'approved_by': _currentUserId,
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('POST to /approval worked!');
//         return;
//       }
//       print('POST to /approval failed with: ${response.statusCode}');
//     } catch (e) {
//       print('POST error: $e');
//     }
//
//     // Method 3: Try different endpoint structure
//     print('Method 3: Trying /update-status endpoint...');
//     try {
//       final response = await http.post(
//         Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/update-status'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'status': 'approved',
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('/update-status worked!');
//         return;
//       }
//       print('/update-status failed with: ${response.statusCode}');
//     } catch (e) {
//       print('/update-status error: $e');
//     }
//
//     throw Exception('All approve methods failed. Please check API documentation.');
//   }
//
//   Future<void> rejectLeave(int leaveId) async {
//     try {
//       // Check if user is admin
//       if (!_isAdmin) {
//         throw Exception('Only admin users can reject leaves');
//       }
//
//       _isLoading = true;
//       _error = '';
//       _successMessage = '';
//       notifyListeners();
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('No authentication token found');
//       }
//
//       print('=== REJECT LEAVE ===');
//       print('Leave ID to reject: $leaveId');
//
//       // Try PATCH method with just status
//       final apiUrl = 'https://api.afaqmis.com/api/leaves/$leaveId/status';
//       print('Trying PATCH to: $apiUrl');
//
//       final response = await http.patch(
//         Uri.parse(apiUrl),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode({
//           'status': 'rejected',
//         }),
//       );
//
//       print('PATCH Response status: ${response.statusCode}');
//       print('PATCH Response body: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//         print('Success response: $responseData');
//
//         // Update the leave status locally
//         final index = _leaves.indexWhere((leave) => leave.id == leaveId);
//         if (index != -1) {
//           _leaves[index] = _leaves[index].copyWith(status: 'rejected');
//           print('Updated local leave status to: ${_leaves[index].status}');
//           _applyFilters();
//         }
//
//         _successMessage = 'Leave rejected successfully!';
//
//         // Refresh leaves list
//         await fetchLeaves();
//       } else if (response.statusCode == 400) {
//         // Try with different field names
//         final errorData = json.decode(response.body);
//         print('400 Error: $errorData');
//
//         // Try alternative reject methods
//         await _tryAlternativeRejectMethods(leaveId, token);
//       } else {
//         throw Exception('Failed to reject leave: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       _error = e.toString();
//       print('Error in rejectLeave: $e');
//       print('Stack trace: $stackTrace');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> _tryAlternativeRejectMethods(int leaveId, String token) async {
//     print('Trying alternative reject methods...');
//
//     // Method 1: Try PUT with different field names
//     print('Method 1: Trying PUT with approval_status...');
//     try {
//       final response = await http.put(
//         Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'approval_status': 'rejected',
//           'rejected_at': DateTime.now().toIso8601String(),
//           'rejected_by': _currentUserId,
//           'rejection_reason': 'Rejected by admin',
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('PUT with approval_status worked!');
//         return;
//       }
//       print('PUT failed with: ${response.statusCode}');
//     } catch (e) {
//       print('PUT error: $e');
//     }
//
//     // Method 2: Try POST to reject endpoint
//     print('Method 2: Trying POST to /reject...');
//     try {
//       final response = await http.post(
//         Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/rejection'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'action': 'reject',
//           'rejected_by': _currentUserId,
//           'reason': 'Rejected by admin',
//         }),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         print('POST to /rejection worked!');
//         return;
//       }
//       print('POST to /rejection failed with: ${response.statusCode}');
//     } catch (e) {
//       print('POST error: $e');
//     }
//
//     throw Exception('All reject methods failed. Please check API documentation.');
//   }
//   Future<bool> submitLeave({
//     required String natureOfLeave,
//     required DateTime fromDate,
//     required DateTime toDate,
//     required int days,
//     String? reason,
//   }) async {
//     try {
//       _isLoading = true;
//       _error = '';
//       _successMessage = '';
//       notifyListeners();
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('No authentication token found');
//       }
//
//       // Check if we have all required user data
//       if (_currentUserId == null) {
//         throw Exception('User ID not found. Please login again.');
//       }
//       if (_currentDepartmentId == null) {
//         throw Exception('Department ID not found. Please login again.');
//       }
//
//       // Prepare the request body with all required fields
//       final requestBody = {
//         'leave_id': _generateLeaveId(),
//         'date': DateTime.now().toIso8601String().split('T')[0], // Current date
//         'department_id': _currentDepartmentId,
//         'employee_id': _currentUserId,
//         'nature_of_leave': natureOfLeave,
//         'from_date': fromDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
//         'to_date': toDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
//         'days': days,
//         'reason': reason ?? '',
//         'submitted_by_role': _userRole,
//       };
//
//       print('Submitting leave request: $requestBody');
//
//       final response = await http.post(
//         Uri.parse('https://api.afaqmis.com/api/leaves'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       );
//
//       print('Submit leave response status: ${response.statusCode}');
//       print('Submit leave response body: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Refresh the leaves list to include the new leave
//         await fetchLeaves();
//
//         _successMessage = 'Leave request submitted successfully!';
//         return true;
//       } else {
//         final errorData = json.decode(response.body);
//         final errorMessage = errorData['message'] ??
//             errorData['error'] ??
//             'Failed to submit leave request: ${response.statusCode}';
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       _error = e.toString();
//       print('Error submitting leave: $e');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Statistics
//   int get pendingCount => _leaves.where((leave) => leave.status.toLowerCase() == 'pending').length;
//   int get approvedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'approved').length;
//   int get rejectedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'rejected').length;
//   int get totalDays => _leaves.fold(0, (sum, leave) => sum + leave.days);
//
//   void clearFilters() {
//     _searchQuery = '';
//     _selectedDepartmentFilter = 'All';
//     _selectedEmployeeFilter = 'All';
//     _selectedStatusFilter = 'All';
//     _applyFilters();
//     notifyListeners();
//   }
//
//   void clearMessages() {
//     _error = '';
//     _successMessage = '';
//     notifyListeners();
//   }
//
//
//   // Debug method
//   Future<void> debugUserInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     print('=== DEBUG USER INFO ===');
//     print('Stored user_role: "${prefs.getString('user_role')}"');
//     print('Stored user_id: ${prefs.getInt('user_id')}');
//     print('Stored token exists: ${prefs.getString('token') != null}');
//
//     final userDataString = prefs.getString('userData');
//     if (userDataString != null) {
//       try {
//         final userData = jsonDecode(userDataString);
//         print('userData:');
//         print('  id: ${userData['id']}');
//         print('  name: "${userData['name']}"');
//         print('  role_label: "${userData['role_label']}"');
//       } catch (e) {
//         print('Error parsing userData: $e');
//       }
//     }
//
//     print('Current provider state:');
//     print('  _userRole: "$_userRole"');
//     print('  _isAdmin: $_isAdmin');
//     print('  _currentUserId: $_currentUserId');
//     print('  _currentEmployeeName: "$_currentEmployeeName"');
//     print('========================');
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

          // Save for future use
          await prefs.setString('user_role', _userRole!);
          if (_currentUserId != null) {
            await prefs.setInt('user_id', _currentUserId!);
          }
          if (_currentEmployeeName != null) {
            await prefs.setString('employee_name', _currentEmployeeName!);
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

      _currentDepartmentId = prefs.getInt('department_id');
      _currentEmployeeCode = prefs.getString('employee_code');

      // Check if user is admin
      final roleLower = _userRole!.toLowerCase().trim();
      _isAdmin = roleLower.contains('admin');

      print('Final values:');
      print('User Role: "$_userRole"');
      print('Role (lowercase): "$roleLower"');
      print('User ID: $_currentUserId');
      print('User Name: $_currentEmployeeName');
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
      print('User Role: $_userRole, isAdmin: $_isAdmin, User ID: $_currentUserId');

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
            print('First leave: ${_leaves.first.id}, status: ${_leaves.first.status}');
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

  // New method to fetch all employees for dropdown
  Future<void> fetchAllEmployees() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('https://api.afaqmis.com/api/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Fetch employees response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Employees response type: ${responseData.runtimeType}');

        List<dynamic> employeeList = [];

        // Handle different API response formats
        if (responseData is Map) {
          if (responseData.containsKey('data')) {
            employeeList = responseData['data'] is List ? responseData['data'] : [];
          } else if (responseData.containsKey('employees')) {
            employeeList = responseData['employees'];
          } else if (responseData.containsKey('result')) {
            employeeList = responseData['result'];
          }
        } else if (responseData is List) {
          employeeList = responseData;
        }

        _allEmployees = employeeList.map((employee) {
          return {
            'id': employee['id'] ?? employee['employee_id'] ?? 0,
            'name': employee['name']?.toString() ?? employee['employee_name']?.toString() ?? 'Unknown',
            'employee_code': employee['employee_code']?.toString() ?? employee['code']?.toString() ?? '',
            'department_id': employee['department_id'] ?? 0,
            'department_name': employee['department_name']?.toString() ?? '',
          };
        }).toList();

        print('Fetched ${_allEmployees.length} employees for dropdown');
      } else {
        print('Failed to fetch employees: ${response.statusCode}');
        print('Response body: ${response.body}');
        _allEmployees = [];

        // If API fails, fallback to employees from leaves
        if (_leaves.isNotEmpty) {
          final uniqueEmployees = _leaves.map((leave) {
            return {
              'id': leave.employeeId,
              'name': leave.employeeName,
              'employee_code': leave.employeeCode,
              'department_id': leave.departmentId,
              'department_name': leave.departmentName,
            };
          }).toSet().toList();

          _allEmployees = uniqueEmployees;
          print('Fallback: Using ${_allEmployees.length} employees from leaves data');
        }
      }
    } catch (e) {
      print('Error fetching employees: $e');
      _allEmployees = [];

      // Fallback to employees from leaves
      if (_leaves.isNotEmpty) {
        final uniqueEmployees = _leaves.map((leave) {
          return {
            'id': leave.employeeId,
            'name': leave.employeeName,
            'employee_code': leave.employeeCode,
            'department_id': leave.departmentId,
            'department_name': leave.departmentName,
          };
        }).toSet().toList();

        _allEmployees = uniqueEmployees;
        print('Fallback on error: Using ${_allEmployees.length} employees from leaves data');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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

      // Prepare the request body
      final requestBody = {
        'leave_id': _generateLeaveId(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'department_id': selectedEmployee['department_id'] ?? _currentDepartmentId,
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
          leave.leaveId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
            matchesStatus = leaveStatus == 'pending';
            break;
          case 'approved':
            matchesStatus = leaveStatus == 'approved';
            break;
          case 'rejected':
            matchesStatus = leaveStatus == 'rejected';
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

      // Try PATCH method with just status (common for partial updates)
      final apiUrl = 'https://api.afaqmis.com/api/leaves/$leaveId/status';
      print('Trying PATCH to: $apiUrl');

      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status': 'approved',  // Most APIs only need status
        }),
      );

      print('PATCH Response status: ${response.statusCode}');
      print('PATCH Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Success response: $responseData');

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
      } else if (response.statusCode == 400) {
        // Try with different field names based on the error
        final errorData = json.decode(response.body);
        print('400 Error: $errorData');

        // Try different field combinations
        await _tryAlternativeApproveMethods(leaveId, token);
      } else {
        throw Exception('Failed to approve leave: ${response.statusCode}');
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

  Future<void> _tryAlternativeApproveMethods(int leaveId, String token) async {
    print('Trying alternative approve methods...');

    // Method 1: Try PUT with different field names
    print('Method 1: Trying PUT with approval_status...');
    try {
      final response = await http.put(
        Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'approval_status': 'approved',
          'approved_at': DateTime.now().toIso8601String(),
          'approved_by': _currentUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('PUT with approval_status worked!');
        return;
      }
      print('PUT failed with: ${response.statusCode}');
    } catch (e) {
      print('PUT error: $e');
    }

    // Method 2: Try POST to approve endpoint
    print('Method 2: Trying POST to /approve...');
    try {
      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/approval'),
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
        print('POST to /approval worked!');
        return;
      }
      print('POST to /approval failed with: ${response.statusCode}');
    } catch (e) {
      print('POST error: $e');
    }

    // Method 3: Try different endpoint structure
    print('Method 3: Trying /update-status endpoint...');
    try {
      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/update-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'approved',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('/update-status worked!');
        return;
      }
      print('/update-status failed with: ${response.statusCode}');
    } catch (e) {
      print('/update-status error: $e');
    }

    throw Exception('All approve methods failed. Please check API documentation.');
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

      // Try PATCH method with just status
      final apiUrl = 'https://api.afaqmis.com/api/leaves/$leaveId/status';
      print('Trying PATCH to: $apiUrl');

      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status': 'rejected',
        }),
      );

      print('PATCH Response status: ${response.statusCode}');
      print('PATCH Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Success response: $responseData');

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
      } else if (response.statusCode == 400) {
        // Try with different field names
        final errorData = json.decode(response.body);
        print('400 Error: $errorData');

        // Try alternative reject methods
        await _tryAlternativeRejectMethods(leaveId, token);
      } else {
        throw Exception('Failed to reject leave: ${response.statusCode}');
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

  Future<void> _tryAlternativeRejectMethods(int leaveId, String token) async {
    print('Trying alternative reject methods...');

    // Method 1: Try PUT with different field names
    print('Method 1: Trying PUT with approval_status...');
    try {
      final response = await http.put(
        Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'approval_status': 'rejected',
          'rejected_at': DateTime.now().toIso8601String(),
          'rejected_by': _currentUserId,
          'rejection_reason': 'Rejected by admin',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('PUT with approval_status worked!');
        return;
      }
      print('PUT failed with: ${response.statusCode}');
    } catch (e) {
      print('PUT error: $e');
    }

    // Method 2: Try POST to reject endpoint
    print('Method 2: Trying POST to /reject...');
    try {
      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/leaves/$leaveId/rejection'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': 'reject',
          'rejected_by': _currentUserId,
          'reason': 'Rejected by admin',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('POST to /rejection worked!');
        return;
      }
      print('POST to /rejection failed with: ${response.statusCode}');
    } catch (e) {
      print('POST error: $e');
    }

    throw Exception('All reject methods failed. Please check API documentation.');
  }

  // Statistics
  int get pendingCount => _leaves.where((leave) => leave.status.toLowerCase() == 'pending').length;
  int get approvedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'approved').length;
  int get rejectedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'rejected').length;
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
    print('Stored token exists: ${prefs.getString('token') != null}');

    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        print('userData:');
        print('  id: ${userData['id']}');
        print('  name: "${userData['name']}"');
        print('  role_label: "${userData['role_label']}"');
      } catch (e) {
        print('Error parsing userData: $e');
      }
    }

    print('Current provider state:');
    print('  _userRole: "$_userRole"');
    print('  _isAdmin: $_isAdmin');
    print('  _currentUserId: $_currentUserId');
    print('  _currentEmployeeName: "$_currentEmployeeName"');
    print('========================');
  }
}