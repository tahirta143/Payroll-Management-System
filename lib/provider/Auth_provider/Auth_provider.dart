import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payroll_app/Utility/global_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../permissions_provider/permissions.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  String? token;
  Map<String, dynamic>? userData;
  List<dynamic>? roles;
  List<dynamic>? permissionDetails;

  Future<bool> login(
      String username,
      String password,
      PermissionProvider permissionProvider,
      ) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${GlobalUrls.baseurl}/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emailOrUsername": username,
          "password": password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token = data['token'];
        userData = data['user'];
        roles = data['roles'];
        permissionDetails = data['permissionDetails'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // ── Token save ──────────────────────────────────────────
        await prefs.setString('token', token!);

        // ── User basic info ─────────────────────────────────────
        final userId   = data['user']['id'] as int;
        final userName = data['user']['name']?.toString() ?? '';
        final userRole = data['user']['role_label']?.toString() ?? 'user';
        final empCode  = data['user']['employee_code']?.toString() ?? '';

        await prefs.setInt('user_id', userId);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_role', userRole);
        await prefs.setString('employee_name', userName);
        await prefs.setString('employee_code', empCode);
        await prefs.setString('user_image', data['user']['profile_image']?.toString() ??   // ADD THIS
            data['user']['image']?.toString() ??
            data['user']['avatar']?.toString() ?? '');
        await prefs.setString('userData', jsonEncode(userData));

        // ── Department ID ────────────────────────────────────────
        // API response mein department kahan hai check karo
        int deptId = 0;

        // Try 1: direct department_id field
        if (data['user']['department_id'] != null) {
          deptId = int.tryParse(data['user']['department_id'].toString()) ?? 0;
        }
        // Try 2: department object
        if (deptId == 0 && data['user']['department'] is Map) {
          deptId = int.tryParse(
              data['user']['department']['id']?.toString() ?? '0') ??
              0;
        }
        // Try 3: employee object mein
        if (deptId == 0 && data['employee'] is Map) {
          deptId = int.tryParse(
              data['employee']['department_id']?.toString() ?? '0') ??
              0;
        }

        if (deptId > 0) {
          await prefs.setInt('department_id', deptId);
          print('✅ Department ID saved: $deptId');
        } else {
          print('⚠️ Department ID not found in login response');
          // Department ID baad mein employee API se fetch karenge
        }

        // ── Employee ID fetch karo ───────────────────────────────
        print('🔍 Fetching employee ID for user: $userName (ID: $userId)');
        final empResult = await _fetchEmployeeData(token!, userId, userName);

        final employeeIdStr = empResult['id'] ?? userId.toString();
        final employeeIdInt = int.tryParse(employeeIdStr) ?? userId;
        final employeeDeptId = empResult['department_id'] ?? 0;

        await prefs.setString('employee_id', employeeIdStr);
        await prefs.setInt('employee_id_int', employeeIdInt);

        // Agar department ID abhi bhi 0 hai to employee data se lo
        if (deptId == 0 && employeeDeptId > 0) {
          deptId = employeeDeptId;
          await prefs.setInt('department_id', deptId);
          print('✅ Department ID from employee data: $deptId');
        }

        // ── Verification log ─────────────────────────────────────
        print('==========================================');
        print('✅ LOGIN - SAVED DATA:');
        print('  user_id         = $userId');
        print('  user_name       = "$userName"');
        print('  employee_name   = "$userName"');
        print('  user_role       = "$userRole"');
        print('  employee_id     = "$employeeIdStr"');
        print('  employee_id_int = $employeeIdInt');
        print('  department_id   = $deptId');
        print('==========================================');

        // ── Permissions ─────────────────────────────────────────
        permissionProvider.setPermissions(
          List<String>.from(data['permissions'] ?? []),
        );
        permissionProvider.setUserRole(userRole);

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login error: $e');
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  // Call this method when you need to ensure employee ID is available
  Future<String> getEmployeeId() async {
    // First try from userData
    if (userData != null) {
      final id = userData!['employee_id']?.toString() ??
          userData!['emp_id']?.toString() ?? '';
      if (id.isNotEmpty && id != 'null') {
        return id;
      }
    }

    // Try from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('employee_id');
    if (savedId != null && savedId.isNotEmpty) {
      // Update userData
      if (userData != null) {
        userData!['employee_id'] = savedId;
        userData!['emp_id'] = savedId;
        notifyListeners();
      }
      return savedId;
    }

    // If still not found, use user ID as fallback
    if (userData != null) {
      final userId = userData!['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        print('⚠️ Using user ID as fallback: $userId');
        return userId;
      }
    }

    return '';
  }
  // ── Employee data fetch (ID + department_id) ─────────────────────────────
  Future<Map<String, dynamic>> _fetchEmployeeData(
      String token, int userId, String userName) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/employees?limit=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> list = [];
        if (data is Map && data['data'] is List) {
          list = data['data'];
        } else if (data is Map && data['employees'] is List) {
          list = data['employees'];
        } else if (data is List) {
          list = data;
        }

        print('📋 Employees fetched: ${list.length}');

        // user_id se match — sabse reliable
        for (var emp in list) {
          if (emp['user_id']?.toString() == userId.toString()) {
            final empId   = emp['id']?.toString() ?? '';
            final deptId  = int.tryParse(
                emp['department_id']?.toString() ?? '0') ?? 0;
            print('✅ Found by user_id: emp_id=$empId, dept_id=$deptId');
            return {'id': empId, 'department_id': deptId};
          }
        }

        // Name se match — fallback
        final firstName = userName.split(' ').first.toLowerCase();
        for (var emp in list) {
          final empName = emp['name']?.toString().toLowerCase() ?? '';
          if (empName.contains(firstName)) {
            final empId  = emp['id']?.toString() ?? '';
            final deptId = int.tryParse(
                emp['department_id']?.toString() ?? '0') ?? 0;
            print('✅ Found by name: emp_id=$empId, dept_id=$deptId');
            return {'id': empId, 'department_id': deptId};
          }
        }

        print('⚠️ Employee not found in list');
      }
    } catch (e) {
      print('❌ Error fetching employee data: $e');
    }

    return {'id': userId.toString(), 'department_id': 0};
  }

  // ── Old fetchEmployeeId kept for compatibility ────────────────────────────
  Future<String> fetchEmployeeId(
      String token, int userId, String userName) async {
    final result = await _fetchEmployeeData(token, userId, userName);
    return result['id']?.toString() ?? userId.toString();
  }// Add this method to AuthProvider
  void debugPrintStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    print('🔍 SHARED PREFERENCES DEBUG ==========');
    print('employee_id: ${prefs.getString('employee_id')}');
    print('user_id: ${prefs.getInt('user_id')}');
    print('userData string: ${prefs.getString('userData')}');
    print('=======================================');
  }

  // ── Auto login ────────────────────────────────────────────────────────────
  // Future<void> autoLogin(PermissionProvider permissionProvider) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedToken = prefs.getString('token');
  //
  //   if (savedToken != null) {
  //     token = savedToken;
  //
  //     // Read saved values
  //     final savedName = prefs.getString('user_name') ?? '';
  //     final savedRole = prefs.getString('user_role') ?? '';
  //     final savedEmail = prefs.getString('user_email') ?? '';
  //     final savedImage = prefs.getString('user_image') ?? '';
  //     final savedEmployeeId = prefs.getString('employee_id') ?? ''; // This is "18"
  //     final userDataString = prefs.getString('userData');
  //     final rolesString = prefs.getString('roles');
  //     final permissionDetailsStr = prefs.getString('permissionDetails');
  //
  //     if (userDataString != null) {
  //       userData = jsonDecode(userDataString);
  //
  //       // 🔥 CRITICAL FIX: Add employee_id from SharedPreferences to userData
  //       if (savedEmployeeId.isNotEmpty) {
  //         userData!['employee_id'] = savedEmployeeId;
  //         userData!['emp_id'] = savedEmployeeId;
  //         print('✅✅✅ CRITICAL: Added employee_id "$savedEmployeeId" to userData');
  //       }
  //
  //       // If name is missing in userData, inject it from saved prefs
  //       if ((userData!['name'] == null || userData!['name'].toString().isEmpty) && savedName.isNotEmpty) {
  //         userData!['name'] = savedName;
  //       }
  //       if (userData!['profile_image'] == null || userData!['profile_image'].toString().isEmpty) {
  //         userData!['profile_image'] = savedImage;
  //       }
  //       // If role_label is missing, inject from saved prefs
  //       if ((userData!['role_label'] == null || userData!['role_label'].toString().isEmpty) && savedRole.isNotEmpty) {
  //         userData!['role_label'] = savedRole;
  //       }
  //
  //       permissionProvider.setUserRole(userData!['role_label'] ?? savedRole);
  //
  //       print('✅ autoLogin - userData restored with employee_id: ${userData!['employee_id']}');
  //     } else {
  //       // Fallback: rebuild minimal userData from saved prefs
  //       userData = {
  //         'name': savedName,
  //         'role_label': savedRole,
  //         'email': savedEmail,
  //         'profile_image': savedImage,
  //         'employee_id': savedEmployeeId, // 🔥 Add employee_id here
  //         'emp_id': savedEmployeeId,
  //         'id': prefs.getInt('user_id'),
  //       };
  //       permissionProvider.setUserRole(savedRole);
  //
  //       print('⚠️ autoLogin - userData rebuilt from prefs with employee_id: $savedEmployeeId');
  //     }
  //
  //     if (rolesString != null) {
  //       roles = jsonDecode(rolesString);
  //     }
  //
  //     if (permissionDetailsStr != null) {
  //       permissionDetails = jsonDecode(permissionDetailsStr);
  //       final permissions = permissionDetails!
  //           .map<String>((p) => p['code'] as String)
  //           .toList();
  //       permissionProvider.setPermissions(permissions);
  //     }
  //
  //     // Force a notify to update all listeners
  //     notifyListeners();
  //   }
  // }

  Future<void> autoLogin(PermissionProvider permissionProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken != null) {
      token = savedToken;

      // Read saved values
      final savedName = prefs.getString('user_name') ?? '';
      final savedRole = prefs.getString('user_role') ?? '';
      final savedEmail = prefs.getString('user_email') ?? '';
      final savedImage = prefs.getString('user_image') ?? '';
      final savedEmployeeId = prefs.getString('employee_id') ?? '';
      final userDataString = prefs.getString('userData');
      final rolesString = prefs.getString('roles');
      final permissionDetailsStr = prefs.getString('permissionDetails');

      print('🔐 AUTO LOGIN - Restoring data');
      print('  savedRole: $savedRole');
      print('  savedEmployeeId: $savedEmployeeId');
      print('  hasPermissionDetails: ${permissionDetailsStr != null}');

      if (userDataString != null) {
        userData = jsonDecode(userDataString);

        // Add employee_id to userData if missing
        if (savedEmployeeId.isNotEmpty &&
            (userData!['employee_id'] == null || userData!['employee_id'].toString().isEmpty)) {
          userData!['employee_id'] = savedEmployeeId;
          userData!['emp_id'] = savedEmployeeId;
          print('  ✅ Added employee_id to userData: $savedEmployeeId');
        }

        // Ensure role_label is in userData
        if ((userData!['role_label'] == null || userData!['role_label'].toString().isEmpty) && savedRole.isNotEmpty) {
          userData!['role_label'] = savedRole;
          print('  ✅ Added role_label to userData: $savedRole');
        }
      } else {
        // Fallback: rebuild minimal userData from saved prefs
        userData = {
          'name': savedName,
          'role_label': savedRole,
          'email': savedEmail,
          'profile_image': savedImage,
          'employee_id': savedEmployeeId,
          'emp_id': savedEmployeeId,
          'id': prefs.getInt('user_id'),
        };
        print('  ⚠️ userData rebuilt from prefs');
      }

      // Restore roles
      if (rolesString != null) {
        roles = jsonDecode(rolesString);
        print('  roles restored: ${roles?.length} roles');
      }

      // 🔥 CRITICAL: Restore permissionDetails and set permissions
      if (permissionDetailsStr != null) {
        permissionDetails = jsonDecode(permissionDetailsStr);
        print('  permissionDetails restored: ${permissionDetails?.length} permissions');

        // Extract permission codes
        final permissions = permissionDetails!
            .map<String>((p) => p['code'] as String)
            .toList();

        print('  Setting permissions in PermissionProvider: ${permissions.length} permissions');
        permissionProvider.setPermissions(permissions);
        permissionProvider.setUserRole(savedRole);
      } else {
        print('  ⚠️ No permissionDetails found in prefs');
        // Try to load from PermissionProvider's saved prefs as fallback
        await permissionProvider.loadFromPrefs();
      }

      // Force a notify to update all listeners
      notifyListeners();

      print('✅ AUTO LOGIN COMPLETE');
      print('  userRole: ${userData?['role_label']}');
      print('  permissions count: ${permissionProvider.permissions.length}');
    } else {
      print('❌ No saved token found');
    }
  }
  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    token            = null;
    userData         = null;
    roles            = null;
    permissionDetails = null;
    notifyListeners();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isAdmin {
    if (roles == null) return false;
    return roles!.any(
            (role) => role['name'].toString().toLowerCase().contains('admin'));
  }

  bool get isStaff {
    final role = userData?['role_label']?.toString().toLowerCase() ??
        userData?['role']?.toString().toLowerCase() ?? '';
    return role != 'admin' && role != 'administrator';
  }

  bool get isAttendenceUser {
    if (roles == null) return false;
    return roles!.any((role) =>
        role['name'].toString().toLowerCase().contains('attendence'));
  }

  bool hasPermission(String permissionCode) {
    if (permissionDetails == null) return false;
    return permissionDetails!.any((p) => p['code'] == permissionCode);
  }


  String get employeeId =>
      userData?['employee_id']?.toString() ??
          userData?['emp_id']?.toString() ?? '';

  String get userRole  => userData?['role_label'] ?? 'User';
  String get userName  => userData?['name'] ?? '';
  String get userEmail => userData?['email'] ?? '';
  String get userImage =>                                          // ADD THIS
  userData?['profile_image']?.toString() ??
      userData?['image']?.toString() ??
      userData?['avatar']?.toString() ??
      userData?['photo']?.toString() ?? '';
}