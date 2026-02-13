import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Model class
class NonAdminDashboardSummary {
  final String type;
  final String employeeId;
  final String employeeName;
  final String month;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int shortLeaveCount;
  final int lateCount;

  // Calculated fields
  final double presentPercentage;
  final double absentPercentage;
  final double leavePercentage;
  final double latePercentage;
  final int totalDays;

  NonAdminDashboardSummary({
    required this.type,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.shortLeaveCount,
    required this.lateCount,
    required this.presentPercentage,
    required this.absentPercentage,
    required this.leavePercentage,
    required this.latePercentage,
    required this.totalDays,
  });

  factory NonAdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    int present = json['present_count'] ?? 0;
    int absent = json['absent_count'] ?? 0;
    int leave = json['leave_count'] ?? 0;
    int late = json['late_count'] ?? 0;
    int shortLeave = json['short_leave_count'] ?? 0;
    int total = present + absent + leave;

    return NonAdminDashboardSummary(
      type: json['type'] ?? 'employee',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      month: json['month'] ?? '',
      presentCount: present,
      absentCount: absent,
      leaveCount: leave,
      shortLeaveCount: shortLeave,
      lateCount: late,
      presentPercentage: total > 0 ? (present / total) * 100 : 0,
      absentPercentage: total > 0 ? (absent / total) * 100 : 0,
      leavePercentage: total > 0 ? (leave / total) * 100 : 0,
      latePercentage: present > 0 ? (late / present) * 100 : 0,
      totalDays: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'month': month,
      'present_count': presentCount,
      'absent_count': absentCount,
      'leave_count': leaveCount,
      'short_leave_count': shortLeaveCount,
      'late_count': lateCount,
      'present_percentage': presentPercentage,
      'absent_percentage': absentPercentage,
      'leave_percentage': leavePercentage,
      'late_percentage': latePercentage,
      'total_days': totalDays,
    };
  }

  bool get isNoDataForDate => presentCount == 0 && absentCount == 0 && leaveCount == 0;
}

// Provider class
class NonAdminDashboardProvider extends ChangeNotifier {
  NonAdminDashboardSummary? _currentSummary;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  bool _isInitialized = false;
  late SharedPreferences _prefs;
  String? _employeeId;
  String? _currentMonth;
  String? _authToken; // Add this to store the auth token

  // API URL
  static const String _baseUrl = 'https://api.afaqmis.com';

  NonAdminDashboardSummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String? get currentMonth => _currentMonth;

  NonAdminDashboardProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load auth token from SharedPreferences
    _authToken = _prefs.getString('token');
    debugPrint('🔑 Auth token loaded: ${_authToken != null ? 'Yes' : 'No'}');
    await _loadSavedData();
  }

  void setAuthToken(String token) {
    _authToken = token;
    debugPrint('🔑 Auth token set in provider');
  }

  void setEmployeeId(String employeeId) {
    _employeeId = employeeId;
    debugPrint('✅ Employee ID set in provider: $_employeeId');
    _saveEmployeeId();
  }

  Future<void> _saveEmployeeId() async {
    if (_employeeId != null) {
      await _prefs.setString('non_admin_employee_id', _employeeId!);
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final String? savedData = _prefs.getString('non_admin_dashboard_data');
      final String? savedMonth = _prefs.getString('non_admin_selected_month');
      final String? savedEmployeeId = _prefs.getString('non_admin_employee_id');

      // Also try to get from auth provider's saved employee_id
      if (savedEmployeeId == null || savedEmployeeId.isEmpty) {
        // Try to get from the main employee_id saved by AuthProvider
        final authEmployeeId = _prefs.getString('employee_id');
        if (authEmployeeId != null && authEmployeeId.isNotEmpty) {
          _employeeId = authEmployeeId;
          debugPrint('✅ Loaded employee_id from AuthProvider storage: $_employeeId');
          await _prefs.setString('non_admin_employee_id', _employeeId!);
        }
      } else {
        _employeeId = savedEmployeeId;
        debugPrint('✅ Loaded employee_id from provider storage: $_employeeId');
      }

      if (savedData != null) {
        final Map<String, dynamic> jsonData = jsonDecode(savedData);
        _currentSummary = NonAdminDashboardSummary.fromJson(jsonData);
      }
      if (savedMonth != null) {
        _currentMonth = savedMonth;
      }
    } catch (e) {
      debugPrint('❌ Error loading saved dashboard data: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      if (_currentSummary != null) {
        await _prefs.setString(
            'non_admin_dashboard_data',
            jsonEncode(_currentSummary!.toJson())
        );
      }
      if (_currentMonth != null) {
        await _prefs.setString('non_admin_selected_month', _currentMonth!);
      }
    } catch (e) {
      debugPrint('❌ Error saving dashboard data: $e');
    }
  }

  /// Built-in API service method with authentication token
  Future<Map<String, dynamic>> _apiGet(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      // Check if token is available
      if (_authToken == null || _authToken!.isEmpty) {
        // Try to load token again from SharedPreferences
        _authToken = _prefs.getString('token');
        if (_authToken == null || _authToken!.isEmpty) {
          throw Exception('No authentication token available');
        }
      }

      String urlString = '$_baseUrl/api/$endpoint';

      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        urlString = '$urlString?$queryString';
      }

      final uri = Uri.parse(urlString);

      debugPrint('🌐 Making API request to: $uri');
      debugPrint('🔑 Using auth token: ${_authToken!.substring(0, min(20, _authToken!.length))}...');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken', // Add the authorization header
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📥 Response status code: ${response.statusCode}');

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - Token might be expired');
        throw Exception('Unauthorized - Please login again');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ API Request failed: $e');
      throw Exception('Network Error: $e');
    }
  }

  /// Fetches dashboard summary with authentication
  Future<void> fetchDashboardSummary({String? month}) async {
    if (_isLoading) return;

    // Check for auth token
    if (_authToken == null || _authToken!.isEmpty) {
      _authToken = _prefs.getString('token');
      if (_authToken == null || _authToken!.isEmpty) {
        _error = 'Authentication required - Please login again';
        debugPrint('❌ $_error');
        notifyListeners();
        return;
      }
    }

    // Check for employee ID
    if (_employeeId == null || _employeeId!.isEmpty) {
      debugPrint('⚠️ In-memory employeeId is null, checking SharedPreferences...');

      _employeeId = _prefs.getString('non_admin_employee_id');

      if (_employeeId == null || _employeeId!.isEmpty) {
        _employeeId = _prefs.getString('employee_id');
        if (_employeeId != null && _employeeId!.isNotEmpty) {
          debugPrint('✅ Found employee_id in auth storage: $_employeeId');
          await _prefs.setString('non_admin_employee_id', _employeeId!);
        }
      }

      if (_employeeId == null || _employeeId!.isEmpty) {
        _error = 'Employee ID not set';
        debugPrint('❌ $_error');
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _error = null;

    String monthToUse;
    if (month != null && month.isNotEmpty) {
      monthToUse = month;
    } else {
      monthToUse = DateFormat('MM-yyyy').format(DateTime.now());
    }

    _currentMonth = monthToUse;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      queryParams['employee_id'] = _employeeId!;
      queryParams['month'] = monthToUse;

      debugPrint('🌐 Fetching non-admin dashboard with params: $queryParams');

      final response = await _apiGet('dashboard-summary', queryParams: queryParams);

      if (response != null && response.isNotEmpty) {
        _currentSummary = NonAdminDashboardSummary.fromJson(response);
        _error = null;
        await _saveData();

        debugPrint('✅ Dashboard data loaded successfully');
        debugPrint('📊 Present: ${_currentSummary!.presentCount}');
      } else {
        _error = 'Failed to load dashboard data - empty response';
        debugPrint('❌ $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Exception fetching dashboard summary: $e');

      // If unauthorized, clear token and force re-login
      if (e.toString().contains('Unauthorized')) {
        _authToken = null;
        await _prefs.remove('token');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboardData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    String monthToUse = _currentMonth ?? DateFormat('MM-yyyy').format(DateTime.now());
    await fetchDashboardSummary(month: monthToUse);

    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> fetchDataForMonth(DateTime month) async {
    final formattedMonth = DateFormat('MM-yyyy').format(month);
    await fetchDashboardSummary(month: formattedMonth);
  }

  String getCurrentMonthFormatted() {
    return DateFormat('MM-yyyy').format(DateTime.now());
  }

  void clearData() {
    _currentSummary = null;
    _error = null;
    _currentMonth = null;
    _authToken = null;
    _prefs.remove('non_admin_dashboard_data');
    _prefs.remove('non_admin_selected_month');
    _prefs.remove('non_admin_employee_id');
    notifyListeners();
  }

  Future<void> logout() async {
    clearData();
  }
}

// Helper function for string substring
int min(int a, int b) => a < b ? a : b;