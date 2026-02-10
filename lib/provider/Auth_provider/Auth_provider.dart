// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../permissions_provider/permissions.dart';
//
//
// class AuthProvider with ChangeNotifier {
//   bool isLoading = false;
//   String? token;
//
//   Future<bool> login(
//       String username,
//       String password,
//       PermissionProvider permissionProvider,
//       ) async {
//     isLoading = true;
//     notifyListeners();
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://api.afaqmis.com/api/users/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "emailOrUsername": username,
//           "password": password,
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//
//       if (response.statusCode == 200) {
//         token = data['token'];
//
//
//         // 🔹 Save token in SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('token', token!);
//
//         permissionProvider.setPermissions(
//           List<String>.from(data['permissions']),
//         );
//
//         isLoading = false;
//         notifyListeners();
//         return true;
//       }
//     } catch (_) {}
//
//     isLoading = false;
//     notifyListeners();
//     return false;
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../permissions_provider/permissions.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  String? token;
  Map<String, dynamic>? userData;
  List<dynamic>? roles;
  List<dynamic>? permissionDetails;

  // Future<bool> login(
  //     String username,
  //     String password,
  //     PermissionProvider permissionProvider,
  //     ) async {
  //   isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://api.afaqmis.com/api/users/login'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         "emailOrUsername": username,
  //         "password": password,
  //       }),
  //     );
  //
  //     final data = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200) {
  //       token = data['token'];
  //       userData = data['user'];
  //       roles = data['roles'];
  //       permissionDetails = data['permissionDetails'];
  //
  //       // Extract user information - use consistent field names
  //       final userRole = data['user']['role_label']?.toString() ??
  //           data['user']['role']?.toString() ??
  //           'user';
  //
  //       final userId = data['user']['id'] ??
  //           data['user']['user_id'] ??
  //           0;
  //
  //       final employeeCode = data['user']['employee_code']?.toString() ??
  //           data['user']['emp_id']?.toString() ??
  //           '';
  //
  //       final employeeName = data['user']['name']?.toString() ??
  //           data['user']['employee_name']?.toString() ??
  //           data['user']['username']?.toString() ??
  //           '';
  //
  //       // Save all data in SharedPreferences with consistent keys
  //       final prefs = await SharedPreferences.getInstance();
  //
  //       // Clear old data first
  //       await prefs.clear();
  //
  //       // Save new data
  //       await prefs.setString('token', token!);
  //       await prefs.setString('userData', jsonEncode(userData));
  //       await prefs.setString('roles', jsonEncode(roles));
  //       await prefs.setString('permissionDetails', jsonEncode(permissionDetails));
  //
  //       // CRITICAL: Save user role and info with consistent keys
  //       await prefs.setString('user_role', userRole);
  //       await prefs.setInt('user_id', userId);
  //       await prefs.setString('employee_code', employeeCode);
  //       await prefs.setString('employee_name', employeeName);
  //       await prefs.setString('user_name', employeeName); // Add this for compatibility
  //
  //       // For debugging - print what we're saving
  //       print('=== LOGIN SUCCESS - SAVED DATA ===');
  //       print('user_role: "$userRole"');
  //       print('user_id: $userId');
  //       print('employee_name: "$employeeName"');
  //       print('employee_code: "$employeeCode"');
  //       print('Is admin check: ${userRole.toLowerCase().contains('admin')}');
  //
  //       // Save raw user data for debugging
  //       await prefs.setString('debug_raw_login_data', jsonEncode(data));
  //
  //       // Set permissions in permission provider
  //       permissionProvider.setPermissions(
  //         List<String>.from(data['permissions']),
  //       );
  //
  //       // Also set user role for role-based navigation
  //       permissionProvider.setUserRole(userRole);
  //
  //       isLoading = false;
  //       notifyListeners();
  //       return true;
  //     } else {
  //       print('Login failed with status: ${response.statusCode}');
  //       print('Response: ${response.body}');
  //       isLoading = false;
  //       notifyListeners();
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Login error: $e');
  //     isLoading = false;
  //     notifyListeners();
  //     return false;
  //   }
  // }
  Future<bool> login(
      String username,
      String password,
      PermissionProvider permissionProvider,
      ) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emailOrUsername": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token = data['token'];
        userData = data['user'];
        roles = data['roles'];
        permissionDetails = data['permissionDetails'];

        // Extract employee ID - try multiple possible field names
        final employeeId = data['user']['employee_id']?.toString() ??
            data['user']['emp_id']?.toString() ??
            data['user']['id']?.toString() ??
            '';

        final employeeCode = data['user']['employee_code']?.toString() ??
            data['user']['emp_code']?.toString() ??
            '';

        final userRole = data['user']['role_label']?.toString() ??
            data['user']['role']?.toString() ??
            'user';

        final userName = data['user']['name']?.toString() ??
            data['user']['username']?.toString() ??
            '';

        // Save all data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // Clear old data
        await prefs.clear();

        // Save new data
        await prefs.setString('token', token!);
        await prefs.setString('userData', jsonEncode(userData));
        await prefs.setString('roles', jsonEncode(roles));
        await prefs.setString('permissionDetails', jsonEncode(permissionDetails));

        // Save employee-specific data
        await prefs.setString('employee_id', employeeId);
        await prefs.setString('employee_code', employeeCode);
        await prefs.setString('user_role', userRole);
        await prefs.setString('user_name', userName);

        // Debug log
        print('=== LOGIN SUCCESS ===');
        print('Employee ID: $employeeId');
        print('Employee Code: $employeeCode');
        print('User Role: $userRole');
        print('Is Staff: ${userRole.toLowerCase() != 'admin'}');

        // Set permissions
        permissionProvider.setPermissions(
          List<String>.from(data['permissions']),
        );

        // Set user role
        permissionProvider.setUserRole(userRole);

        isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  // Get employee ID
  String get employeeId {
    return userData?['employee_id']?.toString() ??
        userData?['emp_id']?.toString() ?? '';
  }

  // Check if user is staff (non-admin)
  bool get isStaff {
    final role = userData?['role_label']?.toString().toLowerCase() ??
        userData?['role']?.toString().toLowerCase() ??
        '';
    return role != 'admin' && role != 'administrator';
  }
  // users

  // Add this method to AuthProvider for testing
  Future<bool> debugTestLogin() async {
    print('=== DEBUG LOGIN TEST ===');

    // Try different credential formats
    final testCredentials = [
      {
        'username': 'admin@afaqmis.com',
        'password': 'admin123'
      },
      {
        'username': 'admin',
        'password': 'password'
      },
      {
        'username': 'administrator',
        'password': 'admin'
      },
      // Add your actual test credentials here
    ];

    for (var creds in testCredentials) {
      print('Testing: ${creds['username']}');
      final response = await http.post(
        Uri.parse('https://api.afaqmis.com/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emailOrUsername": creds['username'],
          "password": creds['password'],
        }),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Success with: ${creds['username']}');
        return true;
      }
    }

    return false;
  }
  Future<void> autoLogin(PermissionProvider permissionProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken != null) {
      token = savedToken;

      // Restore user data
      final userDataString = prefs.getString('userData');
      final rolesString = prefs.getString('roles');
      final permissionDetailsString = prefs.getString('permissionDetails');

      if (userDataString != null) {
        userData = jsonDecode(userDataString);
        permissionProvider.setUserRole(userData!['role_label'] ?? '');
      }

      if (rolesString != null) {
        roles = jsonDecode(rolesString);
      }

      if (permissionDetailsString != null) {
        permissionDetails = jsonDecode(permissionDetailsString);

        // Extract permission codes from details
        final permissions = permissionDetails!
            .map<String>((p) => p['code'] as String)
            .toList();
        permissionProvider.setPermissions(permissions);
      }

      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userData');
    await prefs.remove('roles');
    await prefs.remove('permissionDetails');

    token = null;
    userData = null;
    roles = null;
    permissionDetails = null;

    notifyListeners();
  }

  bool get isAdmin {
    if (roles == null) return false;
    return roles!.any((role) =>
        role['name'].toString().toLowerCase().contains('admin'));
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

  String get userRole => userData?['role_label'] ?? 'User';
  String get userName => userData?['name'] ?? '';
  String get userEmail => userData?['email'] ?? '';
}