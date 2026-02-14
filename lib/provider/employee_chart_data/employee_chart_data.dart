import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:payroll_app/provider/Auth_provider/Auth_provider.dart';
import 'package:provider/provider.dart';

// Fix this import path - make sure it matches your file location
import '../../model/employee_chart_data/employee_chart_data.dart';


class AttendanceChartProvider extends ChangeNotifier {
  AttendanceChartModel? _chartData;
  bool _isLoading = false;
  String? _error;
  String _selectedMonth = _getCurrentMonth();

  // Getters
  AttendanceChartModel? get chartData => _chartData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedMonth => _selectedMonth;

  static String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  // Set month
  void setMonth(String month) {
    if (_selectedMonth != month) {
      _selectedMonth = month;
      notifyListeners();
    }
  }

  // Clear data
  void clearData() {
    _chartData = null;
    _error = null;
    notifyListeners();
  }

  // Fetch attendance chart data for a specific employee
  Future<void> fetchEmployeeAttendanceChart({
    required String employeeId,
    String? month,
    BuildContext? context,
  }) async {
    if (employeeId.isEmpty) {
      print('❌ Employee ID is empty');
      _error = 'Employee ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final monthParam = month ?? _selectedMonth;
      final url = 'https://api.afaqmis.com/api/dashboard-chart?month=$monthParam&employee_id=$employeeId';

      print('🔍 Fetching attendance chart from: $url');
      print('👤 Using Employee ID: $employeeId');
      print('📅 Using Month: $monthParam');

      String? token;
      if (context != null) {
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          token = authProvider.token;
          print('✅ Token found: ${token != null}');
        } catch (e) {
          print('❌ Could not get AuthProvider from context: $e');
        }
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('📤 Making API request...');
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        _chartData = AttendanceChartModel.fromJson(jsonData);
        _error = null;

        print('✅ Successfully loaded chart data');
        print('📊 Employee: ${_chartData?.employeeName}');
        print('📊 Total Present: ${_chartData?.totalPresent}');
        print('📊 Total Absent: ${_chartData?.totalAbsent}');
        print('📊 Total Late: ${_chartData?.totalLate}');
        print('📊 Has Data: ${_chartData?.hasData}');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        _error = 'Failed to load chart data: ${response.statusCode}';
        _chartData = null;
      }
    } catch (e) {
      print('❌ Error fetching attendance chart: $e');
      _error = 'Network error: ${e.toString()}';
      _chartData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Refresh current data
  Future<void> refreshData({
    required String employeeId,
    BuildContext? context,
  }) async {
    await fetchEmployeeAttendanceChart(
      employeeId: employeeId,
      month: _selectedMonth,
      context: context,
    );
  }

  // Reset state (useful for logout)
  void reset() {
    _chartData = null;
    _isLoading = false;
    _error = null;
    _selectedMonth = _getCurrentMonth();
    notifyListeners();
  }
}