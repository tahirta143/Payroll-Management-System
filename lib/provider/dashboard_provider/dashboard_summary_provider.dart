import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/dashboar_model/dashboard_summary.dart';

class DashboardSummaryProvider with ChangeNotifier {
  DashboardSummary? _dashboardSummary;
  DashboardSummary? _monthlySummary;
  String _selectedMonth = 'all';
  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;

  // Track if data has been fixed
  bool _dataWasFixed = false;
  String? _dataFixExplanation;

  // Base URL
  static const String _baseUrl = 'https://api.afaqmis.com';

  // SharedPreferences - NO LATE KEYWORD
  static SharedPreferences? _prefs;
  static const String _tokenKey = 'token';

  // Getters
  DashboardSummary? get dashboardSummary => _dashboardSummary;
  DashboardSummary? get monthlySummary => _monthlySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRefreshing => _isRefreshing;
  String get selectedMonth => _selectedMonth;
  bool get dataWasFixed => _dataWasFixed;
  String? get dataFixExplanation => _dataFixExplanation;

  // **CRITICAL FIX**: Static initialization method
  static Future<void> initializeSharedPreferences() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Get token from SharedPreferences
  Future<String> _getToken() async {
    try {
      // Initialize if not already done
      if (_prefs == null) {
        await initializeSharedPreferences();
      }

      final token = _prefs!.getString(_tokenKey);
      return token ?? '';
    } catch (e) {
      debugPrint('Error getting token: $e');
      return '';
    }
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    try {
      if (_prefs == null) {
        await initializeSharedPreferences();
      }
      await _prefs!.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Clear token from SharedPreferences
  Future<void> _clearToken() async {
    try {
      if (_prefs == null) {
        await initializeSharedPreferences();
      }
      await _prefs!.remove(_tokenKey);
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  // **NEW: Data sanitization and fixing method**
  DashboardSummary _sanitizeAndFixData(DashboardSummary original, Map<String, dynamic> rawData) {
    debugPrint('=== DATA SANITIZATION STARTED ===');
    debugPrint('Original data:');
    debugPrint('- total_employees: ${original.totalEmployees}');
    debugPrint('- present_count: ${original.presentCount}');
    debugPrint('- leave_count: ${original.leaveCount}');
    debugPrint('- absent_count: ${original.absentCount}');
    debugPrint('- short_leave_count: ${original.shortLeaveCount}');
    debugPrint('- late_comers_count: ${original.lateComersCount}');

    // Reset fix tracking
    _dataWasFixed = false;
    _dataFixExplanation = null;

    final errors = original.validate();

    if (errors.isEmpty) {
      debugPrint('✅ Data is valid, no fixes needed');
      return original;
    }

    debugPrint('⚠️ Data issues found:');
    for (final error in errors) {
      debugPrint('  - $error');
    }

    // Start with original data
    int totalEmployees = original.totalEmployees;
    int presentCount = original.presentCount;
    int leaveCount = original.leaveCount;
    int shortLeaveCount = original.shortLeaveCount;
    int absentCount = original.absentCount;
    int lateComersCount = original.lateComersCount;

    String fixExplanation = 'Data was adjusted because: ${errors.first}\n\n';

    // **FIX 1: If present = total, then leave and absent should be 0**
    if (presentCount == totalEmployees && (leaveCount > 0 || absentCount > 0)) {
      fixExplanation += 'Everyone is marked present, so leave and absent set to 0.\n';
      leaveCount = 0;
      absentCount = 0;
      _dataWasFixed = true;
    }

    // **FIX 2: If sum doesn't match total, adjust absent count**
    final sum = presentCount + leaveCount + absentCount;
    if (sum != totalEmployees) {
      if (sum > totalEmployees) {
        // Too many people in categories
        fixExplanation += 'Present($presentCount) + Leave($leaveCount) + Absent($absentCount) = $sum '
            'exceeds Total($totalEmployees). ';

        // Try different adjustment strategies
        if (presentCount <= totalEmployees) {
          // Keep present, adjust leave first, then absent
          final availableForLeaveAbsent = totalEmployees - presentCount;
          if (leaveCount > availableForLeaveAbsent) {
            leaveCount = availableForLeaveAbsent;
            absentCount = 0;
            fixExplanation += 'Adjusted leave to $leaveCount, absent to 0.';
          } else {
            absentCount = availableForLeaveAbsent - leaveCount;
            fixExplanation += 'Adjusted absent to $absentCount.';
          }
        } else {
          // Even present count is too high - scale everything down proportionally
          final scale = totalEmployees / sum;
          presentCount = (presentCount * scale).round();
          leaveCount = (leaveCount * scale).round();
          absentCount = totalEmployees - presentCount - leaveCount;
          fixExplanation += 'Scaled all values proportionally.';
        }
      } else {
        // Not enough people in categories - adjust absent
        absentCount = totalEmployees - presentCount - leaveCount;
        fixExplanation += 'Adjusted absent count to $absentCount to match total.';
      }
      _dataWasFixed = true;
    }

    // **FIX 3: Ensure late comers doesn't exceed present count**
    if (lateComersCount > presentCount) {
      fixExplanation += 'Late comers ($lateComersCount) exceeds present count ($presentCount). ';
      lateComersCount = presentCount;
      fixExplanation += 'Set late comers to present count: $lateComersCount.';
      _dataWasFixed = true;
    }

    // **FIX 4: Ensure short leave doesn't exceed present count**
    if (shortLeaveCount > presentCount) {
      fixExplanation += 'Short leave ($shortLeaveCount) exceeds present count ($presentCount). ';
      shortLeaveCount = presentCount;
      fixExplanation += 'Set short leave to present count: $shortLeaveCount.';
      _dataWasFixed = true;
    }

    // Create fixed summary
    final fixedSummary = DashboardSummary(
      totalEmployees: totalEmployees,
      presentCount: presentCount,
      leaveCount: leaveCount,
      shortLeaveCount: shortLeaveCount,
      absentCount: absentCount,
      lateComersCount: lateComersCount,
      month: original.month,
    );

    // Validate the fixed data
    final fixedErrors = fixedSummary.validate();
    if (fixedErrors.isEmpty) {
      debugPrint('✅ Data successfully fixed');
      debugPrint('Fixed data:');
      debugPrint('- total_employees: $totalEmployees');
      debugPrint('- present_count: $presentCount (${fixedSummary.presentPercentage.toStringAsFixed(1)}%)');
      debugPrint('- leave_count: $leaveCount (${fixedSummary.leavePercentage.toStringAsFixed(1)}%)');
      debugPrint('- absent_count: $absentCount (${fixedSummary.absentPercentage.toStringAsFixed(1)}%)');
      debugPrint('- short_leave_count: $shortLeaveCount');
      debugPrint('- late_comers_count: $lateComersCount');
    } else {
      debugPrint('❌ Fixing failed, errors remain:');
      for (final error in fixedErrors) {
        debugPrint('  - $error');
      }
    }

    _dataFixExplanation = fixExplanation;
    debugPrint('=== DATA SANITIZATION COMPLETED ===');

    return fixedSummary;
  }

  // Fetch dashboard summary (with optional month filter)
  Future<void> fetchDashboardSummary({String? month}) async {
    try {
      _isLoading = true;
      _error = null;
      _dataWasFixed = false;
      _dataFixExplanation = null;
      notifyListeners();

      // Initialize SharedPreferences if needed
      if (_prefs == null) {
        await initializeSharedPreferences();
      }

      // Build URL
      String url = '$_baseUrl/api/dashboard-summary';
      if (month != null && month.isNotEmpty && month != 'all') {
        url += '?month=$month';
        _selectedMonth = month;
      } else {
        _selectedMonth = 'all';
      }

      debugPrint('\n🔄 Fetching dashboard data from: $url');

      // Get token
      final token = await _getToken();

      if (token.isEmpty) {
        _error = 'Authentication required. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📥 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // **Log raw data for debugging**
        debugPrint('📊 Raw API Data:');
        debugPrint('total_employees: ${data['total_employees']}');
        debugPrint('present_count: ${data['present_count']}');
        debugPrint('leave_count: ${data['leave_count']}');
        debugPrint('absent_count: ${data['absent_count']}');
        debugPrint('short_leave_count: ${data['short_leave_count']}');
        debugPrint('late_comers_count: ${data['late_comers_count']}');

        // Calculate and log the issue
        final total = data['total_employees'] ?? 0;
        final present = data['present_count'] ?? 0;
        final leave = data['leave_count'] ?? 0;
        final absent = data['absent_count'] ?? 0;
        final sum = present + leave + absent;

        debugPrint('🔢 Data Validation Check:');
        debugPrint('Present($present) + Leave($leave) + Absent($absent) = $sum');
        debugPrint('Total Employees = $total');
        debugPrint('Difference = ${sum - total}');

        if (sum != total) {
          debugPrint('⚠️ WARNING: Data inconsistency detected!');
          debugPrint('   This suggests either:');
          debugPrint('   1. Test/mock data from server');
          debugPrint('   2. Bug in backend API logic');
          debugPrint('   3. Different calculation logic');
        }

        final originalSummary = DashboardSummary.fromJson(data);

        // **Sanitize and fix the data**
        final sanitizedSummary = _sanitizeAndFixData(originalSummary, data);

        if (_dataWasFixed) {
          debugPrint('🛠️ Data was automatically fixed');
          debugPrint('Fix explanation: $_dataFixExplanation');
        }

        if (month != null && month.isNotEmpty && month != 'all') {
          _monthlySummary = sanitizedSummary;
        } else {
          _dashboardSummary = sanitizedSummary;
        }

        _error = null;

        // Log final percentages
        debugPrint('📈 Final Statistics:');
        debugPrint('Present: ${sanitizedSummary.presentCount} (${sanitizedSummary.presentPercentage.toStringAsFixed(1)}%)');
        debugPrint('Leave: ${sanitizedSummary.leaveCount} (${sanitizedSummary.leavePercentage.toStringAsFixed(1)}%)');
        debugPrint('Absent: ${sanitizedSummary.absentCount} (${sanitizedSummary.absentPercentage.toStringAsFixed(1)}%)');
        debugPrint('Short Leave: ${sanitizedSummary.shortLeaveCount} (${sanitizedSummary.shortLeavePercentage.toStringAsFixed(1)}%)');
        debugPrint('Late Comers: ${sanitizedSummary.lateComersCount} (${sanitizedSummary.lateComersPercentage.toStringAsFixed(1)}%)');

      } else if (response.statusCode == 401) {
        _error = 'Session expired. Please login again.';
        await _clearToken();
      } else if (response.statusCode == 404) {
        _error = 'Dashboard data not found.';
      } else if (response.statusCode >= 500) {
        _error = 'Server error. Please try again later.';
      } else {
        _error = 'Failed to load dashboard data: ${response.statusCode}';
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      debugPrint('Dashboard summary error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to set token from AuthProvider
  Future<void> setToken(String token) async {
    await _saveToken(token);
  }

  // Method to check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token.isNotEmpty;
  }

  // Refresh dashboard data
  Future<void> refreshDashboardData() async {
    _isRefreshing = true;
    notifyListeners();

    await fetchDashboardSummary();

    _isRefreshing = false;
    notifyListeners();
  }

  // Set month filter
  void setMonthFilter(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Clear monthly summary
  void clearMonthlySummary() {
    _monthlySummary = null;
    _selectedMonth = 'all';
    notifyListeners();
  }

  // Get current summary (monthly if available, otherwise all-time)
  DashboardSummary? get currentSummary {
    return _selectedMonth != 'all' && _monthlySummary != null
        ? _monthlySummary
        : _dashboardSummary;
  }

  // Get stats with data fix warning
  Map<String, dynamic> getStats() {
    final summary = currentSummary ?? _dashboardSummary;

    if (summary == null) {
      return {
        'totalEmployees': 0,
        'presentCount': 0,
        'leaveCount': 0,
        'shortLeaveCount': 0,
        'absentCount': 0,
        'lateComersCount': 0,
        'presentPercentage': 0.0,
        'leavePercentage': 0.0,
        'absentPercentage': 0.0,
        'dataWasFixed': _dataWasFixed,
        'dataFixExplanation': _dataFixExplanation,
      };
    }

    final total = summary.totalEmployees;
    final presentPercentage = total > 0 ? (summary.presentCount / total) * 100 : 0;
    final leavePercentage = total > 0 ? (summary.leaveCount / total) * 100 : 0;
    final absentPercentage = total > 0 ? (summary.absentCount / total) * 100 : 0;

    return {
      'totalEmployees': total,
      'presentCount': summary.presentCount,
      'leaveCount': summary.leaveCount,
      'shortLeaveCount': summary.shortLeaveCount,
      'absentCount': summary.absentCount,
      'lateComersCount': summary.lateComersCount,
      'presentPercentage': presentPercentage,
      'leavePercentage': leavePercentage,
      'absentPercentage': absentPercentage,
      'month': summary.month,
      'dataWasFixed': _dataWasFixed,
      'dataFixExplanation': _dataFixExplanation,
    };
  }

  // Clear all data
  void clearData() {
    _dashboardSummary = null;
    _monthlySummary = null;
    _selectedMonth = 'all';
    _error = null;
    _dataWasFixed = false;
    _dataFixExplanation = null;
    notifyListeners();
  }

  // Logout - clear all auth data
  Future<void> logout() async {
    await _clearToken();
    clearData();
  }
}