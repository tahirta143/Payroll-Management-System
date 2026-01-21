// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../Utility/permissions.dart';
// import '../provider/Auth_provider/Auth_provider.dart';
// import '../testing/attendance.dart';
// import '../testing/employee.dart';
// import '../testing/report.dart';
// import '../testing/salary.dart';
// import 'Dashboard_screen/dashboard_screen.dart';
//
//
// class BottombarScreen extends StatefulWidget {
//   const BottombarScreen({super.key});
//
//   @override
//   State<BottombarScreen> createState() => _BottombarScreenState();
// }
//
// class _BottombarScreenState extends State<BottombarScreen> {
//   int _selectedIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     print('BottombarScreen initialized');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//
//     print('BottombarScreen building...');
//     print('Is authenticated: ${authProvider.isAuthenticated}');
//     print('User: ${authProvider.user?.username}');
//     print('Token: ${authProvider.token?.substring(0, 20)}...');
//
//     if (!authProvider.isAuthenticated) {
//       print('User not authenticated, showing loading screen');
//       return const Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//
//     // Define all bottom navigation items with required permissions
//     final List<BottomNavItem> allItems = [
//       BottomNavItem(
//         icon: Icons.dashboard,
//         label: 'Dashboard',
//         screen: DashboardScreen(),
//         requiredPermission: AppPermissions.canViewDashboard,
//         alwaysVisible: true,
//       ),
//       BottomNavItem(
//         icon: Icons.people,
//         label: 'Employees',
//         screen: EmployeeScreen(),
//         requiredPermission: AppPermissions.canViewEmployees,
//       ),
//       BottomNavItem(
//         icon: Icons.calendar_today,
//         label: 'Attendance',
//         screen: AttendanceScreen(),
//         requiredPermission: AppPermissions.canViewAttendence,
//       ),
//       BottomNavItem(
//         icon: Icons.monetization_on,
//         label: 'Salary',
//         screen: SalaryScreen(),
//         requiredPermission: AppPermissions.canViewSalary,
//       ),
//       BottomNavItem(
//         icon: Icons.assessment,
//         label: 'Reports',
//         screen: ReportsScreen(),
//         requiredPermission: AppPermissions.canViewReports,
//       ),
//     ];
//
//     // Filter items based on user permissions
//     final visibleItems = allItems.where((item) {
//       if (item.alwaysVisible) return true;
//       if (item.requiredPermission != null) {
//         final hasPerm = authProvider.hasPermission(item.requiredPermission!);
//         print('Checking ${item.label}: has permission ${item.requiredPermission}: $hasPerm');
//         return hasPerm;
//       }
//       return true;
//     }).toList();
//
//     print('Total visible items: ${visibleItems.length}');
//     visibleItems.forEach((item) => print('Visible: ${item.label}'));
//
//     // Adjust selected index if current selection is not available
//     if (_selectedIndex >= visibleItems.length) {
//       _selectedIndex = 0;
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(visibleItems.isNotEmpty ? visibleItems[_selectedIndex].label : 'Payroll'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () {
//               authProvider.logout();
//             },
//           ),
//         ],
//       ),
//       body: visibleItems.isEmpty
//           ? _buildNoAccessScreen(authProvider)
//           : visibleItems[_selectedIndex].screen,
//       bottomNavigationBar: visibleItems.length > 1
//           ? BottomNavigationBar(
//         items: visibleItems
//             .map((item) => BottomNavigationBarItem(
//           icon: Icon(item.icon),
//           label: item.label,
//         ))
//             .toList(),
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         selectedItemColor: const Color(0xFF667EEA),
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         type: BottomNavigationBarType.fixed,
//       )
//           : null,
//     );
//   }
//
//   Widget _buildNoAccessScreen(AuthProvider authProvider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.block,
//             size: 80,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'No Access Available',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 10),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 40),
//             child: Text(
//               'You do not have permission to access any features. Please contact your administrator.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton(
//             onPressed: () {
//               authProvider.logout();
//             },
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class BottomNavItem {
//   final IconData icon;
//   final String label;
//   final Widget screen;
//   final String? requiredPermission;
//   final bool alwaysVisible;
//
//   BottomNavItem({
//     required this.icon,
//     required this.label,
//     required this.screen,
//     this.requiredPermission,
//     this.alwaysVisible = false,
//   });
// }