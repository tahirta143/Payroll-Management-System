import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../model/attendance_model/attendance_model.dart';
import '../../../provider/attendance_provider/attendance_provider.dart';

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
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      provider.fetchAllData();
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

  Future<void> _pullToRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      await provider.fetchAttendance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance data refreshed!'),
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
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
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
      });

      // Refresh data for selected date
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      provider.fetchAttendance();
    }
  }

  void _showTodayData() {
    setState(() {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDateForApi(_selectedDate!);
    });

    // Refresh data for today
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchAttendance();
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

  int _deptPriority(String deptName) {
    final name = deptName.toLowerCase();
    if (name.contains('coretech') || name.contains('core tech')) return 0;
    if (name.contains('infinity')) return 1;
    if (name.contains('skylink') || name.contains('sky link')) return 2;
    return 3;
  }

  List<Attendance> _getFilteredAttendance(List<Attendance> attendanceList) {
    List<Attendance> filtered = attendanceList;

    if (_selectedStatusFilter != 'All') {
      filtered = filtered.where((a) {
        switch (_selectedStatusFilter) {
          case 'Present':
            return a.isPresent;
          case 'Late':
            return a.isPresent && a.lateMinutes > 0;
          case 'Absent':
            return !a.isPresent;
          case 'On Leave':
          // You need to add a field in Attendance model to track leave
          // For now, we'll consider employees with no timeIn and no timeOut as on leave
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
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getTitleText() {
    if (widget.selectedDate != null) {
      return "Attendance - ${_formatDate(_targetDate)}";
    } else if (_selectedDate != null &&
        _formatDateForApi(_selectedDate!) != DateFormat('yyyy-MM-dd').format(DateTime.now())) {
      return "Attendance - ${_formatDate(_targetDate)}";
    } else {
      return "Today's Attendance";
    }
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
                      provider.fetchAttendance();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing attendance...'),
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
              Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  final dateAttendance =
                  _getDateAttendance(provider.allAttendance);

                  final totalPresent =
                      dateAttendance.where((a) => a.isPresent).length;
                  final totalLate = dateAttendance
                      .where((a) => a.isPresent && a.lateMinutes > 0)
                      .length;
                  final totalOnLeave = dateAttendance
                      .where((a) => !a.isPresent && a.status.toLowerCase().contains('leave'))
                      .length;
                  final totalAbsent = dateAttendance
                      .where((a) => !a.isPresent && !a.status.toLowerCase().contains('leave'))
                      .length;

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
                                isSelected:
                                _selectedStatusFilter == 'Present',
                                onTap: () => setState(() {
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
                                isSelected: _selectedStatusFilter == 'Late',
                                onTap: () => setState(() {
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
                                isSelected:
                                _selectedStatusFilter == 'On Leave',
                                onTap: () => setState(() {
                                  _selectedStatusFilter =
                                  _selectedStatusFilter == 'On Leave'
                                      ? 'All'
                                      : 'On Leave';
                                }),
                                size: size,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildClickableStatCard(
                                icon: Iconsax.close_circle,
                                title: 'Absent',
                                count: totalAbsent.toString(),
                                color: const Color(0xFFF44336),
                                isSelected:
                                _selectedStatusFilter == 'Absent',
                                onTap: () => setState(() {
                                  _selectedStatusFilter =
                                  _selectedStatusFilter == 'Absent'
                                      ? 'All'
                                      : 'Absent';
                                }),
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

              // Attendance List
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
                  child: _buildAttendanceList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Date Filter Widget
  Widget _buildDateFilter() {
    final displayDate = _dateController.text == 'All Time'
        ? 'All Time'
        : _formatDateForDisplay(_dateController.text);

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
                  'Select Date',
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
                      controller: _dateController,
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
              backgroundColor: _dateController.text ==
                  DateFormat('yyyy-MM-dd').format(DateTime.now())
                  ? const Color(0xFF667EEA).withOpacity(0.1)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _dateController.text ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now())
                      ? const Color(0xFF667EEA)
                      : Colors.grey[300]!,
                ),
              ),
            ),
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _dateController.text ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now())
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _dateController.text ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now())
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
                _buildProfileImage(attendance, size),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.employeeName,
                        style: TextStyle(
                          fontSize: size.width > 600 ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          attendance.departmentName,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 10 : 9,
                            color: const Color(0xFF667EEA),
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
                          attendance.isPresent && attendance.timeIn.isNotEmpty
                              ? attendance.timeIn.length >= 5
                              ? attendance.timeIn.substring(0, 5)
                              : attendance.timeIn
                              : '--:--',
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
                              ? attendance.timeOut.length >= 5
                              ? attendance.timeOut.substring(0, 5)
                              : attendance.timeOut
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

  Widget _buildProfileImage(Attendance attendance, Size size) {
    const String baseUrl = 'https://api.afaqmis.com';
    print('=== DEBUG: Building card for ${attendance.employeeName} ===');
    print('Image URL: ${attendance.imageUrl}');
    print('Has image URL: ${attendance.imageUrl != null}');
    print('Image URL not empty: ${attendance.imageUrl?.isNotEmpty ?? false}');
    final String initial = attendance.employeeName.isNotEmpty
        ? attendance.employeeName[0].toUpperCase()
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

    if (attendance.imageUrl == null || attendance.imageUrl!.trim().isEmpty) {
      return fallback;
    }

    String imageUrl = attendance.imageUrl!.trim();
    if (!imageUrl.startsWith('http')) {
      final cleanPath =
      imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
      imageUrl = '$baseUrl/$cleanPath';
    }

    debugPrint('🖼️ Loading image: $imageUrl');

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
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
            widget.selectedDate != null
                ? 'Loading attendance for ${_formatDate(_targetDate)}...'
                : "Loading today's attendance...",
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

  Widget _buildErrorScreen(AttendanceProvider provider) {
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
              provider.error.length > 100
                  ? '${provider.error.substring(0, 100)}...'
                  : provider.error,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.fetchAttendance(),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.calendar_tick, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Attendance Data',
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
                final provider = Provider.of<AttendanceProvider>(
                    context,
                    listen: false);
                provider.fetchAttendance();
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