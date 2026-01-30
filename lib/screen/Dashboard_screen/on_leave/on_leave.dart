import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../model/leave_approve_model/leave_approve.dart';
import '../../../provider/leave_approve_provider/leave_approve.dart';

class LeaveListScreen extends StatefulWidget {
  final String? selectedDate;

  const LeaveListScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLeaves();

    // Add scroll listener for pull-to-refresh
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 0 && !_isRefreshing) {
      _pullToRefresh();
    }
  }

  Future<void> _pullToRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      await provider.fetchLeaves();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave data refreshed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadLeaves() async {
    final provider = Provider.of<LeaveProvider>(context, listen: false);
    await provider.fetchLeaves();
  }

  // Get target date in YYYY-MM-DD format
  String get _targetDate {
    return widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
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

  // Format date for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Format DateTime for display
  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Filter leaves by search query
  List<ApproveLeave> _filterLeaves(List<ApproveLeave> leaves, String query) {
    if (query.isEmpty) return leaves;

    return leaves.where((leave) {
      return leave.employeeName.toLowerCase().contains(query.toLowerCase()) ||
          leave.employeeCode.toLowerCase().contains(query.toLowerCase()) ||
          leave.departmentName.toLowerCase().contains(query.toLowerCase()) ||
          leave.natureOfLeave.toLowerCase().contains(query.toLowerCase()) ||
          (leave.reason != null && leave.reason!.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get pay mode color
  Color _getPayModeColor(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'with_pay':
        return Colors.green[50]!;
      case 'without_pay':
        return Colors.orange[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getPayModeTextColor(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'with_pay':
        return Colors.green[700]!;
      case 'without_pay':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _formatPayMode(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'with_pay':
        return 'With Pay';
      case 'without_pay':
        return 'Without Pay';
      default:
        return payMode.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        title: Text(
          "Approved Leaves - ${_formatDate(_targetDate)}",
          style: TextStyle(
            fontSize: screenWidth < 360 ? 18 : screenWidth < 600 ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<LeaveProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  // User role indicator - Hide on very small screens
                  if (screenWidth > 320)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 360 ? 8 : 12,
                        vertical: screenWidth < 360 ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            provider.isAdmin ? Iconsax.shield_tick : Iconsax.user,
                            size: screenWidth < 360 ? 14 : 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: screenWidth < 360 ? 4 : 6),
                          Text(
                            provider.isAdmin ? 'Admin' : 'User',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 12 : 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(width: screenWidth < 360 ? 8 : 16),
                  IconButton(
                    icon: Icon(
                      Iconsax.refresh,
                      size: screenWidth < 360 ? 20 : 24,
                    ),
                    onPressed: () {
                      provider.fetchLeaves();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing leaves...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Refresh',
                  ),
                  SizedBox(width: screenWidth < 360 ? 8 : 16),
                ],
              );
            },
          ),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
          ),
          child: Column(
            children: [
              // Date Header Card
              Container(
                margin: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
                padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth < 360 ? 16 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(DateTime.parse(_targetDate)),
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenWidth < 360 ? 2 : 4),
                        Text(
                          _formatDate(_targetDate),
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 360 ? 8 : 12,
                        vertical: screenWidth < 360 ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(screenWidth < 360 ? 10 : 12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.calendar_tick,
                            size: screenWidth < 360 ? 16 : 18,
                            color: const Color(0xFF667EEA),
                          ),
                          SizedBox(width: screenWidth < 360 ? 4 : 6),
                          Text(
                            'Approved Only',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF667EEA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 12 : 16,
                  vertical: screenWidth < 360 ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth < 360 ? 12 : 15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 12 : 16),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.search_normal,
                        color: Colors.grey[500],
                        size: screenWidth < 360 ? 18 : 20,
                      ),
                      SizedBox(width: screenWidth < 360 ? 8 : 12),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _searchQuery),
                          decoration: InputDecoration(
                            hintText: 'Search by name, ID, department...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: screenWidth < 360 ? 12 : 14,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 12 : 14,
                            color: Colors.black87,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Iconsax.close_circle,
                            size: screenWidth < 360 ? 16 : 18,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Statistics Cards
              Consumer<LeaveProvider>(
                builder: (context, provider, child) {
                  final dateLeaves = _getLeavesForDate(provider.allLeaves, _targetDate);
                  final filteredLeaves = _filterLeaves(dateLeaves, _searchQuery);

                  return _buildStatisticsCards(
                    screenWidth: screenWidth,
                    totalLeaves: filteredLeaves.length,
                    totalDays: filteredLeaves.fold(0, (sum, leave) => sum + leave.days),
                  );
                },
              ),

              SizedBox(height: screenWidth < 360 ? 12 : 16),

              // Leave List
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    screenWidth < 360 ? 12 : 16,
                    0,
                    screenWidth < 360 ? 12 : 16,
                    screenWidth < 360 ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth < 360 ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildLeaveList(screenWidth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards({
    required double screenWidth,
    required int totalLeaves,
    required int totalDays,
  }) {
    double cardHeight = screenWidth < 360 ? 90 : 110;
    final isSmallScreen = screenWidth < 360;

    return SizedBox(
      height: cardHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: isSmallScreen ? 6 : 8,
          mainAxisSpacing: isSmallScreen ? 6 : 8,
          childAspectRatio: isSmallScreen ? 2.0 : 2.5,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 6 : 8,
        ),
        itemCount: 2,
        itemBuilder: (context, index) {
          final stats = [
            {
              'icon': Iconsax.people,
              'title': 'Employees on Leave',
              'count': totalLeaves.toString(),
              'subtitle': 'Total Employees',
              'color': const Color(0xFF667EEA),
            },
            {
              'icon': Iconsax.calendar,
              'title': 'Total Leave Days',
              'count': totalDays.toString(),
              'subtitle': 'Days',
              'color': const Color(0xFF4CAF50),
            },
          ];

          final stat = stats[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 40,
                  height: isSmallScreen ? 32 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (stat['color'] as Color).withOpacity(0.2),
                        (stat['color'] as Color).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stat['title'] as String,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        stat['count'] as String,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaveList(double screenWidth) {
    final isSmallScreen = screenWidth < 360;

    return Consumer<LeaveProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.allLeaves.isEmpty) {
          return _buildLoadingScreen(screenWidth);
        }

        if (provider.error.isNotEmpty) {
          return _buildErrorScreen(provider, screenWidth);
        }

        final dateLeaves = _getLeavesForDate(provider.allLeaves, _targetDate);
        final filteredLeaves = _filterLeaves(dateLeaves, _searchQuery);

        if (filteredLeaves.isEmpty) {
          return _buildEmptyScreen(screenWidth);
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
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
                itemCount: filteredLeaves.length,
                itemBuilder: (context, index) {
                  final leave = filteredLeaves[index];
                  return _buildLeaveCard(leave, screenWidth);
                },
              ),

              // Pull-to-refresh indicator
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
                                const Color(0xFF667EEA),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            'Refreshing...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
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

  Widget _buildLeaveCard(ApproveLeave leave, double screenWidth) {
    final statusColor = _getStatusColor(leave.status);
    final statusText = leave.status.toUpperCase();
    final isSmallScreen = screenWidth < 360;

    // Debug logging
    print('=== DEBUG: Building leave card for ${leave.employeeName} ===');
    print('Image URL: ${leave.imageUrl}');
    print('Has image: ${leave.imageUrl != null && leave.imageUrl!.isNotEmpty}');

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Row(
          children: [
            // Profile Image with Status Indicator - UPDATED
            Stack(
              children: [
                // Profile Image Container
                Container(
                  width: isSmallScreen ? 40 : 50,
                  height: isSmallScreen ? 40 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: leave.imageUrl != null && leave.imageUrl!.isNotEmpty
                        ? null // No gradient when image exists
                        : const LinearGradient(
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: leave.imageUrl != null && leave.imageUrl!.isNotEmpty
                        ? Image.network(
                      leave.imageUrl!,
                      fit: BoxFit.cover,
                      width: isSmallScreen ? 40 : 50,
                      height: isSmallScreen ? 40 : 50,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF667EEA),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Image load error for ${leave.employeeName}: $error');
                        // Fallback to initials when image fails to load
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF667EEA),
                                Color(0xFF764BA2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              leave.employeeName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : Center(
                      // Show initials when no image URL is available
                      child: Text(
                        leave.employeeName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Status indicator dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: isSmallScreen ? 10 : 12,
                    height: isSmallScreen ? 10 : 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSmallScreen ? 1.5 : 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            // Employee Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          leave.employeeName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: isSmallScreen ? 2 : 4),
                  // Text(
                  //   leave.employeeCode,
                  //   style: TextStyle(
                  //     fontSize: isSmallScreen ? 10 : 12,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                  // SizedBox(height: isSmallScreen ? 6 : 8),

                  // Leave Details
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
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                              ),
                              child: Text(
                                leave.natureOfLeave,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: isSmallScreen ? 6 : 8),

                      // Pay Mode
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay Mode',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getPayModeColor(leave.payMode),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                              ),
                              child: Text(
                                _formatPayMode(leave.payMode),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getPayModeTextColor(leave.payMode),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: isSmallScreen ? 6 : 8),

                      // Leave Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                              ),
                              child: Text(
                                '${leave.days} day${leave.days != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Leave Dates and Reason
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Iconsax.calendar,
                              size: isSmallScreen ? 10 : 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 6),
                            Flexible(
                              child: Text(
                                '${_formatDateTime(leave.fromDate)} - ${_formatDateTime(leave.toDate)}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Text(
                            'Reason: ${leave.reason!}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF667EEA),
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 16 : 20),
          Text(
            'Loading approved leaves...',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 14 : 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 6 : 8),
          Text(
            'Please wait',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 12 : 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(LeaveProvider provider, double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 360 ? 16 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: screenWidth < 360 ? 50 : 60,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenWidth < 360 ? 12 : 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 16 : 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth < 360 ? 6 : 8),
            Text(
              provider.error.length > 100
                  ? '${provider.error.substring(0, 100)}...'
                  : provider.error,
              style: TextStyle(
                fontSize: screenWidth < 360 ? 12 : 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth < 360 ? 16 : 20),
            ElevatedButton(
              onPressed: () => provider.fetchLeaves(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth < 360 ? 8 : 10),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 20 : 24,
                  vertical: screenWidth < 360 ? 10 : 12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: screenWidth < 360 ? 16 : 18),
                  SizedBox(width: screenWidth < 360 ? 6 : 8),
                  Text(
                    'Retry',
                    style: TextStyle(fontSize: screenWidth < 360 ? 12 : 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen(double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 360 ? 16 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar_remove,
              size: screenWidth < 360 ? 50 : 60,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenWidth < 360 ? 12 : 16),
            Text(
              'No Approved Leaves',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 16 : 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth < 360 ? 6 : 8),
            Text(
              'No approved leaves found for ${_formatDate(_targetDate)}',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 12 : 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              SizedBox(height: screenWidth < 360 ? 6 : 8),
              Text(
                'Search query: "$_searchQuery"',
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 11 : 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
            SizedBox(height: screenWidth < 360 ? 16 : 20),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<LeaveProvider>(context, listen: false);
                provider.fetchLeaves();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth < 360 ? 8 : 10),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 20 : 24,
                  vertical: screenWidth < 360 ? 10 : 12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: screenWidth < 360 ? 16 : 18),
                  SizedBox(width: screenWidth < 360 ? 6 : 8),
                  Text(
                    'Check Again',
                    style: TextStyle(fontSize: screenWidth < 360 ? 12 : 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}