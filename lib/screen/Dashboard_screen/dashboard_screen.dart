import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payroll_app/screen/Dashboard_screen/today_attandance/today_attandnace.dart';
import 'package:payroll_app/screen/Dashboard_screen/tottal_staff/staff_details_screen.dart';
import 'package:payroll_app/screen/attendance/attendance_screen.dart';
import 'package:payroll_app/screen/salery/salary.dart';
import 'package:payroll_app/screen/settings/settings.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../model/dashboar_model/dashboard_summary.dart';
import '../../provider/Auth_provider/Auth_provider.dart';
import '../../provider/chart_provider/chart_provider.dart';
import '../../provider/dashboard_provider/dashboard_summary_provider.dart';
import '../../provider/permissions_provider/permissions.dart';
import '../../widget/dashboard_chart/dashborad_chart.dart';
import '../Approve_Leave/ApproveLeaveScreen.dart';
import '../salary_sheet/salary_sheet.dart';
import '../salary_slip/salary_slip.dart';
import 'absents_screen/absents_screen.dart';
import 'on_leave/on_leave.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isInitialized = false;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await DashboardSummaryProvider.initializeSharedPreferences();

    setState(() {
      _isInitialized = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = context.read<DashboardSummaryProvider>();
      final authProvider = context.read<AuthProvider>();
      final chartProvider = context.read<ChartProvider>();

      if (authProvider.token != null) {
        // Fetch data for the current date (today)
        dashboardProvider.fetchDashboardSummary(date: _dateController.text);
        chartProvider.fetchAttendanceData();
      }
    });
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

      // Fetch data for selected date
      final dashboardProvider = context.read<DashboardSummaryProvider>();
      dashboardProvider.fetchDashboardSummary(date: _dateController.text);
    }
  }

  void _showAllTimeData() {
    setState(() {
      _selectedDate = null;
      _dateController.text = 'All Time';
    });

    final dashboardProvider = context.read<DashboardSummaryProvider>();
    dashboardProvider.fetchDashboardSummary(date: null);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF667EEA)),
          ),
        ),
      );
    }

    final p = context.watch<PermissionProvider>();
    final Size size = MediaQuery.of(context).size;
    final screens = _getScreens(p);

    // Ensure currentIndex is within bounds
    if (_currentIndex >= screens.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = 0;
        });
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: _getAppBarTitle(_currentIndex),
        centerTitle: true,
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
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Iconsax.refresh, color: Colors.white),
              onPressed: () {
                final dashboardProvider = context.read<DashboardSummaryProvider>();
                final chartProvider = context.read<ChartProvider>();

                // Refresh with current date filter
                dashboardProvider.refreshDashboardData(
                  date: _dateController.text == 'All Time' ? null : _dateController.text,
                );
                chartProvider.fetchAttendanceData();
              },
            ),
        ],
      ),

      drawer: SidebarDrawer(
        permissionProvider: p,
        selectedIndex: _currentIndex,
        onMenuSelected: (index) {
          // Ensure index is within bounds
          if (index < screens.length) {
            setState(() {
              _currentIndex = index;
            });
          } else {
            // If index is out of bounds, go to dashboard
            setState(() {
              _currentIndex = 0;
            });
          }
          if (MediaQuery.of(context).size.width < 768) {
            Navigator.of(context).pop();
          }
        },
        onLogout: _handleLogout,
        getScreenIndexForItem: (itemTitle) => _getScreenIndexForItem(itemTitle, p),
      ),

      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0,
        children: screens,
      ),

      bottomNavigationBar: _buildBottomNavigationBar(p),
    );
  }

  Widget _getAppBarTitle(int index) {
    final screens = _getScreens(context.read<PermissionProvider>());

    if (index < screens.length) {
      Widget screen = screens[index];

      if (screen is SettingsScreen) {
        return const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screen is AttendanceScreen) {
        return const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screen is ApproveLeaveScreen) {
        return const Text(
          'Leave Approval',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screen is SalaryScreen) {
        return const Text(
          'Salary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screen is SalarySlipScreen) {
        return const Text(
          'Salary Slip',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screen is SalarySheetScreen) {
        return const Text(
          'Salary Sheet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
    }

    // Default to Dashboard title
    return const Text(
      'Dashboard',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
  List<Widget> _getScreens(PermissionProvider p) {
    List<Widget> screens = [];

    // 0 - Dashboard (always first)
    screens.add(_buildHomeScreen());

    // 1 - Attendance
    if (p.hasPermission('can-view-attendence')) {
      screens.add(const AttendanceScreen());
    }

    // 2 - Leave Approval
    if (p.hasPermission('can-edit-leave-application')) {
      screens.add(const ApproveLeaveScreen());
    }

    // 3 - Salary Slip
    screens.add(const SalarySlipScreen());

    // 4 - Salary Sheet
    screens.add(const SalarySheetScreen());

    // 5 - Old Salary Screen
    if (p.hasPermission('can-view-salary')) {
      screens.add(const SalaryScreen());
    }

    // 6 - Settings (always last)
    screens.add(const SettingsScreen());

    // Debug output
    print('=== SCREENS LIST ===');
    print('Total screens: ${screens.length}');
    for (int i = 0; i < screens.length; i++) {
      String screenName = screens[i].runtimeType.toString();
      print('Screen $i: $screenName');
    }

    return screens;
  }
  // Helper method to get screen index based on item title
  int _getScreenIndexForItem(String itemTitle, PermissionProvider p) {
    final screens = _getScreens(p);

    // Map titles to their indices
    final Map<String, int> titleToIndex = {};

    for (int i = 0; i < screens.length; i++) {
      if (i == 0) {
        titleToIndex['Dashboard'] = i;
      } else if (screens[i] is AttendanceScreen) {
        titleToIndex['Staff Attendance'] = i;
      } else if (screens[i] is ApproveLeaveScreen) {
        titleToIndex['Approve Leave'] = i;
      } else if (screens[i] is SalarySlipScreen) {
        titleToIndex['Salary Slip'] = i;
      } else if (screens[i] is SalarySheetScreen) {
        titleToIndex['Salary Sheet'] = i;
      } else if (screens[i] is SalaryScreen) {
        titleToIndex['Salary'] = i;
      } else if (screens[i] is SettingsScreen) {
        titleToIndex['Settings'] = i;
      }
    }

    // Return the index or 0 (Dashboard) if not found
    return titleToIndex[itemTitle] ?? 0;
  }

  int _getBottomNavIndex(int screenIndex, PermissionProvider p) {
    // If it's the dashboard (screen 0), return bottom nav index 0
    if (screenIndex == 0) return 0;

    int bottomNavIndex = 1;
    int currentScreenIndex = 1;

    // 1. Attendance
    if (p.hasPermission('can-view-attendence')) {
      if (currentScreenIndex == screenIndex) return bottomNavIndex;
      currentScreenIndex++;
      bottomNavIndex++;
    }

    // 2. Leave Approval
    if (p.hasPermission('can-edit-leave-application')) {
      if (currentScreenIndex == screenIndex) return bottomNavIndex;
      currentScreenIndex++;
      bottomNavIndex++;
    }

    // 3. Salary Slip - NOT in bottom nav (skip)
    if (currentScreenIndex == screenIndex) return 0; // Go to home since not in bottom nav
    currentScreenIndex++;

    // 4. Salary Sheet - NOT in bottom nav (skip)
    if (currentScreenIndex == screenIndex) return 0; // Go to home since not in bottom nav
    currentScreenIndex++;

    // 5. Salary (Old Salary Screen) - in bottom nav (only if has permission)
    if (p.hasPermission('can-view-salary')) {
      if (currentScreenIndex == screenIndex) return bottomNavIndex;
      currentScreenIndex++;
      bottomNavIndex++;
    }

    // 6. Settings - Always in bottom nav
    if (currentScreenIndex == screenIndex) return bottomNavIndex;

    return 0;
  }

  int _getScreenIndex(int bottomNavIndex, PermissionProvider p) {
    // If bottom nav index is 0, return screen index 0 (Dashboard)
    if (bottomNavIndex == 0) return 0;

    int screenIndex = 1;
    int currentBottomNavIndex = 1;

    // 1. Attendance
    if (p.hasPermission('can-view-attendence')) {
      if (currentBottomNavIndex == bottomNavIndex) return screenIndex;
      screenIndex++;
      currentBottomNavIndex++;
    }

    // 2. Leave Approval
    if (p.hasPermission('can-edit-leave-application')) {
      if (currentBottomNavIndex == bottomNavIndex) return screenIndex;
      screenIndex++;
      currentBottomNavIndex++;
    }

    // 3. Salary Slip - NOT in bottom nav (skip - screenIndex increases)
    screenIndex++;

    // 4. Salary Sheet - NOT in bottom nav (skip - screenIndex increases)
    screenIndex++;

    // 5. Salary (Old Salary Screen)
    if (p.hasPermission('can-view-salary')) {
      if (currentBottomNavIndex == bottomNavIndex) return screenIndex;
      screenIndex++;
      currentBottomNavIndex++;
    }

    // 6. Settings
    if (currentBottomNavIndex == bottomNavIndex) return screenIndex;

    return 0;
  }

  Widget _buildBottomNavigationBar(PermissionProvider p) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Iconsax.home, size: 22),
        label: 'Home',
      ),
    ];

    // Add attendance item if permission exists
    if (p.hasPermission('can-view-attendence')) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.finger_cricle, size: 22),
          label: 'Attendance',
        ),
      );
    }

    // Add leave approval item if permission exists
    if (p.hasPermission('can-edit-leave-application')) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.calendar_tick, size: 22),
          label: 'Leave',
        ),
      );
    }

    // Add salary item if permission exists (old salary screen)
    if (p.hasPermission('can-view-salary')) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.wallet_money, size: 22),
          label: 'Salary',
        ),
      );
    }

    // Always add settings
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Iconsax.setting, size: 22),
        label: 'Settings',
      ),
    );

    // Get current bottom nav index based on current screen index
    int currentBottomNavIndex = _getBottomNavIndex(_currentIndex, p);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BottomNavigationBar(
          currentIndex: currentBottomNavIndex,
          onTap: (bottomNavIndex) {
            final screenIndex = _getScreenIndex(bottomNavIndex, p);
            setState(() => _currentIndex = screenIndex);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
          elevation: 0,
          items: items,
        ),
      ),
    );
  }
  Widget _buildHomeScreen() {
    final Size size = MediaQuery.of(context).size;
    final p = context.read<PermissionProvider>();
    final dashboardProvider = context.watch<DashboardSummaryProvider>();
    final chartProvider = context.watch<ChartProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await dashboardProvider.refreshDashboardData(
          date: _dateController.text == 'All Time' ? null : _dateController.text,
        );
        await chartProvider.fetchAttendanceData();
      },
      color: const Color(0xFF667EEA),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Welcome Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ),
                    ),
                    child: const Icon(
                      Iconsax.profile_circle,
                      color: Color(0xFF667EEA),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),

            // Date Filter Widget
            _buildDateFilter(dashboardProvider),

            // Statistics Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: dashboardProvider.isLoading && !dashboardProvider.isRefreshing
                  ? _buildLoadingCards()
                  : dashboardProvider.error != null
                  ? _buildErrorWidget(dashboardProvider)
                  : _buildStatsGrid(dashboardProvider, size),
            ),

            const SizedBox(height: 24),

            // Additional Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // child: _buildAdditionalStats(dashboardProvider, size),
            ),

            const SizedBox(height: 24),

            // Attendance Chart Section
            _buildAttendanceChartSection(chartProvider),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(DashboardSummaryProvider provider) {
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
            onPressed: _showAllTimeData,
            style: TextButton.styleFrom(
              backgroundColor: _dateController.text == 'All Time'
                  ? const Color(0xFF667EEA).withOpacity(0.1)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _dateController.text == 'All Time'
                      ? const Color(0xFF667EEA)
                      : Colors.grey[300]!,
                ),
              ),
            ),
            child: Text(
              'All Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _dateController.text == 'All Time'
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _dateController.text == 'All Time'
                    ? const Color(0xFF667EEA)
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: List.generate(4, (index) => _buildLoadingCard()),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(DashboardSummaryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 20),
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
      child: Column(
        children: [
          const Icon(Iconsax.warning_2, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Failed to load dashboard data',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => provider.fetchDashboardSummary(
                  date: _dateController.text == 'All Time'
                      ? null
                      : _dateController.text,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.refresh, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Retry', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  provider.clearData();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardSummaryProvider provider, Size size) {
    final summary = provider.currentSummary;

    if (summary == null) {
      return _buildNoDataWidget();
    }

    // Get the actual date from the summary model
    String actualDate = summary.selectedDate;

    // Format the date for display
    String displayDateText = 'All Time';
    bool isDateSpecific = false;

    if (actualDate != 'all' && actualDate != 'All Time') {
      try {
        final parsedDate = DateTime.parse(actualDate);
        displayDateText = DateFormat('dd MMM yyyy').format(parsedDate);
        isDateSpecific = true;
      } catch (e) {
        displayDateText = actualDate;
        isDateSpecific = actualDate != 'all';
      }
    }

    // Create title suffix
    String dateSuffix = isDateSpecific ? '\n$displayDateText' : '\nAll Time';

    // Check if this is a date with no attendance data yet (all zeros)
    final isNoDataYet = summary.isNoDataForDate;

    return Column(
      children: [
        // Show a message if no attendance data yet for this date
        if (isNoDataYet && isDateSpecific)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle,
                    color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No attendance data marked yet for $displayDateText',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.totalEmployees} employees - Attendance not recorded',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Statistics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            // Total Staff Card - ALWAYS show this, even if no data yet
            _buildClickableStatCard(
              icon: Iconsax.people,
              title: 'Total Staff$dateSuffix',
              value: '${summary.totalEmployees}',
              subtitle: 'All Employees', // Always show this subtitle
              color: const Color(0xFF4CAF50), // Always green for total staff
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffDetailsScreen(
                      title: 'Total Staff',
                      filterType: 'all',
                      selectedDate: isDateSpecific ? actualDate : null,
                    ),
                  ),
                );
              },
            ),

            // Present Card
            _buildClickableStatCard(
              icon: Iconsax.calendar_tick,
              title: isDateSpecific
                  ? 'Attendance$dateSuffix'
                  : 'Today Attendance$dateSuffix',
              value: '${summary.presentCount}',
              subtitle: isNoDataYet
                  ? 'Not marked yet'
                  : '${summary.presentPercentage.toStringAsFixed(1)}%',
              color: isNoDataYet ? Colors.grey : const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodayAttendance(
                      selectedDate: isDateSpecific ? actualDate : null,
                    ),
                  ),
                );
              },
            ),

            // Leave Card
            _buildClickableStatCard(
              icon: Iconsax.calendar_remove,
              title: 'On Leave$dateSuffix',
              value: '${summary.leaveCount}',
              subtitle: isNoDataYet
                  ? 'Not marked yet'
                  : '${summary.leavePercentage.toStringAsFixed(1)}%',
              color: isNoDataYet ? Colors.grey : const Color(0xFFFF9800),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaveListScreen(
                      selectedDate: isDateSpecific ? actualDate : null,
                    ),
                  ),
                );
              },
            ),

            // Absent Card
            _buildClickableStatCard(
              icon: Iconsax.calendar_remove,
              title: 'Absent$dateSuffix',
              value: '${summary.absentCount}',
              subtitle: isNoDataYet
                  ? 'Not marked yet'
                  : '${summary.absentPercentage.toStringAsFixed(1)}%',
              color: isNoDataYet ? Colors.grey : const Color(0xFFF44336),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AbsentListScreen(
                      selectedDate: isDateSpecific ? actualDate : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClickableStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor:
        isDisabled ? Colors.transparent : color.withOpacity(0.1),
        child: Container(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                  isDisabled ? Colors.grey[200] : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDisabled ? Colors.grey[400] : color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDisabled ? Colors.grey[600] : Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDisabled ? Colors.grey[500] : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDisabled ? Colors.grey[500] : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableDetailStatCard({
    required IconData icon,
    required String title,
    required String value,
    required double percentage,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        child: Container(
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 20),
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
      child: Column(
        children: [
          Icon(Iconsax.document, color: Colors.grey[400], size: 48),
          const SizedBox(height: 16),
          const Text(
            'No dashboard data available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull down to refresh or click the button below',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChartSection(ChartProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          margin:
          EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 20 : 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    provider.isAdmin ? Iconsax.chart_square : Iconsax.chart_2,
                    color: const Color(0xFF667EEA),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.isAdmin ? 'Team Attendance' : 'My Attendance',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (!provider.isLoading)
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: provider.isLoading
                            ? Colors.grey
                            : const Color(0xFF667EEA),
                        size: 18,
                      ),
                      onPressed: provider.isLoading
                          ? null
                          : () {
                        provider.fetchAttendanceData();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (provider.isLoading)
          _buildChartLoading(screenWidth)
        else if (provider.error != null)
          _buildChartError(provider, screenWidth)
        else
          _buildChartWidget(provider, screenWidth),
      ],
    );
  }

  Widget _buildChartLoading(double screenWidth) {
    return Container(
      height: screenWidth > 600 ? 350 : 300,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 20 : 16,
      ),
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF667EEA)),
            SizedBox(height: 16),
            Text('Loading chart data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildChartError(ChartProvider provider, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 20 : 16,
      ),
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
      child: Column(
        children: [
          const Icon(Iconsax.warning_2, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.fetchAttendanceData(),
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
    );
  }

  Widget _buildChartWidget(ChartProvider provider, double screenWidth) {
    return ChartWidget(
      chartData: provider.chartData,
      chartTitle: provider.isAdmin
          ? 'Team Attendance Overview'
          : 'My Attendance Overview',
      chartHeight: screenWidth > 600 ? 350 : 300,
      presentColor: const Color(0xFF4CAF50),
      absentColor: const Color(0xFFF44336),
      lateColor: const Color(0xFFFF9800),
      showLegend: true,
      showGridLines: true,
    );
  }

  // Correct logout handler method
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667EEA),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final auth =
                Provider.of<AuthProvider>(context, listen: false);
                final dashboardProvider =
                Provider.of<DashboardSummaryProvider>(context,
                    listen: false);

                Navigator.of(dialogContext).pop();

                await auth.logout();
                await dashboardProvider.logout();

                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SidebarDrawer extends StatelessWidget {
  final PermissionProvider permissionProvider;
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final Function(BuildContext) onLogout;
  final Function(String) getScreenIndexForItem;
  final Function? onDrawerClose;

  const SidebarDrawer({
    super.key,
    required this.permissionProvider,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.onLogout,
    required this.getScreenIndexForItem,
    this.onDrawerClose,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: true);

    // Check if user is admin
    final isAdmin = permissionProvider.hasPermission('can-view-salary-sheet') ||
        permissionProvider.userRole.toLowerCase().contains('admin');

    // Define all menu items that could appear in drawer
    final List<Map<String, dynamic>> allMenuItems = [
      {
        'icon': Iconsax.dcube,
        'title': 'Dashboard',
        'permission': 'can-view-dashboard',
        'requiresPermission': true,
      },
      {
        'icon': Iconsax.finger_cricle,
        'title': 'Staff Attendance',
        'permission': 'can-view-attendence',
        'requiresPermission': true,
      },
      {
        'icon': Iconsax.tick_circle,
        'title': 'Approve Leave',
        'permission': 'can-edit-leave-application',
        'requiresPermission': true,
      },
      {
        'icon': Iconsax.document_text,
        'title': 'Salary Slip',
        'permission': 'can-view-salary-slip',
        'requiresPermission': true,
        'description': 'View your salary slips',
      },
      {
        'icon': Iconsax.document_copy,
        'title': 'Salary Sheet',
        'permission': 'can-view-salary-sheet',
        'requiresPermission': true,
        'isAdminOnly': true,
        'description': 'Admin: View all salary data',
      },
      {
        'icon': Iconsax.wallet_money,
        'title': 'Salary',
        'permission': 'can-view-salary',
        'requiresPermission': true,
      },
      {
        'icon': Iconsax.setting,
        'title': 'Settings',
        'permission': 'always-available',
        'requiresPermission': false,
      },
      {
        'icon': Iconsax.logout,
        'title': 'Logout',
        'permission': 'can-logout',
        'isLogout': true,
        'requiresPermission': false,
      },
    ];

    // Filter menu items based on permissions
    List<Map<String, dynamic>> menuItems = [];

    for (var item in allMenuItems) {
      if (item['isLogout'] == true) {
        menuItems.add(item);
        continue;
      }

      if (!item['requiresPermission']) {
        menuItems.add(item);
        continue;
      }

      if (item['title'] == 'Salary Sheet') {
        // Show Salary Sheet only for admin users
        if (isAdmin) {
          menuItems.add(item);
        }
        continue;
      }

      if (item['title'] == 'Salary Slip') {
        // Show Salary Slip for all users (assuming can-view-salary-slip is given to all)
        menuItems.add(item);
        continue;
      }

      if (permissionProvider.hasPermission(item['permission'])) {
        menuItems.add(item);
      }
    }

    return Drawer(
      width: 280,
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Iconsax.dcube,
                        color: Color(0xFF667EEA),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Afaq MIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'HR Management System',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  children: [
                    ...menuItems.map((item) {
                      if (item['isLogout'] == true) {
                        return _drawerItem(
                          icon: item['icon'],
                          title: item['title'],
                          hasPermission: true,
                          onTap: () => onLogout(context),
                          isSelected: false,
                          isLogout: true,
                          description: item['description'],
                          isAdminOnly: item['isAdminOnly'] == true,
                        );
                      }

                      // Use the provided function to get the correct index
                      final screenIndex = getScreenIndexForItem(item['title']);
                      final isSelected = selectedIndex == screenIndex;

                      return _drawerItem(
                        icon: item['icon'],
                        title: item['title'],
                        hasPermission: true,
                        onTap: () {
                          onMenuSelected(screenIndex);
                          if (onDrawerClose != null) onDrawerClose!();
                        },
                        isSelected: isSelected,
                        description: item['description'],
                        isAdminOnly: item['isAdminOnly'] == true,
                      );
                    }).toList(),
                  ],
                ),
              ),

              // User Profile Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border:
                  Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 2),
                        gradient: const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.profile_circle,
                        color: Color(0xFF667EEA),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName.isNotEmpty ? auth.userName : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.userEmail.isNotEmpty
                                ? auth.userEmail
                                : 'user@company.com',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAdmin ? Colors.green : Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isAdmin ? 'Admin' : 'Staff',
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.green[100]
                                    : Colors.blue[100],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required bool hasPermission,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLogout = false,
    String? description,
    bool isAdminOnly = false,
  }) {
    if (!hasPermission) return const SizedBox.shrink();

    Color iconColor;
    Color bgColor;
    Color borderColor;

    if (isLogout) {
      iconColor = Colors.white;
      bgColor = Colors.red.withOpacity(0.8);
      borderColor = Colors.red.withOpacity(0.4);
    } else if (isSelected) {
      iconColor = Colors.white;
      bgColor = Colors.white.withOpacity(0.3);
      borderColor = Colors.white.withOpacity(0.6);
    } else {
      iconColor = Colors.white70;
      bgColor = Colors.white.withOpacity(0.1);
      borderColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: isSelected || isLogout
            ? [
          BoxShadow(
            color: (isLogout ? Colors.red : Colors.white)
                .withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isLogout
              ? Colors.red.withOpacity(0.1)
              : Colors.white.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLogout
                        ? Colors.red.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLogout
                          ? Colors.red.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      if (isAdminOnly && !isLogout)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 15,
                          fontWeight: isSelected || isLogout
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      if (description != null && !isLogout) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            color: iconColor.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (isAdminOnly && !isLogout) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.green[100],
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected && !isLogout)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                if (isLogout)
                  const Icon(
                    Iconsax.arrow_right_3,
                    color: Colors.white70,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient? gradient;
  final VoidCallback onTap;

  const PermissionCard({
    super.key,
    required this.title,
    required this.icon,
    this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ??
                const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (gradient?.colors.first ?? const Color(0xFF667EEA))
                    .withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'View Details',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}