import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utility/global_url.dart';
import '../../model/short_leave_model.dart';

class ShortLeavesProvider with ChangeNotifier {
  List<ShortLeaveModel> _shortLeaves = [];
  List<Map<String, dynamic>> _allEmployees = [];
  bool _isLoading = false;
  String _error = '';

  List<ShortLeaveModel> get shortLeaves => _shortLeaves;
  List<Map<String, dynamic>> get allEmployees => _allEmployees;
  bool get isLoading => _isLoading;
  String get error => _error;

  String _userRole = 'user';
  String _currentEmployeeId = '';

  bool get isAdmin => _userRole.toLowerCase().contains('admin');
  String get currentEmployeeId => _currentEmployeeId;

  Future<void> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Robustly check for user role
    _userRole = prefs.getString('user_role')?.toLowerCase() ?? 'user';
    
    // Robustly check for current employee ID (matches AttendanceProvider's multiple-source pattern)
    _currentEmployeeId = prefs.getString('employee_id') ?? 
                         prefs.getString('emp_id') ?? 
                         prefs.getInt('user_id')?.toString() ?? 
                         '';
                         
    print('ShortLeaves Initialized - Role: $_userRole, ID: $_currentEmployeeId');
    notifyListeners();
  }

  Future<void> fetchAllEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${GlobalUrls.baseurl}/api/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['employees'] != null) {
          _allEmployees = (data['employees'] as List).map((e) => {
            'id': e['id'],
            'name': e['name'],
            'employee_code': e['employee_code'] ?? '',
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
    notifyListeners();
  }

  Future<void> fetchShortLeaves({
    int? employeeId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _error = 'No authentication token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // If not admin and no specific employeeId provided, use current user's ID
      if (!isAdmin && employeeId == null && _currentEmployeeId.isNotEmpty) {
        employeeId = int.tryParse(_currentEmployeeId);
      }

      String url = '${GlobalUrls.baseurl}/api/short-leaves';
      List<String> params = [];
      if (employeeId != null) params.add('employee_id=$employeeId');
      if (status != null && status != 'all') params.add('status=$status');
      if (fromDate != null && fromDate.isNotEmpty) params.add('from_date=$fromDate');
      if (toDate != null && toDate.isNotEmpty) params.add('to_date=$toDate');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print('Fetching short leaves from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<ShortLeaveModel> fetchedLeaves = [];
        
        if (data['leaves'] != null) {
          fetchedLeaves = (data['leaves'] as List)
              .map((item) => ShortLeaveModel.fromJson(item))
              .toList();
        }
        
        // ── Local Filtering ─────────────────────────────────────
        // If not admin, ensure we only show the user's OWN records
        // (Mirrors the robust filtering used in AttendanceProvider)
        if (!isAdmin && _currentEmployeeId.isNotEmpty) {
          final idInt = int.tryParse(_currentEmployeeId);
          _shortLeaves = fetchedLeaves.where((l) => l.employeeId == idInt).toList();
          print('Local Filter Applied: Retained ${_shortLeaves.length} of ${fetchedLeaves.length} records for user $_currentEmployeeId');
        } else {
          _shortLeaves = fetchedLeaves;
        }
      } else {
        _error = 'Failed to fetch short leaves: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching short leaves: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addShortLeave(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // If not admin, always force YOUR employee ID to prevent misattribution
      if (!isAdmin && _currentEmployeeId.isNotEmpty) {
        payload['employee_id'] = int.tryParse(_currentEmployeeId);
      }

      final response = await http.post(
        Uri.parse('${GlobalUrls.baseurl}/api/short-leaves'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchShortLeaves();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to add short leave';
        return false;
      }
    } catch (e) {
      _error = 'Error adding short leave: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateShortLeave(int id, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // If not admin, always force YOUR employee ID to prevent misattribution
      if (!isAdmin && _currentEmployeeId.isNotEmpty) {
        payload['employee_id'] = int.tryParse(_currentEmployeeId);
      }

      final response = await http.put(
        Uri.parse('${GlobalUrls.baseurl}/api/short-leaves/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchShortLeaves();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to update short leave';
        return false;
      }
    } catch (e) {
      _error = 'Error updating short leave: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteShortLeave(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${GlobalUrls.baseurl}/api/short-leaves/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _shortLeaves.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete short leave';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting short leave: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
