import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../model/attendance_model/attendance_model.dart';
import '../../provider/attendance_provider/attendance_provider.dart';
import '../../provider/Auth_provider/Auth_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late AttendanceProvider _provider;
  String _employeeId = '';

  // Add RefreshController
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _employeeId = authProvider.employeeId;
      _provider = Provider.of<AttendanceProvider>(context, listen: false);

      // Add a small delay to ensure provider is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _provider.fetchAllData();
          _searchController.clear();
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      // DON'T reset filters - just refresh data
      _provider.fetchAllData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  // Remove _resetFilters method completely - we don't want to reset filters

  // Add refresh method
  Future<void> _onRefresh() async {
    await _provider.fetchAllData();
    _refreshController.refreshCompleted();
  }

  // Helper method to format time to 12-hour format with AM/PM
  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty || timeString == '--:--') {
      return '--:--';
    }

    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts[1].substring(0, 2);

          // Determine AM/PM
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

          return '$displayHour:$minute $period';
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  // Helper method to format date as "17 Feb 2026"
  String _formatDisplayDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final isLargeScreen = screenWidth >= 900;

    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final isStaff = !attendanceProvider.isAdmin;


    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),

              const SizedBox(height: 8),

              // Search Section
              _buildSearchSection(isStaff),

              // Statistics Cards (Admin only)
              Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  return !isStaff ? _buildStatisticsCards(provider) : const SizedBox.shrink();
                },
              ),

              SizedBox(height: isSmallScreen ? 14 : 18),

              // Attendance List with Pull to Refresh
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    isSmallScreen ? 12 : 16,
                    0,
                    isSmallScreen ? 12 : 16,
                    isSmallScreen ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: isSmallScreen ? 10 : 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildAttendanceList(isStaff),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          return !isStaff
              ? FloatingActionButton(
            onPressed: () {
              provider.navigateToAddScreen(context);
            },
            backgroundColor: const Color(0xFF667EEA),
            child: Icon(
              Iconsax.add,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchSection(bool isStaff) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        // Update search controller text when provider search query changes
        if (_searchController.text != provider.searchQuery) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchController.text = provider.searchQuery;
          });
        }

        return Container(
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: isSmallScreen ? 8 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: isStaff
                        ? 'Search your attendance...'
                        : 'Search by employee name or ID...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey[500],
                      size: isSmallScreen ? 20 : 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Iconsax.close_circle,
                        color: Colors.grey[500],
                        size: isSmallScreen ? 20 : 22,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Filter Row
              if (isStaff)
                _buildMonthFilter(provider)
              else
                _buildFilterRow(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterRow(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Row(
      children: [
        Expanded(child: _buildDepartmentFilter(provider)),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(child: _buildEmployeeFilter(provider)),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(child: _buildMonthFilter(provider)),
      ],
    );
  }

  Widget _buildEmployeeFilter(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        final isDepartmentSelected = provider.selectedDepartmentFilter != 'All';
        final employeesForDepartment = provider.filteredEmployees;
        final hasEmployees = employeesForDepartment.isNotEmpty;
        final isEnabled = isDepartmentSelected && hasEmployees;

        String displayText;
        if (!isDepartmentSelected) {
          displayText = 'Select Dept';
        } else if (!hasEmployees) {
          displayText = 'No employees';
        } else if (provider.selectedEmployeeFilter.isEmpty) {
          displayText = 'Select Emp';
        } else {
          displayText = provider.selectedEmployeeFilter;
        }

        return Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF667EEA).withOpacity(0.5)
                  : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedEmployeeFilter.isNotEmpty
                  ? provider.selectedEmployeeFilter
                  : null,
              isExpanded: true,
              icon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  Iconsax.arrow_down_1,
                  size: 16,
                  color: isEnabled
                      ? const Color(0xFF667EEA)
                      : Colors.grey[400],
                ),
              ),
              style: TextStyle(
                fontSize: 13,
                color: isEnabled ? Colors.black87 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _truncateText(displayText, 12),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? Colors.black87 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onChanged: isEnabled ? (String? value) {
                if (value != null && value.isNotEmpty) {
                  provider.setEmployeeFilter(value);
                }
              } : null,
              items: isEnabled ? employeesForDepartment.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee.name,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _truncateText(employee.name, 15),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList() : null,
            ),
          ),
        );
      },
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildDepartmentFilter(AttendanceProvider provider) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedDepartmentFilter,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: const Color(0xFF667EEA),
            ),
          ),
          elevation: 2,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          onChanged: (String? value) {
            if (value != null) {
              provider.setDepartmentFilter(value);
            }
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'All',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'All Depts',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...provider.departmentNames.where((dept) => dept != 'All').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilter(AttendanceProvider provider) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedMonthFilter,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: const Color(0xFF667EEA),
            ),
          ),
          elevation: 2,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          onChanged: (String? value) {
            if (value != null) {
              provider.setMonthFilter(value);
              // Don't fetch all data again - just filter existing data
            }
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'All',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'All Months',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...provider.availableMonths.where((month) => month != 'All').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _truncateText(value, 10),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    // Show shimmer while loading
    if (provider.isLoading) {
      final cardHeight = isVerySmallScreen
          ? screenHeight * 0.16
          : (isSmallScreen ? screenHeight * 0.17 : screenHeight * 0.18);

      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SizedBox(
          height: cardHeight,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: isVerySmallScreen ? 10 : (isSmallScreen ? 15 : 20),
              mainAxisSpacing: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
              childAspectRatio: isVerySmallScreen ? 0.9 : (isSmallScreen ? 1.0 : 1.1),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20),
              vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8),
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.all(isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 10)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
                      height: isVerySmallScreen ? 26 : (isSmallScreen ? 30 : 34),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(height: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8)),
                    Container(
                      width: 40,
                      height: 16,
                      color: Colors.white,
                    ),
                    SizedBox(height: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4)),
                    Container(
                      width: 30,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: isVerySmallScreen ? 1 : 2),
                    Container(
                      width: 25,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Calculate statistics from the CURRENT FILTERED attendance data
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    int totalRecords = provider.attendance.length;

    for (var attendance in provider.attendance) {
      if (attendance.isPresent) {
        presentCount++;
        if (attendance.lateMinutes > 0) {
          lateCount++;
        }
      } else {
        absentCount++;
      }
    }

    // Don't show statistics if no records
    if (totalRecords == 0) {
      return const SizedBox.shrink();
    }

    final cardHeight = isVerySmallScreen
        ? screenHeight * 0.16
        : (isSmallScreen ? screenHeight * 0.17 : screenHeight * 0.18);

    return SizedBox(
      height: cardHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: isVerySmallScreen ? 10 : (isSmallScreen ? 15 : 20),
          mainAxisSpacing: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
          childAspectRatio: isVerySmallScreen ? 0.9 : (isSmallScreen ? 1.0 : 1.1),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20),
          vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8),
        ),
        itemCount: 3,
        itemBuilder: (context, index) {
          final stats = [
            {
              'icon': Iconsax.tick_circle,
              'title': 'Present',
              'count': presentCount.toString(),
              'color': const Color(0xFF4CAF50),
              'subtitle': totalRecords > 0 ? '${((presentCount / totalRecords) * 100).toStringAsFixed(0)}%' : '0%',
            },
            {
              'icon': Iconsax.clock,
              'title': 'Late',
              'count': lateCount.toString(),
              'color': const Color(0xFFFF9800),
              'subtitle': presentCount > 0 ? '${((lateCount / presentCount) * 100).toStringAsFixed(0)}%' : '0%',
            },
            {
              'icon': Iconsax.close_circle,
              'title': 'Absent',
              'count': absentCount.toString(),
              'color': const Color(0xFFF44336),
              'subtitle': totalRecords > 0 ? '${((absentCount / totalRecords) * 100).toStringAsFixed(0)}%' : '0%',
            },
          ];

          final stat = stats[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
                  height: isVerySmallScreen ? 26 : (isSmallScreen ? 30 : 34),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (stat['color'] as Color).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                    ),
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8)),
                Text(
                  stat['count'] as String,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4)),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                    color: (stat['color'] as Color).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isVerySmallScreen ? 1 : 2),
                Text(
                  stat['subtitle'] as String,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceList(bool isStaff) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        // Show shimmer while loading attendance data
        if (provider.isLoadingAttendance && provider.attendance.isEmpty) {
          return Column(
            children: [
              // Table Header
              Container(
                padding: EdgeInsets.all(isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Serial Number
                    SizedBox(
                      width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
                      child: Text(
                        'Sr.No',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: isVerySmallScreen ? 4 : 8),
                    // Date
                    Expanded(
                      flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Time In
                    Expanded(
                      flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                      child: Text(
                        'Time In',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Time Out
                    Expanded(
                      flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                      child: Text(
                        'Time Out',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Status
                    Expanded(
                      flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Shimmer rows
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                            vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12),
                          ),
                          child: Row(
                            children: [
                              // Serial Number
                              SizedBox(
                                width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
                                child: Container(
                                  height: 12,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: isVerySmallScreen ? 4 : 8),
                              // Date Column
                              Expanded(
                                flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 12,
                                      width: 60,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 4),
                                    if (!isStaff)
                                      Container(
                                        height: 10,
                                        width: 40,
                                        color: Colors.white,
                                      ),
                                  ],
                                ),
                              ),
                              // Time In
                              Expanded(
                                flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                                child: Container(
                                  height: 12,
                                  width: 40,
                                  color: Colors.white,
                                ),
                              ),
                              // Time Out
                              Expanded(
                                flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                                child: Container(
                                  height: 12,
                                  width: 40,
                                  color: Colors.white,
                                ),
                              ),
                              // Status
                              Expanded(
                                flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                                child: Container(
                                  height: 12,
                                  width: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        if (provider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: isSmallScreen ? 50 : 60,
                  color: Colors.grey[300],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                  child: Text(
                    'Error: ${provider.error}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                ElevatedButton(
                  onPressed: () => provider.fetchAllData(),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.attendance.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.note_remove,
                  size: isSmallScreen ? 50 : 60,
                  color: Colors.grey[300],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  isStaff
                      ? 'No attendance records found for you'
                      : 'No attendance records found',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
                  child: Text(
                    isStaff
                        ? 'Your attendance will appear here once marked'
                        : 'Try adding new attendance records',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Table Header
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Serial Number
                  SizedBox(
                    width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
                    child: Text(
                      'Sr.No',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: isVerySmallScreen ? 4 : 8),
                  // Date
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Time In
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Time In',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Time Out
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Time Out',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Status
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Table Body with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF667EEA),
                backgroundColor: Colors.white,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: provider.attendance.length,
                  itemBuilder: (context, index) {
                    final attendance = provider.attendance[index];
                    final serialNo = index + 1;
                    return GestureDetector(
                      child: _buildTableRow(attendance, serialNo, isStaff),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildTableRow(Attendance attendance, int serialNo, bool isStaff) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    // Determine status display
    String statusDisplay = attendance.status;
    Color statusColor = attendance.statusColor;

    // If it's Sunday, show as Holiday
    if (attendance.date.weekday == DateTime.sunday) {
      statusDisplay = 'Holiday';
      statusColor = Colors.purple;
    } else if (attendance.status.toLowerCase() == 'on time' || attendance.status.toLowerCase() == 'perfect') {
      statusDisplay = 'Present';
      statusColor = const Color(0xFF4CAF50);
    }

    // Format times to 12-hour format
    String timeInFormatted = _formatTime(attendance.timeIn);
    String timeOutFormatted = _formatTime(attendance.timeOut);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
          vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12),
        ),
        child: Row(
          children: [
            // Serial Number
            SizedBox(
              width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
              child: Text(
                serialNo.toString(),
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: isVerySmallScreen ? 4 : 8),
            // Date Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDisplayDate(attendance.date),
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isStaff && attendance.employeeName.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      attendance.employeeName,
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Time In Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      vertical: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4),
                    ),
                    decoration: BoxDecoration(
                      color: attendance.isPresent && attendance.date.weekday != DateTime.sunday
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      attendance.isPresent && attendance.date.weekday != DateTime.sunday
                          ? timeInFormatted
                          : '--:--',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: attendance.isPresent && attendance.date.weekday != DateTime.sunday
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Time Out Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      vertical: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4),
                    ),
                    decoration: BoxDecoration(
                      color: attendance.isPresent && attendance.timeOut.isNotEmpty && attendance.date.weekday != DateTime.sunday
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          attendance.isPresent && attendance.timeOut.isNotEmpty && attendance.date.weekday != DateTime.sunday
                              ? timeOutFormatted
                              : '--:--',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                            fontWeight: FontWeight.w600,
                            color: attendance.isPresent && attendance.timeOut.isNotEmpty && attendance.date.weekday != DateTime.sunday
                                ? Colors.blue[700]
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (attendance.overtimeMinutes > 0 && attendance.date.weekday != DateTime.sunday) ...[
                          SizedBox(height: isVerySmallScreen ? 1 : 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OT: ${attendance.overtimeMinutes}m',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Status Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                  vertical: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statusDisplay,
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11),
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attendance.lateMinutes > 0 && attendance.status.toLowerCase() == 'late' && attendance.date.weekday != DateTime.sunday) ...[
                      SizedBox(height: isVerySmallScreen ? 1 : 2),
                      Text(
                        'Late by ${attendance.lateMinutes}m',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 9),
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (attendance.date.weekday == DateTime.sunday) ...[
                      SizedBox(height: isVerySmallScreen ? 1 : 2),
                      Text(
                        'Weekly Off',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 9),
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}