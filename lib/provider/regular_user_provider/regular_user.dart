import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
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
    int present    = json['present_count']     ?? 0;
    int absent     = json['absent_count']      ?? 0;
    int leave      = json['leave_count']       ?? 0;
    int late       = json['late_count']        ?? 0;
    int shortLeave = json['short_leave_count'] ?? 0;
    int total      = present + absent + leave;

    return NonAdminDashboardSummary(
      type:              json['type']                  ?? 'employee',
      employeeId:        json['employee_id']?.toString() ?? '',
      employeeName:      json['employee_name']         ?? '',
      month:             json['month']                 ?? '',
      presentCount:      present,
      absentCount:       absent,
      leaveCount:        leave,
      shortLeaveCount:   shortLeave,
      lateCount:         late,
      presentPercentage: total   > 0 ? (present / total)   * 100 : 0,
      absentPercentage:  total   > 0 ? (absent  / total)   * 100 : 0,
      leavePercentage:   total   > 0 ? (leave   / total)   * 100 : 0,
      latePercentage:    present > 0 ? (late    / present) * 100 : 0,
      totalDays:         total,
    );
  }

  Map<String, dynamic> toJson() => {
    'type':               type,
    'employee_id':        employeeId,
    'employee_name':      employeeName,
    'month':              month,
    'present_count':      presentCount,
    'absent_count':       absentCount,
    'leave_count':        leaveCount,
    'short_leave_count':  shortLeaveCount,
    'late_count':         lateCount,
    'present_percentage': presentPercentage,
    'absent_percentage':  absentPercentage,
    'leave_percentage':   leavePercentage,
    'late_percentage':    latePercentage,
    'total_days':         totalDays,
  };

  bool get isNoDataForDate =>
      presentCount == 0 && absentCount == 0 && leaveCount == 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
class NonAdminDashboardProvider extends ChangeNotifier {
  NonAdminDashboardSummary? _currentSummary;
  bool    _isLoading     = false;
  bool    _isRefreshing  = false;
  String? _error;
  bool    _isInitialized = false;
  late SharedPreferences _prefs;
  String? _currentMonth;

  static const String _baseUrl = 'https://api.afaqmis.com';

  // ── Public getters ────────────────────────────────────────────────────────
  NonAdminDashboardSummary? get currentSummary  => _currentSummary;
  bool    get isLoading     => _isLoading;
  bool    get isRefreshing  => _isRefreshing;
  String? get error         => _error;
  bool    get isInitialized => _isInitialized;
  String? get currentMonth  => _currentMonth;

  NonAdminDashboardProvider() {
    _init();
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedSummary();
  }

  // ── Compatibility stubs ───────────────────────────────────────────────────
  // These are kept so existing call-sites don't break.
  // They are no-ops because we now always read token & employee_id
  // fresh from SharedPreferences (owned by AuthProvider).
  void setAuthToken(String token) {
    debugPrint('ℹ️ setAuthToken() called — no-op, token read from prefs automatically');
  }

  void setEmployeeId(String employeeId) {
    debugPrint('ℹ️ setEmployeeId() called — no-op, employee_id read from prefs automatically');
  }

  // ── Load only cached summary (never caches employee_id) ──────────────────
  Future<void> _loadCachedSummary() async {
    try {
      final String? savedData  = _prefs.getString('non_admin_dashboard_data');
      final String? savedMonth = _prefs.getString('non_admin_selected_month');

      if (savedData != null) {
        final Map<String, dynamic> jsonData = jsonDecode(savedData);
        _currentSummary = NonAdminDashboardSummary.fromJson(jsonData);
        debugPrint('📦 Loaded cached dashboard summary');
      }
      if (savedMonth != null) {
        _currentMonth = savedMonth;
      }
    } catch (e) {
      debugPrint('❌ Error loading cached dashboard data: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ── Resolve employee ID — always reads AuthProvider's prefs key ───────────
  //
  //  AuthProvider.login() does:
  //    1. prefs.clear()                          — wipes all stale values
  //    2. prefs.setString('employee_id', ...)    — saves the correct ID
  //
  //  So 'employee_id' in prefs is always the current user's correct ID.
  //  We NEVER write our own shadow copy, so nothing can go stale.
  String? _resolveEmployeeId() {
    // ✅ Primary source of truth — set by AuthProvider after login
    final id = _prefs.getString('employee_id');
    if (id != null && id.isNotEmpty) {
      debugPrint('✅ employee_id resolved: $id');
      return id;
    }

    // Fallback: user_id (int) — also set by AuthProvider
    final userId = _prefs.getInt('user_id');
    if (userId != null) {
      debugPrint('⚠️ employee_id missing — falling back to user_id: $userId');
      return userId.toString();
    }

    debugPrint('❌ Could not resolve employee ID from prefs');
    return null;
  }

  // ── Save summary to cache ─────────────────────────────────────────────────
  Future<void> _saveData() async {
    try {
      if (_currentSummary != null) {
        await _prefs.setString(
          'non_admin_dashboard_data',
          jsonEncode(_currentSummary!.toJson()),
        );
      }
      if (_currentMonth != null) {
        await _prefs.setString('non_admin_selected_month', _currentMonth!);
      }
    } catch (e) {
      debugPrint('❌ Error saving dashboard data: $e');
    }
  }

  // ── HTTP GET with Bearer token ────────────────────────────────────────────
  Future<Map<String, dynamic>> _apiGet(
      String endpoint, {
        Map<String, dynamic>? queryParams,
      }) async {
    // Always read token fresh — AuthProvider owns the 'token' key
    final authToken = _prefs.getString('token');
    if (authToken == null || authToken.isEmpty) {
      throw Exception('No authentication token — please login again');
    }

    final uri = Uri.parse('$_baseUrl/api/$endpoint').replace(
      queryParameters: queryParams?.map(
            (k, v) => MapEntry(k, v.toString()),
      ),
    );

    debugPrint('🌐 GET $uri');
    debugPrint('🔑 Token: ${authToken.substring(0, authToken.length.clamp(0, 20))}...');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type':  'application/json',
        'Accept':        'application/json',
        'Authorization': 'Bearer $authToken',
      },
    ).timeout(const Duration(seconds: 30));

    debugPrint('📥 Status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        return jsonDecode(response.body) as Map<String, dynamic>;
      case 401:
        throw Exception('Unauthorized — please login again');
      case 404:
        throw Exception('Not found (404): ${response.body}');
      default:
        throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }

  // ── Fetch dashboard summary ───────────────────────────────────────────────
  Future<void> fetchDashboardSummary({String? month}) async {
    if (_isLoading) return;

    // Resolve employee ID fresh every time — no stale in-memory value
    final employeeId = _resolveEmployeeId();
    if (employeeId == null) {
      _error = 'Employee ID not found — please login again';
      debugPrint('❌ $_error');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error     = null;

    final monthToUse = (month != null && month.isNotEmpty)
        ? month
        : DateFormat('MM-yyyy').format(DateTime.now());

    _currentMonth = monthToUse;
    notifyListeners();

    try {
      final queryParams = {
        'employee_id': employeeId,
        'month':       monthToUse,
      };

      debugPrint('🌐 Fetching dashboard — params: $queryParams');

      final response = await _apiGet(
        'dashboard-summary',
        queryParams: queryParams,
      );

      if (response.isNotEmpty) {
        _currentSummary = NonAdminDashboardSummary.fromJson(response);
        _error = null;
        await _saveData();

        debugPrint('✅ Dashboard loaded — '
            'Present: ${_currentSummary!.presentCount}, '
            'Absent: ${_currentSummary!.absentCount}, '
            'Late: ${_currentSummary!.lateCount}');
      } else {
        _error = 'Empty response from server';
        debugPrint('❌ $_error');
      }
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchDashboardSummary error: $e');

      if (e.toString().contains('Unauthorized')) {
        await _prefs.remove('token');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Convenience helpers ───────────────────────────────────────────────────
  Future<void> refreshDashboardData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    await fetchDashboardSummary(
      month: _currentMonth ?? DateFormat('MM-yyyy').format(DateTime.now()),
    );

    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> fetchDataForMonth(DateTime month) async {
    await fetchDashboardSummary(
      month: DateFormat('MM-yyyy').format(month),
    );
  }

  String getCurrentMonthFormatted() =>
      DateFormat('MM-yyyy').format(DateTime.now());

  // ── Clear / logout ────────────────────────────────────────────────────────
  // Only clears OUR cache keys.
  // Never touches 'employee_id' or 'token' — those belong to AuthProvider.
  void clearData() {
    _currentSummary = null;
    _error          = null;
    _currentMonth   = null;
    _prefs.remove('non_admin_dashboard_data');
    _prefs.remove('non_admin_selected_month');
    notifyListeners();
  }

  Future<void> logout() async => clearData();
}