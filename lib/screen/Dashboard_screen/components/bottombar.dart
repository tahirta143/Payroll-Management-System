import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/permissions_provider/permissions.dart';


class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PermissionProvider>();

    final List<Map<String, dynamic>> navItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'permission': 'can-view-dashboard'},
      {'title': 'Attendance', 'icon': Icons.fingerprint, 'permission': 'can-view-attendance'},
      {'title': 'Leave', 'icon': Icons.beach_access, 'permission': 'can-view-leave'},
      {'title': 'Salary', 'icon': Icons.account_balance_wallet, 'permission': 'can-view-salary'},
    ];

    final availableNavItems = navItems
        .where((item) => p.hasPermission(item['permission']))
        .toList();

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: availableNavItems.map((item) {
          final index = navItems.indexOf(item);
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onItemSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'],
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}