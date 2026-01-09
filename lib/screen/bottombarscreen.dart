import 'package:flutter/material.dart';

import 'Approve_Leave/ApproveLeaveScreen.dart';
import 'Dashboard_screen/dashboard_screen.dart';



class BottombarScreen extends StatefulWidget {
  const BottombarScreen({super.key});

  @override
  State<BottombarScreen> createState() => _BottombarScreenState();
}

class _BottombarScreenState extends State<BottombarScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DashboardScreen(),
    ApproveLeaveScreen(),
    DashboardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    } else {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Exit App",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text("Are you sure you want to exit the app?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Exit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor:Color(0xFF764BA2).withOpacity(0.99) ,
        body: _screens[_selectedIndex],
        bottomNavigationBar: _buildModernBottomNavBar(),
      ),
    );
  }

  Widget _buildModernBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA).withOpacity(0.95),
                Color(0xFF764BA2).withOpacity(0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final isActive = _selectedIndex == index;

              final items = [
                {
                  'icon': Icons.home_rounded,
                  'label': 'DashBoard',
                  'activeIcon': Icons.home_filled,
                },
                {
                  'icon': Icons.calendar_today_outlined,
                  'label': 'Attendance',
                  'activeIcon': Icons.shopping_bag_rounded,
                },
                {
                  'icon': Icons.event_available,
                  'label': 'Leave',
                  'activeIcon': Icons.people_rounded,
                },
                {
                  'icon': Icons.account_balance_wallet_outlined,
                  'label': 'Salary',
                  'activeIcon': Icons.person_rounded,
                },
              ];

              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(index),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: isActive ? 45 : 35,
                        height: isActive ? 45 : 35,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          )
                              : null,
                        ),
                        child: Icon(
                          isActive
                              ? item['activeIcon'] as IconData
                              : item['icon'] as IconData,
                          size: isActive ? 22 : 20,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: isActive ? 12 : 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                        ),
                        child: Text(item['label'] as String),
                      ),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Alternative minimal white design
  Widget _buildMinimalBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = _selectedIndex == index;

          final items = [
            {'icon': Icons.home_outlined, 'label': 'DashBoard'},
            {'icon': Icons.people_outline, 'label': 'Employees'},
            {'icon': Icons.person_outline, 'label': 'User'},
            {'icon': Icons.shopping_bag_outlined, 'label': 'Attendence'},
          ];

          final item = items[index];

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onItemTapped(index),
                highlightColor: Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? Color(0xFF667EEA).withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 22,
                        color: isActive
                            ? Color(0xFF667EEA)
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? Color(0xFF667EEA)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}