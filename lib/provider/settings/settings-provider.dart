// lib/provider/settings_provider/attendance_settings_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../Utility/global_url.dart';
import '../../model/settings/settings-model.dart';
import '../Auth_provider/Auth_provider.dart';

class AttendanceSettingsProvider extends ChangeNotifier {
  // State variables
  AttendanceSettings? _settings;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  // Getters
  AttendanceSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _settings != null;
  DateTime? get lastFetched => _lastFetched;

  // Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (_lastFetched == null) return true;
    return DateTime.now().difference(_lastFetched!) > const Duration(minutes: 5);
  }

  // ============================================================
  // MAIN DATA FETCHING METHOD
  // ============================================================

  Future<void> fetchAttendanceSettings({BuildContext? context, bool forceRefresh = false}) async {
    print('🔄 Starting fetchAttendanceSettings()');

    // If we have data and it's not stale and not forcing refresh, skip fetching
    if (!forceRefresh && hasData && !isStale) {
      print('✅ Using cached settings data from $_lastFetched');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _makeApiCall(context);
    } catch (e) {
      print('❌ Exception in fetchAttendanceSettings: $e');
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // PRIVATE HELPER METHODS
  // ============================================================

  Future<void> _makeApiCall(BuildContext? context) async {
    final endpoint = 'attendance-settings';
    final url = '${GlobalUrls.baseurl}/api/$endpoint';

    print('\n📡 ========== API REQUEST DETAILS ==========');
    print('📡 URL: $url');

    // Get authentication token
    final token = await _getAuthToken(context);
    if (token == null) {
      _error = 'Authentication required. Please login again.';
      print('❌ No authentication token found');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    print('📡 Token available: ${token.isNotEmpty}');
    print('📡 Making request...');

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    print('\n📡 ========== API RESPONSE ==========');
    print('📡 Response Status: ${response.statusCode}');
    print('📡 Response Body:');
    print(response.body);

    await _processResponse(response);
  }

  Future<String?> _getAuthToken(BuildContext? context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        print('🔑 Found token in SharedPreferences');
        return token;
      }

      // Try alternative token keys
      final altToken = prefs.getString('auth_token') ??
          prefs.getString('access_token') ??
          prefs.getString('jwt_token');

      if (altToken != null && altToken.isNotEmpty) {
        print('🔑 Found alternative token');
        return altToken;
      }

      // Try to get from AuthProvider if context is available
      if (context != null) {
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.token != null && authProvider.token!.isNotEmpty) {
            print('🔑 Found token in AuthProvider');
            return authProvider.token;
          }
        } catch (e) {
          print('⚠️ Could not get token from AuthProvider: $e');
        }
      }

      print('⚠️ No authentication token found');
      return null;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _processResponse(http.Response response) async {
    print('\n🔍 ========== PROCESSING RESPONSE ==========');

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);

        print('🔍 JSON Response Type: ${jsonData.runtimeType}');
        print('🔍 Response keys: ${jsonData is Map ? jsonData.keys.join(', ') : 'Not a Map'}');

        // Parse the response
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('settings')) {
          print('🔍 Response has correct structure, parsing...');
          _settings = AttendanceSettings.fromJson(jsonData['settings'] as Map<String, dynamic>);
          _lastFetched = DateTime.now();
          _logSuccess();
        } else {
          print('⚠️ Unexpected response format, trying alternative parsing');
          // If the response is different, try to parse as direct settings object
          try {
            _settings = AttendanceSettings.fromJson(jsonData as Map<String, dynamic>);
            _lastFetched = DateTime.now();
            _logSuccess();
          } catch (e) {
            throw Exception('Invalid response format: $e');
          }
        }

        _error = null;
      } catch (e) {
        _error = 'Failed to parse response: $e';
        _settings = null;
        print('❌ JSON parsing error: $e');
        print('❌ Stack trace: ${e.toString()}');
        print('❌ Response body: ${response.body}');
      }
    } else {
      await _handleHttpError(response);
    }
  }

  void _logSuccess() {
    print('\n✅ ========== SETTINGS LOADED SUCCESSFULLY ==========');
    print('✅ Settings ID: ${_settings!.id}');
    print('✅ Max Late Time: ${_settings!.maxLateTime}');
    print('✅ Half Day Deduction: ${_settings!.halfDayDeductionPercent}%');
    print('✅ Full Day Deduction: ${_settings!.fullDayDeductionPercent}%');
    print('✅ Overtime Start After: ${_settings!.overtimeStartAfter}');
    print('✅ Overtime Rate: ${_settings!.overtimeRate}');
    print('✅ Last Updated: ${_settings!.formattedUpdatedAt}');
  }

  Future<void> _handleHttpError(http.Response response) async {
    print('\n❌ ========== HTTP ERROR ==========');

    switch (response.statusCode) {
      case 400:
        _error = 'Bad request. Invalid parameters sent to server.';
        print('❌ 400 Bad Request');
        break;
      case 401:
        _error = 'Session expired. Please login again.';
        // Clear invalid token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        print('❌ 401 Unauthorized - Token cleared');
        break;
      case 403:
        _error = 'Access forbidden. You don\'t have permission.';
        print('❌ 403 Forbidden');
        break;
      case 404:
        _error = 'Settings endpoint not found.';
        print('❌ 404 Not Found');
        break;
      case 500:
        _error = 'Server error. Please try again later.';
        print('❌ 500 Internal Server Error');
        break;
      default:
        _error = 'Failed to load settings (Status: ${response.statusCode})';
        print('❌ HTTP Error ${response.statusCode}');
    }

    print('❌ Error message: $_error');
    print('❌ Response body: ${response.body}');

    _settings = null;
  }

  void _handleError(dynamic error) {
    print('\n❌ ========== GENERAL ERROR ==========');
    print('❌ Error type: ${error.runtimeType}');
    print('❌ Error message: $error');

    if (error is http.ClientException) {
      _error = 'Network error: ${error.message}';
    } else if (error is FormatException) {
      _error = 'Invalid data format received from server';
    } else if (error is TimeoutException) {
      _error = 'Request timeout. Please check your internet connection.';
    } else if (error is String) {
      _error = error;
    } else {
      _error = 'An unexpected error occurred: $error';
    }

    _settings = null;
  }

  // ============================================================
  // PUBLIC UTILITY METHODS
  // ============================================================

  // Refresh settings
  Future<void> refreshSettings({BuildContext? context}) async {
    print('🔄 Manual refresh requested for attendance settings');
    if (_isLoading) {
      print('⚠️ Already loading, skipping refresh');
      return;
    }
    await fetchAttendanceSettings(context: context, forceRefresh: true);
  }

  // Clear settings data
  void clearSettings() {
    print('🗑️ Clearing attendance settings data');
    _settings = null;
    _error = null;
    _lastFetched = null;
    notifyListeners();
  }

  // Get settings summary for display
  Map<String, dynamic> get settingsSummary {
    if (_settings == null) {
      return {
        'maxLateTime': 'Not available',
        'halfDayDeduction': '0%',
        'fullDayDeduction': '0%',
        'overtimeStart': 'Not available',
        'overtimeRate': '0',
        'lastUpdated': 'Never',
      };
    }

    return {
      'maxLateTime': _settings!.formattedMaxLateTime,
      'halfDayDeduction': '${_settings!.halfDayDeductionPercent}%',
      'fullDayDeduction': '${_settings!.fullDayDeductionPercent}%',
      'overtimeStart': _settings!.formattedOvertimeStart,
      'overtimeRate': _settings!.overtimeRate,
      'lastUpdated': _settings!.formattedUpdatedAt,
    };
  }

  // Export settings as JSON
  String exportSettingsAsJson() {
    if (_settings == null) return '{}';
    return jsonEncode(_settings!.toJson());
  }
}