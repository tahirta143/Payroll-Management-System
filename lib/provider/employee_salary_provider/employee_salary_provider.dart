import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../model/employee_salary_model/employee_salary_model.dart';

class EmployeeSalaryProvider with ChangeNotifier {
  List<EmployeeSalary> _salaries = [];
  bool _isLoading = false;
  String _error = '';
  String? _authToken;

  List<EmployeeSalary> get salaries => _salaries;
  bool get isLoading => _isLoading;
  String get error => _error;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static const String _baseUrl = 'https://api.afaqmis.com/api';

  // Fetch all employee salaries
  Future<void> fetchEmployeeSalaries({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/employee-salaries'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body)['employee_salaries'];
        _salaries = responseData.map((json) => EmployeeSalary.fromJson(json)).toList();
        _error = '';
      } else {
        _error = 'Failed to load salaries: ${response.statusCode}';
        if (response.statusCode == 401) {
          _error = 'Unauthorized. Please login again.';
        }
      }
    } catch (e) {
      _error = 'Error fetching salaries: $e';
      if (kDebugMode) {
        print('Error: $e');
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Fetch single salary by ID
  Future<EmployeeSalary?> fetchSalaryById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/employee-salaries/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return EmployeeSalary.fromJson(json.decode(response.body));
      } else {
        _error = 'Failed to load salary: ${response.statusCode}';
        return null;
      }
    } catch (e) {
      _error = 'Error fetching salary: $e';
      return null;
    }
  }

  // Create new salary
  Future<bool> createSalary(EmployeeSalary salary) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/employee-salaries'),
        headers: _headers,
        body: json.encode(salary.toJson()),
      );

      _isLoading = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchEmployeeSalaries(showLoading: false);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create salary: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error creating salary: $e';
      notifyListeners();
      return false;
    }
  }

  // Update existing salary
  Future<bool> updateSalary(EmployeeSalary salary) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/employee-salaries/${salary.id}'),
        headers: _headers,
        body: json.encode(salary.toJson()),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final index = _salaries.indexWhere((s) => s.id == salary.id);
        if (index != -1) {
          _salaries[index] = salary;
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Failed to update salary: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating salary: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete salary
  Future<bool> deleteSalary(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/employee-salaries/$id'),
        headers: _headers,
      );

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _salaries.removeWhere((salary) => salary.id == id);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete salary: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error deleting salary: $e';
      notifyListeners();
      return false;
    }
  }

  // Filter salaries by employee name or code
  List<EmployeeSalary> searchSalaries(String query) {
    if (query.isEmpty) return _salaries;

    final lowerQuery = query.toLowerCase();
    return _salaries.where((salary) {
      return salary.employeeName.toLowerCase().contains(lowerQuery) ||
          salary.employeeCode.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = '';
  }
}