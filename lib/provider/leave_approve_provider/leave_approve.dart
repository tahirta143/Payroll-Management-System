// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../Utility/global_url.dart';
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
//   // New properties for employee dropdown and pay mode
//   List<Map<String, dynamic>> _allEmployees = [];
//   final List<String> _payModes = ['With Pay', 'Without Pay'];
//   final List<String> _leaveTypes = [
//     'sick_leave',
//     'annual_leave',
//     'casual_leave',
//     'emergency_leave',
//     'maternity_leave',
//     'paternity_leave',
//     'study_leave',
//     'compensatory_leave',
//     'urgent_work'
//   ];
//
//   // Debug mode
//   bool _debugMode = true;
//   String? _lastCreatedLeaveId;
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
//   String? get currentEmployeeName => _currentEmployeeName;
//   String? get currentEmployeeCode => _currentEmployeeCode;
//
//   // New getters
//   List<Map<String, dynamic>> get allEmployees => _allEmployees;
//   List<String> get payModes => _payModes;
//   List<String> get leaveTypes => _leaveTypes;
//   String? get lastCreatedLeaveId => _lastCreatedLeaveId;
// // Add this method to LeaveProvider
//   void setCurrentDepartmentId(int? deptId) {
//     _currentDepartmentId = deptId;
//     print('Updated current department ID to: $_currentDepartmentId');
//     notifyListeners();
//   }
//   // Call this method after user logs in to set their role and ID
//   Future<void> initializeUserData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       print('=== INITIALIZE USER DATA ===');
//
//       // Get user data
//       final userDataString = prefs.getString('userData');
//       if (userDataString != null && userDataString.isNotEmpty) {
//         try {
//           final userData = jsonDecode(userDataString);
//           print('userData: $userData');
//
//           // Extract user info
//           _currentUserId = userData['id'];
//           _currentEmployeeName = userData['name']?.toString() ?? '';
//           _currentEmployeeCode = userData['employee_code']?.toString() ?? '';
//           _userRole = userData['role_label']?.toString() ?? 'user';
//
//           // NORMALIZE THE ROLE - CRITICAL FIX
//           if (_userRole!.toLowerCase().contains('attendence') ||
//               _userRole!.toLowerCase().contains('attendance') ||
//               _userRole!.toLowerCase().contains('employee') ||
//               _userRole!.toLowerCase().contains('staff') ||
//               _userRole!.toLowerCase().contains('user')) {
//             _userRole = 'employee'; // Normalize to 'employee'
//             print('Normalized role from "${userData['role_label']}" to "$_userRole"');
//           }
//
//           // Extract department ID
//           if (userData['department'] != null) {
//             if (userData['department'] is Map) {
//               _currentDepartmentId = userData['department']['id'];
//             } else {
//               _currentDepartmentId = userData['department_id'];
//             }
//           }
//
//           // If department ID is still null, try to get it from department_id field
//           if (_currentDepartmentId == null && userData['department_id'] != null) {
//             _currentDepartmentId = userData['department_id'];
//           }
//
//           // Determine if admin
//           final roleLower = _userRole!.toLowerCase().trim();
//           _isAdmin = roleLower.contains('admin') ||
//               roleLower.contains('super') ||
//               roleLower.contains('manager');
//
//           // Save for future use
//           await prefs.setString('user_role', _userRole!);
//           if (_currentUserId != null) {
//             await prefs.setInt('user_id', _currentUserId!);
//           }
//           if (_currentEmployeeName != null) {
//             await prefs.setString('employee_name', _currentEmployeeName!);
//           }
//           if (_currentDepartmentId != null) {
//             await prefs.setInt('department_id', _currentDepartmentId!);
//           }
//           if (_currentEmployeeCode != null) {
//             await prefs.setString('employee_code', _currentEmployeeCode!);
//           }
//
//         } catch (e) {
//           print('Error parsing userData: $e');
//         }
//       }
//
//       // If still not set, try from storage
//       if (_userRole == null) {
//         _userRole = prefs.getString('user_role') ?? 'employee'; // Default to employee
//       }
//       if (_currentUserId == null) {
//         _currentUserId = prefs.getInt('user_id');
//       }
//       if (_currentEmployeeName == null) {
//         _currentEmployeeName = prefs.getString('employee_name');
//       }
//       if (_currentDepartmentId == null) {
//         _currentDepartmentId = prefs.getInt('department_id');
//       }
//       if (_currentEmployeeCode == null) {
//         _currentEmployeeCode = prefs.getString('employee_code');
//       }
//
//       // Re-check admin status
//       final roleLower = _userRole!.toLowerCase().trim();
//       _isAdmin = roleLower.contains('admin') ||
//           roleLower.contains('super') ||
//           roleLower.contains('manager');
//
//       print('Final values:');
//       print('User Role: "$_userRole"');
//       print('User ID: $_currentUserId');
//       print('User Name: "$_currentEmployeeName"');
//       print('User Code: "$_currentEmployeeCode"');
//       print('Department ID: $_currentDepartmentId');
//       print('isAdmin: $_isAdmin');
//       print('==============================');
//
//       notifyListeners();
//     } catch (e) {
//       print('Error initializing user data: $e');
//       _isAdmin = false;
//       _userRole = 'employee'; // Default to employee
//     }
//   }
//
//   // Generate a unique leave_id
//   // Generate a unique leave_id that matches API expected format: LV-123456789
//   String _generateLeaveId() {
//     final now = DateTime.now();
//     final random = Random();
//     // Generate 9 random digits
//     final randomNum = random.nextInt(900000000) + 100000000;
//     return 'LV-$randomNum'; // ✅ Format: LV-432980326
//   }
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
//       // Initialize user data first
//       await initializeUserData();
//
//       String apiUrl = '${GlobalUrls.baseurl}/api/leaves';
//
//       print('=== FETCH LEAVES ===');
//       print('Fetching from: $apiUrl');
//       print('User is admin: $_isAdmin');
//       print('Current user ID: $_currentUserId');
//       print('Current user name: "$_currentEmployeeName"');
//       print('Current department ID: $_currentDepartmentId');
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
//           print('=== API RESPONSE STRUCTURE ===');
//           responseData.forEach((key, value) {
//             print('Key: "$key", Type: ${value.runtimeType}');
//             if (value is List) {
//               print('  List length: ${value.length}');
//             }
//           });
//
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
//           // Debug: Print all leaves
//           print('=== DEBUG: ALL LEAVES FROM API ===');
//           for (var i = 0; i < min(_leaves.length, 10); i++) {
//             final leave = _leaves[i];
//             print('Leave ${i + 1}:');
//             print('  ID: ${leave.id}');
//             print('  Employee ID: ${leave.employeeId}');
//             print('  Employee Name: "${leave.employeeName}"');
//             print('  Employee Code: "${leave.employeeCode}"');
//             print('  Status: ${leave.status}');
//             print('  Department ID: ${leave.departmentId}');
//             if (leave.employeeId == _currentUserId) {
//               print('  ✓ THIS IS CURRENT USER (ID: $_currentUserId)');
//             }
//           }
//         }
//
//         // If user is not admin, filter to show only their leaves
//         if (!_isAdmin && _currentUserId != null) {
//           print('=== FILTERING LEAVES FOR NON-ADMIN USER ===');
//           print('Current user ID: $_currentUserId');
//           print('Current user name: "$_currentEmployeeName"');
//           final originalCount = _leaves.length;
//
//           if (!_debugMode) {
//             // Production filtering
//             _leaves = _leaves.where((leave) => leave.employeeId == _currentUserId).toList();
//             print('Filtered from $originalCount to ${_leaves.length} leaves for user ID: $_currentUserId');
//
//             // Also filter by employee name as additional check
//             if (_leaves.isEmpty && _currentEmployeeName != null) {
//               print('Trying to filter by employee name: "$_currentEmployeeName"');
//               _leaves = _leaves.where((leave) =>
//               leave.employeeName.toLowerCase().contains(_currentEmployeeName!.toLowerCase()) ||
//                   (_currentEmployeeCode != null && leave.employeeCode.toLowerCase().contains(_currentEmployeeCode!.toLowerCase()))
//               ).toList();
//               print('After name filtering: ${_leaves.length} leaves');
//             }
//           } else {
//             // Debug mode: Show debug info but don't filter
//             print('DEBUG MODE: Showing all leaves for debugging');
//             print('Total leaves: ${_leaves.length}');
//
//             // Count user's leaves
//             int userLeavesCount = _leaves.where((leave) => leave.employeeId == _currentUserId).length;
//             print('User has $userLeavesCount leaves in total list');
//
//             // Show user's leaves
//             print('=== USER LEAVES ===');
//             for (var leave in _leaves.where((leave) => leave.employeeId == _currentUserId)) {
//               print('  - ${leave.employeeName} (ID: ${leave.employeeId}) - Status: ${leave.status}');
//             }
//           }
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
//   // Add this method to fetch employee images
//   Future<Map<String, String>> fetchAllEmployees() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       if (token.isEmpty) return {};
//
//       final url = Uri.parse('${GlobalUrls.baseurl}/api/employees');
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> employeesData = responseData['employees'] ?? [];
//
//         // Create a map of employee codes to image URLs
//         final Map<String, String> employeeImageMap = {};
//
//         for (var emp in employeesData) {
//           final empCode = emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '';
//           final empName = emp['name']?.toString() ?? emp['employee_name']?.toString() ?? '';
//           final empId = emp['id']?.toString() ?? emp['employee_id']?.toString() ?? '';
//
//           // Try to get image URL from various possible fields
//           final imageUrl = emp['image_url']?.toString() ??
//               emp['profile_image']?.toString() ??
//               emp['avatar']?.toString() ??
//               emp['photo']?.toString() ??
//               emp['image']?.toString();
//
//           if (empCode.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
//             employeeImageMap[empCode] = imageUrl;
//           }
//           if (empName.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
//             employeeImageMap[empName] = imageUrl;
//           }
//           if (empId.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
//             employeeImageMap[empId] = imageUrl;
//           }
//         }
//
//         print('Fetched ${employeeImageMap.length} employee images');
//         return employeeImageMap;
//       }
//     } catch (e) {
//       print('Error fetching employee images: $e');
//     }
//
//     return {};
//   }
//
//   // NEW: Method to fetch all employees for dropdown
//   Future<void> fetchAllEmployeesForDropdown() async {
//     try {
//       print('=== FETCHING EMPLOYEES FOR DROPDOWN ===');
//       print('User is admin: $_isAdmin');
//       print('Current user ID: $_currentUserId');
//       print('Current user name: "$_currentEmployeeName"');
//       print('Current department ID: $_currentDepartmentId');
//
//       // Always clear existing list first
//       _allEmployees.clear();
//
//       // For non-admin users, add only themselves
//       if (!_isAdmin) {
//         print('Non-admin user: Adding only current user to dropdown');
//
//         if (_currentUserId != null && _currentEmployeeName != null) {
//           _allEmployees.add({
//             'id': _currentUserId!,
//             'name': _currentEmployeeName!,
//             'employee_code': _currentEmployeeCode ?? '',
//             'department_id': _currentDepartmentId ?? 1,
//             'department_name': 'My Department',
//             'designation': 'Employee',
//             'image': null,
//           });
//           print('Added current user to dropdown: "$_currentEmployeeName", Dept ID: $_currentDepartmentId');
//         } else {
//           print('Warning: Current user data not available for non-admin');
//         }
//
//         notifyListeners();
//         return;
//       }
//
//       // For admin users, fetch all employees from API
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('No authentication token found');
//       }
//
//       final url = Uri.parse('${GlobalUrls.baseurl}/api/employees');
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final List<dynamic> employeesData = responseData['employees'] ?? [];
//
//         print('Found ${employeesData.length} employees in API response');
//
//         // Process each employee
//         for (var emp in employeesData) {
//           try {
//             // Extract department ID - handle multiple formats
//             int? departmentId;
//
//             if (emp['department_id'] != null) {
//               departmentId = int.tryParse(emp['department_id'].toString());
//             } else if (emp['department'] != null) {
//               if (emp['department'] is Map) {
//                 departmentId = int.tryParse(emp['department']['id']?.toString() ?? '');
//               } else {
//                 departmentId = int.tryParse(emp['department'].toString());
//               }
//             } else if (emp['dept_id'] != null) {
//               departmentId = int.tryParse(emp['dept_id'].toString());
//             }
//
//             final employeeMap = {
//               'id': emp['id'] ?? 0,
//               'name': emp['name']?.toString() ?? 'Unknown',
//               'employee_code': emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '',
//               'department_id': departmentId ?? 1,
//               'department_name': emp['department_name']?.toString() ??
//                   (emp['department'] is Map ? emp['department']['name']?.toString() : 'Unknown Department'),
//               'designation': emp['designation']?.toString() ??
//                   (emp['designation_info'] is Map ? emp['designation_info']['name']?.toString() : ''),
//               'image': emp['image']?.toString() ??
//                   emp['image_url']?.toString() ??
//                   emp['profile_image']?.toString(),
//             };
//
//             // Only add if we have at least name
//             if (employeeMap['name'] != 'Unknown') {
//               _allEmployees.add(employeeMap);
//             }
//           } catch (e) {
//             print('Error processing employee: $e, data: $emp');
//           }
//         }
//
//         print('Successfully loaded ${_allEmployees.length} employees for dropdown');
//         notifyListeners();
//       } else {
//         print('Failed to fetch employees: ${response.statusCode}');
//         print('Response body: ${response.body}');
//         throw Exception('Failed to fetch employees: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       print('Error in fetchAllEmployeesForDropdown: $e');
//       print('Stack trace: $stackTrace');
//
//       // Fallback: Add current user even if there's an error
//       if (_currentUserId != null && _currentEmployeeName != null) {
//         _allEmployees.add({
//           'id': _currentUserId!,
//           'name': _currentEmployeeName!,
//           'employee_code': _currentEmployeeCode ?? '',
//           'department_id': _currentDepartmentId ?? 1,
//           'department_name': 'My Department',
//           'designation': 'Employee',
//           'image': null,
//         });
//         notifyListeners();
//       }
//
//       _error = 'Failed to load employees: $e';
//       notifyListeners();
//     }
//   }
//
//   // Submit leave for admin (selecting employee)
//   Future<bool> submitLeave({
//     required int selectedEmployeeId,
//     required String natureOfLeave,
//     required DateTime fromDate,
//     required DateTime toDate,
//     required int days,
//     required String payMode,
//     String? reason,
//   }) async {
//     try {
//       if (!_isAdmin) {
//         throw Exception('Only admin users can submit leaves for other employees');
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
//       // Find selected employee
//       final selectedEmployee = _allEmployees.firstWhere(
//             (emp) => emp['id'] == selectedEmployeeId,
//         orElse: () => {},
//       );
//
//       if (selectedEmployee.isEmpty) {
//         throw Exception('Selected employee not found');
//       }
//
//       int? departmentId = selectedEmployee['department_id'];
//       if (departmentId == null || departmentId == 0) {
//         departmentId = _currentDepartmentId ?? 1;
//       }
//
//       // ✅ FIX: Generate a leave_id (server will still generate its own, but API requires this field)
//       final generatedLeaveId = _generateLeaveId();
//
//       final requestBody = {
//         'leave_id': generatedLeaveId, // ✅ ADD THIS - API requires this field
//         'date': DateTime.now().toIso8601String().split('T')[0],
//         'department_id': departmentId,
//         'employee_id': selectedEmployeeId,
//         'nature_of_leave': natureOfLeave,
//         'from_date': fromDate.toIso8601String().split('T')[0],
//         'to_date': toDate.toIso8601String().split('T')[0],
//         'days': days,
//         'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
//         'reason': reason ?? '',
//         'submitted_by_role': 'admin',
//         'submitted_by': _currentUserId,
//         'status': 'pending',
//       };
//
//       print('=== ADMIN LEAVE SUBMISSION ===');
//       print('Request Body: $requestBody');
//
//       final response = await http.post(
//         Uri.parse('${GlobalUrls.baseurl}/api/leaves'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       );
//
//       print('Response Status: ${response.statusCode}');
//       print('Response Body: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//
//         // STORE THE REAL LEAVE ID FROM API (might be different from what we sent)
//         _lastCreatedLeaveId = responseData['leave_id']?.toString() ?? generatedLeaveId;
//
//         print('✅ ADMIN: Leave created with ID: $_lastCreatedLeaveId');
//
//         await fetchLeaves();
//
//         _successMessage = 'Leave request submitted successfully! Leave ID: $_lastCreatedLeaveId';
//         return true;
//       } else {
//         // Handle error response
//         try {
//           final errorData = json.decode(response.body);
//           final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to submit leave';
//           throw Exception(errorMessage);
//         } catch (e) {
//           throw Exception('Failed to submit leave: ${response.statusCode}');
//         }
//       }
//     } catch (e) {
//       _error = e.toString();
//       print('Error in submitLeave: $e');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//   // Update the problematic section (around line 679)
//   Future<bool> submitLeaveForSelf({
//     required String natureOfLeave,
//     required DateTime fromDate,
//     required DateTime toDate,
//     required int days,
//     required String payMode,
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
//       // Get employee ID and department ID from userData
//       int? employeeId;
//       int? departmentId;
//
//       final userDataString = prefs.getString('userData');
//       if (userDataString != null) {
//         try {
//           final userData = jsonDecode(userDataString);
//
//           // ❌ DON'T use 'id' - that's the user ID, not employee ID
//           // ✅ Use 'employee_id' or fetch from employees table
//           dynamic employeeIdRaw = userData['employee_id'] ?? userData['emp_id'];
//
//           if (employeeIdRaw != null) {
//             // If it's a string like "EMP-15", extract the number
//             if (employeeIdRaw is String && employeeIdRaw.startsWith('EMP-')) {
//               employeeId = int.tryParse(employeeIdRaw.substring(4));
//             } else {
//               employeeId = employeeIdRaw is String
//                   ? int.tryParse(employeeIdRaw)
//                   : employeeIdRaw.toInt();
//             }
//           }
//
//           // Extract department ID
//           if (userData['department'] is Map) {
//             departmentId = userData['department']['id']?.toInt();
//           }
//           if (departmentId == null) {
//             departmentId = userData['department_id']?.toInt() ??
//                 userData['dept_id']?.toInt();
//           }
//         } catch (e) {
//           print('Error parsing userData: $e');
//         }
//       }
//
//       // ❌ DON'T fallback to _currentUserId - that's the auth user ID
//       // Instead, fetch the actual employee ID from employees table
//       if (employeeId == null) {
//         // Fetch the employee record using the user's email or username
//         employeeId = await _fetchEmployeeIdFromDatabase(token);
//       }
//
//       departmentId ??= _currentDepartmentId;
//
//       if (employeeId == null || employeeId == 0) {
//         throw Exception('Employee ID is required. Please contact administrator.');
//       }
//       if (departmentId == null || departmentId == 0) {
//         throw Exception('Department ID is required. Please contact administrator.');
//       }
//
//       // Generate a leave_id (API requires this field)
//       final generatedLeaveId = _generateLeaveId();
//
//       // ✅ FIXED: Use 'emp_id' with "EMP-" prefix format
//       final requestBody = {
//         'leave_id': generatedLeaveId,
//         'date': DateTime.now().toIso8601String().split('T')[0],
//         'department_id': departmentId,
//         'employee_id': employeeId,  // ✅ Use 'emp_id' with EMP- prefix
//         'nature_of_leave': natureOfLeave,
//         'from_date': fromDate.toIso8601String().split('T')[0],
//         'to_date': toDate.toIso8601String().split('T')[0],
//         'days': days,
//         'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
//         'reason': reason ?? '',
//         'submitted_by_role': 'employee',
//         'submitted_by': employeeId,
//         'status': 'pending',
//       };
//
//       print('=== NON-ADMIN LEAVE SUBMISSION ===');
//       print('Request Body: $requestBody');
//
//       final response = await http.post(
//         Uri.parse('${GlobalUrls.baseurl}/api/leaves'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       );
//
//       print('Response Status: ${response.statusCode}');
//       print('Response Body: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//         _lastCreatedLeaveId = responseData['leave_id']?.toString() ?? generatedLeaveId;
//         print('✅ NON-ADMIN: Leave created with ID: $_lastCreatedLeaveId');
//
//         await fetchLeaves();
//         _successMessage = 'Leave request submitted successfully! Leave ID: $_lastCreatedLeaveId';
//         return true;
//       } else {
//         try {
//           final errorData = json.decode(response.body);
//           final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to submit leave';
//           throw Exception(errorMessage);
//         } catch (e) {
//           throw Exception('Failed to submit leave: ${response.statusCode}');
//         }
//       }
//     } catch (e, stackTrace) {
//       _error = e.toString();
//       print('Error in submitLeaveForSelf: $e');
//       print('Stack trace: $stackTrace');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
// // Add this helper method to fetch the actual employee ID
//   Future<int?> _fetchEmployeeIdFromDatabase(String token) async {
//     try {
//       // Use the current user's email or username to find their employee record
//       final prefs = await SharedPreferences.getInstance();
//       final userDataString = prefs.getString('userData');
//
//       if (userDataString != null) {
//         final userData = jsonDecode(userDataString);
//         final email = userData['email'];
//         final username = userData['username'];
//
//         // Fetch employees and find the one matching this user
//         final response = await http.get(
//           Uri.parse('${GlobalUrls.baseurl}/api/employees'),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           final List<dynamic> employees = data['employees'] ?? [];
//
//           // Try to match by email or name
//           for (var emp in employees) {
//             if (emp['email'] == email ||
//                 emp['name'] == userData['name'] ||
//                 emp['username'] == username) {
//               return emp['id']?.toInt();
//             }
//           }
//         }
//       }
//     } catch (e) {
//       print('Error fetching employee ID: $e');
//     }
//     return null;
//   }
//   void _extractFilters() {
//     // Extract unique departments
//     final departmentSet = _leaves
//         .where((leave) => leave.departmentName.isNotEmpty)
//         .map((leave) => leave.departmentName)
//         .toSet();
//
//     // For non-admin users, if no departments found, add their department
//     if (!_isAdmin && departmentSet.isEmpty && _currentEmployeeName != null) {
//       _departments = ['All', 'My Department'];
//       _selectedDepartmentFilter = 'My Department';
//     } else {
//       // Use Set to ensure uniqueness, then convert to List
//       final uniqueDepartments = departmentSet.toList()..sort();
//       _departments = ['All', ...uniqueDepartments];
//
//       // If non-admin, also add "My Department" option
//       if (!_isAdmin && _currentEmployeeName != null && !_departments.contains('My Department')) {
//         _departments.add('My Department');
//       }
//     }
//
//     // Extract unique employees - only for admin
//     if (_isAdmin) {
//       // FIX: Ensure employee names are unique
//       final employeeSet = _leaves
//           .where((leave) => leave.employeeName.isNotEmpty)
//           .map((leave) => leave.employeeName)
//           .toSet();  // Using Set to ensure uniqueness
//
//       // Convert to list and sort
//       final uniqueEmployees = employeeSet.toList()..sort();
//
//       // For admin users
//       _employees = ['All', ...uniqueEmployees];
//     } else {
//       // For non-admin, show only themselves
//       // FIX: Ensure only one "My Leaves" option
//       if (_currentEmployeeName != null && _currentEmployeeName!.isNotEmpty) {
//         _employees = ['All', _currentEmployeeName!];
//       } else {
//         _employees = ['All', 'My Leaves'];
//       }
//       _selectedEmployeeFilter = _currentEmployeeName ?? 'My Leaves';
//     }
//
//     print('Extracted ${_departments.length} departments and ${_employees.length} employees');
//     print('Departments: $_departments');
//     print('Employees: $_employees');
//   }
//   void _applyFilters() {
//     _filteredLeaves = _leaves.where((leave) {
//       // Search filter
//       final matchesSearch = _searchQuery.isEmpty ||
//           leave.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           leave.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           (leave.leaveId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
//           (leave.reason != null && leave.reason!.toLowerCase().contains(_searchQuery.toLowerCase()));
//
//       // Department filter
//       bool matchesDepartment;
//       if (!_isAdmin && _selectedDepartmentFilter == 'My Department') {
//         // For non-admin, if they have "My Department" selected, show all their leaves
//         matchesDepartment = true;
//       } else {
//         matchesDepartment = _selectedDepartmentFilter == 'All' ||
//             leave.departmentName == _selectedDepartmentFilter;
//       }
//
//       // Employee filter
//       bool matchesEmployee;
//       if (!_isAdmin) {
//         // For non-admin, only show their own leaves
//         matchesEmployee = leave.employeeId == _currentUserId ||
//             (_currentEmployeeName != null &&
//                 leave.employeeName.toLowerCase().contains(_currentEmployeeName!.toLowerCase()));
//       } else {
//         matchesEmployee = _selectedEmployeeFilter == 'All' ||
//             leave.employeeName == _selectedEmployeeFilter;
//       }
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
//             matchesStatus = leaveStatus == 'pending' || leaveStatus.contains('pending');
//             break;
//           case 'approved':
//             matchesStatus = leaveStatus == 'approved' || leaveStatus.contains('approved');
//             break;
//           case 'rejected':
//             matchesStatus = leaveStatus == 'rejected' || leaveStatus.contains('rejected');
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
//
//
//   // debug logs
//   Future<void> debugUserDataForLeave() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       print('=== DEBUG USER DATA FOR LEAVE ===');
//
//       // Check token
//       final token = prefs.getString('token');
//       print('Token exists: ${token != null && token.isNotEmpty}');
//
//       // Check userData
//       final userDataString = prefs.getString('userData');
//       print('UserData exists: ${userDataString != null}');
//
//       if (userDataString != null) {
//         try {
//           final userData = jsonDecode(userDataString);
//           print('Full UserData: $userData');
//
//           // Check all possible fields
//           final possibleIdFields = ['id', 'employee_id', 'user_id', 'emp_id', 'staff_id'];
//           final possibleDeptFields = ['department', 'department_id', 'dept_id'];
//
//           print('=== ID FIELDS ===');
//           for (var field in possibleIdFields) {
//             print('$field: ${userData[field]}');
//           }
//
//           print('=== DEPARTMENT FIELDS ===');
//           for (var field in possibleDeptFields) {
//             print('$field: ${userData[field]}');
//           }
//
//           // Check department structure
//           if (userData['department'] != null) {
//             print('Department field type: ${userData['department'].runtimeType}');
//             if (userData['department'] is Map) {
//               print('Department Map: ${userData['department']}');
//             }
//           }
//         } catch (e) {
//           print('Error parsing userData: $e');
//         }
//       }
//
//       print('=== PROVIDER STATE ===');
//       print('Current User ID: $_currentUserId');
//       print('Current Department ID: $_currentDepartmentId');
//       print('Current Employee Name: $_currentEmployeeName');
//       print('Current Employee Code: $_currentEmployeeCode');
//       print('User Role: $_userRole');
//       print('isAdmin: $_isAdmin');
//       print('============================');
//     } catch (e) {
//       print('Error in debugUserDataForLeave: $e');
//     }
//   }
//
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
//       // Try multiple methods
//       bool success = false;
//
//       // Method 1: PATCH to status endpoint
//       print('Method 1: Trying PATCH to /status...');
//       try {
//         final response = await http.patch(
//           Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId/status'),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//           },
//           body: jsonEncode({
//             'status': 'approved',
//             'approved_by': _currentUserId,
//             'approved_at': DateTime.now().toIso8601String(),
//           }),
//         );
//
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           print('PATCH to /status worked!');
//           success = true;
//         }
//       } catch (e) {
//         print('PATCH error: $e');
//       }
//
//       // Method 2: PUT to main endpoint
//       if (!success) {
//         print('Method 2: Trying PUT to main endpoint...');
//         try {
//           final response = await http.put(
//             Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'status': 'approved',
//               'approval_status': 'approved',
//               'approved_by': _currentUserId,
//               'approved_at': DateTime.now().toIso8601String(),
//             }),
//           );
//
//           if (response.statusCode == 200 || response.statusCode == 201) {
//             print('PUT worked!');
//             success = true;
//           }
//         } catch (e) {
//           print('PUT error: $e');
//         }
//       }
//
//       // Method 3: POST to approve endpoint
//       if (!success) {
//         print('Method 3: Trying POST to /approve...');
//         try {
//           final response = await http.post(
//             Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId/approve'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'action': 'approve',
//               'approved_by': _currentUserId,
//             }),
//           );
//
//           if (response.statusCode == 200 || response.statusCode == 201) {
//             print('POST to /approve worked!');
//             success = true;
//           }
//         } catch (e) {
//           print('POST error: $e');
//         }
//       }
//
//       if (success) {
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
//       } else {
//         throw Exception('All approve methods failed');
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
//       // Try multiple methods
//       bool success = false;
//
//       // Method 1: PATCH to status endpoint
//       print('Method 1: Trying PATCH to /status...');
//       try {
//         final response = await http.patch(
//           Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId/status'),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//           },
//           body: jsonEncode({
//             'status': 'rejected',
//             'rejected_by': _currentUserId,
//             'rejected_at': DateTime.now().toIso8601String(),
//             'rejection_reason': 'Rejected by admin',
//           }),
//         );
//
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           print('PATCH to /status worked!');
//           success = true;
//         }
//       } catch (e) {
//         print('PATCH error: $e');
//       }
//
//       // Method 2: PUT to main endpoint
//       if (!success) {
//         print('Method 2: Trying PUT to main endpoint...');
//         try {
//           final response = await http.put(
//             Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'status': 'rejected',
//               'approval_status': 'rejected',
//               'rejected_by': _currentUserId,
//               'rejected_at': DateTime.now().toIso8601String(),
//               'rejection_reason': 'Rejected by admin',
//             }),
//           );
//
//           if (response.statusCode == 200 || response.statusCode == 201) {
//             print('PUT worked!');
//             success = true;
//           }
//         } catch (e) {
//           print('PUT error: $e');
//         }
//       }
//       // Method 3: POST to reject endpoint
//       if (!success) {
//         print('Method 3: Trying POST to /reject...');
//         try {
//           final response = await http.post(
//             Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId/reject'),
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//             body: jsonEncode({
//               'action': 'reject',
//               'rejected_by': _currentUserId,
//               'rejection_reason': 'Rejected by admin',
//             }),
//           );
//
//           if (response.statusCode == 200 || response.statusCode == 201) {
//             print('POST to /reject worked!');
//             success = true;
//           }
//         } catch (e) {
//           print('POST error: $e');
//         }
//       }
//
//       if (success) {
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
//       } else {
//         throw Exception('All reject methods failed');
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
//   // Statistics
//   int get pendingCount => _leaves.where((leave) => leave.status.toLowerCase() == 'pending' || leave.status.toLowerCase().contains('pending')).length;
//   int get approvedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'approved' || leave.status.toLowerCase().contains('approved')).length;
//   int get rejectedCount => _leaves.where((leave) => leave.status.toLowerCase() == 'rejected' || leave.status.toLowerCase().contains('rejected')).length;
//   int get totalDays => _leaves.fold(0, (sum, leave) => sum + leave.days);
//
//   void clearFilters() {
//     _searchQuery = '';
//     if (_isAdmin) {
//       _selectedDepartmentFilter = 'All';
//       _selectedEmployeeFilter = 'All';
//     } else {
//       _selectedEmployeeFilter = _currentEmployeeName ?? 'My Leaves';
//     }
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
//   // Debug method
//   Future<void> debugUserInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     print('=== DEBUG USER INFO ===');
//     print('Stored user_role: "${prefs.getString('user_role')}"');
//     print('Stored user_id: ${prefs.getInt('user_id')}');
//     print('Stored department_id: ${prefs.getInt('department_id')}');
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
//         print('  department: ${userData['department']}');
//         print('  department_id: ${userData['department_id']}');
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
//     print('  _currentDepartmentId: $_currentDepartmentId');
//     print('  All employees count: ${_allEmployees.length}');
//     print('  Leaves count: ${_leaves.length}');
//     print('  Filtered leaves count: ${_filteredLeaves.length}');
//     print('========================');
//   }
//
//   // Toggle debug mode
//   void toggleDebugMode() {
//     _debugMode = !_debugMode;
//     print('Debug mode: $_debugMode');
//     notifyListeners();
//   }
// }
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

  bool _isAdmin = false;
  int? _currentUserId;
  int? _currentDepartmentId;
  String? _currentEmployeeCode;
  String? _currentEmployeeName;
  String? _userRole;

  // EMPLOYEE ID — yahi important hai (auth provider se save hoti hai)
  int? _currentEmployeeId;

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

  bool _debugMode = true;
  String? _lastCreatedLeaveId;

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
  int? get currentEmployeeId => _currentEmployeeId;
  List<Map<String, dynamic>> get allEmployees => _allEmployees;
  List<String> get payModes => _payModes;
  List<String> get leaveTypes => _leaveTypes;
  String? get lastCreatedLeaveId => _lastCreatedLeaveId;

  void setCurrentDepartmentId(int? deptId) {
    _currentDepartmentId = deptId;
    print('Updated current department ID to: $_currentDepartmentId');
    notifyListeners();
  }

  // ✅ FIX 1: initializeUserData — SharedPreferences se employee_id properly read karo
  // ✅ FIXED initializeUserData — null/zero department_id handle karta hai
  Future<void> initializeUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('=== INITIALIZE USER DATA ===');
      print('All prefs keys: ${prefs.getKeys()}');

      // ── STEP 1: Employee ID ───────────────────────────────────────────────
      final empIdInt = prefs.getInt('employee_id_int');
      if (empIdInt != null && empIdInt > 0) {
        _currentEmployeeId = empIdInt;
        print('✅ employee_id_int: $_currentEmployeeId');
      } else {
        final empIdStr = prefs.getString('employee_id') ?? '';
        final parsed = int.tryParse(empIdStr);
        if (parsed != null && parsed > 0) {
          _currentEmployeeId = parsed;
          print('✅ employee_id (string): $_currentEmployeeId');
        }
      }

      // ── STEP 2: User basic info ──────────────────────────────────────────
      _currentUserId       = prefs.getInt('user_id');
      _currentEmployeeName = prefs.getString('employee_name') ??
          prefs.getString('user_name');
      _currentEmployeeCode = prefs.getString('employee_code');
      _userRole            = prefs.getString('user_role') ?? 'employee';

      print('  user_id       = $_currentUserId');
      print('  employee_name = "$_currentEmployeeName"');
      print('  user_role     = "$_userRole"');

      // ── STEP 3: userData JSON se additional info ──────────────────────────
      final userDataString = prefs.getString('userData');
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final ud = jsonDecode(userDataString);

          // Employee name fallback
          if (_currentEmployeeName == null || _currentEmployeeName!.isEmpty) {
            _currentEmployeeName = ud['name']?.toString() ?? '';
          }

          // User ID fallback
          if (_currentUserId == null) {
            _currentUserId = ud['id'] as int?;
          }

          // Role from userData
          final roleFromData = ud['role_label']?.toString() ?? '';
          if (roleFromData.isNotEmpty) {
            _userRole = roleFromData;
          }

          print('  userData parsed OK — name: "${ud['name']}", role: "${ud['role_label']}"');
        } catch (e) {
          print('  ⚠️ userData parse error: $e');
        }
      }

      // ── STEP 4: Role normalize ────────────────────────────────────────────
      final roleLower = (_userRole ?? '').toLowerCase().trim();
      if (roleLower.contains('attendence') ||
          roleLower.contains('attendance') ||
          roleLower.contains('employee') ||
          roleLower.contains('staff') ||
          roleLower.contains('user')) {
        _userRole = 'employee';
      }

      _isAdmin = roleLower.contains('admin') ||
          roleLower.contains('super') ||
          roleLower.contains('manager');

      // ── STEP 5: Department ID ─────────────────────────────────────────────
      final savedDeptId = prefs.getInt('department_id');
      if (savedDeptId != null && savedDeptId > 0) {
        _currentDepartmentId = savedDeptId;
        print('✅ department_id from prefs: $_currentDepartmentId');
      } else {
        // Department ID nahi mila — API se fetch karo
        print('⚠️ Department ID not in prefs, fetching from API...');
        await _fetchAndSaveDepartmentId(prefs);
      }

      // ── STEP 6: Employee ID fallback ─────────────────────────────────────
      if (_currentEmployeeId == null || _currentEmployeeId == 0) {
        if (_currentUserId != null && _currentUserId! > 0) {
          _currentEmployeeId = _currentUserId;
          print('⚠️ Employee ID fallback to user_id: $_currentEmployeeId');
        }
      }

      print('\n✅ FINAL VALUES:');
      print('  userRole       = "$_userRole"');
      print('  isAdmin        = $_isAdmin');
      print('  userId         = $_currentUserId');
      print('  employeeId     = $_currentEmployeeId');
      print('  employeeName   = "$_currentEmployeeName"');
      print('  departmentId   = $_currentDepartmentId');
      print('==============================');

      notifyListeners();
    } catch (e) {
      print('❌ Error initializing user data: $e');
      _isAdmin  = false;
      _userRole = 'employee';
    }
  }

  // Department ID API se fetch karke save karo
  Future<void> _fetchAndSaveDepartmentId(SharedPreferences prefs) async {
    try {
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      final empIdInt = _currentEmployeeId ?? _currentUserId;
      if (empIdInt == null) return;

      // Employee detail se department_id lo
      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/employees/$empIdInt'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Response structure handle karo
        final empData = data is Map && data['data'] != null
            ? data['data']
            : data is Map && data['employee'] != null
            ? data['employee']
            : data;

        final deptId = int.tryParse(
            empData['department_id']?.toString() ?? '0') ?? 0;

        if (deptId > 0) {
          _currentDepartmentId = deptId;
          await prefs.setInt('department_id', deptId);
          print('✅ Department ID fetched from API: $deptId');
        }
      } else {
        // Fallback: employees list se try karo
        final listResponse = await http.get(
          Uri.parse('${GlobalUrls.baseurl}/api/employees?limit=1000'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (listResponse.statusCode == 200) {
          final listData = jsonDecode(listResponse.body);
          List<dynamic> empList = [];
          if (listData is Map && listData['data'] is List) {
            empList = listData['data'];
          } else if (listData is Map && listData['employees'] is List) {
            empList = listData['employees'];
          } else if (listData is List) {
            empList = listData;
          }

          for (var emp in empList) {
            if (emp['id']?.toString() == empIdInt.toString() ||
                emp['user_id']?.toString() == (_currentUserId?.toString() ?? '')) {
              final deptId = int.tryParse(
                  emp['department_id']?.toString() ?? '0') ?? 0;
              if (deptId > 0) {
                _currentDepartmentId = deptId;
                await prefs.setInt('department_id', deptId);
                print('✅ Department ID from list: $deptId');
                return;
              }
            }
          }
        }

        // Absolute fallback
        _currentDepartmentId = 1;
        print('⚠️ Department ID defaulting to 1');
      }
    } catch (e) {
      print('❌ Error fetching department: $e');
      _currentDepartmentId = 1; // default fallback
    }
  }

  // ✅ FIX 2: forceLoadEmployeeId — SharedPreferences se employee_id properly load karo
  Future<void> forceLoadEmployeeId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('🔍 FORCE LOADING EMPLOYEE ID FROM STORAGE');

      // Int try first
      final empIdInt = prefs.getInt('employee_id_int');
      if (empIdInt != null && empIdInt > 0) {
        _currentEmployeeId = empIdInt;
        print('✅ Force loaded employee_id_int: $_currentEmployeeId');
        notifyListeners();
        return;
      }

      // String fallback
      final empIdStr = prefs.getString('employee_id');
      if (empIdStr != null && empIdStr.isNotEmpty) {
        final parsed = int.tryParse(empIdStr);
        if (parsed != null && parsed > 0) {
          _currentEmployeeId = parsed;
          print('✅ Force loaded employee_id (string): $_currentEmployeeId');
          notifyListeners();
          return;
        }
      }

      // Last resort: user_id use karo
      if (_currentUserId != null && _currentUserId! > 0) {
        _currentEmployeeId = _currentUserId;
        print('⚠️ Force load: using user_id as employee_id: $_currentEmployeeId');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error force loading employee ID: $e');
    }
  }

  String _generateLeaveId() {
    final now = DateTime.now();
    final random = Random();
    final randomNum = random.nextInt(900000000) + 100000000;
    return 'LV-$randomNum';
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

      await initializeUserData();

      String apiUrl = '${GlobalUrls.baseurl}/api/leaves';

      print('=== FETCH LEAVES ===');
      print('User is admin: $_isAdmin');
      print('Current EMPLOYEE ID: $_currentEmployeeId');
      print('Current user ID: $_currentUserId');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        List<dynamic> leaveList = [];

        if (responseData is Map) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            leaveList = responseData['data'];
          } else if (responseData.containsKey('leaves') && responseData['leaves'] is List) {
            leaveList = responseData['leaves'];
          } else if (responseData.containsKey('result')) {
            leaveList = responseData['result'];
          }
        } else if (responseData is List) {
          leaveList = responseData;
        }

        _leaves = leaveList.map((json) => ApproveLeave.fromJson(json)).toList();

        // Non-admin ke liye employee ID se filter karo
        if (!_isAdmin && _currentEmployeeId != null) {
          print('=== FILTERING LEAVES FOR EMPLOYEE ===');
          print('Filtering by EMPLOYEE ID: $_currentEmployeeId');
          final originalCount = _leaves.length;
          _leaves = _leaves.where((leave) => leave.employeeId == _currentEmployeeId).toList();
          print('Filtered from $originalCount to ${_leaves.length} leaves');
        }

        _extractFilters();
        _applyFilters();
      } else {
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
        final Map<String, String> employeeImageMap = {};

        for (var emp in employeesData) {
          final empCode = emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '';
          final imageUrl = emp['image_url']?.toString() ??
              emp['profile_image']?.toString() ??
              emp['avatar']?.toString() ??
              emp['photo']?.toString() ??
              emp['image']?.toString();

          if (empCode.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
            employeeImageMap[empCode] = imageUrl;
          }
        }
        return employeeImageMap;
      }
    } catch (e) {
      print('Error fetching employee images: $e');
    }
    return {};
  }

  // ✅ FIX 3: fetchAllEmployeesForDropdown — non-admin ke liye EMPLOYEE ID use karo, user ID nahi
  Future<void> fetchAllEmployeesForDropdown() async {
    try {
      print('=== FETCHING EMPLOYEES FOR DROPDOWN ===');
      _allEmployees.clear();

      if (!_isAdmin) {
        // ✅ CORRECT: _currentEmployeeId use karo (employee table ka ID)
        // _currentUserId nahi (users table ka ID)
        final empId = _currentEmployeeId ?? _currentUserId;

        if (empId != null && _currentEmployeeName != null) {
          _allEmployees.add({
            'id': empId, // ✅ Employee ID
            'name': _currentEmployeeName!,
            'employee_code': _currentEmployeeCode ?? '',
            'department_id': _currentDepartmentId ?? 1,
            'department_name': 'My Department',
            'designation': 'Employee',
            'image': null,
          });
          print('✅ Non-admin employee added: $_currentEmployeeName (Employee ID: $empId)');
        }
        notifyListeners();
        return;
      }

      // Admin ke liye API se fetch karo
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> employeesData = responseData['employees'] ?? [];

        for (var emp in employeesData) {
          try {
            _allEmployees.add({
              'id': emp['id'] ?? 0,
              'name': emp['name']?.toString() ?? 'Unknown',
              'employee_code': emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '',
              'department_id': int.tryParse(emp['department_id']?.toString() ?? '1') ?? 1,
              'department_name': emp['department_name']?.toString() ?? 'Unknown Department',
              'designation': emp['designation']?.toString() ?? '',
              'image': emp['image']?.toString() ?? '',
            });
          } catch (e) {
            print('Error processing employee: $e');
          }
        }
        print('✅ Loaded ${_allEmployees.length} employees for dropdown');
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
  }

  // ✅ FIX 4: submitLeaveForSelf — employee_id properly use karo
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

      print('=== NON-ADMIN LEAVE SUBMISSION ===');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // STEP 1: Fresh load karo SharedPreferences se
      await forceLoadEmployeeId();

      // STEP 2: Agar abhi bhi null hai to initializeUserData try karo
      if (_currentEmployeeId == null || _currentEmployeeId == 0) {
        await initializeUserData();
      }

      // STEP 3: Final check — employee_id hona chahiye
      if (_currentEmployeeId == null || _currentEmployeeId == 0) {
        // Last fallback: user_id use karo
        if (_currentUserId != null && _currentUserId! > 0) {
          _currentEmployeeId = _currentUserId;
          print('⚠️ Using user_id as employee_id: $_currentEmployeeId');
        } else {
          throw Exception('Employee ID not found. Please logout and login again.');
        }
      }

      // STEP 4: Department ID fallback
      if (_currentDepartmentId == null || _currentDepartmentId == 0) {
        final savedDeptId = prefs.getInt('department_id');
        if (savedDeptId != null && savedDeptId > 0) {
          _currentDepartmentId = savedDeptId;
        } else {
          _currentDepartmentId = 1; // default
        }
        print('⚠️ Department ID fallback: $_currentDepartmentId');
      }

      print('✅ Submitting with EMPLOYEE ID: $_currentEmployeeId');
      print('✅ Department ID: $_currentDepartmentId');

      final generatedLeaveId = _generateLeaveId();

      final requestBody = {
        'leave_id': generatedLeaveId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'department_id': _currentDepartmentId,
        'employee_id': _currentEmployeeId!, // ✅ Employee ID (employees table)
        'nature_of_leave': natureOfLeave,
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'days': days,
        'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
        'reason': reason ?? '',
        'submitted_by_role': 'employee',
        'submitted_by': _currentEmployeeId!, // ✅ Employee ID
        'status': 'pending',
      };

      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${GlobalUrls.baseurl}/api/leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _lastCreatedLeaveId = responseData['leave_id']?.toString() ?? generatedLeaveId;
        _successMessage = 'Leave request submitted successfully! Leave ID: $_lastCreatedLeaveId';
        await fetchLeaves();
        return true;
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to submit leave';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Failed to submit leave: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      print('❌ Error in submitLeaveForSelf: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

      final selectedEmployee = _allEmployees.firstWhere(
            (emp) => emp['id'] == selectedEmployeeId,
        orElse: () => {},
      );

      if (selectedEmployee.isEmpty) {
        throw Exception('Selected employee not found');
      }

      int? departmentId = selectedEmployee['department_id'] ?? _currentDepartmentId ?? 1;

      final generatedLeaveId = _generateLeaveId();

      final requestBody = {
        'leave_id': generatedLeaveId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'department_id': departmentId,
        'employee_id': selectedEmployeeId,
        'nature_of_leave': natureOfLeave,
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'days': days,
        'pay_mode': payMode.toLowerCase().replaceAll(' ', '_'),
        'reason': reason ?? '',
        'submitted_by_role': 'admin',
        'submitted_by': _currentEmployeeId ?? _currentUserId,
        'status': 'pending',
      };

      print('=== ADMIN LEAVE SUBMISSION ===');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('${GlobalUrls.baseurl}/api/leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _lastCreatedLeaveId = responseData['leave_id']?.toString() ?? generatedLeaveId;
        _successMessage = 'Leave request submitted successfully! Leave ID: $_lastCreatedLeaveId';
        await fetchLeaves();
        return true;
      } else {
        throw Exception('Failed to submit leave: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      print('Error in submitLeave: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> _fetchEmployeeIdFromDatabase(String token) async {
    return _currentEmployeeId;
  }

  void _extractFilters() {
    final departmentSet = _leaves
        .where((leave) => leave.departmentName.isNotEmpty)
        .map((leave) => leave.departmentName)
        .toSet();

    if (!_isAdmin && departmentSet.isEmpty && _currentEmployeeName != null) {
      _departments = ['All', 'My Department'];
      _selectedDepartmentFilter = 'My Department';
    } else {
      final uniqueDepartments = departmentSet.toList()..sort();
      _departments = ['All', ...uniqueDepartments];
    }

    if (_isAdmin) {
      final employeeSet = _leaves
          .where((leave) => leave.employeeName.isNotEmpty)
          .map((leave) => leave.employeeName)
          .toSet();
      final uniqueEmployees = employeeSet.toList()..sort();
      _employees = ['All', ...uniqueEmployees];
    } else {
      if (_currentEmployeeName != null && _currentEmployeeName!.isNotEmpty) {
        _employees = ['All', _currentEmployeeName!];
      }
      _selectedEmployeeFilter = _currentEmployeeName ?? 'My Leaves';
    }
  }

  void _applyFilters() {
    _filteredLeaves = _leaves.where((leave) {
      final matchesSearch = _searchQuery.isEmpty ||
          leave.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          leave.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (leave.leaveId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      bool matchesDepartment;
      if (!_isAdmin && _selectedDepartmentFilter == 'My Department') {
        matchesDepartment = true;
      } else {
        matchesDepartment = _selectedDepartmentFilter == 'All' ||
            leave.departmentName == _selectedDepartmentFilter;
      }

      bool matchesEmployee;
      if (!_isAdmin) {
        matchesEmployee = leave.employeeId == _currentEmployeeId;
      } else {
        matchesEmployee = _selectedEmployeeFilter == 'All' ||
            leave.employeeName == _selectedEmployeeFilter;
      }

      final leaveStatus = leave.status.toLowerCase();
      final selectedStatus = _selectedStatusFilter.toLowerCase();

      bool matchesStatus;
      if (_selectedStatusFilter == 'All') {
        matchesStatus = true;
      } else {
        matchesStatus = leaveStatus.contains(selectedStatus);
      }

      return matchesSearch && matchesDepartment && matchesEmployee && matchesStatus;
    }).toList();
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

  Future<void> debugUserDataForLeave() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== DEBUG USER DATA FOR LEAVE ===');
    print('employee_id_int: ${prefs.getInt('employee_id_int')}');
    print('employee_id: ${prefs.getString('employee_id')}');
    print('Current Employee ID: $_currentEmployeeId');
    print('Current User ID: $_currentUserId');
    print('Current Employee Name: $_currentEmployeeName');
    print('isAdmin: $_isAdmin');
    print('============================');
  }

  Future<void> approveLeave(int leaveId) async {
    try {
      if (!_isAdmin) throw Exception('Only admin users can approve leaves');

      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('No authentication token found');

      bool success = false;

      try {
        final response = await http.patch(
          Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'status': 'approved',
            'approved_by': _currentEmployeeId ?? _currentUserId,
          }),
        );
        success = response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        print('PATCH error: $e');
      }

      if (success) {
        final index = _leaves.indexWhere((leave) => leave.id == leaveId);
        if (index != -1) {
          _leaves[index] = _leaves[index].copyWith(status: 'approved');
          _applyFilters();
        }
        _successMessage = 'Leave approved successfully!';
        await fetchLeaves();
      } else {
        throw Exception('Failed to approve leave');
      }
    } catch (e) {
      _error = e.toString();
      print('Error in approveLeave: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectLeave(int leaveId) async {
    try {
      if (!_isAdmin) throw Exception('Only admin users can reject leaves');

      _isLoading = true;
      _error = '';
      _successMessage = '';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('No authentication token found');

      bool success = false;

      try {
        final response = await http.patch(
          Uri.parse('${GlobalUrls.baseurl}/api/leaves/$leaveId/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'status': 'rejected',
            'rejected_by': _currentEmployeeId ?? _currentUserId,
            'rejection_reason': 'Rejected by admin',
          }),
        );
        success = response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        print('PATCH error: $e');
      }

      if (success) {
        final index = _leaves.indexWhere((leave) => leave.id == leaveId);
        if (index != -1) {
          _leaves[index] = _leaves[index].copyWith(status: 'rejected');
          _applyFilters();
        }
        _successMessage = 'Leave rejected successfully!';
        await fetchLeaves();
      } else {
        throw Exception('Failed to reject leave');
      }
    } catch (e) {
      _error = e.toString();
      print('Error in rejectLeave: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get pendingCount =>
      _leaves.where((leave) => leave.status.toLowerCase().contains('pending')).length;
  int get approvedCount =>
      _leaves.where((leave) => leave.status.toLowerCase().contains('approved')).length;
  int get rejectedCount =>
      _leaves.where((leave) => leave.status.toLowerCase().contains('rejected')).length;
  int get totalDays =>
      _leaves.fold(0, (sum, leave) => sum + leave.days);

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

  Future<void> debugUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== DEBUG USER INFO ===');
    print('Stored employee_id_int: ${prefs.getInt('employee_id_int')}');
    print('Stored employee_id: ${prefs.getString('employee_id')}');
    print('Current Employee ID: $_currentEmployeeId');
    print('Current User ID: $_currentUserId');
    print('Is Admin: $_isAdmin');
    print('========================');
  }

  void toggleDebugMode() {
    _debugMode = !_debugMode;
    print('Debug mode: $_debugMode');
    notifyListeners();
  }
}