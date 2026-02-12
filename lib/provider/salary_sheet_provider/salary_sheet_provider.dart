import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utility/global_url.dart';
import '../../model/attendance_model/attendance_model.dart';
import '../../model/salary_sheet/salary_sheet.dart' hide Department;

class SalarySheetProvider extends ChangeNotifier {
  // API URLs - Using your actual API URL
  static const String _baseUrl = '${GlobalUrls.baseurl}/api';
  static String getDepartmentsUrl() => '$_baseUrl/departments';
  static String getSalarySheetUrl(String month, int departmentId) =>
      '$_baseUrl/monthly-salary-sheet?month=$month&department_id=$departmentId';

  // State
  MonthlySalarySheet? _salarySheet;
  List<Department> _departments = [];
  bool _isLoading = false;
  bool _isLoadingDepartments = false;
  String _error = '';

  String _selectedMonth = '';
  int? _selectedDepartmentId;

  // Getters
  MonthlySalarySheet? get salarySheet => _salarySheet;
  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  bool get isLoadingDepartments => _isLoadingDepartments;
  String get error => _error;
  String get selectedMonth => _selectedMonth;
  int? get selectedDepartmentId => _selectedDepartmentId;

  // Setters
  set selectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  set selectedDepartmentId(int? id) {
    _selectedDepartmentId = id;
    notifyListeners();
  }

  // Get token from shared preferences
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      print('🔑 Token from SharedPreferences: ${token.isNotEmpty ? "Found" : "NOT FOUND"}');
      if (token.isEmpty) {
        print('❌ ERROR: No authentication token found in SharedPreferences');
        throw Exception('No authentication token found. Please login again.');
      }

      return token;
    } catch (e) {
      print('❌ ERROR getting token: $e');
      throw Exception('Failed to get authentication token: $e');
    }
  }

  // Initialize - Load departments on startup
  Future<void> initialize() async {
    print('🚀 Initializing SalarySheetProvider...');
    await _fetchDepartments();

    // Set default month to current month
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    print('📅 Default month set to: $_selectedMonth');

    // Auto-select first department if available
    if (_departments.isNotEmpty && _selectedDepartmentId == null) {
      _selectedDepartmentId = _departments.first.id;
      print('🏢 Auto-selected department: ${_departments.first.name} (ID: ${_departments.first.id})');
    } else if (_departments.isEmpty) {
      print('⚠️ No departments available to auto-select');
    }
  }

  // Fetch departments from API
  Future<void> _fetchDepartments() async {
    print('🔄 Starting department fetch...');
    _isLoadingDepartments = true;
    _error = '';
    notifyListeners();

    try {
      final token = await _getToken();

      print('🌐 Making API request to: ${getDepartmentsUrl()}');
      print('🔑 Using token: ${token.substring(0, min(20, token.length))}...');

      final response = await http.get(
        Uri.parse(getDepartmentsUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Response status code: ${response.statusCode}');
      print('📡 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          print('📊 Response data type: ${data.runtimeType}');

          List<dynamic> departmentsList = [];

          if (data is Map) {
            print('🗺️ Response is a Map, keys: ${data.keys.toList()}');

            if (data.containsKey('departments')) {
              print('✅ Found "departments" key');
              departmentsList = data['departments'] as List<dynamic>;
            } else if (data.containsKey('data')) {
              print('✅ Found "data" key');
              departmentsList = data['data'] as List<dynamic>;
            } else {
              print('🔍 Looking for any list in response...');
              for (var key in data.keys) {
                if (data[key] is List) {
                  print('✅ Found list in key: $key');
                  departmentsList = data[key] as List<dynamic>;
                  break;
                }
              }
            }
          } else if (data is List) {
            print('✅ Response is directly a List');
            departmentsList = data;
          }

          if (departmentsList.isNotEmpty) {
            print('📋 Parsing ${departmentsList.length} departments...');

            _departments = departmentsList
                .where((item) => item is Map<String, dynamic>)
                .map((d) {
              try {
                return Department.fromJson(d);
              } catch (e) {
                print('⚠️ Error parsing department item: $e');
                print('Item data: $d');
                return null;
              }
            })
                .where((dept) => dept != null)
                .cast<Department>()
                .toList();

            print('=== SALARY DEPARTMENTS LOADED ===');
            print('✅ Total departments: ${_departments.length}');
            for (var dept in _departments) {
              print('🏢 Department: ${dept.name} (ID: ${dept.id})');
            }

            if (_departments.isEmpty) {
              _error = 'No departments found in API response';
              print('⚠️ WARNING: departmentsList had items but parsing resulted in 0 departments');
            }
          } else {
            _error = 'No departments data found in API response';
            _departments = [];
            print('⚠️ departmentsList is empty or null');
          }

        } catch (e) {
          _error = 'Error parsing departments data: $e';
          _departments = [];
          print('❌ ERROR parsing JSON: $e');
          print('Response body: ${response.body}');
        }

      } else if (response.statusCode == 401) {
        _error = 'Unauthorized - Please login again';
        _departments = [];
        print('❌ 401 Unauthorized - Check if token is valid');
      } else if (response.statusCode == 403) {
        _error = 'Forbidden - You don\'t have permission to view departments';
        _departments = [];
        print('❌ 403 Forbidden - No permission to access departments');
      } else if (response.statusCode == 404) {
        _error = 'Departments endpoint not found (404)';
        _departments = [];
        print('❌ 404 Not Found - Check if endpoint ${getDepartmentsUrl()} is correct');
      } else {
        _error = 'Failed to load departments. Status: ${response.statusCode}';
        _departments = [];
        print('❌ Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Network error: $e';
      _departments = [];
      print('❌ ERROR fetching departments: $e');
    } finally {
      _isLoadingDepartments = false;
      print('🏁 Department fetch completed. Departments count: ${_departments.length}');
      notifyListeners();
    }
  }

  // Fetch salary sheet from API
  Future<void> fetchSalarySheet() async {
    if (_selectedMonth.isEmpty || _selectedDepartmentId == null) {
      _error = 'Please select month and department first';
      print('⚠️ Cannot fetch salary sheet: Month or department not selected');
      notifyListeners();
      return;
    }

    print('🔄 Fetching salary sheet for month: $_selectedMonth, department: $_selectedDepartmentId');
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final token = await _getToken();

      final url = getSalarySheetUrl(_selectedMonth, _selectedDepartmentId!);
      print('🌐 Making salary API request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Salary response status: ${response.statusCode}');
      print('📡 Salary response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          _salarySheet = MonthlySalarySheet.fromJson(data);

          print('✅ SALARY SHEET DATA LOADED ===');
          print('📅 Month: ${_salarySheet?.month}');
          print('🏢 Department ID: ${_salarySheet?.departmentId}');
          print('💰 Total Salary: ${_salarySheet?.totals.salarySum}');
          print('👥 Total Employees: ${_salarySheet?.totals.employeesCount}');
          print('📊 Rows loaded: ${_salarySheet?.rows.length}');

          if (_salarySheet != null && _salarySheet!.rows.isNotEmpty) {
            for (int i = 0; i < min(5, _salarySheet!.rows.length); i++) {
              final row = _salarySheet!.rows[i];
              print('👤 Row $i: ${row.employee} - Salary: ${row.salary} - Net: ${row.total}');
            }
          } else {
            print('⚠️ Salary sheet has no rows');
          }
        } catch (e) {
          _salarySheet = null;
          _error = 'Error parsing salary data: $e';
          print('❌ ERROR parsing salary JSON: $e');
        }
      } else if (response.statusCode == 401) {
        _salarySheet = null;
        _error = 'Unauthorized - Please login again';
        print('❌ 401 Unauthorized for salary data');
      } else if (response.statusCode == 403) {
        _salarySheet = null;
        _error = 'Forbidden - You don\'t have permission to view salary data';
        print('❌ 403 Forbidden for salary data');
      } else if (response.statusCode == 404) {
        _salarySheet = null;
        _error = 'Salary data not found for selected month/department';
        print('❌ 404 Salary data not found');
      } else {
        _salarySheet = null;
        _error = 'Failed to load salary sheet. Status: ${response.statusCode}';
        print('❌ Salary API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _salarySheet = null;
      _error = 'Network error: $e';
      print('❌ NETWORK ERROR fetching salary: $e');
    } finally {
      _isLoading = false;
      print('🏁 Salary sheet fetch completed');
      notifyListeners();
    }
  }

  // Filter employees by search
  List<SalaryRow> filterEmployees(String query) {
    if (_salarySheet == null || query.isEmpty) {
      return _salarySheet?.rows ?? [];
    }

    final lowerQuery = query.toLowerCase();
    return _salarySheet!.rows.where((row) =>
    row.employee.toLowerCase().contains(lowerQuery) ||
        row.meta.empId.toLowerCase().contains(lowerQuery) ||
        (row.designation?.toLowerCase().contains(lowerQuery) ?? false) ||
        row.unit.toLowerCase().contains(lowerQuery)).toList();
  }

  // Get department name by ID
  String getDepartmentName(int? id) {
    if (id == null) return 'Select Department';
    try {
      final dept = _departments.firstWhere(
            (d) => d.id == id,
        orElse: () => Department(id: id, name: 'Unknown Department (ID: $id)'),
      );
      return dept.name;
    } catch (e) {
      print('⚠️ Error getting department name for ID $id: $e');
      return 'Department $id';
    }
  }

  // Get detailed department information
  Map<String, dynamic> getDepartmentDetails() {
    if (_departments.isEmpty) {
      return {'error': 'No departments loaded'};
    }

    final deptDetails = {
      'totalDepartments': _departments.length,
      'departments': _departments.map((dept) {
        return {
          'id': dept.id,
          'name': dept.name,
          'hasDescription': dept.description?.isNotEmpty ?? false,
          'description': dept.description ?? 'No description',
        };
      }).toList(),
    };

    return deptDetails;
  }

  // Get detailed salary sheet information
  Map<String, dynamic> getSalarySheetDetails() {
    if (_salarySheet == null) {
      return {'error': 'No salary sheet loaded'};
    }

    final sheet = _salarySheet!;
    final sheetDetails = {
      'month': sheet.month,
      'departmentId': sheet.departmentId,
      'departmentName': getDepartmentName(sheet.departmentId),
      'totals': {
        'salarySum': sheet.totals.salarySum,
        'totalSum': sheet.totals.totalSum,
        'employeesCount': sheet.totals.employeesCount,
      },
      'totalRows': sheet.rows.length,
      'calculatedRows': sheet.rows.where((row) => row.isCalculated).length,
      'pendingRows': sheet.rows.where((row) => !row.isCalculated).length,
      'sampleData': sheet.rows.take(3).map((row) {
        return {
          'employee': row.employee,
          'empId': row.meta.empId,
          'salary': row.salary,
          'netSalary': row.total,
          'isCalculated': row.isCalculated,
        };
      }).toList(),
    };

    return sheetDetails;
  }

  // Get all API response data
  Map<String, dynamic> getAllApiData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'appInfo': {
        'baseUrl': _baseUrl,
        'endpoints': {
          'departments': getDepartmentsUrl(),
          'salarySheet': getSalarySheetUrl(_selectedMonth, _selectedDepartmentId ?? 0),
        }
      },
      'userState': {
        'selectedMonth': _selectedMonth,
        'selectedDepartmentId': _selectedDepartmentId,
        'selectedDepartmentName': getDepartmentName(_selectedDepartmentId),
        'isLoading': _isLoading,
        'isLoadingDepartments': _isLoadingDepartments,
        'error': _error,
      },
      'departments': getDepartmentDetails(),
      'salarySheet': getSalarySheetDetails(),
      'availableMonths': availableMonths,
    };
  }

  // Test all endpoints and get detailed responses - THIS IS THE METHOD
  Future<Map<String, dynamic>> testAllEndpointsDetailed() async {
    print('🔍 Starting detailed API endpoint test');

    final results = {
      'timestamp': DateTime.now().toIso8601String(),
      'authTest': {},
      'departmentsTest': {},
      'salarySheetTest': {},
      'summary': {}
    };

    try {
      results['authTest'] = await _testAuthentication();
      results['departmentsTest'] = await _testDepartmentsEndpoint();
      results['salarySheetTest'] = await _testSalarySheetEndpoint();
      results['summary'] = _createTestSummary(results);

    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  // Private helper methods
  Future<Map<String, dynamic>> _testAuthentication() async {
    final result = {
      'success': false,
      'tokenLength': 0,
      'hasToken': false,
    };

    try {
      final token = await _getToken();
      result['success'] = token.isNotEmpty;
      result['tokenLength'] = token.length;
      result['hasToken'] = token.isNotEmpty;
      result['tokenPreview'] = token.isNotEmpty ?
      '${token.substring(0, min(20, token.length))}...' : 'No token';
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Future<Map<String, dynamic>> _testDepartmentsEndpoint() async {
    final result = {
      'success': false,
      'statusCode': 0,
      'responseTime': 0,
      'dataStructure': {},
      'rawDataPreview': '',
      'parsedCount': 0,
    };

    try {
      final token = await _getToken();
      final startTime = DateTime.now();

      final response = await http.get(
        Uri.parse(getDepartmentsUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      result['statusCode'] = response.statusCode;
      result['responseTime'] = responseTime;
      result['success'] = response.statusCode == 200;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        result['rawDataPreview'] = response.body.length > 500 ?
        '${response.body.substring(0, 500)}...' : response.body;

        result['dataStructure'] = _analyzeDataStructure(data);
        result['parsedCount'] = _countDepartmentsInResponse(data);
        result['sampleDepartments'] = _getSampleDepartments(data);
      } else {
        result['error'] = response.body;
      }

    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Future<Map<String, dynamic>> _testSalarySheetEndpoint() async {
    final result = {
      'success': false,
      'statusCode': 0,
      'responseTime': 0,
      'dataStructure': {},
      'testParameters': {
        'month': '2026-01',
        'departmentId': 8
      }
    };

    try {
      final token = await _getToken();
      final startTime = DateTime.now();

      final url = getSalarySheetUrl('2026-01', 8);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      result['statusCode'] = response.statusCode;
      result['responseTime'] = responseTime;
      result['success'] = response.statusCode == 200;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        result['dataStructure'] = _analyzeDataStructure(data);
        result['analysis'] = _analyzeSalarySheetData(data);
        result['rawDataPreview'] = response.body.length > 1000 ?
        '${response.body.substring(0, 1000)}...' : response.body;
      } else {
        result['error'] = response.body;
      }

    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Map<String, dynamic> _analyzeDataStructure(dynamic data) {
    final analysis = {
      'type': data.runtimeType.toString(),
      'isMap': data is Map,
      'isList': data is List,
      'keys': [],
      'listLength': 0,
      'nestedStructures': [],
    };

    if (data is Map) {
      analysis['keys'] = data.keys.toList();

      for (var key in data.keys) {
        final value = data[key];
        if (value is Map || value is List) {
          (analysis['nestedStructures'] as List).add({
            'key': key,
            'type': value.runtimeType.toString(),
            'isList': value is List,
            'isMap': value is Map,
          });
        }
      }
    } else if (data is List) {
      analysis['listLength'] = data.length;
      if (data.isNotEmpty) {
        analysis['firstItemType'] = data.first.runtimeType.toString();
      }
    }

    return analysis;
  }

  int _countDepartmentsInResponse(dynamic data) {
    if (data is Map) {
      if (data.containsKey('departments') && data['departments'] is List) {
        return (data['departments'] as List).length;
      } else if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List).length;
      } else {
        for (var key in data.keys) {
          if (data[key] is List) {
            return (data[key] as List).length;
          }
        }
      }
    } else if (data is List) {
      return data.length;
    }
    return 0;
  }

  List<Map<String, dynamic>> _getSampleDepartments(dynamic data) {
    final List<dynamic> sample = [];
    List<dynamic> departments = [];

    if (data is Map) {
      if (data.containsKey('departments') && data['departments'] is List) {
        departments = data['departments'] as List<dynamic>;
      } else if (data.containsKey('data') && data['data'] is List) {
        departments = data['data'] as List<dynamic>;
      }
    } else if (data is List) {
      departments = data;
    }

    if (departments.isNotEmpty) {
      for (int i = 0; i < min(3, departments.length); i++) {
        if (departments[i] is Map) {
          sample.add(departments[i]);
        }
      }
    }

    return sample.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _analyzeSalarySheetData(dynamic data) {
    final analysis = {
      'hasMonth': false,
      'hasRows': false,
      'hasTotals': false,
      'rowCount': 0,
      'sampleRow': {},
      'totalsData': {},
    };

    if (data is Map) {
      analysis['hasMonth'] = data.containsKey('month');
      analysis['hasRows'] = data.containsKey('rows') && data['rows'] is List;
      analysis['hasTotals'] = data.containsKey('totals');

      if (data.containsKey('rows') && data['rows'] is List) {
        final rows = data['rows'] as List;
        analysis['rowCount'] = rows.length;

        if (rows.isNotEmpty && rows.first is Map) {
          analysis['sampleRow'] = rows.first;
        }
      }

      if (data.containsKey('totals') && data['totals'] is Map) {
        analysis['totalsData'] = data['totals'];
      }
    }

    return analysis;
  }

  Map<String, dynamic> _createTestSummary(Map<String, dynamic> results) {
    final authTest = results['authTest'] as Map<String, dynamic>;
    final deptTest = results['departmentsTest'] as Map<String, dynamic>;
    final salaryTest = results['salarySheetTest'] as Map<String, dynamic>;

    int rowCount = 0;
    if (salaryTest.containsKey('analysis')) {
      final analysis = salaryTest['analysis'] as Map<String, dynamic>;
      rowCount = analysis['rowCount'] ?? 0;
    }

    return {
      'overallSuccess': authTest['success'] == true &&
          deptTest['success'] == true &&
          salaryTest['success'] == true,
      'authentication': authTest['success'] == true ? '✅ Valid token' : '❌ No token',
      'departmentsApi': deptTest['success'] == true ?
      '✅ Success (${deptTest['parsedCount']} departments)' : '❌ Failed',
      'salarySheetApi': salaryTest['success'] == true ?
      '✅ Success ($rowCount employees)' : '❌ Failed',
      'recommendations': _generateRecommendations(authTest, deptTest, salaryTest),
    };
  }

  List<String> _generateRecommendations(
      Map<String, dynamic> authTest,
      Map<String, dynamic> deptTest,
      Map<String, dynamic> salaryTest,
      ) {
    final List<String> recommendations = [];

    if (authTest['success'] != true) {
      recommendations.add('Fix authentication: Check token validity and login');
    }

    if (deptTest['success'] != true) {
      recommendations.add('Check departments endpoint: URL may be incorrect or permissions missing');
    }

    if (salaryTest['success'] != true) {
      recommendations.add('Check salary sheet endpoint: Verify month and department parameters');
    }

    if (deptTest['parsedCount'] == 0 && deptTest['success'] == true) {
      recommendations.add('No departments found in response. Check API data structure');
    }

    if (salaryTest.containsKey('analysis')) {
      final analysis = salaryTest['analysis'] as Map<String, dynamic>?;
      if (analysis != null) {
        final rowCount = analysis['rowCount'] ?? 0;
        if (rowCount == 0 && salaryTest['success'] == true) {
          recommendations.add('Salary sheet loaded but has no rows for selected parameters');
        }
      }
    }

    return recommendations;
  }

  // Original test method
  Future<void> testAllApiEndpoints() async {
    print('🔍 ==========================================');
    print('🔍 STARTING API ENDPOINT TEST');
    print('🔍 ==========================================');

    try {
      print('📋 STEP 1: Checking authentication token');
      final token = await _getToken();
      print('✅ Token found (first 20 chars): ${token.substring(0, min(20, token.length))}...');

      print('\n📋 STEP 2: Testing departments endpoint');
      final deptUrl = getDepartmentsUrl();
      print('🌐 URL: $deptUrl');

      final deptResponse = await http.get(
        Uri.parse(deptUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${deptResponse.statusCode}');

      if (deptResponse.statusCode == 200) {
        print('✅ SUCCESS: Departments API returned 200');
        try {
          final dynamic deptData = json.decode(deptResponse.body);
          print('📊 Response Type: ${deptData.runtimeType}');
          if (deptData is Map) {
            print('🗺️ Map Keys: ${deptData.keys.toList()}');
          } else if (deptData is List) {
            print('📋 List Length: ${deptData.length}');
          }
        } catch (e) {
          print('❌ ERROR parsing departments JSON: $e');
        }
      } else {
        print('❌ FAILED: Departments API returned ${deptResponse.statusCode}');
      }

      print('\n📋 STEP 3: Testing salary sheet endpoint');
      final salaryUrl = getSalarySheetUrl('2026-01', 8);
      print('🌐 URL: $salaryUrl');

      final salaryResponse = await http.get(
        Uri.parse(salaryUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${salaryResponse.statusCode}');

      if (salaryResponse.statusCode == 200) {
        print('✅ SUCCESS: Salary API returned 200');
        try {
          final dynamic salaryData = json.decode(salaryResponse.body);
          print('📊 Response Type: ${salaryData.runtimeType}');
          if (salaryData is Map) {
            print('🗺️ Map Keys: ${salaryData.keys.toList()}');
          }
        } catch (e) {
          print('❌ ERROR parsing salary JSON: $e');
        }
      } else {
        print('❌ FAILED: Salary API returned ${salaryResponse.statusCode}');
      }

    } catch (e) {
      print('❌ ERROR during API testing: $e');
    }

    print('\n🔍 ==========================================');
    print('🔍 API TEST COMPLETE');
    print('🔍 ==========================================');
  }

  // Helper method to print JSON structure
  void _printJsonStructure(dynamic data, int indent) {
    if (data is Map) {
      data.forEach((key, value) {
        print('${'  ' * indent}• $key: ${value.runtimeType}');
        if (value is Map || value is List) {
          _printJsonStructure(value, indent + 1);
        }
      });
    } else if (data is List) {
      print('${'  ' * indent}• List of ${data.length} items');
      if (data.isNotEmpty) {
        _printJsonStructure(data[0], indent + 1);
      }
    }
  }

  // Get summary statistics
  Map<String, dynamic> getSummary() {
    if (_salarySheet == null) {
      print('📊 Summary requested but salarySheet is null');
      return {};
    }

    final rows = _salarySheet!.rows;
    final calculated = rows.where((row) => row.isCalculated).length;

    final deductions = rows.fold(0.0, (sum, row) {
      final rowDeductions = row.deductions ?? 0.0;
      return sum + rowDeductions;
    });

    final summary = {
      'totalSalary': _salarySheet!.totals.salarySum,
      'netSalary': _salarySheet!.totals.totalSum,
      'employees': _salarySheet!.totals.employeesCount,
      'calculated': calculated,
      'deductions': deductions,
    };

    return summary;
  }

  // Generate list of months (last 12 months)
  List<String> get availableMonths {
    final now = DateTime.now();
    final months = <String>[];

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i);
      months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }

    final result = months.reversed.toList();
    return result;
  }

  // Clear data
  void clear() {
    print('🧹 Clearing salary sheet data');
    _salarySheet = null;
    _error = '';
    notifyListeners();
  }
}