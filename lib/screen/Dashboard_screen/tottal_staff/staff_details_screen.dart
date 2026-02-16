import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package

// Employee model
class Employee {
  final int id;
  final String empId;
  final String name;
  final String? image;
  final String department;
  final String? designation;
  final DateTime? hiringDate;
  final bool enabled;

  Employee({
    required this.id,
    required this.empId,
    required this.name,
    this.image,
    required this.department,
    this.designation,
    this.hiringDate,
    required this.enabled,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Extract department name
    String departmentName = '';
    if (json['department'] is Map<String, dynamic>) {
      departmentName = json['department']['name']?.toString() ?? '';
    } else {
      departmentName = json['department_name']?.toString() ?? 'No Department';
    }

    // Extract designation
    String? designationName;
    if (json['designation'] is Map<String, dynamic>) {
      designationName = json['designation']['name']?.toString();
    }

    // Parse hiring date
    DateTime? hiringDate;
    if (json['hiring_date'] != null) {
      try {
        hiringDate = DateTime.parse(json['hiring_date'].toString());
      } catch (e) {
        // If parsing fails, try to handle it differently
        try {
          final dateStr = json['hiring_date'].toString();
          if (dateStr.contains('T')) {
            hiringDate = DateTime.parse(dateStr);
          } else {
            // Fix: Add the 'T' separator properly
            hiringDate = DateTime.parse('${dateStr}T00:00:00.000Z');
          }
        } catch (e) {
          debugPrint('Error parsing hiring date: $e');
        }
      }
    }

    return Employee(
      id: json['id'] ?? 0,
      empId: json['emp_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      image: json['image']?.toString(),
      department: departmentName,
      designation: designationName,
      hiringDate: hiringDate,
      enabled: json['enabled'] ?? true,
    );
  }

  String get displayName => name;
  String get employeeCode => empId;
}

class StaffDetailsScreen extends StatefulWidget {
  final String title;
  final String filterType; // 'all', 'present', 'absent', 'leave', 'late', 'short_leave'
  final String? selectedDate;

  const StaffDetailsScreen({
    super.key,
    required this.title,
    required this.filterType,
    this.selectedDate,
  });

  @override
  State<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends State<StaffDetailsScreen> {
  List<Employee> _employeeList = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  // API endpoint
  static const String _baseUrl = 'https://api.afaqmis.com';

  @override
  void initState() {
    super.initState();
    _loadEmployeesData();
  }

  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token') ?? '';
    } catch (e) {
      debugPrint('Error getting token: $e');
      return '';
    }
  }

  Future<void> _loadEmployeesData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();

      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Authentication required. Please login again.';
        });
        return;
      }

      // Build API URL to fetch all employees
      String url = '$_baseUrl/api/employees';

      debugPrint('🔄 Loading employees data from: $url');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📥 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        List<Employee> employeeList = [];

        if (responseData is Map<String, dynamic> && responseData['employees'] is List) {
          final List<dynamic> employeeData = responseData['employees'];
          debugPrint('📊 Found ${employeeData.length} employees in "employees" key');

          for (var item in employeeData) {
            if (item is Map<String, dynamic>) {
              try {
                final employee = Employee.fromJson(item);
                employeeList.add(employee);
              } catch (e) {
                debugPrint('❌ Error parsing employee: $e');
                debugPrint('Employee data: $item');
              }
            }
          }
        }

        debugPrint('✅ Successfully loaded ${employeeList.length} employees');

        if (employeeList.isEmpty) {
          setState(() {
            _error = 'No employees found in the system';
            _isLoading = false;
          });
          return;
        }

        employeeList.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        setState(() {
          _employeeList = employeeList;
          _isLoading = false;
        });


      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Session expired. Please login again.';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _error = 'Employees endpoint not found.';
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _isLoading = false;
          _error = 'You don\'t have permission to view employees.';
        });
      } else {
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? errorData['error'] ?? 'Failed to load employees data';
          setState(() {
            _isLoading = false;
            _error = message;
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _error = 'Failed to load employees data: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      debugPrint('Employees data error: $e');
      debugPrint('Error stack: ${e.toString()}');

      setState(() {
        _isLoading = false;
        _error = 'Error loading employees: ${e.toString()}';
      });
    }
  }

  List<Employee> get _filteredEmployeeList {
    var filteredList = _employeeList;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((employee) =>
      employee.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          employee.empId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          employee.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (employee.designation ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = widget.selectedDate ?? 'All Time';
    final totalCount = _filteredEmployeeList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Date: $dateText • Total: $totalCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _loadEmployeesData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Staff Count Summary
          _buildSummaryHeader(),

          // Staff List
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _error != null
                ? _buildError()
                : _filteredEmployeeList.isEmpty
                ? _buildEmptyState()
                : _buildEmployeeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Iconsax.search_normal, color: Colors.grey, size: 20),
            ),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search by name, ID, department, or designation...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Iconsax.close_circle, color: Colors.grey, size: 18),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final activeCount = _filteredEmployeeList.where((emp) => emp.enabled).length;
    final inactiveCount = _filteredEmployeeList.length - activeCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('Total', _filteredEmployeeList.length.toString(), Colors.white),
          _buildMiniStat('Active', activeCount.toString(), const Color(0xFF4CAF50)),
          _buildMiniStat('Inactive', inactiveCount.toString(), const Color(0xFFF44336)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployeesData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.people,
            color: Colors.grey[400],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'No employees in the system',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEmployeeList.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployeeList[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showEmployeeDetails(employee);
              },
              borderRadius: BorderRadius.circular(12),
              splashColor: const Color(0xFF667EEA).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Image
                    _buildEmployeeImage(employee),

                    const SizedBox(width: 16),

                    // Employee Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Employee Name and Status
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: employee.enabled
                                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                                      : const Color(0xFFF44336).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: employee.enabled
                                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                                        : const Color(0xFFF44336).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  employee.enabled ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: employee.enabled
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFF44336),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // // Employee ID
                          // Row(
                          //   children: [
                          //     const Icon(Iconsax.tag, size: 12, color: Colors.grey),
                          //     const SizedBox(width: 4),
                          //     Text(
                          //       employee.empId,
                          //       style: const TextStyle(
                          //         fontSize: 12,
                          //         color: Colors.grey,
                          //       ),
                          //     ),
                          //   ],
                          // ),

                          const SizedBox(height: 4),

                          // Department
                          Row(
                            children: [
                              const Icon(Iconsax.category, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  employee.department,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Designation (if available)
                          if (employee.designation != null && employee.designation!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Iconsax.briefcase, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    employee.designation!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 4),

                          // Hiring Date
                          if (employee.hiringDate != null)
                            Row(
                              children: [
                                const Icon(Iconsax.calendar, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Hiring: ${DateFormat('dd MMM yyyy').format(employee.hiringDate!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeImage(Employee employee) {
    if (employee.image != null && employee.image!.isNotEmpty) {
      // If image URL is available
      final imageUrl = employee.image!.startsWith('http')
          ? employee.image!
          : '$_baseUrl${employee.image!.startsWith('/') ? '' : '/'}${employee.image!}';

      return SizedBox(
        width: 60,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              child: Center(
                child: Text(
                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              child: Center(
                child: Text(
                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Default avatar with initials
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667EEA),
            ),
          ),
        ),
      );
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  _buildEmployeeImage(employee),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (employee.designation != null && employee.designation!.isNotEmpty)
                          Text(
                            employee.designation!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: employee.enabled
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : const Color(0xFFF44336).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: employee.enabled
                                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                                  : const Color(0xFFF44336).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            employee.enabled ? 'Active Employee' : 'Inactive Employee',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: employee.enabled
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFF44336),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Employee Details
              _buildDetailRow('Employee Code', employee.empId, Iconsax.tag),
              _buildDetailRow('Department', employee.department, Iconsax.category),
              if (employee.designation != null && employee.designation!.isNotEmpty)
                _buildDetailRow('Designation', employee.designation!, Iconsax.briefcase),
              if (employee.hiringDate != null)
                _buildDetailRow(
                  'Hiring Date',
                  DateFormat('dd MMM yyyy').format(employee.hiringDate!),
                  Iconsax.calendar,
                ),

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}