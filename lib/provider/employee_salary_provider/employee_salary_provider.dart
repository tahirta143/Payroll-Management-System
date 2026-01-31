import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/attendance_model/attendance_model.dart';
import '../../model/employee_salary_model/employee_salary_model.dart';


class EmployeeSalaryProvider with ChangeNotifier {
  List<EmployeeSalary> _salaries = [];
  List<Employee> _employees = [];
  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  String _error = '';
  String? _authToken;

  List<EmployeeSalary> get salaries => _salaries;
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  bool get isLoadingEmployees => _isLoadingEmployees;
  String get error => _error;
  String? get authToken => _authToken;

  static const String _baseUrl = 'https://api.afaqmis.com/api';

  void setAuthToken(String token) {
    print('[Provider] Setting auth token');
    _authToken = token;
    notifyListeners();
  }

  Future<String> _getToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      print('[Provider] Retrieved token from storage, length: ${token.length}');

      if (token.isNotEmpty) {
        _authToken = token;
      }

      return token;
    } catch (e) {
      print('[Provider] Error getting token: $e');
      return '';
    }
  }

  Map<String, String> _getHeaders(String token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('[Provider] Added Authorization header with token');
    } else {
      print('[Provider] No token available for Authorization header');
    }

    return headers;
  }

  Future<bool> loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        print('[Provider] Token loaded from SharedPreferences: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        setAuthToken(token);
        return true;
      } else {
        print('[Provider] No token found in SharedPreferences');
        _error = 'Authentication required. Please login.';
        return false;
      }
    } catch (e) {
      print('[Provider] Error loading token: $e');
      _error = 'Error loading authentication: $e';
      return false;
    }
  }

  // Fetch all employee salaries
  Future<void> fetchEmployeeSalaries({bool showLoading = true}) async {
    print('[Provider] fetchEmployeeSalaries called');

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      final url = '$_baseUrl/employee-salaries';

      print('[Provider] Fetching salaries from: $url');
      print('[Provider] Token available: ${token.isNotEmpty}');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      print('[Provider] Salary API Response Status: ${response.statusCode}');
      print('[Provider] Salary API Response Body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        if (decodedBody is Map && decodedBody.containsKey('employee_salaries')) {
          final List<dynamic> responseData = decodedBody['employee_salaries'];
          print('[Provider] Found ${responseData.length} salaries in response');

          _salaries = responseData.map((json) => EmployeeSalary.fromJson(json)).toList();
          _error = '';

          print('[Provider] Successfully parsed ${_salaries.length} salaries');
        } else {
          print('[Provider] Unexpected response format for salaries');
          _error = 'Unexpected response format';
        }
      } else {
        _error = 'Failed to load salaries: ${response.statusCode}';
        print('[Provider] Error: $_error');

        if (response.statusCode == 401) {
          _error = 'Unauthorized. Please login again.';
        }
      }
    } catch (e) {
      _error = 'Error fetching salaries: $e';
      print('[Provider] Exception in fetchEmployeeSalaries: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Fetch all employees - UPDATED TO HANDLE DIFFERENT API RESPONSE FORMATS
  Future<void> fetchEmployees() async {
    print('[Provider] ===== FETCH EMPLOYEES STARTED =====');

    try {
      _isLoadingEmployees = true;
      notifyListeners();

      final token = await _getToken();
      print('[Provider] Token for employees API: ${token.isNotEmpty ? "Available (${token.length} chars)" : "Not available"}');

      final url = '$_baseUrl/employees';
      print('[Provider] Fetching employees from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      print('[Provider] Employees API Response Status: ${response.statusCode}');
      print('[Provider] Employees API Response Body length: ${response.body.length}');

      // Print first 500 characters of response for debugging
      if (response.body.length > 500) {
        print('[Provider] Response preview: ${response.body.substring(0, 500)}...');
      } else {
        print('[Provider] Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          print('[Provider] Successfully decoded JSON response');

          // Clear existing employees
          _employees = [];

          // Handle different response formats
          if (data is Map) {
            print('[Provider] Response is a Map, keys: ${data.keys.toList()}');

            // Try common response structures
            if (data.containsKey('employees') && data['employees'] is List) {
              print('[Provider] Found employees key with List data');
              _parseEmployeesFromList(data['employees']);
            }
            else if (data.containsKey('data') && data['data'] is List) {
              print('[Provider] Found data key with List data');
              _parseEmployeesFromList(data['data']);
            }
            else if (data.containsKey('users') && data['users'] is List) {
              print('[Provider] Found users key with List data');
              _parseEmployeesFromList(data['users']);
            }
            else if (data.containsKey('staff') && data['staff'] is List) {
              print('[Provider] Found staff key with List data');
              _parseEmployeesFromList(data['staff']);
            }
            else {
              // Try to parse all values that are lists
              print('[Provider] Trying to find any List in Map values');
              for (var key in data.keys) {
                if (data[key] is List) {
                  print('[Provider] Found List in key: $key');
                  _parseEmployeesFromList(data[key] as List);
                  break;
                }
              }
            }
          }
          else if (data is List) {
            print('[Provider] Response is a List directly');
            _parseEmployeesFromList(data);
          }
          else {
            print('[Provider] Unexpected response type: ${data.runtimeType}');
          }

          print('[Provider] After parsing, found ${_employees.length} employees');

          // If still no employees, try to get them from salary data
          if (_employees.isEmpty) {
            print('[Provider] No employees found in API response, checking salary data');
            await _getEmployeesFromSalaries();
          }

        } catch (e) {
          print('[Provider] Error parsing employees JSON: $e');
          await _getEmployeesFromSalaries();
        }
      } else {
        print('[Provider] API returned error status: ${response.statusCode}');
        print('[Provider] Error response body: ${response.body}');
        await _getEmployeesFromSalaries();
      }
    } catch (e) {
      print('[Provider] Exception in fetchEmployees: $e');
      await _getEmployeesFromSalaries();
    } finally {
      _isLoadingEmployees = false;
      notifyListeners();
      print('[Provider] ===== FETCH EMPLOYEES COMPLETED =====');
    }
  }

  // Parse employees from a list
  void _parseEmployeesFromList(List<dynamic> list) {
    print('[Provider] Parsing ${list.length} items from list');

    int parsedCount = 0;
    for (var i = 0; i < list.length; i++) {
      try {
        final item = list[i];

        if (item is Map<String, dynamic>) {
          print('[Provider] Item $i keys: ${item.keys.toList()}');

          // Try to parse employee from map
          final employee = _parseEmployeeMap(item);

          if (employee.id != 0 && employee.name.isNotEmpty) {
            // Check for duplicates
            if (!_employees.any((e) => e.id == employee.id)) {
              _employees.add(employee);
              parsedCount++;
              print('[Provider] ✅ Parsed employee: ${employee.name} (ID: ${employee.id})');
            } else {
              print('[Provider] ⚠️ Duplicate employee ID: ${employee.id}');
            }
          } else {
            print('[Provider] ⚠️ Invalid employee data at index $i: ID=${employee.id}, Name=${employee.name}');
          }
        } else {
          print('[Provider] ⚠️ Item $i is not a Map, type: ${item.runtimeType}');
        }
      } catch (e) {
        print('[Provider] ❌ Error parsing item $i: $e');
      }
    }

    print('[Provider] Successfully parsed $parsedCount employees from list');
  }

  // Parse employee from map with multiple possible field names
  Employee _parseEmployeeMap(Map<String, dynamic> item) {
    print('[Provider] Parsing employee from map with keys: ${item.keys.toList()}');

    // Debug: Print all values
    item.forEach((key, value) {
      print('[Provider]   $key: $value (${value.runtimeType})');
    });

    // Try different field name patterns
    int id = 0;
    String name = '';
    String empId = '';
    String department = 'N/A';
    int departmentId = 0;

    // Try to get ID
    if (item.containsKey('id')) {
      id = _parseInt(item['id']) ?? 0;
    } else if (item.containsKey('employee_id')) {
      id = _parseInt(item['employee_id']) ?? 0;
    } else if (item.containsKey('Id')) {
      id = _parseInt(item['Id']) ?? 0;
    } else if (item.containsKey('ID')) {
      id = _parseInt(item['ID']) ?? 0;
    }

    // Try to get name
    if (item.containsKey('name')) {
      name = item['name'].toString();
    } else if (item.containsKey('employee_name')) {
      name = item['employee_name'].toString();
    } else if (item.containsKey('full_name')) {
      name = item['full_name'].toString();
    } else if (item.containsKey('Name')) {
      name = item['Name'].toString();
    }

    // Try to get employee code/ID
    if (item.containsKey('employee_code')) {
      empId = item['employee_code'].toString();
    } else if (item.containsKey('emp_id')) {
      empId = item['emp_id'].toString();
    } else if (item.containsKey('code')) {
      empId = item['code'].toString();
    } else if (item.containsKey('employeeId')) {
      empId = item['employeeId'].toString();
    }

    // Try to get department
    if (item.containsKey('department')) {
      department = item['department'].toString();
    } else if (item.containsKey('department_name')) {
      department = item['department_name'].toString();
    } else if (item.containsKey('Department')) {
      department = item['Department'].toString();
    }

    // Try to get department ID
    if (item.containsKey('department_id')) {
      departmentId = _parseInt(item['department_id']) ?? 0;
    } else if (item.containsKey('departmentId')) {
      departmentId = _parseInt(item['departmentId']) ?? 0;
    }

    print('[Provider] Parsed values - ID: $id, Name: $name, EmpID: $empId, Dept: $department');

    return Employee(
      id: id,
      name: name,
      empId: empId,
      department: department,
      departmentId: departmentId,
    );
  }

  // Helper to parse integer
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.tryParse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return null;
  }

  // Get employees from salary data as fallback
  Future<void> _getEmployeesFromSalaries() async {
    print('[Provider] Getting employees from salary data...');

    // Make sure we have salaries
    if (_salaries.isEmpty) {
      print('[Provider] No salaries available, fetching them first');
      await fetchEmployeeSalaries(showLoading: false);
    }

    // Extract unique employees from salaries
    final Map<int, Employee> employeeMap = {};

    for (var salary in _salaries) {
      if (salary.employeeId != 0 && salary.employeeName.isNotEmpty) {
        if (!employeeMap.containsKey(salary.employeeId)) {
          employeeMap[salary.employeeId] = Employee(
            id: salary.employeeId,
            name: salary.employeeName,
            empId: salary.employeeCode,
            department: 'N/A',
            departmentId: 0,
          );
          print('[Provider] Created employee from salary: ${salary.employeeName} (ID: ${salary.employeeId})');
        }
      }
    }

    _employees = employeeMap.values.toList();
    print('[Provider] Created ${_employees.length} employees from salary data');

    // If still no employees, use hardcoded fallback
    if (_employees.isEmpty) {
      print('[Provider] No employees in salary data, using fallback');
      _employees = _getFallbackEmployees();
    }
  }

  List<Employee> _getFallbackEmployees() {
    print('[Provider] Using fallback employees');
    return [
      Employee(id: 1, name: 'John Doe', empId: 'EMP001', department: 'IT', departmentId: 1),
      Employee(id: 2, name: 'Jane Smith', empId: 'EMP002', department: 'HR', departmentId: 2),
      Employee(id: 3, name: 'Robert Johnson', empId: 'EMP003', department: 'Finance', departmentId: 3),
    ];
  }

  // Test API endpoint
  Future<void> testApiEndpoint(String endpoint) async {
    print('[Provider] Testing API endpoint: $endpoint');

    try {
      final token = await _getToken();
      final url = '$_baseUrl/$endpoint';

      print('[Provider] Testing URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      print('[Provider] Test Response Status: ${response.statusCode}');
      print('[Provider] Test Response Headers: ${response.headers}');
      print('[Provider] Test Response Body (first 1000 chars):');
      if (response.body.length > 1000) {
        print(response.body.substring(0, 1000) + '...');
      } else {
        print(response.body);
      }

      // Try to parse as JSON
      try {
        final jsonData = json.decode(response.body);
        print('[Provider] JSON structure type: ${jsonData.runtimeType}');

        if (jsonData is Map) {
          print('[Provider] JSON keys: ${jsonData.keys.toList()}');
        } else if (jsonData is List) {
          print('[Provider] JSON list length: ${jsonData.length}');
          if (jsonData.isNotEmpty) {
            print('[Provider] First item type: ${jsonData.first.runtimeType}');
            if (jsonData.first is Map) {
              print('[Provider] First item keys: ${(jsonData.first as Map).keys.toList()}');
            }
          }
        }
      } catch (e) {
        print('[Provider] Could not parse as JSON: $e');
      }
    } catch (e) {
      print('[Provider] Error testing endpoint: $e');
    }
  }

  // Search employees by name or ID
  List<Employee> searchEmployees(String query) {
    if (query.isEmpty) return _employees;

    final lowerQuery = query.toLowerCase();
    return _employees.where((employee) {
      return employee.name.toLowerCase().contains(lowerQuery) ||
          employee.empId.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get employee by ID
  Employee? getEmployeeById(int id) {
    try {
      return _employees.firstWhere((emp) => emp.id == id);
    } catch (e) {
      print('[Provider] Employee not found with ID: $id');
      return null;
    }
  }

  // Fetch single salary by ID
  Future<EmployeeSalary?> fetchSalaryById(int id) async {
    try {
      final token = await _getToken();
      final url = '$_baseUrl/employee-salaries/$id';

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final decodedJson = json.decode(response.body);
        return EmployeeSalary.fromJson(decodedJson);
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
      final token = await _getToken();
      final url = '$_baseUrl/employee-salaries';
      final requestData = salary.toJson();

      print('[Provider] Creating salary for employee ${salary.employeeId}');
      print('[Provider] Request data: $requestData');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      );

      print('[Provider] Create response status: ${response.statusCode}');
      print('[Provider] Create response body: ${response.body}');

      _isLoading = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchEmployeeSalaries(showLoading: false);
        notifyListeners();
        return true;
      } else {
        try {
          final errorBody = json.decode(response.body);
          _error = 'Failed to create salary: ${errorBody['message'] ?? 'Unknown error'}';
        } catch (e) {
          _error = 'Failed to create salary: ${response.statusCode}';
        }
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
      final token = await _getToken();
      final url = '$_baseUrl/employee-salaries/${salary.id}';
      final requestData = salary.toJson();

      print('[Provider] Updating salary ID: ${salary.id}');
      print('[Provider] Request data: $requestData');

      final response = await http.put(
        Uri.parse(url),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      );

      print('[Provider] Update response status: ${response.statusCode}');
      print('[Provider] Update response body: ${response.body}');

      _isLoading = false;

      if (response.statusCode == 200) {
        final index = _salaries.indexWhere((s) => s.id == salary.id);
        if (index != -1) {
          _salaries[index] = salary;
          notifyListeners();
        }
        return true;
      } else {
        try {
          final errorBody = json.decode(response.body);
          _error = 'Failed to update salary: ${errorBody['message'] ?? 'Unknown error'}';
        } catch (e) {
          _error = 'Failed to update salary: ${response.statusCode}';
        }
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

  // In EmployeeSalaryProvider class, add this method:
  Future<List<Employee>> getAvailableEmployees() async {
    try {
      // If employees are not loaded, fetch them
      if (_employees.isEmpty && !_isLoadingEmployees) {
        await fetchEmployees();
      }

      // Return ALL employees, not just those without salaries
      return _employees.toList();
    } catch (e) {
      print('Error getting available employees: $e');
      return [];
    }
  }
  // Delete salary
  Future<bool> deleteSalary(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final url = '$_baseUrl/employee-salaries/$id';

      print('[Provider] Deleting salary ID: $id');

      final response = await http.delete(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      print('[Provider] Delete response status: ${response.statusCode}');
      print('[Provider] Delete response body: ${response.body}');

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

  // Search salaries
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

  // Check if employee already has salary
  bool employeeHasSalary(int employeeId) {
    return _salaries.any((salary) => salary.employeeId == employeeId);
  }
}