import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../model/absents_model/absents_model.dart';

class AbsentProvider with ChangeNotifier {
  List<Absent> _absents = [];
  List<Absent> get absents => _absents;

  List<Absent> _filteredAbsents = [];
  List<Absent> get filteredAbsents => _filteredAbsents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _error = '';
  String get error => _error;

  String? _selectedDate;
  String? get selectedDate => _selectedDate;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  String? _authToken;

  // Set auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Set admin status
  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
  }
  // Add this method to fetch employee images
  Future<Map<String, String>> _fetchEmployeeImagesMap() async {
    try {
      if (_authToken == null || _authToken!.isEmpty) return {};

      final url = Uri.parse('https://api.afaqmis.com/api/employees');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> employeesData = responseData['employees'];

        // Create a map of employee codes to image URLs
        final Map<String, String> employeeImageMap = {};

        for (var emp in employeesData) {
          final empCode = emp['employee_code']?.toString() ?? emp['emp_id']?.toString() ?? '';
          final empName = emp['name']?.toString() ?? emp['employee_name']?.toString() ?? '';

          // Try to get image URL from various possible fields
          final imageUrl = emp['image_url']?.toString() ??
              emp['profile_image']?.toString() ??
              emp['avatar']?.toString() ??
              emp['photo']?.toString() ??
              emp['image']?.toString();

          if (empCode.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
            employeeImageMap[empCode] = imageUrl;
          }
          if (empName.isNotEmpty && imageUrl != null && imageUrl.isNotEmpty) {
            employeeImageMap[empName] = imageUrl;
          }
        }

        return employeeImageMap;
      }
    } catch (e) {
      print('Error fetching employee images: $e');
    }

    return {};
  }
  Future<void> fetchAbsents({String? date}) async {
    try {
      // Check if we have a token
      if (_authToken == null || _authToken!.isEmpty) {
        _error = 'Authentication required. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isLoading = true;
      _error = '';
      _selectedDate = date;
      notifyListeners();

      final url = Uri.parse('https://api.afaqmis.com/api/absents');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> absentsData = responseData['absents'];

        // Parse absents
        _absents = [];
        for (var item in absentsData) {
          try {
            final absent = Absent.fromJson(item);
            _absents.add(absent);
          } catch (e) {
            print('Error parsing absent item: $e');
          }
        }

        // STEP 1: Filter by selected date if provided
        List<Absent> tempFilteredAbsents;
        if (date != null && date != 'All Time') {
          final targetDate = DateTime.parse(date);

          tempFilteredAbsents = _absents.where((absent) {
            // Normalize absent date (remove time part)
            final absentDateNormalized = DateTime(
              absent.absentDate.year,
              absent.absentDate.month,
              absent.absentDate.day,
            );

            // Normalize target date (remove time part)
            final targetDateNormalized = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
            );

            return absentDateNormalized == targetDateNormalized;
          }).toList();

          print('Filtered ${tempFilteredAbsents.length} absents for date: $date');
        } else {
          tempFilteredAbsents = List.from(_absents);
        }

        // STEP 2: Fetch employee images
        print('Fetching employee images...');
        final employeeImageMap = await _fetchEmployeeImagesMap();
        print('Fetched ${employeeImageMap.length} employee images');

        // STEP 3: Update filtered absents with image URLs
        _filteredAbsents = [];
        for (var absent in tempFilteredAbsents) {
          String? imageUrl;

          // Try to find image by employee code
          if (employeeImageMap.containsKey(absent.empId)) {
            imageUrl = employeeImageMap[absent.empId];
            print('Found image for ${absent.employeeName} by empId: $imageUrl');
          }
          // Try to find image by employee name
          else if (employeeImageMap.containsKey(absent.employeeName)) {
            imageUrl = employeeImageMap[absent.employeeName];
            print('Found image for ${absent.employeeName} by name: $imageUrl');
          }

          // Create a new Absent with the image URL (or null if not found)
          final updatedAbsent = Absent(
            id: absent.id,
            code: absent.code,
            departmentId: absent.departmentId,
            employeeId: absent.employeeId,
            designation: absent.designation,
            absentDate: absent.absentDate,
            reason: absent.reason,
            createdAt: absent.createdAt,
            updatedAt: absent.updatedAt,
            empId: absent.empId,
            employeeName: absent.employeeName,
            departmentName: absent.departmentName,
            imageUrl: imageUrl,
          );

          _filteredAbsents.add(updatedAbsent);
        }

        // Sort by absent date (most recent first)
        _filteredAbsents.sort((a, b) => b.absentDate.compareTo(a.absentDate));

        _error = '';
      } else if (response.statusCode == 401) {
        _error = 'Session expired. Please login again.';
        _absents = [];
        _filteredAbsents = [];
      } else {
        _error = 'Failed to load absent data: ${response.statusCode}';
        _absents = [];
        _filteredAbsents = [];
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _absents = [];
      _filteredAbsents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Filter absents by search query
  void filterAbsents(String query) {
    if (query.isEmpty) {
      _filteredAbsents = List.from(_absents);
    } else {
      _filteredAbsents = _absents.where((absent) {
        return absent.employeeName.toLowerCase().contains(query.toLowerCase()) ||
            absent.empId.toLowerCase().contains(query.toLowerCase()) ||
            absent.departmentName.toLowerCase().contains(query.toLowerCase()) ||
            (absent.designation != null && absent.designation!.toLowerCase().contains(query.toLowerCase())) ||
            (absent.reason != null && absent.reason!.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }

    // Sort by absent date (most recent first)
    _filteredAbsents.sort((a, b) => b.absentDate.compareTo(a.absentDate));

    notifyListeners();
  }

  // Get statistics for the current filtered absents
  Map<String, int> getAbsentStats() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Normalize today and yesterday for comparison
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final yesterdayNormalized = DateTime(yesterday.year, yesterday.month, yesterday.day);

    return {
      'total': _filteredAbsents.length,
      'today': _filteredAbsents.where((a) {
        final absentDateNormalized = DateTime(a.absentDate.year, a.absentDate.month, a.absentDate.day);
        return absentDateNormalized == todayNormalized;
      }).length,
      'yesterday': _filteredAbsents.where((a) {
        final absentDateNormalized = DateTime(a.absentDate.year, a.absentDate.month, a.absentDate.day);
        return absentDateNormalized == yesterdayNormalized;
      }).length,
      'thisWeek': _filteredAbsents.where((a) {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final startOfWeekNormalized = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final absentDateNormalized = DateTime(a.absentDate.year, a.absentDate.month, a.absentDate.day);
        return absentDateNormalized.isAfter(startOfWeekNormalized.subtract(const Duration(days: 1)));
      }).length,
    };
  }

  void clearData() {
    _absents = [];
    _filteredAbsents = [];
    _error = '';
    notifyListeners();
  }

  void setSelectedDate(String? date) {
    _selectedDate = date;
  }
}
