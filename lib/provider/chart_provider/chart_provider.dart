// chart_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/chart_model/chart_model.dart';
import '../Auth_provider/Auth_provider.dart';
import 'package:provider/provider.dart';

class ChartProvider extends ChangeNotifier {
  DashboardChartResponse? _chartData;
  String? _selectedMonth;
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;
  int? _userId;
  String? _userName;
  String? _employeeCode;

  DashboardChartResponse? get chartData => _chartData;
  String? get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _chartData != null && _chartData!.data.isNotEmpty;
  bool get isAdmin => _isAdmin;
  int? get userId => _userId;
  String? get userName => _userName;

  // Base URL for API
  static const String _baseUrl = 'https://api.afaqmis.com/api';

  // Load user info from SharedPreferences
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get user role
      final userRole = prefs.getString('user_role')?.toLowerCase() ?? '';
      _isAdmin = userRole.contains('admin') || userRole == 'administrator';

      // Get user ID
      _userId = prefs.getInt('user_id');

      // Get user name
      _userName = prefs.getString('employee_name') ??
          prefs.getString('user_name') ??
          'User';

      // Get employee code
      _employeeCode = prefs.getString('employee_code');

      print('👤 ChartProvider - Loaded User Info:');
      print('👤 Role: $_isAdmin (from: $userRole)');
      print('👤 User ID: $_userId');
      print('👤 Name: $_userName');
      print('👤 Employee Code: $_employeeCode');

    } catch (e) {
      print('❌ Error loading user info: $e');
      _isAdmin = false;
    }
  }

  // Fetch chart data with role-based filtering
  Future<void> fetchAttendanceData({String? month, BuildContext? context}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedMonth = month;

      // Load user info if not already loaded
      if (_userId == null) {
        await _loadUserInfo();
      }

      // If still no user info, try to get from AuthProvider context
      if (context != null && _userId == null) {
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          // _userId = authProvider.userId;
          _isAdmin = authProvider.isAdmin;
          _userName = authProvider.userName;
          print('👤 Loaded from AuthProvider:');
          print('👤 User ID: $_userId');
          print('👤 Is Admin: $_isAdmin');
        } catch (e) {
          print('❌ Error getting auth provider: $e');
        }
      }

      // Build API URL based on user role
      String apiUrl;
      final Map<String, String> queryParams = {};

      // Add month parameter if provided
      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
      }

      // For admin: Get all data
      // For regular user: Get only their data using employee_code
      if (!_isAdmin) {
        if (_employeeCode != null && _employeeCode!.isNotEmpty) {
          queryParams['employee_code'] = _employeeCode!;
          print('👤 Non-admin: Using employee_code: $_employeeCode');
        } else if (_userId != null) {
          queryParams['user_id'] = _userId.toString();
          print('👤 Non-admin: Using user_id: $_userId');
        } else {
          print('⚠️ Non-admin user has no employee_code or user_id');
        }
      } else {
        print('👑 Admin: Fetching all employee data');
      }

      // Build the final URL
      final uri = Uri.parse('$_baseUrl/dashboard-chart');
      apiUrl = uri.replace(queryParameters: queryParams).toString();

      print('📡 API Request:');
      print('📡 URL: $apiUrl');
      print('📡 User Role: ${_isAdmin ? "Admin" : "User"}');

      // Get authentication token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      print('📡 Token available: ${authToken != null && authToken.isNotEmpty}');

      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if token exists
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
        print('📡 Authorization header added');
      } else {
        print('⚠️ No auth token found in SharedPreferences');

        // Try to get token from AuthProvider
        if (context != null) {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.token != null) {
              headers['Authorization'] = 'Bearer ${authProvider.token}';
              print('📡 Got token from AuthProvider');
            }
          } catch (e) {
            print('❌ Error getting token from AuthProvider: $e');
          }
        }
      }

      print('📡 Making request with headers: $headers');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('✅ API Response successful');

        // Debug: Print first record
        if (jsonData['data'] is List && (jsonData['data'] as List).isNotEmpty) {
          print('📊 First record: ${jsonData['data'][0]}');
        }

        _chartData = DashboardChartResponse.fromJson(jsonData);

        // Show success message
        if (_isAdmin) {
          final count = _chartData?.data.length ?? 0;
          print('👑 Admin: Loaded $count records for all employees');
        } else {
          final count = _chartData?.data.length ?? 0;
          print('👤 User ($_userName): Loaded $count personal records');
        }

        _error = null;
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized. Please login again.';
        print('❌ 401 Unauthorized');

        try {
          final errorJson = jsonDecode(response.body);
          _error = errorJson['message'] ?? _error;
          print('❌ Error message: $_error');
        } catch (_) {}

        _chartData = null;

        // Clear token on auth failure
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');

      } else {
        _error = 'Failed to load data (Status: ${response.statusCode})';
        print('❌ API Error: $_error');
        print('❌ Response: ${response.body}');

        try {
          final errorJson = jsonDecode(response.body);
          _error = errorJson['message'] ?? _error;
        } catch (_) {}

        _chartData = null;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Exception: $e');
      _chartData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data
  void clearData() {
    _chartData = null;
    _selectedMonth = null;
    _error = null;
    notifyListeners();
  }

  // Get chart title based on user role
  String get chartTitle {
    String rolePrefix = _isAdmin ? 'Team ' : 'My ';

    if (_selectedMonth != null) {
      return '${rolePrefix}Attendance - ${_formatMonth(_selectedMonth!)}';
    }

    return '${rolePrefix}Attendance Overview';
  }

  String _formatMonth(String month) {
    try {
      final date = DateTime.parse('$month-01');
      return '${_getMonthName(date.month)} ${date.year}';
    } catch (_) {
      return month;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Get available months for dropdown
  List<String> get availableMonths {
    final months = <String>[];
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months.add(monthStr);
    }

    return months;
  }
}