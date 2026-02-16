// chart_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../Utility/global_url.dart';
import '../../model/chart_model/chart_model.dart';
import '../Auth_provider/Auth_provider.dart';

class ChartProvider extends ChangeNotifier {
  // State variables
  DashboardChartResponse? _chartData;
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  String _chartType = 'daily'; // 'daily' or 'monthly'
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;
  int? _userId;
  String? _userName;
  String? _employeeCode;
  String? _userRole;

  // Chart statistics
  Map<String, dynamic> _stats = {
    'present': 0,
    'absent': 0,
    'late': 0,
    'total': 0,
    'attendanceRate': 0.0,
    'lateRate': 0.0,
  };

  // Getters
  DashboardChartResponse? get chartData => _chartData;
  DateTime? get selectedDate => _selectedDate;
  DateTime? get selectedMonth => _selectedMonth;
  String get chartType => _chartType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _chartData != null && _chartData!.data.isNotEmpty;
  bool get isAdmin => _isAdmin;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  Map<String, dynamic> get stats => _stats;

  // Initialize
  ChartProvider() {
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _selectedDate = now;
    _selectedMonth = DateTime(now.year, now.month, 1);

    print('📅 ChartProvider initialized:');
    print('   Selected Date: $_selectedDate');
    print('   Selected Month: $_selectedMonth');
    print('   Formatted Date: ${_formatDateForAPI(_selectedDate!)}');
  }

  // ============================================================
  // USER INFO MANAGEMENT
  // ============================================================

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get user role
      _userRole = prefs.getString('user_role')?.toLowerCase() ?? '';
      print('📋 Raw user_role from storage: $_userRole');

      // Determine if user is admin
      _isAdmin = _userRole!.contains('admin') ||
          _userRole == 'administrator' ||
          _userRole == 'superadmin' ||
          _userRole == 'manager' ||
          _userRole == 'supervisor';

      // Get user ID
      _userId = prefs.getInt('user_id');

      // Get user name
      _userName = prefs.getString('employee_name') ??
          prefs.getString('user_name') ??
          prefs.getString('name') ??
          'User';

      // Get employee code
      _employeeCode = prefs.getString('employee_code') ??
          prefs.getString('emp_code') ??
          prefs.getString('code') ??
          prefs.getString('employee_id');

      print('👤 User Info Loaded:');
      print('   Role: $_userRole (Is Admin: $_isAdmin)');
      print('   User ID: $_userId');
      print('   Name: $_userName');
      print('   Employee Code: $_employeeCode');

    } catch (e) {
      print('❌ Error loading user info: $e');
      _isAdmin = false;
    }
  }

  // ============================================================
  // SETTER METHODS
  // ============================================================

  void setChartType(String type) {
    if (type == 'daily' || type == 'monthly') {
      print('📊 Chart type changed from $_chartType to $type');
      _chartType = type;
      _chartData = null; // Clear previous data
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    print('📅 Selected date changed to: $date');
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    print('📅 Selected month changed to: $month');
    _selectedMonth = month;
    notifyListeners();
  }

  // ============================================================
  // MAIN DATA FETCHING METHOD
  // ============================================================

  Future<void> fetchAttendanceData({BuildContext? context}) async {
    print('🔄 Starting fetchAttendanceData()');
    print('   Current chart type: $_chartType');
    print('   Selected date: $_selectedDate');
    print('   Selected month: $_selectedMonth');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load user info
      await _loadUserInfo();

      // Build query parameters
      final Map<String, String> queryParams = {};

      print('📊 Building query parameters:');
      print('   Chart type: $_chartType');

      if (_chartType == 'daily') {
        if (_selectedDate != null) {
          final formattedDate = _formatDateForAPI(_selectedDate!);
          queryParams['date'] = formattedDate;
          print('   Adding date parameter: $formattedDate');
        } else {
          print('⚠️ Selected date is null! Using current date');
          final now = DateTime.now();
          queryParams['date'] = _formatDateForAPI(now);
          _selectedDate = now;
        }
      } else {
        if (_selectedMonth != null) {
          final formattedMonth = _formatMonthForAPI(_selectedMonth!);
          queryParams['month'] = formattedMonth;
          print('   Adding month parameter: $formattedMonth');
        } else {
          print('⚠️ Selected month is null! Using current month');
          final now = DateTime.now();
          queryParams['month'] = _formatMonthForAPI(now);
          _selectedMonth = DateTime(now.year, now.month, 1);
        }
      }

      // Add user-specific filters for non-admin users
      if (!_isAdmin) {
        print('👤 Non-admin user, adding filters');
        await _addUserFilters(queryParams);
      } else {
        print('👑 Admin user, no filters needed');
      }

      // Make API call
      await _makeApiCall(queryParams, context);

    } catch (e) {
      print('❌ Exception in fetchAttendanceData: $e');
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // PRIVATE HELPER METHODS
  // ============================================================

  Future<void> _addUserFilters(Map<String, String> queryParams) async {
    print('👤 Adding user filters...');

    if (_employeeCode != null && _employeeCode!.isNotEmpty) {
      queryParams['employee_code'] = _employeeCode!;
      print('   Added employee_code filter: $_employeeCode');
    } else if (_userId != null) {
      queryParams['user_id'] = _userId.toString();
      print('   Added user_id filter: $_userId');
    } else {
      // Try to get employee code from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final empCode = prefs.getString('employee_code');
      if (empCode != null && empCode.isNotEmpty) {
        queryParams['employee_code'] = empCode;
        _employeeCode = empCode;
        print('   Found employee_code in storage: $empCode');
      } else {
        print('⚠️ No user identifier found for non-admin user');
        _error = 'User identification missing. Please contact administrator.';
        throw Exception(_error);
      }
    }
  }

  Future<void> _makeApiCall(Map<String, String> queryParams, BuildContext? context) async {
    final endpoint = 'dashboard-chart';
    final uri = Uri.parse('${GlobalUrls.baseurl}/api/$endpoint');
    final url = uri.replace(queryParameters: queryParams).toString();

    print('\n📡 ========== API REQUEST DETAILS ==========');
    print('📡 URL: $url');
    print('📡 Chart Type: $_chartType');
    print('📡 User Role: ${_isAdmin ? "Admin" : "Regular User"}');
    print('📡 Query Params: $queryParams');

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

        // Detailed debug of API response
        _debugApiResponse(jsonData);

        // Handle your API response format
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('granularity') &&
            jsonData.containsKey('data')) {

          print('🔍 Response has correct structure, parsing...');
          _chartData = DashboardChartResponse.fromJson(jsonData as Map<String, dynamic>);

          // Debug parsed data
          _debugParsedData();

          _updateStatistics();
          _logSuccess();
        } else {
          print('⚠️ Unexpected response format, trying alternative parsing');
          // If the response is different, create appropriate DashboardChartResponse
          _chartData = _createChartDataFromResponse(jsonData);
          _updateStatistics();
          _logSuccess();
        }

        _error = null;
      } catch (e) {
        _error = 'Failed to parse response: $e';
        _chartData = null;
        print('❌ JSON parsing error: $e');
        print('❌ Stack trace: ${e.toString()}');
        print('❌ Response body: ${response.body}');
      }
    } else {
      await _handleHttpError(response);
    }
  }

  // Debug API response
  void _debugApiResponse(dynamic jsonData) {
    print('\n🔍 === DEBUG API RESPONSE ===');

    if (jsonData is Map<String, dynamic>) {
      print('🔍 Response is a Map with keys: ${jsonData.keys.join(', ')}');

      if (jsonData.containsKey('granularity')) {
        print('🔍 Granularity: ${jsonData['granularity']}');
      }

      if (jsonData.containsKey('data')) {
        final data = jsonData['data'];
        print('🔍 Data type: ${data.runtimeType}');

        if (data is List) {
          print('🔍 Data list length: ${data.length}');

          for (var i = 0; i < data.length; i++) {
            final item = data[i];
            print('🔍 Item $i:');
            print('   Type: ${item.runtimeType}');

            if (item is Map) {
              print('   Keys: ${item.keys.join(', ')}');
              print('   Values: $item');

              // Show specific values
              if (item.containsKey('label')) {
                print('   Label: ${item['label']}');
              }
              if (item.containsKey('date')) {
                print('   Date: ${item['date']}');
              }
              if (item.containsKey('present')) {
                print('   Present: ${item['present']} (type: ${item['present'].runtimeType})');
              }
              if (item.containsKey('absent')) {
                print('   Absent: ${item['absent']} (type: ${item['absent'].runtimeType})');
              }
              if (item.containsKey('late')) {
                print('   Late: ${item['late']} (type: ${item['late'].runtimeType})');
              }
            }
          }
        } else {
          print('🔍 Data is not a list: $data');
        }
      } else {
        print('🔍 No "data" key in response');
      }
    } else {
      print('🔍 Response is not a Map: $jsonData');
    }
  }

  // Debug parsed data
  void _debugParsedData() {
    print('\n🔍 === DEBUG PARSED DATA ===');

    if (_chartData == null) {
      print('🔍 _chartData is null');
      return;
    }

    print('🔍 Granularity: ${_chartData!.granularity}');
    print('🔍 Data items count: ${_chartData!.data.length}');

    if (_chartData!.data.isNotEmpty) {
      print('🔍 First item details:');
      final firstItem = _chartData!.data.first;
      print('   Label: ${firstItem.label}');
      print('   Date: ${firstItem.date}');
      print('   Present: ${firstItem.present}');
      print('   Absent: ${firstItem.absent}');
      print('   Late: ${firstItem.late}');
      print('   Total: ${firstItem.total}');

      // Show all items
      print('\n🔍 All items:');
      for (var i = 0; i < _chartData!.data.length; i++) {
        final item = _chartData!.data[i];
        print('   [$i] ${item.label}: P=${item.present}, A=${item.absent}, L=${item.late}');
      }
    } else {
      print('🔍 No data items in _chartData');
    }
  }

  DashboardChartResponse _createChartDataFromResponse(dynamic jsonData) {
    print('\n🔍 Creating DashboardChartResponse from alternative format');

    List<ChartData> chartItems = [];

    if (jsonData is Map<String, dynamic> &&
        jsonData.containsKey('data') &&
        jsonData['data'] is List) {
      // If response has data array
      final dataList = jsonData['data'] as List;
      print('🔍 Processing data list with ${dataList.length} items');

      for (var i = 0; i < dataList.length; i++) {
        var item = dataList[i];
        print('🔍 Processing item $i: $item');

        try {
          // Convert dynamic item to Map<String, dynamic>
          final Map<String, dynamic> itemMap = _convertToMap(item);
          print('🔍 Converted to Map: $itemMap');

          chartItems.add(ChartData.fromJson(itemMap));
          print('🔍 Successfully added ChartData');
        } catch (e) {
          print('❌ Error parsing chart item $i: $e');
          print('❌ Item: $item');
        }
      }
      return DashboardChartResponse(
        granularity: jsonData['granularity']?.toString() ?? (_chartType == 'daily' ? 'day' : 'month'),
        data: chartItems,
      );
    } else if (jsonData is List) {
      // If response is directly a list
      print('🔍 Response is a List with ${jsonData.length} items');

      for (var i = 0; i < jsonData.length; i++) {
        var item = jsonData[i];
        print('🔍 Processing item $i: $item');

        try {
          // Convert dynamic item to Map<String, dynamic>
          final Map<String, dynamic> itemMap = _convertToMap(item);
          print('🔍 Converted to Map: $itemMap');

          chartItems.add(ChartData.fromJson(itemMap));
          print('🔍 Successfully added ChartData');
        } catch (e) {
          print('❌ Error parsing chart item $i: $e');
          print('❌ Item: $item');
        }
      }
      return DashboardChartResponse(
        granularity: _chartType == 'daily' ? 'day' : 'month',
        data: chartItems,
      );
    } else if (jsonData is Map<String, dynamic>) {
      // If response is a single object (like your example)
      print('🔍 Response is a single Map object');
      print('🔍 Map: $jsonData');

      try {
        chartItems.add(ChartData.fromJson(jsonData));
        print('🔍 Successfully added ChartData');
      } catch (e) {
        print('❌ Error parsing chart item: $e');
      }
      return DashboardChartResponse(
        granularity: 'day',
        data: chartItems,
      );
    }

    print('🔍 Unknown response format, returning empty DashboardChartResponse');
    return DashboardChartResponse(
      granularity: _chartType == 'daily' ? 'day' : 'month',
      data: [],
    );
  }

  // Helper method to convert dynamic to Map<String, dynamic>
  Map<String, dynamic> _convertToMap(dynamic item) {
    print('🔍 Converting to Map: ${item.runtimeType}');

    if (item is Map<String, dynamic>) {
      print('🔍 Already Map<String, dynamic>');
      return item;
    } else if (item is Map<dynamic, dynamic>) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      print('🔍 Converting Map<dynamic, dynamic> to Map<String, dynamic>');
      final Map<String, dynamic> convertedMap = {};
      item.forEach((key, value) {
        if (key is String) {
          convertedMap[key] = value;
          print('   Key "$key": $value (type: ${value.runtimeType})');
        } else if (key != null) {
          convertedMap[key.toString()] = value;
          print('   Key "${key.toString()}": $value (type: ${value.runtimeType})');
        }
      });
      return convertedMap;
    } else {
      print('🔍 Not a Map, returning empty Map');
      return {};
    }
  }

  void _updateStatistics() {
    print('\n📊 ========== UPDATING STATISTICS ==========');

    if (_chartData != null && _chartData!.data.isNotEmpty) {
      final totalPresent = _chartData!.totalPresent;
      final totalAbsent = _chartData!.totalAbsent;
      final totalLate = _chartData!.totalLate;
      final totalAll = totalPresent + totalAbsent + totalLate;

      print('📊 Calculated from chart data:');
      print('   Total Present: $totalPresent');
      print('   Total Absent: $totalAbsent');
      print('   Total Late: $totalLate');
      print('   Total All: $totalAll');

      _stats = {
        'present': totalPresent,
        'absent': totalAbsent,
        'late': totalLate,
        'total': totalAll,
        'attendanceRate': totalAll > 0 ? (totalPresent / totalAll * 100) : 0,
        'lateRate': totalAll > 0 ? (totalLate / totalAll * 100) : 0,
      };

      print('📊 Updated stats:');
      print('   Present: ${_stats['present']}');
      print('   Absent: ${_stats['absent']}');
      print('   Late: ${_stats['late']}');
      print('   Total: ${_stats['total']}');
      print('   Attendance Rate: ${_stats['attendanceRate']}%');
      print('   Late Rate: ${_stats['lateRate']}%');
    } else {
      print('📊 No chart data, resetting stats to zero');
      _stats = {
        'present': 0,
        'absent': 0,
        'late': 0,
        'total': 0,
        'attendanceRate': 0.0,
        'lateRate': 0.0,
      };
    }
  }

  void _logSuccess() {
    print('\n✅ ========== DATA LOADED SUCCESSFULLY ==========');
    print('✅ Granularity: ${_chartData!.granularity}');
    print('✅ Total records: ${_chartData!.data.length}');
    print('✅ Statistics: Present=${_stats['present']}, Absent=${_stats['absent']}, Late=${_stats['late']}');

    if (_chartData!.data.isNotEmpty) {
      print('✅ First record:');
      final first = _chartData!.data.first;
      print('   Label: ${first.label}');
      print('   Present: ${first.present}');
      print('   Absent: ${first.absent}');
      print('   Late: ${first.late}');
      print('   Date: ${first.date}');
    }
  }

  Future<void> _handleHttpError(http.Response response) async {
    print('\n❌ ========== HTTP ERROR ==========');

    switch (response.statusCode) {
      case 400:
        _error = 'Bad request. Invalid parameters sent to server.';
        print('❌ 400 Bad Request - Check query parameters');
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
        _error = 'API endpoint not found.';
        print('❌ 404 Not Found');
        break;
      case 500:
        _error = 'Server error. Please try again later.';
        print('❌ 500 Internal Server Error');
        break;
      default:
        _error = 'Failed to load data (Status: ${response.statusCode})';
        print('❌ HTTP Error ${response.statusCode}');
    }

    print('❌ Error message: $_error');
    print('❌ Response body: ${response.body}');

    _chartData = null;
    _stats = {
      'present': 0,
      'absent': 0,
      'late': 0,
      'total': 0,
      'attendanceRate': 0.0,
      'lateRate': 0.0,
    };
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

    _chartData = null;
    _stats = {
      'present': 0,
      'absent': 0,
      'late': 0,
      'total': 0,
      'attendanceRate': 0.0,
      'lateRate': 0.0,
    };
  }

  // ============================================================
  // DATE FORMATTING METHODS - UPDATED TO "17 Feb 2026" FORMAT
  // ============================================================

  String _formatDateForAPI(DateTime date) {
    final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    print('📅 Formatting date $date for API: $formatted');
    return formatted;
  }

  String _formatMonthForAPI(DateTime date) {
    final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    print('📅 Formatting month $date for API: $formatted');
    return formatted;
  }

  String _formatDateForDisplay(DateTime date) {
    // Format as "17 Feb 2026"
    final day = date.day;
    final month = _getMonthAbbreviation(date.month);
    final year = date.year;
    return '$day $month $year';
  }

  String _formatMonthForDisplay(DateTime date) {
    // Format as "Feb 2026"
    final month = _getMonthAbbreviation(date.month);
    final year = date.year;
    return '$month $year';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // ============================================================
  // PUBLIC UTILITY METHODS
  // ============================================================

  String get chartTitle {
    final rolePrefix = _isAdmin ? ' ' : 'My ';

    if (_chartType == 'daily' && _selectedDate != null) {
      return '${rolePrefix}Attendance - ${_formatDateForDisplay(_selectedDate!)}';
    } else if (_chartType == 'monthly' && _selectedMonth != null) {
      return '${rolePrefix}Monthly Attendance - ${_formatMonthForDisplay(_selectedMonth!)}';
    }

    return '${rolePrefix}Attendance Overview';
  }

  String get chartSubtitle {
    if (!hasData) return 'No data available';

    final present = _stats['present'];
    final total = _stats['total'];
    final rate = _stats['attendanceRate'];

    return 'Present: $present/$total (${rate.toStringAsFixed(1)}%)';
  }

  List<Map<String, String>> get availableMonthsFormatted {
    final now = DateTime.now();
    final months = <Map<String, String>>[];

    // Generate last 12 months
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add({
        'value': _formatMonthForAPI(month),
        'label': _formatMonthForDisplay(month),
      });
    }

    return months;
  }

  // Get data for chart visualization
  Map<String, dynamic> get chartVisualizationData {
    print('\n📊 ========== CHART VISUALIZATION DATA ==========');

    if (_chartData == null || !hasData) {
      print('📊 No chart data available');
      return {
        'labels': [],
        'present': [],
        'absent': [],
        'late': [],
        'sortedData': [],
      };
    }

    final labels = <String>[];
    final presentData = <int>[];
    final absentData = <int>[];
    final lateData = <int>[];

    // Sort data by date
    final sortedData = _chartData!.sortedData;

    print('📊 Processing ${sortedData.length} items for chart');

    for (final item in sortedData) {
      final label = item.getFormattedLabel(_chartData!.granularity);
      labels.add(label);
      presentData.add(item.present);
      absentData.add(item.absent);
      lateData.add(item.late);

      print('📊 Chart item: $label - P:${item.present}, A:${item.absent}, L:${item.late}');
    }

    // Debug totals
    final totalPresent = presentData.fold(0, (sum, value) => sum + value);
    final totalAbsent = absentData.fold(0, (sum, value) => sum + value);
    final totalLate = lateData.fold(0, (sum, value) => sum + value);

    print('📊 Chart totals - Present: $totalPresent, Absent: $totalAbsent, Late: $totalLate');
    print('📊 Stats totals - Present: ${_stats['present']}, Absent: ${_stats['absent']}, Late: ${_stats['late']}');

    return {
      'labels': labels,
      'present': presentData,
      'absent': absentData,
      'late': lateData,
      'sortedData': sortedData,
    };
  }

  // Refresh data
  Future<void> refreshData({BuildContext? context}) async {
    print('🔄 Manual refresh requested');
    if (_isLoading) {
      print('⚠️ Already loading, skipping refresh');
      return;
    }
    await fetchAttendanceData(context: context);
  }

  // Clear all data
  void clearData() {
    print('🗑️ Clearing all chart data');
    _chartData = null;
    _error = null;
    _stats = {
      'present': 0,
      'absent': 0,
      'late': 0,
      'total': 0,
      'attendanceRate': 0.0,
      'lateRate': 0.0,
    };
    notifyListeners();
  }

  // Reset to default
  void reset() {
    print('🔄 Resetting ChartProvider to defaults');
    _initializeDates();
    _chartType = 'daily';
    clearData();
  }

  // Test with specific date
  Future<void> testSpecificDate(String dateString) async {
    print('\n🧪 ========== TESTING SPECIFIC DATE ==========');
    try {
      final date = DateTime.parse(dateString);
      print('🧪 Testing date: $date');

      setSelectedDate(date);
      setChartType('daily');

      await fetchAttendanceData();
    } catch (e) {
      print('❌ Error testing date $dateString: $e');
    }
  }

  // Export data as JSON
  String exportDataAsJson() {
    if (_chartData == null) return '{}';

    final exportData = {
      'chartType': _chartType,
      'selectedDate': _selectedDate?.toIso8601String(),
      'selectedMonth': _selectedMonth?.toIso8601String(),
      'statistics': _stats,
      'data': _chartData!.toJson(),
    };

    return jsonEncode(exportData);
  }
}