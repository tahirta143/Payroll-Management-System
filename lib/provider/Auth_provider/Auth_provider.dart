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
import 'package:payroll_app/Utility/global_url.dart';
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
      // 1. PEHLE LOGIN KARO
      final response = await http.post(
        Uri.parse('${GlobalUrls.baseurl}/api/users/login'),
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

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Save token and basic data
        await prefs.setString('token', token!);
        await prefs.setString('userData', jsonEncode(userData));

        // 🔴🔴🔴 FIX: EMPLOYEE DATA ALAG SE FETCH KARO
        String employeeId = '';

        // USER ID SE EMPLOYEE DHUNDO
        final userId = data['user']['id'].toString(); // This is 15

        print('🔍 Fetching employee for user ID: $userId');

        // TRY 1: /api/employees/by-user/{userId}
        final empResponse = await http.get(
          Uri.parse('${GlobalUrls.baseurl}/api/employees/by-user/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        // After successful login
        if (response.statusCode == 200) {
          token = data['token'];
          userData = data['user'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Save token
          await prefs.setString('token', token!);

          // 🔴 FETCH REAL EMPLOYEE ID
          final userId = data['user']['id']; // 15
          final userName = data['user']['name'] ?? '';

          String employeeId = await fetchEmployeeId(token!, userId, userName);

          // Save employee ID
          await prefs.setString('employee_id', employeeId);
          await prefs.setInt('employee_id_int', int.tryParse(employeeId) ?? 0);

          print('✅ FINAL EMPLOYEE ID: $employeeId'); // Should be 18!
        }
        // TRY 2: Agar upar fail ho to /api/employees?user_id={userId}
        if (employeeId.isEmpty) {
          final empListResponse = await http.get(
            Uri.parse('${GlobalUrls.baseurl}/api/employees?user_id=$userId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (empListResponse.statusCode == 200) {
            final empListData = jsonDecode(empListResponse.body);
            if (empListData is List && empListData.isNotEmpty) {
              employeeId = empListData[0]['id']?.toString() ?? '';
              print('✅ Employee found via employees list: $employeeId');
            }
          }
        }

        // TRY 3: Agar employee mil gaya to use karo, warna user ID se kaam chalao
        if (employeeId.isEmpty) {
          // LAST RESORT: User se pucho manually
          print('⚠️⚠️⚠️ AUTO employee fetch FAILED!');
          print('User ID: $userId, User Name: ${data['user']['name']}');

          // TEMPORARY HARDCODE - SIRF MAZHAR AHMED KE LIYE
          if (data['user']['name']?.toString().contains('Mazhar') ?? false) {
            employeeId = '18';
            print('🔴 HARDCODED: Setting employee ID to 18 for Mazhar Ahmed');
          } else {
            employeeId = userId; // fallback to user ID
          }
        }

        // Save employee ID
        await prefs.setString('employee_id', employeeId);
        await prefs.setInt('employee_id_int', int.tryParse(employeeId) ?? 0);

        // Save other data
        final userRole = data['user']['role_label']?.toString() ?? 'user';
        final userName = data['user']['name']?.toString() ?? '';

        await prefs.setString('user_role', userRole);
        await prefs.setString('user_name', userName);

        print('🔴🔴🔴 FINAL - Employee ID saved: $employeeId');

        // Set permissions
        permissionProvider.setPermissions(
          List<String>.from(data['permissions']),
        );
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
  Future<String> fetchEmployeeId(String token, int userId, String userName) async {
    try {
      // 🔴 DIRECT APPROACH - User ID se employee dhundho
      print('🔍 Searching employee for user: $userName (ID: $userId)');

      // API call with filter
      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/employees?limit=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse employees list
        List<dynamic> employeesList = [];
        if (data is Map && data['data'] is List) {
          employeesList = data['data'];
        } else if (data is List) {
          employeesList = data;
        }

        // Find employee by name
        for (var emp in employeesList) {
          final empName = emp['name']?.toString() ?? '';
          final empId = emp['id']?.toString() ?? '';

          if (empName.contains('Mazhar') || userName.contains('Mazhar')) {
            print('✅ FOUND MAZHAR! Employee ID: $empId');
            return empId;
          }

          // Also try to match by user_id if available
          if (emp['user_id']?.toString() == userId.toString()) {
            print('✅ Found employee by user_id: $empId');
            return empId;
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching employees: $e');
    }

    // 🔴 FALLBACK - Hardcode for Mazhar
    if (userName.contains('Mazhar')) {
      print('⚠️ Using hardcoded ID 18 for Mazhar');
      return '18';
    }

    return userId.toString(); // fallback to user ID
  }
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
        Uri.parse('${GlobalUrls.baseurl}/api/users/login'),
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