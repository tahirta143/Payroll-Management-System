import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../model/absents_model/absents_model.dart';
import '../../../provider/Auth_provider/Auth_provider.dart';
import '../../../provider/absents_provider/absents_provider.dart';

class AbsentListScreen extends StatefulWidget {
  final String? selectedDate;

  const AbsentListScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  State<AbsentListScreen> createState() => _AbsentListScreenState();
}

class _AbsentListScreenState extends State<AbsentListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String _searchQuery = '';

  // Target date getter
  String get _targetDate {
    return widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 0 && !_isRefreshing) {
      _pullToRefresh();
    }
  }

  // Format date for display
  String _formatDate(dynamic dateInput) {
    try {
      DateTime date;

      if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else if (dateInput is DateTime) {
        date = dateInput;
      } else {
        return dateInput.toString();
      }

      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateInput.toString();
    }
  }

  // Format DateTime for display
  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();

    // Delay the API call until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsents();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pullToRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final provider = Provider.of<AbsentProvider>(context, listen: false);
      await provider.fetchAbsents(date: widget.selectedDate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absent data refreshed!'),
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

  Future<void> _loadAbsents() async {
    final provider = Provider.of<AbsentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Debug logging
    print('=== LOADING ABSENTS DEBUG ===');
    print('Selected date from widget: ${widget.selectedDate}');
    print('Target date: $_targetDate');
    print('Has token: ${authProvider.token != null}');
    if (authProvider.token != null) {
      print('Token length: ${authProvider.token!.length}');
    }

    // Set the token in the absent provider
    if (authProvider.token != null) {
      provider.setAuthToken(authProvider.token!);
    } else {
      print('ERROR: No authentication token available!');
    }

    // Also set admin status if available
    provider.setAdminStatus(authProvider.isAdmin);

    await provider.fetchAbsents(date: widget.selectedDate);

    // Debug: Check results after fetch
    print('After fetch - filtered absents: ${provider.filteredAbsents.length}');
    print('After fetch - all absents: ${provider.absents.length}');
    print('Provider error: ${provider.error}');
    print('=== END LOADING DEBUG ===');
  }

  // Get reason color
  Color _getReasonColor(String? reason) {
    if (reason == null || reason.isEmpty) return Colors.grey;

    final reasonLower = reason.toLowerCase();
    if (reasonLower.contains('sick') || reasonLower.contains('ill')) {
      return const Color(0xFF2196F3);
    } else if (reasonLower.contains('leave') || reasonLower.contains('vacation')) {
      return const Color(0xFFFF9800);
    } else if (reasonLower.contains('personal')) {
      return const Color(0xFF9C27B0);
    } else if (reasonLower.contains('emergency')) {
      return const Color(0xFFF44336);
    } else {
      return const Color(0xFF795548);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        title: Text(
          "Absent Employees - ${_formatDate(_targetDate)}",
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
          Consumer<AbsentProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  // User role indicator
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
                      provider.fetchAbsents(date: widget.selectedDate);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing absent list...'),
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
                            Iconsax.calendar_remove,
                            size: screenWidth < 360 ? 16 : 18,
                            color: const Color(0xFF667EEA),
                          ),
                          SizedBox(width: screenWidth < 360 ? 4 : 6),
                          Text(
                            'Absent',
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
                            final provider = Provider.of<AbsentProvider>(context, listen: false);
                            provider.filterAbsents(value);
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
                            final provider = Provider.of<AbsentProvider>(context, listen: false);
                            provider.filterAbsents('');
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Statistics Cards
              Consumer<AbsentProvider>(
                builder: (context, provider, child) {
                  final stats = provider.getAbsentStats();
                  return _buildStatisticsCards(
                    screenWidth: screenWidth,
                    totalAbsents: stats['total'] ?? 0,
                    todayAbsents: stats['today'] ?? 0,
                    yesterdayAbsents: stats['yesterday'] ?? 0,
                    thisWeekAbsents: stats['thisWeek'] ?? 0,
                  );
                },
              ),

              SizedBox(height: screenWidth < 360 ? 12 : 16),

              // Absent List
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
                  child: _buildAbsentList(screenWidth),
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
    required int totalAbsents,
    required int todayAbsents,
    required int yesterdayAbsents,
    required int thisWeekAbsents,
  }) {
    final isSmallScreen = screenWidth < 360;
    double cardHeight = isSmallScreen ? 90 : 110;

    return SizedBox(
      height: cardHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: isSmallScreen ? 6 : 8,
          mainAxisSpacing: isSmallScreen ? 6 : 8,
          childAspectRatio: isSmallScreen ? 0.8 : 1.0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 6 : 8,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final stats = [
            {
              'icon': Iconsax.profile_2user,
              'title': 'Total',
              'count': totalAbsents.toString(),
              'color': const Color(0xFF667EEA),
            },
            {
              'icon': Iconsax.calendar,
              'title': 'Today',
              'count': todayAbsents.toString(),
              'color': const Color(0xFF4CAF50),
            },
            {
              'icon': Iconsax.calendar_1,
              'title': 'Yesterday',
              'count': yesterdayAbsents.toString(),
              'color': const Color(0xFFFF9800),
            },
            {
              'icon': Iconsax.calendar,
              'title': 'This Week',
              'count': thisWeekAbsents.toString(),
              'color': const Color(0xFF9C27B0),
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
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSmallScreen ? 24 : 28,
                  height: isSmallScreen ? 24 : 28,
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
                    size: isSmallScreen ? 14 : 16,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  stat['count'] as String,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbsentList(double screenWidth) {
    final isSmallScreen = screenWidth < 360;

    return Consumer<AbsentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredAbsents.isEmpty) {
          return _buildLoadingScreen(screenWidth);
        }

        if (provider.error.isNotEmpty) {
          return _buildErrorScreen(provider, screenWidth);
        }

        if (provider.filteredAbsents.isEmpty) {
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
                itemCount: provider.filteredAbsents.length,
                itemBuilder: (context, index) {
                  final absent = provider.filteredAbsents[index];
                  return _buildAbsentCard(absent, screenWidth);
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

  Widget _buildAbsentCard(Absent absent, double screenWidth) {
    final isSmallScreen = screenWidth < 360;
    final reasonColor = _getReasonColor(absent.reason);

    // ADD DEBUG LOGGING
    print('=== DEBUG: Building card for ${absent.employeeName} ===');
    print('Image URL: ${absent.imageUrl}');
    print('Has image URL: ${absent.imageUrl != null}');
    print('Image URL not empty: ${absent.imageUrl?.isNotEmpty ?? false}');

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
          color: reasonColor.withOpacity(0.2),
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
                    gradient: absent.imageUrl != null && absent.imageUrl!.isNotEmpty
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
                        color: reasonColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: absent.imageUrl != null && absent.imageUrl!.isNotEmpty
                        ? Image.network(
                      absent.imageUrl!,
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
                        print('Image load error for ${absent.employeeName}: $error');
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
                              absent.employeeName.substring(0, 1).toUpperCase(),
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
                        absent.employeeName.substring(0, 1).toUpperCase(),
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
                      color: reasonColor,
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
                          absent.employeeName,
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
                          color: reasonColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                        ),
                        child: Text(
                          'Absent',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: reasonColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    absent.empId,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),

                  // Absent Details
                  Row(
                    children: [
                      // Department
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Department',
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
                                absent.departmentName,
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

                      // Designation
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Designation',
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
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                              ),
                              child: Text(
                                absent.designation ?? 'Not Specified',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: isSmallScreen ? 6 : 8),

                      // Absent Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Absent Date',
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
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                              ),
                              child: Text(
                                _formatDateTime(absent.absentDate),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Reason
                  if (absent.reason != null && absent.reason!.isNotEmpty) ...[
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
                                Iconsax.info_circle,
                                size: isSmallScreen ? 10 : 12,
                                color: reasonColor,
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 6),
                              Flexible(
                                child: Text(
                                  'Reason: ${absent.reason!}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
            widget.selectedDate != null
                ? 'Loading absents for ${_formatDate(_targetDate)}...'
                : 'Loading all absents...',
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

  Widget _buildErrorScreen(AbsentProvider provider, double screenWidth) {
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
              onPressed: () => provider.fetchAbsents(date: widget.selectedDate),
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
              widget.selectedDate != null
                  ? 'No Absent Employees'
                  : 'No Absent Records',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 16 : 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth < 360 ? 6 : 8),
            Text(
              widget.selectedDate != null
                  ? 'No employees were absent on ${_formatDate(_targetDate)}'
                  : 'No absent records found',
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
                final provider = Provider.of<AbsentProvider>(context, listen: false);
                provider.fetchAbsents(date: widget.selectedDate);
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