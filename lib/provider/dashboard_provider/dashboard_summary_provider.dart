import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utility/global_url.dart';
import '../../model/dashboar_model/dashboard_summary.dart';

class DashboardSummaryProvider with ChangeNotifier {
  DashboardSummary? _dashboardSummary;
  DashboardSummary? _dailySummary;
  String _selectedDate = 'all';
  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;

  // Track if data has been fixed
  bool _dataWasFixed = false;
  String? _dataFixExplanation;

  // Flag to control whether to fix data or not
  bool _shouldFixData = false;
  // Store original data before fixing
  DashboardSummary? _originalSummary;
  DashboardSummary? _originalDailySummary;

  // SharedPreferences
  static SharedPreferences? _prefs;
  static const String _tokenKey = 'token';

  // Getters
  DashboardSummary? get dashboardSummary => _dashboardSummary;
  DashboardSummary? get dailySummary => _dailySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRefreshing => _isRefreshing;
  String get selectedDate => _selectedDate;
  bool get dataWasFixed => _dataWasFixed;
  String? get dataFixExplanation => _dataFixExplanation;
  bool get shouldFixData => _shouldFixData;

  // Get current summary (daily if available, otherwise all-time)
  DashboardSummary? get currentSummary {
    return _selectedDate != 'all' && _dailySummary != null
        ? _dailySummary
        : _dashboardSummary;
  }

  // Setter for shouldFixData
  set shouldFixData(bool value) {
    _shouldFixData = value;

    // When changing the fix mode, update the displayed data
    if (_shouldFixData) {
      if (_originalSummary != null) {
        _dashboardSummary = _sanitizeAndFixData(_originalSummary!, {});
      }
      if (_originalDailySummary != null) {
        _dailySummary = _sanitizeAndFixData(_originalDailySummary!, {});
      }
    } else {
      if (_originalSummary != null) {
        _dashboardSummary = _originalSummary;
      }
      if (_originalDailySummary != null) {
        _dailySummary = _originalDailySummary;
      }
    }

    notifyListeners();
  }

  // Static initialization method
  static Future<void> initializeSharedPreferences() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Get token from SharedPreferences
  Future<String> _getToken() async {
    try {
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

  // Data sanitization and fixing method
  // In DashboardSummaryProvider - Update the _sanitizeAndFixData method

  DashboardSummary _sanitizeAndFixData(
    DashboardSummary original,
    Map<String, dynamic> rawData,
  ) {
    debugPrint('=== DATA SANITIZATION STARTED ===');
    debugPrint('Data fixing enabled: $_shouldFixData');
    debugPrint('Original data:');
    debugPrint('- selectedDate: ${original.selectedDate}');
    debugPrint('- total_employees: ${original.totalEmployees}');
    debugPrint('- present_count: ${original.presentCount}');
    debugPrint('- leave_count: ${original.leaveCount}');
    debugPrint('- absent_count: ${original.absentCount}');
    debugPrint('- short_leave_count: ${original.shortLeaveCount}');
    debugPrint('- late_comers_count: ${original.lateComersCount}');

    // Reset fix tracking
    _dataWasFixed = false;
    _dataFixExplanation = null;

    // Check if this is date-specific data
    final isDateSpecific =
        original.selectedDate != 'all' && original.selectedDate != 'All Time';

    // For date-specific data with all zeros, this might be normal (no attendance marked yet)
    if (isDateSpecific && original.isNoDataForDate) {
      debugPrint(
        '⚠️ Date-specific data with all zeros - This might be normal (no attendance marked yet)',
      );

      if (!_shouldFixData) {
        debugPrint('✅ Data fixing is disabled, returning original data');
        return original;
      }

      // If data fixing is enabled, we should check if this is really an issue
      // For now, we'll just return the original data since zeros might be valid
      return original;
    }

    // Check if we should fix data
    if (!_shouldFixData) {
      debugPrint('⚠️ Data fixing is DISABLED. Returning original data.');
      debugPrint('=== DATA SANITIZATION COMPLETED ===');
      return original;
    }

    final errors = original.validate(isDateSpecific: isDateSpecific);

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

    // **FIX 1: For date-specific data, handle zero data case**
    if (isDateSpecific &&
        totalEmployees > 0 &&
        presentCount == 0 &&
        leaveCount == 0 &&
        absentCount == 0) {
      // This could mean attendance hasn't been marked yet
      // We'll keep it as is, or optionally set absentCount = totalEmployees
      // depending on your business logic

      // Option 1: Keep as is (attendance not marked yet)
      // fixExplanation += 'No attendance marked yet for this date.\n';

      // Option 2: Mark all as absent (if that's your default)
      // absentCount = totalEmployees;
      // fixExplanation += 'No attendance marked yet, all marked as absent.\n';
      // _dataWasFixed = true;

      // For now, we'll use option 1 (keep as is)
      fixExplanation +=
          'No attendance data marked yet for ${original.selectedDate}.\n';
    }

    // **FIX 2: If sum doesn't match total, adjust (only for all-time data)**
    if (!isDateSpecific) {
      final sum = presentCount + leaveCount + absentCount;
      if (sum != totalEmployees) {
        if (sum > totalEmployees) {
          // Too many people in categories
          fixExplanation +=
              'Present($presentCount) + Leave($leaveCount) + Absent($absentCount) = $sum '
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
          fixExplanation +=
              'Adjusted absent count to $absentCount to match total.';
        }
        _dataWasFixed = true;
      }
    }

    // **FIX 3: Ensure late comers doesn't exceed present count**
    if (lateComersCount > presentCount) {
      fixExplanation +=
          'Late comers ($lateComersCount) exceeds present count ($presentCount). ';
      lateComersCount = presentCount;
      fixExplanation += 'Set late comers to present count: $lateComersCount.';
      _dataWasFixed = true;
    }

    // **FIX 4: Ensure short leave doesn't exceed present count**
    if (shortLeaveCount > presentCount) {
      fixExplanation +=
          'Short leave ($shortLeaveCount) exceeds present count ($presentCount). ';
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
      selectedDate: original.selectedDate,
    );

    // Validate the fixed data
    final fixedErrors = fixedSummary.validate(isDateSpecific: isDateSpecific);
    if (fixedErrors.isEmpty) {
      debugPrint('✅ Data successfully fixed');
      debugPrint('Fixed data:');
      debugPrint('- total_employees: $totalEmployees');
      debugPrint(
        '- present_count: $presentCount (${fixedSummary.presentPercentage.toStringAsFixed(1)}%)',
      );
      debugPrint(
        '- leave_count: $leaveCount (${fixedSummary.leavePercentage.toStringAsFixed(1)}%)',
      );
      debugPrint(
        '- absent_count: $absentCount (${fixedSummary.absentPercentage.toStringAsFixed(1)}%)',
      );
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

  // Fetch dashboard summary (with optional date filter) - FIXED VERSION
  Future<void> fetchDashboardSummary({String? date}) async {
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

      // FIXED: Use Uri class to properly build the URL
      String baseUrl = GlobalUrls.baseurl;

      // Ensure baseUrl doesn't have a trailing slash
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      // Build the base URL without query parameters
      String url = '$baseUrl/api/dashboard-summary';

      // Add query parameter properly
      if (date != null && date.isNotEmpty && date != 'all') {
        url += '?date=$date';
        _selectedDate = date;
        debugPrint('🔄 Fetching DAILY summary for date: $date');
      } else {
        url += '?date=all';
        _selectedDate = 'all';
        debugPrint('🔄 Fetching ALL-TIME dashboard summary');
      }

      debugPrint('📤 Making API request to: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      debugPrint('📥 API Response Status: ${response.statusCode}');
      debugPrint('📥 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        DashboardSummary? parsedSummary;

        if (data['data'] != null) {
          // Handle nested data structure
          final summaryData = data['data'];
          debugPrint('📊 API returned nested data structure');
          parsedSummary = DashboardSummary.fromJson(
            summaryData,
            requestedDate: date,
          );
        } else if (data['total_employees'] != null) {
          // Handle flat structure
          debugPrint('📊 API returned flat data structure');
          parsedSummary = DashboardSummary.fromJson(data, requestedDate: date);
        }

        if (parsedSummary != null) {
          debugPrint(
            '✅ Successfully parsed summary: ${parsedSummary.toString()}',
          );

          // Store original data
          if (date != null && date.isNotEmpty && date != 'all') {
            _originalDailySummary = parsedSummary;
          } else {
            _originalSummary = parsedSummary;
          }

          // Apply fixes if enabled
          final processedSummary = _shouldFixData
              ? _sanitizeAndFixData(parsedSummary, {})
              : parsedSummary;

          if (date != null && date.isNotEmpty && date != 'all') {
            _dailySummary = processedSummary;
            debugPrint('✅ Daily summary saved for date: $date');
          } else {
            _dashboardSummary = processedSummary;
            debugPrint('✅ All-time dashboard summary saved');
          }

          _error = null;
        } else {
          debugPrint('❌ Failed to parse summary data');
          _handleNoDataError(date);
        }
      } else if (response.statusCode == 401) {
        _error = 'Session expired. Please login again.';
        await _clearToken();
      } else if (response.statusCode == 404) {
        _handleNoDataError(date);
      } else if (response.statusCode >= 500) {
        _error = 'Server error. Please try again later.';
      } else {
        try {
          final errorData = json.decode(response.body);
          _error = errorData['message'] ?? 'Failed to load dashboard data';
        } catch (e) {
          _error = 'Failed to load dashboard data: ${response.statusCode}';
        }
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

  // Helper method to handle no data error
  void _handleNoDataError(String? date) {
    if (date != null && date.isNotEmpty && date != 'all') {
      _error = 'No attendance data found for $date';
      _dailySummary = null;
      _originalDailySummary = null;
    } else {
      _error = 'Dashboard data not found.';
      _dashboardSummary = null;
      _originalSummary = null;
    }
  }

  // Alternative: Try different endpoints for date-based data
  Future<void> fetchDateWiseData(String date) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

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

      // Try different possible endpoints for date-wise data
      final possibleEndpoints = [
        '${GlobalUrls.baseurl}/api/attendance/daily-summary?date=$date',
        '${GlobalUrls.baseurl}/api/attendance/summary?date=$date',
        '${GlobalUrls.baseurl}/api/daily-attendance?date=$date',
        '${GlobalUrls.baseurl}/api/attendances/summary?date=$date',
      ];

      bool success = false;

      for (final url in possibleEndpoints) {
        debugPrint('🔄 Trying date endpoint: $url');

        final response = await http.get(Uri.parse(url), headers: headers);

        debugPrint('📥 Response for $url: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Try to parse the data
          try {
            Map<String, dynamic> summaryData;

            if (data['data'] != null) {
              summaryData = data['data'];
            } else if (data['summary'] != null) {
              summaryData = data['summary'];
            } else {
              summaryData = data;
            }

            // Check if we have the required fields
            if (summaryData['total_employees'] == null &&
                summaryData['present_count'] == null) {
              debugPrint('❌ Incomplete data from $url');
              continue;
            }

            // Create summary from data using the updated model
            final originalSummary = DashboardSummary.fromJson(
              summaryData,
              requestedDate: date,
            );

            // Store original data
            _originalDailySummary = originalSummary;

            // Apply fixes if enabled
            final processedSummary = _shouldFixData
                ? _sanitizeAndFixData(originalSummary, summaryData)
                : originalSummary;

            _dailySummary = processedSummary;
            _selectedDate = date;
            _error = null;
            success = true;
            debugPrint('✅ Successfully fetched date-wise data from: $url');
            break;
          } catch (e) {
            debugPrint('❌ Failed to parse response from $url: $e');
            continue;
          }
        }
      }

      if (!success) {
        _error = 'No attendance data found for $date';
        _dailySummary = null;
        _originalDailySummary = null;
        debugPrint('⚠️ Could not fetch date-wise data from any endpoint');

        // Fallback: Try to get data from staff attendance endpoint
        await _fetchStaffAttendanceData(date);
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      debugPrint('Date-wise data error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fallback method: Get data from staff attendance list
  Future<void> _fetchStaffAttendanceData(String date) async {
    try {
      final token = await _getToken();

      if (token.isEmpty) return;

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // Get staff attendance for the date
      final url = '${GlobalUrls.baseurl}/api/attendances?date=$date';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] is List) {
          final List<dynamic> attendanceList = data['data'];

          // Calculate summary from attendance list
          int presentCount = 0;
          int leaveCount = 0;
          int absentCount = 0;
          int lateCount = 0;
          int shortLeaveCount = 0;

          for (var attendance in attendanceList) {
            final status = attendance['status']?.toString().toLowerCase() ?? '';

            switch (status) {
              case 'present':
                presentCount++;
                break;
              case 'leave':
                leaveCount++;
                break;
              case 'absent':
                absentCount++;
                break;
              case 'late':
                lateCount++;
                break;
              case 'short_leave':
                shortLeaveCount++;
                break;
            }
          }

          final totalEmployees = attendanceList.length;

          final originalSummary = DashboardSummary(
            totalEmployees: totalEmployees,
            presentCount: presentCount,
            leaveCount: leaveCount,
            absentCount: absentCount,
            shortLeaveCount: shortLeaveCount,
            lateComersCount: lateCount,
            selectedDate: date,
          );

          // Store original data
          _originalDailySummary = originalSummary;

          // Apply fixes if enabled
          final processedSummary = _shouldFixData
              ? _sanitizeAndFixData(originalSummary, {})
              : originalSummary;

          _dailySummary = processedSummary;
          _selectedDate = date;
          _error = null;
          debugPrint(
            '✅ Calculated summary from attendance list: $totalEmployees employees',
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance list: $e');
    }
  }

  // Main method to fetch data
  Future<void> fetchData({String? date}) async {
    if (date != null && date.isNotEmpty && date != 'all') {
      // First try the main dashboard endpoint
      await fetchDashboardSummary(date: date);

      // If no data found, try alternative endpoints
      if (_dailySummary == null &&
          (_error?.contains('No data') == true ||
              _error?.contains('404') == true)) {
        debugPrint('🔄 No data from main endpoint, trying date-wise endpoints');
        await fetchDateWiseData(date);
      }
    } else {
      // For all-time data
      await fetchDashboardSummary(date: null);
    }
  }

  // Refresh dashboard data with date parameter
  Future<void> refreshDashboardData({String? date}) async {
    _isRefreshing = true;
    notifyListeners();

    await fetchData(date: date);

    _isRefreshing = false;
    notifyListeners();
  }

  // Clear daily summary
  void clearDailySummary() {
    _dailySummary = null;
    _originalDailySummary = null;
    _selectedDate = 'all';
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _dashboardSummary = null;
    _dailySummary = null;
    _originalSummary = null;
    _originalDailySummary = null;
    _selectedDate = 'all';
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

  // Method to manually re-apply fixes if needed
  void reapplyDataFixes() {
    if (_originalSummary != null) {
      _dashboardSummary = _sanitizeAndFixData(_originalSummary!, {});
    }
    if (_originalDailySummary != null) {
      _dailySummary = _sanitizeAndFixData(_originalDailySummary!, {});
    }
    notifyListeners();
  }
}
