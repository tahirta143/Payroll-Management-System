import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../model/attendance_model/attendance_model.dart';
import '../../../model/absents_model/absents_model.dart';
import '../../../model/leave_approve_model/leave_approve.dart';
import '../../../provider/attendance_provider/attendance_provider.dart';
import '../../../provider/absents_provider/absents_provider.dart';
import '../../../provider/leave_approve_provider/leave_approve.dart';
import '../../../provider/Auth_provider/Auth_provider.dart';

class TodayAttendance extends StatefulWidget {
  final String? selectedDate;

  const TodayAttendance({super.key, this.selectedDate});

  @override
  State<TodayAttendance> createState() => _TodayAttendanceState();
}

class _TodayAttendanceState extends State<TodayAttendance> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _dateController = TextEditingController();
  bool _isRefreshing = false;
  String _selectedStatusFilter = 'All';
  DateTime? _selectedDate;

  // Track which provider data to show
  bool _showAbsentFromProvider = false;
  bool _showLeavesFromProvider = false;
  Color _getDepartmentColor(String departmentName) {
    final name = departmentName.toLowerCase();

    if (name.contains('infinity')) {
      return Colors.orange; // Infinity - Orange
    } else if (name.contains('coretech') || name.contains('core tech')) {
      return Colors.brown; // Coretech - Purple
    } else if (name.contains('skylink') || name.contains('sky link')) {
      return Colors.blue; // Skylink - Teal (or any color you prefer)
    } else {
      return const Color(0xFF667EEA); // Default - Purple/Blue gradient color
    }
  }
  @override
  void initState() {
    super.initState();

    // Initialize date
    if (widget.selectedDate != null) {
      try {
        _selectedDate = DateTime.parse(widget.selectedDate!);
        _dateController.text = _formatDateForApi(_selectedDate!);
      } catch (e) {
        _selectedDate = DateTime.now();
        _dateController.text = _formatDateForApi(_selectedDate!);
      }
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDateForApi(_selectedDate!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 0 && !_isRefreshing) {
      _pullToRefresh();
    }
  }

  Future<void> _loadData() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final absentProvider = Provider.of<AbsentProvider>(context, listen: false);
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Set auth token in absent provider
    if (authProvider.token != null) {
      absentProvider.setAuthToken(authProvider.token!);
      print('✅ Auth token set in AbsentProvider from TodayAttendance');
    } else {
      print('❌ No auth token available in TodayAttendance');
    }

    // Set admin status in absent provider
    absentProvider.setAdminStatus(authProvider.isAdmin);

    // Fetch data
    await Future.wait([
      attendanceProvider.fetchAllData(),
      absentProvider.fetchAbsents(date: _targetDate),
      leaveProvider.fetchLeaves(),
    ]);
  }

  Future<void> _pullToRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateForDisplay(String dateString) {
    if (dateString == 'all' || dateString == 'All Time') return 'All Time';
    try {
      final date = DateTime.parse(dateString);
      return _formatDisplayDate(date);
    } catch (e) {
      return dateString;
    }
  }

  // New method to format date as "17 Feb 2026"
  String _formatDisplayDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // New method to format time to 12-hour format with AM/PM
  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty || timeString == '--:--') {
      return '--:--';
    }

    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        // Parse time string (assuming format like "14:30" or "09:15")
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts[1].substring(0, 2);

          // Create a DateTime object with today's date and the given time
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, hour, int.parse(minute));

          // Format to 12-hour format with AM/PM
          return DateFormat('h:mm a').format(time);
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDateForApi(picked);
        // Reset filter when date changes
        _selectedStatusFilter = 'All';
        _showAbsentFromProvider = false;
        _showLeavesFromProvider = false;
      });

      // Refresh data for selected date
      _loadData();
    }
  }

  void _showTodayData() {
    setState(() {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDateForApi(_selectedDate!);
      _selectedStatusFilter = 'All';
      _showAbsentFromProvider = false;
      _showLeavesFromProvider = false;
    });

    // Refresh data for today
    _loadData();
  }

  String get _targetDate {
    if (_selectedDate != null) {
      return _formatDateForApi(_selectedDate!);
    }
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  List<Attendance> _getDateAttendance(List<Attendance> allAttendance) {
    try {
      final target = DateTime.parse(_targetDate);
      return allAttendance.where((a) {
        return a.date.year == target.year &&
            a.date.month == target.month &&
            a.date.day == target.day;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Check if a leave covers the target date
  bool _isLeaveForDate(ApproveLeave leave, String targetDate) {
    try {
      // Check if leave is APPROVED
      if (leave.status.toLowerCase() != 'approved') {
        return false;
      }

      // Parse target date
      final target = DateTime.parse(targetDate);

      // Get leave dates
      final fromDate = leave.fromDate;
      final toDate = leave.toDate;

      // Normalize all dates to just the date part (remove time)
      final targetNormalized = DateTime(target.year, target.month, target.day);
      final startNormalized = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final endNormalized = DateTime(toDate.year, toDate.month, toDate.day);

      // Check if target date is within the leave range (inclusive)
      return (targetNormalized.isAfter(startNormalized.subtract(const Duration(days: 1))) &&
          targetNormalized.isBefore(endNormalized.add(const Duration(days: 1))));
    } catch (e) {
      return false;
    }
  }

  // Get approved leaves for a specific date
  List<ApproveLeave> _getLeavesForDate(List<ApproveLeave> allLeaves, String targetDate) {
    return allLeaves.where((leave) => _isLeaveForDate(leave, targetDate)).toList();
  }

  int _deptPriority(String deptName) {
    final name = deptName.toLowerCase();
    if (name.contains('coretech') || name.contains('core tech')) return 0;
    if (name.contains('infinity')) return 1;
    if (name.contains('skylink') || name.contains('sky link')) return 2;
    return 3;
  }

  List<Attendance> _getFilteredAttendance(List<Attendance> attendanceList) {
    if (_showAbsentFromProvider || _showLeavesFromProvider) return [];

    List<Attendance> filtered = attendanceList;

    if (_selectedStatusFilter != 'All') {
      filtered = filtered.where((a) {
        switch (_selectedStatusFilter) {
          case 'Present':
            return a.isPresent && a.lateMinutes == 0;
          case 'Late':
            return a.isPresent && a.lateMinutes > 0;
          case 'Absent':
            return !a.isPresent && !a.status.toLowerCase().contains('leave');
          case 'On Leave':
            return !a.isPresent && a.status.toLowerCase().contains('leave');
          default:
            return true;
        }
      }).toList();
    }

    filtered.sort((a, b) {
      final priorityA = _deptPriority(a.departmentName);
      final priorityB = _deptPriority(b.departmentName);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      final deptCompare = a.departmentName
          .toLowerCase()
          .compareTo(b.departmentName.toLowerCase());
      if (deptCompare != 0) return deptCompare;
      return a.employeeName
          .toLowerCase()
          .compareTo(b.employeeName.toLowerCase());
    });

    return filtered;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _formatDisplayDate(date);
    } catch (e) {
      return dateString;
    }
  }

  // Format DateTime for display
  String _formatDateTime(DateTime date) {
    return _formatDisplayDate(date);
  }

  String _getTitleText() {
    if (_showAbsentFromProvider) {
      return "Absent Employees - ${_formatDate(_targetDate)}";
    } else if (_showLeavesFromProvider) {
      return "On Leave Employees - ${_formatDate(_targetDate)}";
    } else if (widget.selectedDate != null) {
      return "Attendance - ${_formatDate(_targetDate)}";
    } else if (_selectedDate != null &&
        _formatDateForApi(_selectedDate!) != DateFormat('yyyy-MM-dd').format(DateTime.now())) {
      return "Attendance - ${_formatDate(_targetDate)}";
    } else {
      return "Today's Attendance";
    }
  }

  void _handleAbsentCardTap() {
    setState(() {
      _showAbsentFromProvider = true;
      _showLeavesFromProvider = false;
      _selectedStatusFilter = 'All';
    });
  }

  void _handleOnLeaveCardTap() {
    setState(() {
      _showLeavesFromProvider = true;
      _showAbsentFromProvider = false;
      _selectedStatusFilter = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        title: Text(
          _getTitleText(),
          style: TextStyle(
            fontSize: size.width > 600 ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.isAdmin
                              ? Iconsax.shield_tick
                              : Iconsax.user,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.isAdmin ? 'Admin' : 'User',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Iconsax.refresh),
                    onPressed: () {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing data...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
          child: Column(
            children: [
              // Date Filter Widget
              _buildDateFilter(),

              // Statistics Cards
              Consumer4<AttendanceProvider, AbsentProvider, LeaveProvider, AuthProvider>(
                builder: (context, attendanceProvider, absentProvider, leaveProvider, authProvider, child) {
                  final dateAttendance =
                  _getDateAttendance(attendanceProvider.allAttendance);

                  final totalPresent =
                      dateAttendance.where((a) => a.isPresent && a.lateMinutes == 0).length;
                  final totalLate = dateAttendance
                      .where((a) => a.isPresent && a.lateMinutes > 0)
                      .length;

                  // Get leaves for selected date
                  final dateLeaves = _getLeavesForDate(leaveProvider.allLeaves, _targetDate);
                  final totalOnLeave = dateLeaves.length;

                  final totalAbsent = dateAttendance
                      .where((a) => !a.isPresent && !a.status.toLowerCase().contains('leave'))
                      .length;

                  // Get absent count from AbsentProvider for the selected date
                  final absentCount = absentProvider.filteredAbsents.length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildClickableStatCard(
                                icon: Iconsax.tick_circle,
                                title: 'Present',
                                count: totalPresent.toString(),
                                color: const Color(0xFF4CAF50),
                                isSelected: !_showAbsentFromProvider && !_showLeavesFromProvider && _selectedStatusFilter == 'Present',
                                onTap: () => setState(() {
                                  _showAbsentFromProvider = false;
                                  _showLeavesFromProvider = false;
                                  _selectedStatusFilter =
                                  _selectedStatusFilter == 'Present'
                                      ? 'All'
                                      : 'Present';
                                }),
                                size: size,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildClickableStatCard(
                                icon: Iconsax.clock,
                                title: 'Late',
                                count: totalLate.toString(),
                                color: const Color(0xFFFF9800),
                                isSelected: !_showAbsentFromProvider && !_showLeavesFromProvider && _selectedStatusFilter == 'Late',
                                onTap: () => setState(() {
                                  _showAbsentFromProvider = false;
                                  _showLeavesFromProvider = false;
                                  _selectedStatusFilter =
                                  _selectedStatusFilter == 'Late'
                                      ? 'All'
                                      : 'Late';
                                }),
                                size: size,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildClickableStatCard(
                                icon: Iconsax.calendar_remove,
                                title: 'On Leave',
                                count: totalOnLeave.toString(),
                                color: const Color(0xFF2196F3),
                                isSelected: _showLeavesFromProvider || (!_showAbsentFromProvider && !_showLeavesFromProvider && _selectedStatusFilter == 'On Leave'),
                                onTap: _handleOnLeaveCardTap,
                                size: size,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildClickableStatCard(
                                icon: Iconsax.close_circle,
                                title: 'Absent',
                                count: absentCount.toString(),
                                color: const Color(0xFFF44336),
                                isSelected: _showAbsentFromProvider || (!_showAbsentFromProvider && !_showLeavesFromProvider && _selectedStatusFilter == 'Absent'),
                                onTap: _handleAbsentCardTap,
                                size: size,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Filter indicator
              if (_selectedStatusFilter != 'All' || _showAbsentFromProvider || _showLeavesFromProvider)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAbsentFromProvider
                            ? Iconsax.close_circle
                            : _showLeavesFromProvider
                            ? Iconsax.calendar_remove
                            : _getFilterIcon(),
                        size: 16,
                        color: _showAbsentFromProvider
                            ? const Color(0xFFF44336)
                            : _showLeavesFromProvider
                            ? const Color(0xFF2196F3)
                            : _getFilterColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showAbsentFromProvider
                            ? 'Showing: Absent Employees'
                            : _showLeavesFromProvider
                            ? 'Showing: On Leave Employees'
                            : 'Showing: $_selectedStatusFilter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStatusFilter = 'All';
                            _showAbsentFromProvider = false;
                            _showLeavesFromProvider = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Attendance/Absent/Leave List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _showAbsentFromProvider
                      ? _buildAbsentList()
                      : _showLeavesFromProvider
                      ? _buildLeaveList()
                      : _buildAttendanceList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFilterIcon() {
    switch (_selectedStatusFilter) {
      case 'Present':
        return Iconsax.tick_circle;
      case 'Late':
        return Iconsax.clock;
      case 'Absent':
        return Iconsax.close_circle;
      case 'On Leave':
        return Iconsax.calendar_remove;
      default:
        return Iconsax.filter;
    }
  }

  Color _getFilterColor() {
    switch (_selectedStatusFilter) {
      case 'Present':
        return const Color(0xFF4CAF50);
      case 'Late':
        return const Color(0xFFFF9800);
      case 'Absent':
        return const Color(0xFFF44336);
      case 'On Leave':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  // Date Filter Widget
  Widget _buildDateFilter() {
    final displayDate = _selectedDate != null
        ? _formatDisplayDate(_selectedDate!)
        : _formatDisplayDate(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.calendar_1,
              color: Color(0xFF667EEA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(text: displayDate),
                      decoration: InputDecoration(
                        hintText: 'Select Date',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        suffixIcon: Icon(
                          Iconsax.calendar,
                          color: Colors.grey[500],
                          size: 18,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _showTodayData,
            style: TextButton.styleFrom(
              backgroundColor: _selectedDate != null &&
                  _formatDateForApi(_selectedDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                  ? const Color(0xFF667EEA).withOpacity(0.1)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedDate != null &&
                      _formatDateForApi(_selectedDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                      ? const Color(0xFF667EEA)
                      : Colors.grey[300]!,
                ),
              ),
            ),
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _selectedDate != null &&
                    _formatDateForApi(_selectedDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _selectedDate != null &&
                    _formatDateForApi(_selectedDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                    ? const Color(0xFF667EEA)
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStatCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required VoidCallback onTap,
    required Size size,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: size.width > 600 ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: size.width > 600 ? 12 : 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.allAttendance.isEmpty) {
          return _buildLoadingScreen();
        }

        if (provider.error.isNotEmpty) {
          return _buildErrorScreen(provider);
        }

        final dateAttendance = _getDateAttendance(provider.allAttendance);
        final filteredAttendance = _getFilteredAttendance(dateAttendance);

        if (filteredAttendance.isEmpty) {
          return _buildEmptyScreen();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollEndNotification &&
                _scrollController.position.pixels == 0 &&
                !_isRefreshing) {
              _pullToRefresh();
              return true;
            }
            return false;
          },
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredAttendance.length,
                itemBuilder: (context, index) {
                  return _buildAttendanceCard(filteredAttendance[index]);
                },
              ),

              if (_isRefreshing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF667EEA)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Refreshing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (provider.isLoadingAttendance)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667EEA)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.selectedDate != null
                                ? 'Loading attendance for ${_formatDate(_targetDate)}...'
                                : "Loading today's attendance...",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildAbsentList() {
    return Consumer<AbsentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredAbsents.isEmpty) {
          return _buildLoadingScreen();
        }

        if (provider.error.isNotEmpty) {
          return _buildErrorScreen(provider);
        }

        if (provider.filteredAbsents.isEmpty) {
          return _buildEmptyAbsentScreen();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollEndNotification &&
                _scrollController.position.pixels == 0 &&
                !_isRefreshing) {
              _pullToRefresh();
              return true;
            }
            return false;
          },
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.filteredAbsents.length,
                itemBuilder: (context, index) {
                  return _buildAbsentCard(provider.filteredAbsents[index]);
                },
              ),

              if (_isRefreshing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF667EEA)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Refreshing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (provider.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667EEA)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading absent employees...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildLeaveList() {
    return Consumer<LeaveProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.allLeaves.isEmpty) {
          return _buildLoadingScreen();
        }

        if (provider.error.isNotEmpty) {
          return _buildErrorScreen(provider);
        }

        // Get leaves for the selected date
        final dateLeaves = _getLeavesForDate(provider.allLeaves, _targetDate);

        if (dateLeaves.isEmpty) {
          return _buildEmptyLeaveScreen();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollEndNotification &&
                _scrollController.position.pixels == 0 &&
                !_isRefreshing) {
              _pullToRefresh();
              return true;
            }
            return false;
          },
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: dateLeaves.length,
                itemBuilder: (context, index) {
                  return _buildLeaveCard(dateLeaves[index]);
                },
              ),

              if (_isRefreshing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF667EEA)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Refreshing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (provider.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667EEA)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading leave employees...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildAttendanceCard(Attendance attendance) {
    final Size size = MediaQuery.of(context).size;

    String statusText;
    Color statusColor;

    if (attendance.isPresent) {
      if (attendance.lateMinutes > 0) {
        statusText = 'Late (${attendance.lateMinutes}m)';
        statusColor = const Color(0xFFFF9800);
      } else {
        statusText = 'Present';
        statusColor = const Color(0xFF4CAF50);
      }
    } else {
      if (attendance.status.toLowerCase().contains('leave')) {
        statusText = 'On Leave';
        statusColor = const Color(0xFF2196F3);
      } else {
        statusText = 'Absent';
        statusColor = const Color(0xFFF44336);
      }
    }

    // Format times to 12-hour format with AM/PM
    String timeInFormatted = _formatTime(attendance.timeIn);
    String timeOutFormatted = _formatTime(attendance.timeOut);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row 1: Image, Name and Department
            Row(
              children: [
                _buildProfileImage(attendance.imageUrl, attendance.employeeName, size),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          attendance.employeeName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Find this section in _buildAttendanceCard:
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(attendance.departmentName).withOpacity(0.2), // ← Updated
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          attendance.departmentName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 10 : 9,
                            color: _getDepartmentColor(attendance.departmentName), // ← Updated
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Time In, Time Out, Status
            Row(
              children: [
                // Time In
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time In',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: attendance.isPresent
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          attendance.isPresent ? timeInFormatted : '--:--',
                          style: TextStyle(
                            fontSize: size.width > 600 ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: attendance.isPresent
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Time Out
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Out',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: attendance.isPresent && attendance.timeOut.isNotEmpty
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          attendance.isPresent && attendance.timeOut.isNotEmpty
                              ? timeOutFormatted
                              : '--:--',
                          style: TextStyle(
                            fontSize: size.width > 600 ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: attendance.isPresent && attendance.timeOut.isNotEmpty
                                ? Colors.blue[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentCard(Absent absent) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFF44336).withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row 1: Image, Name and Department
            Row(
              children: [
                _buildProfileImage(absent.imageUrl, absent.employeeName, size),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          absent.employeeName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Find this section in _buildAbsentCard:
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(absent.departmentName).withOpacity(0.2), // ← Updated
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          absent.departmentName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 10 : 9,
                            color: _getDepartmentColor(absent.departmentName), // ← Updated
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Employee ID and Reason
            Row(
              children: [
                // Employee ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employee ID',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          absent.empId,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Reason
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: absent.reason != null && absent.reason!.isNotEmpty
                              ? const Color(0xFFF44336).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          absent.reason != null && absent.reason!.isNotEmpty
                              ? absent.reason!.length > 15
                              ? '${absent.reason!.substring(0, 15)}...'
                              : absent.reason!
                              : 'No reason provided',
                          style: TextStyle(
                            fontSize: size.width > 600 ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: absent.reason != null && absent.reason!.isNotEmpty
                                ? const Color(0xFFF44336)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Absent',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF44336),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveCard(ApproveLeave leave) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row 1: Image, Name and Department
            Row(
              children: [
                _buildProfileImage(leave.imageUrl, leave.employeeName, size),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          leave.employeeName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Find this section in _buildLeaveCard:
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(leave.departmentName).withOpacity(0.2), // ← Updated
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          leave.departmentName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 10 : 9,
                            color: _getDepartmentColor(leave.departmentName), // ← Updated
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Leave Details
            Row(
              children: [
                // Leave Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Type',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          leave.natureOfLeave,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${leave.days} day${leave.days != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: size.width > 600 ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: size.width > 600 ? 11 : 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 3: Leave Dates and Reason
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.calendar,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${_formatDisplayDate(leave.fromDate)} - ${_formatDisplayDate(leave.toDate)}',
                          style: TextStyle(
                            fontSize: size.width > 600 ? 11 : 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${leave.reason!}',
                      style: TextStyle(
                        fontSize: size.width > 600 ? 11 : 10,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String employeeName, Size size) {
    const String baseUrl = 'https://api.afaqmis.com';
    final String initial = employeeName.isNotEmpty
        ? employeeName[0].toUpperCase()
        : 'E';

    Widget fallback = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF667EEA),
          ),
        ),
      ),
    );

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return fallback;
    }

    String fullImageUrl = imageUrl.trim();
    if (!fullImageUrl.startsWith('http')) {
      final cleanPath = fullImageUrl.startsWith('/') ? fullImageUrl.substring(1) : fullImageUrl;
      fullImageUrl = '$baseUrl/$cleanPath';
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: fullImageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) {
          debugPrint('❌ Image error [$url]: $error');
          return fallback;
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          const SizedBox(height: 20),
          Text(
            _showAbsentFromProvider
                ? 'Loading absent employees...'
                : _showLeavesFromProvider
                ? 'Loading leave employees...'
                : (widget.selectedDate != null
                ? 'Loading attendance for ${_formatDate(_targetDate)}...'
                : "Loading today's attendance..."),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(dynamic provider) {
    String errorMessage = provider is AttendanceProvider
        ? provider.error
        : (provider is AbsentProvider ? provider.error :
    (provider is LeaveProvider ? provider.error : 'Unknown error'));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage.length > 100
                  ? '${errorMessage.substring(0, 100)}...'
                  : errorMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pullToRefresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Retry', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    String message;
    if (_selectedDate != null &&
        _formatDateForApi(_selectedDate!) != DateFormat('yyyy-MM-dd').format(DateTime.now())) {
      message = 'No attendance records found for ${_formatDate(_targetDate)}';
    } else {
      message = 'No attendance records found for today';
    }

    if (_selectedStatusFilter != 'All') {
      message = 'No $_selectedStatusFilter employees found';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                _selectedStatusFilter == 'Absent'
                    ? Iconsax.close_circle
                    : Iconsax.calendar_tick,
                size: 60,
                color: Colors.grey[300]
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatusFilter == 'Absent'
                  ? 'No Absent Employees'
                  : 'No Attendance Data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Check Again', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAbsentScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.close_circle, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Absent Employees',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate != null &&
                  _formatDateForApi(_selectedDate!) != DateFormat('yyyy-MM-dd').format(DateTime.now())
                  ? 'No employees were absent on ${_formatDate(_targetDate)}'
                  : 'No employees are absent today',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Check Again', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaveScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.calendar_remove, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Employees on Leave',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate != null &&
                  _formatDateForApi(_selectedDate!) != DateFormat('yyyy-MM-dd').format(DateTime.now())
                  ? 'No employees were on leave on ${_formatDate(_targetDate)}'
                  : 'No employees are on leave today',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Check Again', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}