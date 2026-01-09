import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../Approve_Leave/ApproveLeaveScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedMonth = '2026-01';
  final List<String> _months = ['2010-11', '2010-12', '2025-11', '2026-01'];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white

      ),

      ),

      centerTitle: true,
      backgroundColor:Color(0xFF667EEA) ,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(theme),
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildStatisticsCards(),
                        SizedBox(height: 16),
                        _buildAttendanceChart(),
                        SizedBox(height: 16),
                        _buildMonthSelector(),
                        SizedBox(height: 16),
                        _buildLegend(),

                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),),
    );
  }
  Widget _buildStatisticsCards() {
    final cards = [
      {
        'icon': Iconsax.profile_2user,
        'title': 'Employees',
        'count': '20',
        'color': const Color(0xFF4CAF50),
        'onTap': () {}
      },
      {
        'icon': Iconsax.tick_circle,
        'title': 'Present',
        'count': '15',
        'color': const Color(0xFFF44336),
        'onTap': () {},
      },
      {
        'icon': Iconsax.calendar_remove,
        'title': 'Leaves',
        'count': '2',
        'color': const Color(0xFF2196F3),
        'onTap': () {}
      },
      {
        'icon': Iconsax.timer,
        'title': 'Short Leaves',
        'count': '1',
        'color': const Color(0xFFFF9800),
        'onTap': null,
      },
      {
        'icon': Iconsax.close_circle,
        'title': 'Absent',
        'count': '1',
        'color': const Color(0xFF00BCD4),
        'onTap': null,
      },
      {
        'icon': Iconsax.clock,
        'title': 'Late Comers',
        'count': '1',
        'color': const Color(0xFF00BCD4),
        'onTap': null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: MediaQuery.of(context).size.width > 600
              ? 1.5  // Wider screens
              : 1.3, // Normal screens (increased from 1.4 to give more height)
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return GestureDetector(
            onTap: card['onTap'] != null
                ? () => ()
                : () {
              if (card['onTap'] == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${card['title']}: Access restricted"),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // Slightly smaller radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width > 600 ? 14 : 10, // Reduced padding
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width > 600 ? 44 : 36, // Smaller icon container
                    height: MediaQuery.of(context).size.width > 600 ? 44 : 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (card['color'] as Color).withOpacity(0.15), // Reduced opacity
                          (card['color'] as Color).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      card['icon'] as IconData,
                      color: card['color'] as Color,
                      size: MediaQuery.of(context).size.width > 600 ? 20 : 16, // Smaller icons
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card['count'] as String,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2), // Minimal spacing
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card['title'] as String,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 12 : 10, // Smaller font
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildAttendanceChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBarChartColumn('Present', 15, Color(0xFF2196F3), 20),
                _buildBarChartColumn('Absent', 1, Color(0xFFF44336), 20),
                _buildBarChartColumn('Leaves', 2, Color(0xFF9C27B0), 20),
                _buildBarChartColumn('Short Leaves', 1, Color(0xFFFF9800), 20),
                _buildBarChartColumn('Late', 1, Color(0xFF00BCD4), 20),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final labels = ['Present', 'Absent', 'Leaves', 'Short\nLeaves', 'Late'];
              return SizedBox(
                width: 40,
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartColumn(String label, int value, Color color, int maxValue) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final barHeight = 160.0 * percentage; // Reduced from 180
    final isLargeValue = value > (maxValue * 0.7);

    return Expanded( // Wrap each column with Expanded
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bar with 3D effect
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Bar shadow (3D effect)
              Container(
                width: 30, // Reduced from 38
                height: barHeight + 4,
                margin: const EdgeInsets.only(right: 2), // Reduced margin
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              // Main bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                width: 34, // Reduced from 42
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isLargeValue
                        ? [
                      color.withOpacity(0.9),
                      color.withOpacity(0.7),
                      color,
                    ]
                        : [
                      color.withOpacity(0.8),
                      color.withOpacity(0.6),
                      color.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Inner shine effect
                    Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                            Colors.black.withOpacity(0.05),
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    ),

                    // Value badge (floating above for large values)
                    if (isLargeValue)
                      Positioned(
                        top: -20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            value.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9, // Reduced
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Value inside bar
                    if (!isLargeValue && barHeight > 20)
                      Center(
                        child: Transform.translate(
                          offset: const Offset(0, -1),
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: barHeight > 30 ? 10 : 8, // Responsive font
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12), // Reduced spacing

          // Modern label with progress indicator
          SizedBox(
            width: 50, // Reduced from 60
            child: Column(
              children: [
                // Mini progress bar
                Container(
                  width: 30, // Reduced from 40
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 30 * percentage,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Label with percentage
                Column(
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9, // Reduced from 10
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 8, // Reduced from 9
                        fontWeight: FontWeight.w500,
                        color: color,
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

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Month:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF667EEA).withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                icon: Icon(Iconsax.arrow_down_1, size: 16, color: Color(0xFF667EEA)),
                iconSize: 16,
                elevation: 0,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMonth = newValue!;
                  });
                },
                items: _months.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final List<Map<String, dynamic>> legendItems = [
      {'color': Color(0xFF2196F3), 'label': 'Present', 'icon': Iconsax.tick_circle},
      {'color': Color(0xFFF44336), 'label': 'Absent', 'icon': Iconsax.close_circle},
      {'color': Color(0xFF00BCD4), 'label': 'Late', 'icon': Iconsax.clock},
      {'color': Color(0xFF9C27B0), 'label': 'Leaves', 'icon': Iconsax.calendar_remove},
      {'color': Color(0xFFFF9800), 'label': 'Short Leaves', 'icon': Iconsax.timer},
      {'color': Color(0xFF4CAF50), 'label': 'On Time', 'icon': Iconsax.tick_square},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 400;
        final crossAxisCount = isWideScreen ? 3 : 2;
        final itemSpacing = isWideScreen ? 20.0 : 16.0;
        final itemHeight = isWideScreen ? 60.0 : 55.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.info_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Attendance Legend',
                    style: TextStyle(
                      fontSize: isWideScreen ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Responsive grid of legend items
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: itemSpacing,
                  mainAxisSpacing: itemSpacing,
                  childAspectRatio: isWideScreen ? 2.5 : 2.2,
                ),
                itemCount: legendItems.length,
                itemBuilder: (context, index) {
                  final item = legendItems[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Color indicator with icon
                        Container(
                          width: isWideScreen ? 44 : 40,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: item['color'] as Color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              item['icon'] as IconData? ?? Iconsax.info_circle,
                              color: Colors.white,
                              size: isWideScreen ? 18 : 16,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Label
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: isWideScreen ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ Color(0xFF667EEA),
                    Color(0xFF764BA2),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: FutureBuilder<String?>(
                future: null,
                builder: (context, snapshot) {
                  final username = snapshot.data ?? "Admin";
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: const Icon(
                            Iconsax.profile_circle,
                            color: Color(0xFF667EEA),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Iconsax.home,
                    label: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Iconsax.tick_circle,
                    label: 'Approve Leave',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_)=>ApproveLeaveScreen()));
                    }
                  ),
                  _buildDrawerItem(
                    icon: Iconsax.calendar_tick,
                    label: 'Staff Attendance',
                    onTap: () {}
                  ),

                    _buildDrawerItem(
                      icon: Iconsax.money_send,
                      label: 'Salary',
                      onTap: () {},
                    ),

                    _buildDrawerItem(
                      icon: Iconsax.clock,
                      label: 'Attendance Report',
                      onTap: () {}
                    ),
                  _buildDrawerItem(
                    icon: Iconsax.calendar_edit,
                    label: 'Leave Balances',
                    onTap: () {}
                  ),
                  // _buildDrawerItem(
                  //   icon: Iconsax.receipt,
                  //   label: 'Purchase Order',
                  //   onTap: () {}
                  // ),
                  //
                  //   _buildDrawerItem(
                  //     icon: Iconsax.wallet_money,
                  //     label: 'Payments',
                  //     onTap: () {}
                  //   ),

                  const Divider(thickness: 1),
                  _buildDrawerItem(
                    icon: Iconsax.logout,
                    label: 'Logout',
                    color: Colors.red,
                    onTap: (){}
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF667EEA)),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
