import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payroll_app/screen/attendance/attendance_screen.dart';
import 'package:payroll_app/screen/salery/salary.dart';
import 'package:payroll_app/screen/settings/settings.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../provider/Auth_provider/Auth_provider.dart';
import '../../provider/chart_provider/chart_provider.dart';
import '../../provider/dashboard_provider/dashboard_summary_provider.dart';
import '../../provider/permissions_provider/permissions.dart';
import '../../widget/dashboard_chart/dashborad_chart.dart';
import '../Approve_Leave/ApproveLeaveScreen.dart';
// import '../../widgets/chart_widget.dart'; // Added import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize SharedPreferences globally before anything else
    await DashboardSummaryProvider.initializeSharedPreferences();

    setState(() {
      _isInitialized = true;
    });

    // Fetch dashboard data after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = context.read<DashboardSummaryProvider>();
      final authProvider = context.read<AuthProvider>();
      final chartProvider = context.read<ChartProvider>(); // Fixed: Use ChartProvider

      // Only fetch if user is authenticated
      if (authProvider.token != null) {
        dashboardProvider.fetchDashboardSummary();
        chartProvider.fetchAttendanceData(); // Fetch attendance chart data
      }
    });
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
                final chartProvider = context.read<ChartProvider>(); // Fixed: Use ChartProvider
                dashboardProvider.refreshDashboardData();
                chartProvider.fetchAttendanceData(month: chartProvider.selectedMonth);
              },
            ),
        ],
      ),

      /// 📌 SIDEBAR DRAWER
      drawer: SidebarDrawer(
        permissionProvider: p,
        selectedIndex: _currentIndex,
        onMenuSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (MediaQuery.of(context).size.width < 768) {
            Navigator.of(context).pop();
          }
        },
      ),

      /// 🏠 BODY (GRID DASHBOARD)
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(p),
      ),

      /// 🔻 BOTTOM NAVIGATION BAR
      bottomNavigationBar: _buildBottomNavigationBar(p),
    );
  }

  // Helper method to get app bar title based on current index
  Widget _getAppBarTitle(int index) {
    final screens = _getScreens(context.read<PermissionProvider>());

    if (index < screens.length) {
      if (screens[index] is SettingsScreen) {
        return const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screens[index] is AttendanceScreen) {
        return const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screens[index] is ApproveLeaveScreen) {
        return const Text(
          'Leave Approval',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
      if (screens[index] is SalaryScreen) {
        return const Text(
          'Salary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
    }

    // Default to Dashboard
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

    // Screen 0: Dashboard/Home (Always available)
    screens.add(_buildHomeScreen());

    // Screen 1: Attendance (check permission)
    if (p.hasPermission('can-view-attendence')) {
      screens.add(const AttendanceScreen());
    }

    // Screen 2: Leave Approval (check permission)
    if (p.hasPermission('can-edit-leave-application')) {
      screens.add(const ApproveLeaveScreen());
    }

    // Screen 3: Salary (check permission)
    if (p.hasPermission('can-view-salary')) {
      screens.add(const SalaryScreen());
    }

    // Screen 4: Settings (Always available - LAST ITEM)
    screens.add(const SettingsScreen());

    return screens;
  }

  // Get the bottom navigation index from screen index
  int _getBottomNavIndex(int screenIndex, PermissionProvider p) {
    if (screenIndex == 0) return 0; // Dashboard is always first

    int bottomNavIndex = 1;
    int currentScreenIndex = 1;

    // Check each possible screen in order
    if (p.hasPermission('can-view-attendence')) {
      if (currentScreenIndex == screenIndex) return bottomNavIndex;
      currentScreenIndex++;
      bottomNavIndex++;
    }

    if (p.hasPermission('can-edit-leave-application')) {
      if (currentScreenIndex == screenIndex) return bottomNavIndex;
      currentScreenIndex++;
      bottomNavIndex++;
    }

    if (p.hasPermission('can-view-salary')) {
      if (currentScreenIndex == screenIndex) return bottomNavIndex;
      currentScreenIndex++;
      bottomNavIndex++;
    }

    // Settings (always last)
    if (currentScreenIndex == screenIndex) return bottomNavIndex;

    return 0; // Default to Dashboard
  }

  // Get the screen index from bottom navigation index
  int _getScreenIndex(int bottomNavIndex, PermissionProvider p) {
    if (bottomNavIndex == 0) return 0; // Dashboard

    int screenIndex = 1;
    int currentBottomNavIndex = 1;

    // Attendance
    if (p.hasPermission('can-view-attendence')) {
      if (currentBottomNavIndex == bottomNavIndex) return screenIndex;
      screenIndex++;
      currentBottomNavIndex++;
    }

    // Leave
    if (p.hasPermission('can-edit-leave-application')) {
      if (currentBottomNavIndex == bottomNavIndex) return screenIndex;
      screenIndex++;
      currentBottomNavIndex++;
    }

    // Salary
    if (p.hasPermission('can-view-salary')) {
      if (currentBottomNavIndex == bottomNavIndex) return screenIndex;
      screenIndex++;
      currentBottomNavIndex++;
    }

    // Settings (always last)
    if (currentBottomNavIndex == bottomNavIndex) return screenIndex;

    return 0; // Default to Dashboard
  }

  Widget _buildBottomNavigationBar(PermissionProvider p) {
    // Create bottom navigation items based on permissions
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Iconsax.home, size: 22),
        label: 'Home',
      ),
    ];

    if (p.hasPermission('can-view-attendence')) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.finger_cricle, size: 22),
          label: 'Attendance',
        ),
      );
    }

    if (p.hasPermission('can-edit-leave-application')) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.calendar_tick, size: 22),
          label: 'Leave',
        ),
      );
    }

    if (p.hasPermission('can-view-salary')) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.wallet_money, size: 22),
          label: 'Salary',
        ),
      );
    }

    // Always add Settings as LAST item
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Iconsax.setting, size: 22),
        label: 'Settings',
      ),
    );

    // Get current bottom nav index
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
    final chartProvider = context.watch<ChartProvider>(); // Fixed: Use ChartProvider

    return RefreshIndicator(
      onRefresh: () async {
        await dashboardProvider.refreshDashboardData();
        await chartProvider.fetchAttendanceData(month: chartProvider.selectedMonth);
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
                          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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

            // Month Filter
            _buildMonthFilter(dashboardProvider),

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

            // Additional Stats Cards (Short Leave & Late Comers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAdditionalStats(dashboardProvider, size),
            ),

            const SizedBox(height: 24),

            // 🔥 ATTENDANCE CHART SECTION 🔥
            _buildAttendanceChartSection(chartProvider), // Fixed: Pass ChartProvider

            const SizedBox(height: 24),

            // Quick Access Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 16),
                    child: Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      if (p.hasPermission('can-view-attendence'))
                        PermissionCard(
                          title: 'Attendance',
                          icon: Iconsax.finger_cricle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          ),
                          onTap: () => setState(() => _currentIndex = _getScreenIndex(1, p)),
                        ),

                      if (p.hasPermission('can-edit-leave-application'))
                        PermissionCard(
                          title: 'Leave',
                          icon: Iconsax.calendar_edit,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                          ),
                          onTap: () => setState(() => _currentIndex = _getScreenIndex(2, p)),
                        ),

                      if (p.hasPermission('can-view-salary'))
                        PermissionCard(
                          title: 'Salary',
                          icon: Iconsax.wallet_money,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                          ),
                          onTap: () => setState(() => _currentIndex = _getScreenIndex(3, p)),
                        ),

                      // Analytics Card
                      PermissionCard(
                        title: 'Analytics',
                        icon: Iconsax.chart,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        onTap: () => _showAnalyticsOptionsDialog(chartProvider), // Fixed: Pass ChartProvider
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Month Filter Widget
  Widget _buildMonthFilter(DashboardSummaryProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
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
                    'Statistics Period',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.selectedMonth == 'all' ? 'All Time' : 'Month: ${provider.selectedMonth}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Iconsax.filter,
                color: Color(0xFF667EEA),
                size: 20,
              ),
              onPressed: () {
                _showMonthSelectionDialog(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Loading State
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

  // Error State
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
                onPressed: () => provider.fetchDashboardSummary(),
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

  // Stats Grid with Real Data
  Widget _buildStatsGrid(DashboardSummaryProvider provider, Size size) {
    final summary = provider.currentSummary ?? provider.dashboardSummary;

    if (summary == null) {
      return _buildNoDataWidget();
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: size.width > 600 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          icon: Iconsax.people,
          title: 'Total Staff',
          value: '${summary.totalEmployees}',
          color: const Color(0xFF4CAF50),
          iconColor: Colors.white,
        ),
        _buildStatCard(
          icon: Iconsax.calendar_tick,
          title: 'Present',
          value: '${summary.presentCount}',
          subtitle: '${summary.presentPercentage.toStringAsFixed(1)}%',
          color: const Color(0xFF2196F3),
          iconColor: Colors.white,
        ),
        _buildStatCard(
          icon: Iconsax.calendar_remove,
          title: 'On Leave',
          value: '${summary.leaveCount}',
          subtitle: '${summary.leavePercentage.toStringAsFixed(1)}%',
          color: const Color(0xFFFF9800),
          iconColor: Colors.white,
        ),
        _buildStatCard(
          icon: Iconsax.calendar_search,
          title: 'Absent',
          value: '${summary.absentCount}',
          subtitle: '${summary.absentPercentage.toStringAsFixed(1)}%',
          color: const Color(0xFFF44336),
          iconColor: Colors.white,
        ),
      ],
    );
  }

  // Additional Stats Cards
  Widget _buildAdditionalStats(DashboardSummaryProvider provider, Size size) {
    final summary = provider.currentSummary ?? provider.dashboardSummary;

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: size.width > 600 ? 2 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildDetailStatCard(
          icon: Iconsax.clock,
          title: 'Short Leave',
          value: '${summary.shortLeaveCount}',
          percentage: summary.shortLeavePercentage,
          color: const Color(0xFF9C27B0),
        ),
        _buildDetailStatCard(
          icon: Iconsax.timer_1,
          title: 'Late Come',
          value: '${summary.lateComersCount}',
          percentage: summary.lateComersPercentage,
          color: const Color(0xFF795548),
        ),
      ],
    );
  }

  Widget _buildDetailStatCard({
    required IconData icon,
    required String title,
    required String value,
    required double percentage,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 40,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ],
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

  // Update _buildStatCard to include optional subtitle
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    required Color iconColor,
  }) {
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChartSection(ChartProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 300;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

    return Column(
      children: [
        // Chart Header - RESPONSIVE VERSION
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? 20 : 16,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 10 : 12,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Title and icon
              Row(
                children: [
                  Icon(
                    provider.isAdmin ? Iconsax.chart_square : Iconsax.chart_2,
                    color: const Color(0xFF667EEA),
                    size: isSmallScreen ? 20 : 22,
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Expanded(
                    child: Text(
                      provider.isAdmin ? 'Team Attendance' : 'My Attendance',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  // Action buttons on same row for larger screens
                  if (!isSmallScreen && !provider.isLoading)
                    _buildActionButtons(provider, isSmallScreen),
                ],
              ),

              // Second row: Month filter and stats (or actions for small screens)
              const SizedBox(height: 4),

              Row(
                children: [
                  // Month filter chip
                  if (provider.selectedMonth != null)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF667EEA),
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 6),
                            Expanded(
                              child: Text(
                                _formatChartMonth(provider.selectedMonth!),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF667EEA),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Spacer
                  if (provider.selectedMonth != null && isSmallScreen)
                    const SizedBox(width: 8),

                  // Action buttons for small screens
                  if (isSmallScreen && !provider.isLoading)
                    _buildActionButtons(provider, isSmallScreen),
                ],
              ),

              // Stats summary
              if (provider.chartData != null && provider.chartData!.data.isNotEmpty)
                const SizedBox(height: 1),
              // if (provider.chartData != null && provider.chartData!.data.isNotEmpty)
              //   _buildChartSummary(provider, isSmallScreen),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chart Content
        if (provider.isLoading)
          _buildChartLoading(screenWidth)
        else if (provider.error != null)
          _buildChartError(provider, screenWidth)
        else
          _buildChartWidget(provider, screenWidth),
      ],
    );
  }

// Helper: Action buttons
  Widget _buildActionButtons(ChartProvider provider, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: provider.isLoading ? Colors.grey : const Color(0xFF667EEA),
            size: isSmallScreen ? 16 : 18,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          onPressed: provider.isLoading ? null : () {
            provider.fetchAttendanceData(
              month: provider.selectedMonth,
              context: context,
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: const Color(0xFF667EEA),
            size: isSmallScreen ? 16 : 18,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          onPressed: () => _showChartFilterDialog(provider),
        ),
      ],
    );
  }

// Helper: Chart summary
  Widget _buildChartSummary(ChartProvider provider, bool isSmallScreen) {
    final totalPresent = provider.chartData!.totalPresent;
    final totalAbsent = provider.chartData!.totalAbsent;
    final totalLate = provider.chartData!.totalLate;
    final total = totalPresent + totalAbsent + totalLate;
    final percentage = total > 0 ? (totalPresent / total * 100) : 0;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            '$total',
            Colors.blue,
            isSmallScreen,
          ),
          _buildStatItem(
            'Present',
            '$totalPresent',
            const Color(0xFF4CAF50),
            isSmallScreen,
          ),
          _buildStatItem(
            'Absent',
            '$totalAbsent',
            const Color(0xFFF44336),
            isSmallScreen,
          ),
          _buildStatItem(
            'Late',
            '$totalLate',
            const Color(0xFFFF9800),
            isSmallScreen,
          ),
          _buildStatItem(
            'Rate',
            '${percentage.toStringAsFixed(1)}%',
            percentage >= 80 ? Colors.green : Colors.orange,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 8 : 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

// Helper: Loading state
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

// Helper: Error state
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
            onPressed: () => provider.fetchAttendanceData(
              month: provider.selectedMonth,
              context: context,
            ),
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

// Helper: Chart widget
  Widget _buildChartWidget(ChartProvider provider, double screenWidth) {
    return ChartWidget(
      chartData: provider.chartData,
      chartTitle: provider.selectedMonth == null
          ? (provider.isAdmin ? 'Team Attendance Overview' : 'My Attendance Overview')
          : '${provider.isAdmin ? 'Team' : 'My'} Attendance - ${_formatChartMonth(provider.selectedMonth!)}',
      chartHeight: screenWidth > 600 ? 350 : 300,
      presentColor: const Color(0xFF4CAF50),
      absentColor: const Color(0xFFF44336),
      lateColor: const Color(0xFFFF9800),
      showLegend: true,
      showGridLines: true,
    );
  }

// Helper: Format month
  String _formatChartMonth(String month) {
    try {
      final parts = month.split('-');
      final year = int.parse(parts[0]);
      final monthNum = int.parse(parts[1]);
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${monthNames[monthNum - 1]} $year';
    } catch (e) {
      return month;
    }
  }
  void _showChartFilterDialog(ChartProvider provider) {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    // Generate last 6 months plus current month
    final months = <String?>[null]; // null for "All Time"
    for (int i = 0; i < 6; i++) {
      final date = DateTime(currentYear, currentMonth - i);
      final monthString = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months.add(monthString);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.filter_alt, color: Color(0xFF667EEA)),
              SizedBox(width: 10),
              Text(
                'Attendance Data',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final isSelected = provider.selectedMonth == month;

                return ListTile(
                  leading: Icon(
                    month == null ? Icons.all_inclusive : Icons.calendar_month,
                    color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
                  ),
                  title: Text(
                    month == null ? 'All Time' : _formatChartMonth(month),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF667EEA) : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF667EEA), size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    provider.fetchAttendanceData(month: month);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                provider.fetchAttendanceData(month: null); // Load all time
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
              child: const Text('All Time'),
            ),
          ],
        );
      },
    );
  }

  void _showAnalyticsOptionsDialog(ChartProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Analytics Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF667EEA)),
                title: const Text('Refresh Chart Data'),
                onTap: () {
                  Navigator.pop(context);
                  provider.fetchAttendanceData(month: provider.selectedMonth);
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_list, color: Color(0xFF667EEA)),
                title: const Text('Filter by Month'),
                onTap: () {
                  Navigator.pop(context);
                  _showChartFilterDialog(provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timeline, color: Color(0xFF667EEA)),
                title: const Text('View All Time Data'),
                onTap: () {
                  Navigator.pop(context);
                  provider.fetchAttendanceData(month: null);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Month Selection Dialog
  void _showMonthSelectionDialog(DashboardSummaryProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        final currentYear = DateTime.now().year;
        final currentMonth = DateTime.now().month;

        // Generate last 12 months
        final months = <String>['all'];
        for (int i = 0; i < 12; i++) {
          final date = DateTime(currentYear, currentMonth - i);
          final monthString = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          months.add(monthString);
        }

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.calendar_1, color: Color(0xFF667EEA)),
              SizedBox(width: 12),
              Text(
                'Select Period',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final isSelected = provider.selectedMonth == month;

                return ListTile(
                  leading: Icon(
                    month == 'all' ? Iconsax.calendar : Iconsax.calendar_2,
                    color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
                  ),
                  title: Text(
                    month == 'all' ? 'All Time' : month,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF667EEA) : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Iconsax.tick_circle, color: Color(0xFF667EEA), size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (month == 'all') {
                      provider.clearMonthlySummary();
                    } else {
                      provider.fetchDashboardSummary(month: month);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// Fixed SidebarDrawer
class SidebarDrawer extends StatelessWidget {
  final PermissionProvider permissionProvider;
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final Function? onDrawerClose;

  const SidebarDrawer({
    super.key,
    required this.permissionProvider,
    required this.selectedIndex,
    required this.onMenuSelected,
    this.onDrawerClose,
  });

  // Helper method to get screen index for menu items
  int _getScreenIndex(String itemTitle) {
    // Dashboard is always index 0
    if (itemTitle == 'Dashboard') return 0;

    // Settings is always the last item
    if (itemTitle == 'Settings') {
      // Calculate based on how many screens are before Settings
      int index = 1; // Start after Dashboard

      if (permissionProvider.hasPermission('can-view-attendence')) index++;
      if (permissionProvider.hasPermission('can-edit-leave-application')) index++;
      if (permissionProvider.hasPermission('can-view-salary')) index++;

      return index; // Settings is at the calculated index
    }

    // For other menu items, we need to check if they exist and find their position
    List<String> availableScreens = ['Dashboard'];

    if (permissionProvider.hasPermission('can-view-attendence')) {
      availableScreens.add('Staff Attendance');
    }
    if (permissionProvider.hasPermission('can-edit-leave-application')) {
      availableScreens.add('Approve Leave');
    }
    if (permissionProvider.hasPermission('can-view-salary')) {
      availableScreens.add('Salary');
    }
    availableScreens.add('Settings');

    // Find the index of the item title
    return availableScreens.indexOf(itemTitle);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: true);

    // Define menu items
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Iconsax.dcube,
        'title': 'Dashboard',
        'permission': 'can-view-dashboard',
      },
      {
        'icon': Iconsax.finger_cricle,
        'title': 'Staff Attendance',
        'permission': 'can-view-attendence',
      },
      {
        'icon': Iconsax.tick_circle,
        'title': 'Approve Leave',
        'permission': 'can-edit-leave-application',
      },
      {
        'icon': Iconsax.wallet_money,
        'title': 'Salary',
        'permission': 'can-view-salary',
      },
      {
        'icon': Iconsax.setting,
        'title': 'Settings',
        'permission': 'always-available',
      },
      {
        'icon': Iconsax.logout,
        'title': 'Logout',
        'permission': 'can-logout',
        'isLogout': true,
      },
    ];

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
              // Drawer Header
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  children: [
                    ...menuItems.map((item) {
                      // For logout, show it regardless of permission
                      if (item['isLogout'] == true) {
                        return _drawerItem(
                          icon: item['icon'],
                          title: item['title'],
                          hasPermission: true,
                          onTap: () => _handleLogout(context),
                          isSelected: false,
                          isLogout: true,
                        );
                      }

                      // For Settings (always available)
                      if (item['permission'] == 'always-available') {
                        final screenIndex = _getScreenIndex(item['title']);
                        return _drawerItem(
                          icon: item['icon'],
                          title: item['title'],
                          hasPermission: true,
                          onTap: () {
                            onMenuSelected(screenIndex);
                            if (onDrawerClose != null) onDrawerClose!();
                          },
                          isSelected: selectedIndex == screenIndex,
                        );
                      }

                      // For other items, check permission
                      if (!permissionProvider.hasPermission(item['permission'])) {
                        return const SizedBox.shrink();
                      }

                      final screenIndex = _getScreenIndex(item['title']);
                      return _drawerItem(
                        icon: item['icon'],
                        title: item['title'],
                        hasPermission: true,
                        onTap: () {
                          onMenuSelected(screenIndex);
                          if (onDrawerClose != null) onDrawerClose!();
                        },
                        isSelected: selectedIndex == screenIndex,
                      );
                    }).toList(),
                  ],
                ),
              ),

              // User Profile
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
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
                            auth.userEmail.isNotEmpty ? auth.userEmail : 'user@company.com',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
            color: (isLogout ? Colors.red : Colors.white).withOpacity(0.2),
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
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 15,
                      fontWeight: isSelected || isLogout ? FontWeight.w600 : FontWeight.w500,
                    ),
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
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final dashboardProvider =
                Provider.of<DashboardSummaryProvider>(context, listen: false);

                Navigator.of(dialogContext).pop();
                if (onDrawerClose != null) onDrawerClose!();

                // Logout from both providers
                await auth.logout();
                await dashboardProvider.logout();

                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

// Permission Card Component
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