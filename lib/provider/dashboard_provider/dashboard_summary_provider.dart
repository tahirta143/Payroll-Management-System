// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../model/dashboar_model/dashboard_summary.dart';
//
// class DashboardSummaryProvider with ChangeNotifier {
//   DashboardSummary? _dashboardSummary;
//   DashboardSummary? _dailySummary;
//   String _selectedDate = 'all';
//   bool _isLoading = false;
//   String? _error;
//   bool _isRefreshing = false;
//
//   // Track if data has been fixed
//   bool _dataWasFixed = false;
//   String? _dataFixExplanation;
//
//   // Base URL
//   static const String _baseUrl = 'https://api.afaqmis.com';
//
//   // SharedPreferences
//   static SharedPreferences? _prefs;
//   static const String _tokenKey = 'token';
//
//   // Getters
//   DashboardSummary? get dashboardSummary => _dashboardSummary;
//   DashboardSummary? get dailySummary => _dailySummary;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   bool get isRefreshing => _isRefreshing;
//   String get selectedDate => _selectedDate;
//   bool get dataWasFixed => _dataWasFixed;
//   String? get dataFixExplanation => _dataFixExplanation;
//
//   // Static initialization method
//   static Future<void> initializeSharedPreferences() async {
//     if (_prefs == null) {
//       _prefs = await SharedPreferences.getInstance();
//     }
//   }
//
//   // Get token from SharedPreferences
//   Future<String> _getToken() async {
//     try {
//       if (_prefs == null) {
//         await initializeSharedPreferences();
//       }
//
//       final token = _prefs!.getString(_tokenKey);
//       return token ?? '';
//     } catch (e) {
//       debugPrint('Error getting token: $e');
//       return '';
//     }
//   }
//
//   // Save token to SharedPreferences
//   Future<void> _saveToken(String token) async {
//     try {
//       if (_prefs == null) {
//         await initializeSharedPreferences();
//       }
//       await _prefs!.setString(_tokenKey, token);
//     } catch (e) {
//       debugPrint('Error saving token: $e');
//     }
//   }
//
//   // Clear token from SharedPreferences
//   Future<void> _clearToken() async {
//     try {
//       if (_prefs == null) {
//         await initializeSharedPreferences();
//       }
//       await _prefs!.remove(_tokenKey);
//     } catch (e) {
//       debugPrint('Error clearing token: $e');
//     }
//   }
//
//   // Data sanitization and fixing method
//   DashboardSummary _sanitizeAndFixData(DashboardSummary original, Map<String, dynamic> rawData) {
//     debugPrint('=== DATA SANITIZATION STARTED ===');
//     debugPrint('Original data:');
//     debugPrint('- total_employees: ${original.totalEmployees}');
//     debugPrint('- present_count: ${original.presentCount}');
//     debugPrint('- leave_count: ${original.leaveCount}');
//     debugPrint('- absent_count: ${original.absentCount}');
//     debugPrint('- short_leave_count: ${original.shortLeaveCount}');
//     debugPrint('- late_comers_count: ${original.lateComersCount}');
//
//     // Reset fix tracking
//     _dataWasFixed = false;
//     _dataFixExplanation = null;
//
//     final errors = original.validate();
//
//     if (errors.isEmpty) {
//       debugPrint('✅ Data is valid, no fixes needed');
//       return original;
//     }
//
//     debugPrint('⚠️ Data issues found:');
//     for (final error in errors) {
//       debugPrint('  - $error');
//     }
//
//     // Start with original data
//     int totalEmployees = original.totalEmployees;
//     int presentCount = original.presentCount;
//     int leaveCount = original.leaveCount;
//     int shortLeaveCount = original.shortLeaveCount;
//     int absentCount = original.absentCount;
//     int lateComersCount = original.lateComersCount;
//
//     String fixExplanation = 'Data was adjusted because: ${errors.first}\n\n';
//
//     // **FIX 1: If present = total, then leave and absent should be 0**
//     if (presentCount == totalEmployees && (leaveCount > 0 || absentCount > 0)) {
//       fixExplanation += 'Everyone is marked present, so leave and absent set to 0.\n';
//       leaveCount = 0;
//       absentCount = 0;
//       _dataWasFixed = true;
//     }
//
//     // **FIX 2: If sum doesn't match total, adjust absent count**
//     final sum = presentCount + leaveCount + absentCount;
//     if (sum != totalEmployees) {
//       if (sum > totalEmployees) {
//         // Too many people in categories
//         fixExplanation += 'Present($presentCount) + Leave($leaveCount) + Absent($absentCount) = $sum '
//             'exceeds Total($totalEmployees). ';
//
//         // Try different adjustment strategies
//         if (presentCount <= totalEmployees) {
//           // Keep present, adjust leave first, then absent
//           final availableForLeaveAbsent = totalEmployees - presentCount;
//           if (leaveCount > availableForLeaveAbsent) {
//             leaveCount = availableForLeaveAbsent;
//             absentCount = 0;
//             fixExplanation += 'Adjusted leave to $leaveCount, absent to 0.';
//           } else {
//             absentCount = availableForLeaveAbsent - leaveCount;
//             fixExplanation += 'Adjusted absent to $absentCount.';
//           }
//         } else {
//           // Even present count is too high - scale everything down proportionally
//           final scale = totalEmployees / sum;
//           presentCount = (presentCount * scale).round();
//           leaveCount = (leaveCount * scale).round();
//           absentCount = totalEmployees - presentCount - leaveCount;
//           fixExplanation += 'Scaled all values proportionally.';
//         }
//       } else {
//         // Not enough people in categories - adjust absent
//         absentCount = totalEmployees - presentCount - leaveCount;
//         fixExplanation += 'Adjusted absent count to $absentCount to match total.';
//       }
//       _dataWasFixed = true;
//     }
//
//     // **FIX 3: Ensure late comers doesn't exceed present count**
//     if (lateComersCount > presentCount) {
//       fixExplanation += 'Late comers ($lateComersCount) exceeds present count ($presentCount). ';
//       lateComersCount = presentCount;
//       fixExplanation += 'Set late comers to present count: $lateComersCount.';
//       _dataWasFixed = true;
//     }
//
//     // **FIX 4: Ensure short leave doesn't exceed present count**
//     if (shortLeaveCount > presentCount) {
//       fixExplanation += 'Short leave ($shortLeaveCount) exceeds present count ($presentCount). ';
//       shortLeaveCount = presentCount;
//       fixExplanation += 'Set short leave to present count: $shortLeaveCount.';
//       _dataWasFixed = true;
//     }
//
//     // Create fixed summary
//     final fixedSummary = DashboardSummary(
//       totalEmployees: totalEmployees,
//       presentCount: presentCount,
//       leaveCount: leaveCount,
//       shortLeaveCount: shortLeaveCount,
//       absentCount: absentCount,
//       lateComersCount: lateComersCount,
//       month: original.month,
//     );
//
//     // Validate the fixed data
//     final fixedErrors = fixedSummary.validate();
//     if (fixedErrors.isEmpty) {
//       debugPrint('✅ Data successfully fixed');
//       debugPrint('Fixed data:');
//       debugPrint('- total_employees: $totalEmployees');
//       debugPrint('- present_count: $presentCount (${fixedSummary.presentPercentage.toStringAsFixed(1)}%)');
//       debugPrint('- leave_count: $leaveCount (${fixedSummary.leavePercentage.toStringAsFixed(1)}%)');
//       debugPrint('- absent_count: $absentCount (${fixedSummary.absentPercentage.toStringAsFixed(1)}%)');
//       debugPrint('- short_leave_count: $shortLeaveCount');
//       debugPrint('- late_comers_count: $lateComersCount');
//     } else {
//       debugPrint('❌ Fixing failed, errors remain:');
//       for (final error in fixedErrors) {
//         debugPrint('  - $error');
//       }
//     }
//
//     _dataFixExplanation = fixExplanation;
//     debugPrint('=== DATA SANITIZATION COMPLETED ===');
//
//     return fixedSummary;
//   }
//
//   // Fetch dashboard summary (with optional date filter)
//   Future<void> fetchDashboardSummary({String? date}) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       _dataWasFixed = false;
//       _dataFixExplanation = null;
//       notifyListeners();
//
//       // Initialize SharedPreferences if needed
//       if (_prefs == null) {
//         await initializeSharedPreferences();
//       }
//
//       // Get token
//       final token = await _getToken();
//
//       if (token.isEmpty) {
//         _error = 'Authentication required. Please login again.';
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       final headers = {
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//       };
//
//       // Build URL with date parameter
//       String url = '$_baseUrl/api/dashboard-summary';
//       if (date != null && date.isNotEmpty && date != 'all') {
//         url += '?date=$date';
//         _selectedDate = date;
//         debugPrint('🔄 Fetching DAILY summary for date: $date');
//       } else {
//         url += '?date=all';
//         _selectedDate = 'all';
//         debugPrint('🔄 Fetching ALL-TIME dashboard summary');
//       }
//
//       final response = await http.get(
//         Uri.parse(url),
//         headers: headers,
//       );
//
//       debugPrint('📥 API Response Status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         // Check if response has expected structure
//         if (data['data'] != null) {
//           // Handle nested data structure
//           final summaryData = data['data'];
//           debugPrint('📊 API returned nested data structure');
//
//           // Log raw data for debugging
//           debugPrint('📊 Raw API Data:');
//           debugPrint('total_employees: ${summaryData['total_employees']}');
//           debugPrint('present_count: ${summaryData['present_count']}');
//           debugPrint('leave_count: ${summaryData['leave_count']}');
//           debugPrint('absent_count: ${summaryData['absent_count']}');
//           debugPrint('short_leave_count: ${summaryData['short_leave_count']}');
//           debugPrint('late_comers_count: ${summaryData['late_comers_count']}');
//
//           final originalSummary = DashboardSummary.fromJson(summaryData);
//           final sanitizedSummary = _sanitizeAndFixData(originalSummary, summaryData);
//
//           if (date != null && date.isNotEmpty && date != 'all') {
//             _dailySummary = sanitizedSummary;
//             debugPrint('✅ Daily summary saved for date: $date');
//           } else {
//             _dashboardSummary = sanitizedSummary;
//             debugPrint('✅ All-time dashboard summary saved');
//           }
//
//           _error = null;
//
//         } else if (data['total_employees'] != null) {
//           // Handle flat structure
//           debugPrint('📊 API returned flat data structure');
//
//           // Log raw data for debugging
//           debugPrint('📊 Raw API Data:');
//           debugPrint('total_employees: ${data['total_employees']}');
//           debugPrint('present_count: ${data['present_count']}');
//           debugPrint('leave_count: ${data['leave_count']}');
//           debugPrint('absent_count: ${data['absent_count']}');
//           debugPrint('short_leave_count: ${data['short_leave_count']}');
//           debugPrint('late_comers_count: ${data['late_comers_count']}');
//
//           final originalSummary = DashboardSummary.fromJson(data);
//           final sanitizedSummary = _sanitizeAndFixData(originalSummary, data);
//
//           if (date != null && date.isNotEmpty && date != 'all') {
//             _dailySummary = sanitizedSummary;
//             debugPrint('✅ Daily summary saved for date: $date');
//           } else {
//             _dashboardSummary = sanitizedSummary;
//             debugPrint('✅ All-time dashboard summary saved');
//           }
//
//           _error = null;
//
//         } else {
//           // No data found
//           if (date != null && date.isNotEmpty && date != 'all') {
//             _error = 'No data available for selected date';
//             _dailySummary = null;
//           } else {
//             _error = 'No dashboard data available';
//             _dashboardSummary = null;
//           }
//         }
//
//       } else if (response.statusCode == 401) {
//         _error = 'Session expired. Please login again.';
//         await _clearToken();
//       } else if (response.statusCode == 404) {
//         if (date != null && date.isNotEmpty && date != 'all') {
//           _error = 'No attendance data found for $date';
//           _dailySummary = null;
//         } else {
//           _error = 'Dashboard data not found.';
//         }
//       } else if (response.statusCode >= 500) {
//         _error = 'Server error. Please try again later.';
//       } else {
//         try {
//           final errorData = json.decode(response.body);
//           _error = errorData['message'] ?? 'Failed to load dashboard data';
//         } catch (e) {
//           _error = 'Failed to load dashboard data: ${response.statusCode}';
//         }
//         debugPrint('Error response: ${response.body}');
//       }
//     } catch (e) {
//       _error = 'Network error: ${e.toString()}';
//       debugPrint('Dashboard summary error: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Alternative: Try different endpoints for date-based data
//   Future<void> fetchDateWiseData(String date) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
//
//       final token = await _getToken();
//
//       if (token.isEmpty) {
//         _error = 'Authentication required. Please login again.';
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       final headers = {
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//       };
//
//       // Try different possible endpoints for date-wise data
//       final possibleEndpoints = [
//         '$_baseUrl/api/attendance/daily-summary?date=$date',
//         '$_baseUrl/api/attendance/summary?date=$date',
//         '$_baseUrl/api/daily-attendance?date=$date',
//         '$_baseUrl/api/attendances/summary?date=$date',
//       ];
//
//       bool success = false;
//
//       for (final url in possibleEndpoints) {
//         debugPrint('🔄 Trying date endpoint: $url');
//
//         final response = await http.get(
//           Uri.parse(url),
//           headers: headers,
//         );
//
//         debugPrint('📥 Response for $url: ${response.statusCode}');
//
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//
//           // Try to parse the data
//           try {
//             Map<String, dynamic> summaryData;
//
//             if (data['data'] != null) {
//               summaryData = data['data'];
//             } else if (data['summary'] != null) {
//               summaryData = data['summary'];
//             } else {
//               summaryData = data;
//             }
//
//             // Check if we have the required fields
//             if (summaryData['total_employees'] == null && summaryData['present_count'] == null) {
//               debugPrint('❌ Incomplete data from $url');
//               continue;
//             }
//
//             // Create summary from data
//             final summary = DashboardSummary(
//               totalEmployees: summaryData['total_employees'] ?? summaryData['totalEmployees'] ?? 0,
//               presentCount: summaryData['present_count'] ?? summaryData['presentCount'] ?? 0,
//               leaveCount: summaryData['leave_count'] ?? summaryData['leaveCount'] ?? 0,
//               absentCount: summaryData['absent_count'] ?? summaryData['absentCount'] ?? 0,
//               shortLeaveCount: summaryData['short_leave_count'] ?? summaryData['shortLeaveCount'] ?? 0,
//               lateComersCount: summaryData['late_comers_count'] ?? summaryData['lateComersCount'] ?? 0,
//               month: date,
//             );
//
//             _dailySummary = _sanitizeAndFixData(summary, summaryData);
//             _selectedDate = date;
//             _error = null;
//             success = true;
//             debugPrint('✅ Successfully fetched date-wise data from: $url');
//             break;
//           } catch (e) {
//             debugPrint('❌ Failed to parse response from $url: $e');
//             continue;
//           }
//         }
//       }
//
//       if (!success) {
//         _error = 'No attendance data found for $date';
//         _dailySummary = null;
//         debugPrint('⚠️ Could not fetch date-wise data from any endpoint');
//
//         // Fallback: Try to get data from staff attendance endpoint
//         await _fetchStaffAttendanceData(date);
//       }
//
//     } catch (e) {
//       _error = 'Network error: ${e.toString()}';
//       debugPrint('Date-wise data error: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Fallback method: Get data from staff attendance list
//   Future<void> _fetchStaffAttendanceData(String date) async {
//     try {
//       final token = await _getToken();
//
//       if (token.isEmpty) return;
//
//       final headers = {
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json',
//       };
//
//       // Get staff attendance for the date
//       final url = '$_baseUrl/api/attendances?date=$date';
//       final response = await http.get(Uri.parse(url), headers: headers);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['data'] is List) {
//           final List<dynamic> attendanceList = data['data'];
//
//           // Calculate summary from attendance list
//           int presentCount = 0;
//           int leaveCount = 0;
//           int absentCount = 0;
//           int lateCount = 0;
//           int shortLeaveCount = 0;
//
//           for (var attendance in attendanceList) {
//             final status = attendance['status']?.toString().toLowerCase() ?? '';
//
//             switch (status) {
//               case 'present':
//                 presentCount++;
//                 break;
//               case 'leave':
//                 leaveCount++;
//                 break;
//               case 'absent':
//                 absentCount++;
//                 break;
//               case 'late':
//                 lateCount++;
//                 break;
//               case 'short_leave':
//                 shortLeaveCount++;
//                 break;
//             }
//           }
//
//           final totalEmployees = attendanceList.length;
//
//           final summary = DashboardSummary(
//             totalEmployees: totalEmployees,
//             presentCount: presentCount,
//             leaveCount: leaveCount,
//             absentCount: absentCount,
//             shortLeaveCount: shortLeaveCount,
//             lateComersCount: lateCount,
//             month: date,
//           );
//
//           _dailySummary = _sanitizeAndFixData(summary, {});
//           _selectedDate = date;
//           _error = null;
//           debugPrint('✅ Calculated summary from attendance list: $totalEmployees employees');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error fetching attendance list: $e');
//     }
//   }
//
//   // Main method to fetch data
//   Future<void> fetchData({String? date}) async {
//     if (date != null && date.isNotEmpty && date != 'all') {
//       // First try the main dashboard endpoint
//       await fetchDashboardSummary(date: date);
//
//       // If no data found, try alternative endpoints
//       if (_dailySummary == null && (_error?.contains('No data') == true || _error?.contains('404') == true)) {
//         debugPrint('🔄 No data from main endpoint, trying date-wise endpoints');
//         await fetchDateWiseData(date);
//       }
//     } else {
//       // For all-time data
//       await fetchDashboardSummary(date: null);
//     }
//   }
//
//   // Refresh dashboard data with date parameter
//   Future<void> refreshDashboardData({String? date}) async {
//     _isRefreshing = true;
//     notifyListeners();
//
//     await fetchData(date: date);
//
//     _isRefreshing = false;
//     notifyListeners();
//   }
//
//   // Clear daily summary
//   void clearDailySummary() {
//     _dailySummary = null;
//     _selectedDate = 'all';
//     notifyListeners();
//   }
//
//   // Get current summary (daily if available, otherwise all-time)
//   DashboardSummary? get currentSummary {
//     return _selectedDate != 'all' && _dailySummary != null
//         ? _dailySummary
//         : _dashboardSummary;
//   }
//
//   // Get stats with data fix warning
//   Map<String, dynamic> getStats() {
//     final summary = currentSummary ?? _dashboardSummary;
//
//     if (summary == null) {
//       return {
//         'totalEmployees': 0,
//         'presentCount': 0,
//         'leaveCount': 0,
//         'shortLeaveCount': 0,
//         'absentCount': 0,
//         'lateComersCount': 0,
//         'presentPercentage': 0.0,
//         'leavePercentage': 0.0,
//         'absentPercentage': 0.0,
//         'dataWasFixed': _dataWasFixed,
//         'dataFixExplanation': _dataFixExplanation,
//       };
//     }
//
//     final total = summary.totalEmployees;
//     final presentPercentage = total > 0 ? (summary.presentCount / total) * 100 : 0;
//     final leavePercentage = total > 0 ? (summary.leaveCount / total) * 100 : 0;
//     final absentPercentage = total > 0 ? (summary.absentCount / total) * 100 : 0;
//
//     return {
//       'totalEmployees': total,
//       'presentCount': summary.presentCount,
//       'leaveCount': summary.leaveCount,
//       'shortLeaveCount': summary.shortLeaveCount,
//       'absentCount': summary.absentCount,
//       'lateComersCount': summary.lateComersCount,
//       'presentPercentage': presentPercentage,
//       'leavePercentage': leavePercentage,
//       'absentPercentage': absentPercentage,
//       'dataWasFixed': _dataWasFixed,
//       'dataFixExplanation': _dataFixExplanation,
//     };
//   }
//
//   // Method to set token from AuthProvider
//   Future<void> setToken(String token) async {
//     await _saveToken(token);
//   }
//
//   // Method to check if user is authenticated
//   Future<bool> isAuthenticated() async {
//     final token = await _getToken();
//     return token.isNotEmpty;
//   }
//
//   // Clear all data
//   void clearData() {
//     _dashboardSummary = null;
//     _dailySummary = null;
//     _selectedDate = 'all';
//     _error = null;
//     _dataWasFixed = false;
//     _dataFixExplanation = null;
//     notifyListeners();
//   }
//
//   // Logout - clear all auth data
//   Future<void> logout() async {
//     await _clearToken();
//     clearData();
//   }
// }
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
  bool _shouldFixData = false; // Default to false to show original data
  // Store original data before fixing
  DashboardSummary? _originalSummary;
  DashboardSummary? _originalDailySummary;

  // Base URL
  // static const String _baseUrl = 'https://api.afaqmis.com';

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

  // Setter for shouldFixData
  set shouldFixData(bool value) {
    _shouldFixData = value;

    // When changing the fix mode, update the displayed data
    if (_shouldFixData && _originalSummary != null) {
      // If enabling fixes, apply fixes to original data
      _dashboardSummary = _sanitizeAndFixData(_originalSummary!, {});
    } else if (!_shouldFixData && _originalSummary != null) {
      // If disabling fixes, restore original data
      _dashboardSummary = _originalSummary;
    }

    if (_shouldFixData && _originalDailySummary != null) {
      _dailySummary = _sanitizeAndFixData(_originalDailySummary!, {});
    } else if (!_shouldFixData && _originalDailySummary != null) {
      _dailySummary = _originalDailySummary;
    }

    notifyListeners();
  }
  bool get shouldFixData => _shouldFixData;

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

  // Data sanitization and fixing method - UPDATED
  DashboardSummary _sanitizeAndFixData(DashboardSummary original, Map<String, dynamic> rawData) {
    debugPrint('=== DATA SANITIZATION STARTED ===');
    debugPrint('Data fixing enabled: $_shouldFixData');
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

    // Check if we should fix data
    if (!_shouldFixData) {
      debugPrint('⚠️ Data fixing is DISABLED. Returning original data.');
      debugPrint('=== DATA SANITIZATION COMPLETED ===');
      return original;
    }

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

  // Fetch dashboard summary (with optional date filter)
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

      // Build URL with date parameter
      String url = '${GlobalUrls.baseurl}/api/dashboard-summary';
      if (date != null && date.isNotEmpty && date != 'all') {
        url += '?date=$date';
        _selectedDate = date;
        debugPrint('🔄 Fetching DAILY summary for date: $date');
      } else {
        url += '?date=all';
        _selectedDate = 'all';
        debugPrint('🔄 Fetching ALL-TIME dashboard summary');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📥 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if response has expected structure
        if (data['data'] != null) {
          // Handle nested data structure
          final summaryData = data['data'];
          debugPrint('📊 API returned nested data structure');

          // Log raw data for debugging
          debugPrint('📊 Raw API Data:');
          debugPrint('total_employees: ${summaryData['total_employees']}');
          debugPrint('present_count: ${summaryData['present_count']}');
          debugPrint('leave_count: ${summaryData['leave_count']}');
          debugPrint('absent_count: ${summaryData['absent_count']}');
          debugPrint('short_leave_count: ${summaryData['short_leave_count']}');
          debugPrint('late_comers_count: ${summaryData['late_comers_count']}');

          final originalSummary = DashboardSummary.fromJson(summaryData);

          // Store original data
          if (date != null && date.isNotEmpty && date != 'all') {
            _originalDailySummary = originalSummary;
          } else {
            _originalSummary = originalSummary;
          }

          // Apply fixes if enabled
          final processedSummary = _sanitizeAndFixData(originalSummary, summaryData);

          if (date != null && date.isNotEmpty && date != 'all') {
            _dailySummary = processedSummary;
            debugPrint('✅ Daily summary saved for date: $date');
          } else {
            _dashboardSummary = processedSummary;
            debugPrint('✅ All-time dashboard summary saved');
          }

          _error = null;

        } else if (data['total_employees'] != null) {
          // Handle flat structure
          debugPrint('📊 API returned flat data structure');

          // Log raw data for debugging
          debugPrint('📊 Raw API Data:');
          debugPrint('total_employees: ${data['total_employees']}');
          debugPrint('present_count: ${data['present_count']}');
          debugPrint('leave_count: ${data['leave_count']}');
          debugPrint('absent_count: ${data['absent_count']}');
          debugPrint('short_leave_count: ${data['short_leave_count']}');
          debugPrint('late_comers_count: ${data['late_comers_count']}');

          final originalSummary = DashboardSummary.fromJson(data);

          // Store original data
          if (date != null && date.isNotEmpty && date != 'all') {
            _originalDailySummary = originalSummary;
          } else {
            _originalSummary = originalSummary;
          }

          // Apply fixes if enabled
          final processedSummary = _sanitizeAndFixData(originalSummary, data);

          if (date != null && date.isNotEmpty && date != 'all') {
            _dailySummary = processedSummary;
            debugPrint('✅ Daily summary saved for date: $date');
          } else {
            _dashboardSummary = processedSummary;
            debugPrint('✅ All-time dashboard summary saved');
          }

          _error = null;

        } else {
          // No data found
          if (date != null && date.isNotEmpty && date != 'all') {
            _error = 'No data available for selected date';
            _dailySummary = null;
            _originalDailySummary = null;
          } else {
            _error = 'No dashboard data available';
            _dashboardSummary = null;
            _originalSummary = null;
          }
        }

      } else if (response.statusCode == 401) {
        _error = 'Session expired. Please login again.';
        await _clearToken();
      } else if (response.statusCode == 404) {
        if (date != null && date.isNotEmpty && date != 'all') {
          _error = 'No attendance data found for $date';
          _dailySummary = null;
          _originalDailySummary = null;
        } else {
          _error = 'Dashboard data not found.';
        }
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

        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        );

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
            if (summaryData['total_employees'] == null && summaryData['present_count'] == null) {
              debugPrint('❌ Incomplete data from $url');
              continue;
            }

            // Create summary from data
            final originalSummary = DashboardSummary(
              totalEmployees: summaryData['total_employees'] ?? summaryData['totalEmployees'] ?? 0,
              presentCount: summaryData['present_count'] ?? summaryData['presentCount'] ?? 0,
              leaveCount: summaryData['leave_count'] ?? summaryData['leaveCount'] ?? 0,
              absentCount: summaryData['absent_count'] ?? summaryData['absentCount'] ?? 0,
              shortLeaveCount: summaryData['short_leave_count'] ?? summaryData['shortLeaveCount'] ?? 0,
              lateComersCount: summaryData['late_comers_count'] ?? summaryData['lateComersCount'] ?? 0,
              month: date,
            );

            // Store original data
            _originalDailySummary = originalSummary;

            // Apply fixes if enabled
            final processedSummary = _sanitizeAndFixData(originalSummary, summaryData);

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
            month: date,
          );

          // Store original data
          _originalDailySummary = originalSummary;

          // Apply fixes if enabled
          final processedSummary = _sanitizeAndFixData(originalSummary, {});

          _dailySummary = processedSummary;
          _selectedDate = date;
          _error = null;
          debugPrint('✅ Calculated summary from attendance list: $totalEmployees employees');
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
      if (_dailySummary == null && (_error?.contains('No data') == true || _error?.contains('404') == true)) {
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

  // Get current summary (daily if available, otherwise all-time)
  DashboardSummary? get currentSummary {
    return _selectedDate != 'all' && _dailySummary != null
        ? _dailySummary
        : _dashboardSummary;
  }

  // Get original summary (unfixed data)
  DashboardSummary? get currentOriginalSummary {
    return _selectedDate != 'all' && _originalDailySummary != null
        ? _originalDailySummary
        : _originalSummary;
  }

  // Get stats - always returns unfixed/original data
  Map<String, dynamic> getStats({bool useFixedData = false}) {
    DashboardSummary? summary;

    if (useFixedData) {
      summary = currentSummary ?? _dashboardSummary;
    } else {
      summary = currentOriginalSummary ?? _originalSummary;
    }

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
        'usingFixedData': useFixedData,
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
      'dataWasFixed': _dataWasFixed && useFixedData,
      'dataFixExplanation': _dataFixExplanation,
      'usingFixedData': useFixedData,
    };
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