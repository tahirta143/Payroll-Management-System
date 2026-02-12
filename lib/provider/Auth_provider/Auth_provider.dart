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
  }

  // ── Auto login ────────────────────────────────────────────────────────────
  Future<void> autoLogin(PermissionProvider permissionProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken != null) {
      token = savedToken;

      final userDataString       = prefs.getString('userData');
      final rolesString          = prefs.getString('roles');
      final permissionDetailsStr = prefs.getString('permissionDetails');

      if (userDataString != null) {
        userData = jsonDecode(userDataString);
        permissionProvider.setUserRole(userData!['role_label'] ?? '');
      }
      if (rolesString != null) {
        roles = jsonDecode(rolesString);
      }
      if (permissionDetailsStr != null) {
        permissionDetails = jsonDecode(permissionDetailsStr);
        final permissions = permissionDetails!
            .map<String>((p) => p['code'] as String)
            .toList();
        permissionProvider.setPermissions(permissions);
      }

      notifyListeners();
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
}