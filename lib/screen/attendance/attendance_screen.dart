// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import '../../model/attendance_model/attendance_model.dart';
// import '../../provider/attendance_provider/attendance_provider.dart';
// import '../../provider/Auth_provider/Auth_provider.dart'; // Add this import
//
// class AttendanceScreen extends StatefulWidget {
//   const AttendanceScreen({super.key});
//
//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }
//
// class _AttendanceScreenState extends State<AttendanceScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   late AttendanceProvider _provider;
//   String _employeeId = '';
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       _employeeId = authProvider.employeeId;
//       _provider = Provider.of<AttendanceProvider>(context, listen: false);
//       _provider.fetchAllData();
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;
//     final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
//     final isLargeScreen = screenWidth >= 900;
//
//     final authProvider = Provider.of<AuthProvider>(context);
//     final isStaff = !authProvider.isAdmin;
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF667EEA),
//         title: Text(
//           isStaff ? 'My Attendance' : 'Attendance',
//           style: TextStyle(
//             fontSize: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           Consumer<AttendanceProvider>(
//             builder: (context, provider, child) {
//               return Row(
//                 children: [
//                   // User role indicator
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isSmallScreen ? 8 : 12,
//                       vertical: isSmallScreen ? 4 : 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           provider.isAdmin ? Iconsax.shield_tick : Iconsax.user,
//                           size: isSmallScreen ? 14 : 16,
//                           color: Colors.white,
//                         ),
//                         SizedBox(width: isSmallScreen ? 4 : 6),
//                         Text(
//                           provider.isAdmin ? 'Admin' : 'Staff',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 12 : 14,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(width: isSmallScreen ? 8 : 16),
//                   IconButton(
//                     icon: Icon(
//                       Iconsax.refresh,
//                       size: isSmallScreen ? 20 : 24,
//                     ),
//                     onPressed: () => _provider.fetchAllData(),
//                     tooltip: 'Refresh',
//                   ),
//                   SizedBox(width: isSmallScreen ? 8 : 16),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//       body: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: SystemUiOverlayStyle.light.copyWith(
//           statusBarColor: Colors.transparent,
//         ),
//         child: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFF667EEA),
//                 Color(0xFF764BA2),
//               ],
//             ),
//           ),
//           child: Column(
//             children: [
//               // Search Section
//               _buildSearchSection(isStaff),
//
//               // Statistics Cards (Admin only)
//               Consumer<AttendanceProvider>(
//                 builder: (context, provider, child) {
//                   return !isStaff ? _buildStatisticsCards(provider) : const SizedBox.shrink();
//                 },
//               ),
//
//               SizedBox(height: isSmallScreen ? 14 : 18),
//
//               // Attendance List
//               Expanded(
//                 child: Container(
//                   margin: EdgeInsets.fromLTRB(
//                     isSmallScreen ? 12 : 16,
//                     0,
//                     isSmallScreen ? 12 : 16,
//                     isSmallScreen ? 8 : 10,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: isSmallScreen ? 10 : 15,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: _buildAttendanceList(isStaff),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       // Floating Action Button (Admin only)
//       floatingActionButton: Consumer<AttendanceProvider>(
//         builder: (context, provider, child) {
//           return !isStaff
//               ? FloatingActionButton(
//             onPressed: () {
//               provider.navigateToAddScreen(context);
//             },
//             backgroundColor: const Color(0xFF667EEA),
//             child: Icon(
//               Iconsax.add,
//               color: Colors.white,
//               size: isSmallScreen ? 24 : 28,
//             ),
//           )
//               : const SizedBox.shrink();
//         },
//       ),
//     );
//   }
//
//   Widget _buildSearchSection(bool isStaff) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//
//     return Consumer<AttendanceProvider>(
//       builder: (context, provider, child) {
//         return Container(
//           margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
//           padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: isSmallScreen ? 8 : 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               // Search Bar (Visible for all users)
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: TextField(
//                   controller: _searchController,
//                   onChanged: (value) => provider.setSearchQuery(value),
//                   decoration: InputDecoration(
//                     hintText: isStaff
//                         ? 'Search your attendance...'
//                         : 'Search by employee name or ID...',
//                     hintStyle: TextStyle(
//                       color: Colors.grey[500],
//                       fontSize: isSmallScreen ? 13 : 14,
//                     ),
//                     prefixIcon: Icon(
//                       Iconsax.search_normal,
//                       color: Colors.grey[500],
//                       size: isSmallScreen ? 20 : 22,
//                     ),
//                     suffixIcon: _searchController.text.isNotEmpty
//                         ? IconButton(
//                       icon: Icon(
//                         Iconsax.close_circle,
//                         color: Colors.grey[500],
//                         size: isSmallScreen ? 20 : 22,
//                       ),
//                       onPressed: () {
//                         _searchController.clear();
//                         provider.setSearchQuery('');
//                       },
//                     )
//                         : null,
//                     border: InputBorder.none,
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: isSmallScreen ? 12 : 16,
//                       vertical: isSmallScreen ? 12 : 14,
//                     ),
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: isSmallScreen ? 12 : 16),
//
//               // Filter Row
//               if (isStaff)
//               // For staff: Show only month filter
//                 _buildMonthFilter(provider)
//               else
//               // For admin: Show all filters
//                 _buildFilterRow(provider),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildFilterRow(AttendanceProvider provider) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     if (isVerySmallScreen) {
//       // For very small screens, stack filters vertically
//       return Column(
//         children: [
//           _buildDepartmentFilter(provider),
//           SizedBox(height: isSmallScreen ? 8 : 12),
//           _buildEmployeeFilter(provider),
//           SizedBox(height: isSmallScreen ? 8 : 12),
//           _buildMonthFilter(provider),
//         ],
//       );
//     } else {
//       // For normal screens, use horizontal layout
//       return Row(
//         children: [
//           Expanded(child: _buildDepartmentFilter(provider)),
//           SizedBox(width: isSmallScreen ? 6 : 8),
//           Expanded(child: _buildEmployeeFilter(provider)),
//           SizedBox(width: isSmallScreen ? 6 : 8),
//           Expanded(child: _buildMonthFilter(provider)),
//         ],
//       );
//     }
//   }
//
//   Widget _buildEmployeeFilter(AttendanceProvider provider) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     return Consumer<AttendanceProvider>(
//       builder: (context, provider, child) {
//         // Check if department is selected (not "All")
//         final isDepartmentSelected = provider.selectedDepartmentFilter != 'All';
//
//         // Get employees for the selected department
//         final employeesForDepartment = provider.filteredEmployees;
//         final hasEmployees = employeesForDepartment.isNotEmpty;
//
//         // Enable dropdown only when department is selected AND has employees
//         final isEnabled = isDepartmentSelected && hasEmployees;
//
//         // Determine what to show in the dropdown
//         String displayText;
//         if (!isDepartmentSelected) {
//           displayText = 'Select Department';
//         } else if (!hasEmployees) {
//           displayText = 'No employees';
//         } else if (provider.selectedEmployeeFilter.isEmpty) {
//           displayText = 'Select Employee';
//         } else {
//           displayText = provider.selectedEmployeeFilter;
//         }
//
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isEnabled
//                   ? const Color(0xFF667EEA).withOpacity(0.5)
//                   : Colors.grey[300]!,
//               width: 1.5,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: provider.selectedEmployeeFilter.isNotEmpty
//                   ? provider.selectedEmployeeFilter
//                   : null,
//               isExpanded: true,
//               icon: Container(
//                 padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
//                 decoration: BoxDecoration(
//                   color: isEnabled
//                       ? const Color(0xFF667EEA).withOpacity(0.1)
//                       : Colors.grey[200],
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Icon(
//                   Iconsax.arrow_down_1,
//                   size: isSmallScreen ? 14 : 16,
//                   color: isEnabled
//                       ? const Color(0xFF667EEA)
//                       : Colors.grey[400],
//                 ),
//               ),
//               style: TextStyle(
//                 fontSize: isSmallScreen ? 12 : 13,
//                 color: isEnabled ? Colors.black87 : Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//               hint: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSmallScreen ? 8 : 12,
//                   vertical: isSmallScreen ? 6 : 8,
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: isSmallScreen ? 28 : 32,
//                       height: isSmallScreen ? 28 : 32,
//                       decoration: BoxDecoration(
//                         color: isEnabled
//                             ? const Color(0xFF667EEA).withOpacity(0.1)
//                             : Colors.grey[300],
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Icon(
//                           Iconsax.people,
//                           size: isSmallScreen ? 14 : 16,
//                           color: isEnabled
//                               ? const Color(0xFF667EEA)
//                               : Colors.grey[400],
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: isSmallScreen ? 8 : 12),
//                     Expanded(
//                       child: Text(
//                         _truncateText(displayText, isVerySmallScreen ? 15 : 20),
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 12 : 13,
//                           color: isEnabled ? Colors.black87 : Colors.grey[600],
//                           fontWeight: FontWeight.w500,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               onChanged: isEnabled ? (String? value) {
//                 if (value != null && value.isNotEmpty) {
//                   provider.setEmployeeFilter(value);
//                 }
//               } : null,
//               items: isEnabled ? employeesForDepartment.map((employee) {
//                 return DropdownMenuItem<String>(
//                   value: employee.name,
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isSmallScreen ? 8 : 12,
//                       vertical: isSmallScreen ? 6 : 8,
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: isSmallScreen ? 28 : 32,
//                           height: isSmallScreen ? 28 : 32,
//                           decoration: const BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Color(0xFF667EEA),
//                                 Color(0xFF764BA2),
//                               ],
//                             ),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Center(
//                             child: Text(
//                               employee.name.substring(0, 1).toUpperCase(),
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: isSmallScreen ? 8 : 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 _truncateText(employee.name, isVerySmallScreen ? 12 : 18),
//                                 style: TextStyle(
//                                   fontSize: isSmallScreen ? 12 : 13,
//                                   color: Colors.black87,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               if (employee.empId.isNotEmpty)
//                                 Text(
//                                   employee.empId,
//                                   style: TextStyle(
//                                     fontSize: isSmallScreen ? 10 : 11,
//                                     color: Colors.grey[600],
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList() : null,
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   String _truncateText(String text, int maxLength) {
//     if (text.length <= maxLength) return text;
//     return '${text.substring(0, maxLength)}...';
//   }
//
//   Widget _buildDepartmentFilter(AttendanceProvider provider) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: const Color(0xFF667EEA).withOpacity(0.2),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: provider.selectedDepartmentFilter,
//           isExpanded: true,
//           icon: Container(
//             padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF667EEA).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Icon(
//               Iconsax.arrow_down_1,
//               size: isSmallScreen ? 12 : 14,
//               color: const Color(0xFF667EEA),
//             ),
//           ),
//           style: TextStyle(
//             fontSize: isSmallScreen ? 11 : 12,
//             color: provider.selectedDepartmentFilter == 'All'
//                 ? Colors.grey[600]
//                 : Colors.black87,
//             fontWeight: FontWeight.w500,
//           ),
//           onChanged: (String? value) {
//             if (value != null) {
//               provider.setDepartmentFilter(value);
//             }
//           },
//           items: [
//             DropdownMenuItem<String>(
//               value: 'All',
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSmallScreen ? 6 : 8,
//                   vertical: isSmallScreen ? 4 : 6,
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: isSmallScreen ? 24 : 28,
//                       height: isSmallScreen ? 24 : 28,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           '🏢',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 10 : 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: isSmallScreen ? 6 : 8),
//                     Expanded(
//                       child: Text(
//                         'All Depts',
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 11 : 12,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             ...provider.departmentNames.where((dept) => dept != 'All').map((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isSmallScreen ? 6 : 8,
//                     vertical: isSmallScreen ? 4 : 6,
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: isSmallScreen ? 24 : 28,
//                         height: isSmallScreen ? 24 : 28,
//                         decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Color(0xFF667EEA),
//                               Color(0xFF764BA2),
//                             ],
//                           ),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Center(
//                           child: Text(
//                             value.substring(0, 1).toUpperCase(),
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: isSmallScreen ? 10 : 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: isSmallScreen ? 6 : 8),
//                       Expanded(
//                         child: Text(
//                           _truncateText(value, isVerySmallScreen ? 12 : 18),
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 11 : 12,
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMonthFilter(AttendanceProvider provider) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: const Color(0xFF667EEA).withOpacity(0.2),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: provider.selectedMonthFilter,
//           isExpanded: true,
//           icon: Container(
//             padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF667EEA).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Icon(
//               Iconsax.calendar,
//               size: isSmallScreen ? 12 : 14,
//               color: const Color(0xFF667EEA),
//             ),
//           ),
//           style: TextStyle(
//             fontSize: isSmallScreen ? 11 : 12,
//             color: provider.selectedMonthFilter == 'All'
//                 ? Colors.grey[600]
//                 : Colors.black87,
//             fontWeight: FontWeight.w500,
//           ),
//           onChanged: (String? value) {
//             if (value != null) {
//               provider.setMonthFilter(value);
//               // Refresh data with new month filter
//               provider.fetchAllData();
//             }
//           },
//           items: [
//             DropdownMenuItem<String>(
//               value: 'All',
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSmallScreen ? 6 : 8,
//                   vertical: isSmallScreen ? 4 : 6,
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: isSmallScreen ? 24 : 28,
//                       height: isSmallScreen ? 24 : 28,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Icon(
//                           Iconsax.calendar_1,
//                           size: isSmallScreen ? 12 : 14,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: isSmallScreen ? 6 : 8),
//                     Expanded(
//                       child: Text(
//                         'All Months',
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 11 : 12,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             ...provider.availableMonths.where((month) => month != 'All').map((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isSmallScreen ? 6 : 8,
//                     vertical: isSmallScreen ? 4 : 6,
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: isSmallScreen ? 24 : 28,
//                         height: isSmallScreen ? 24 : 28,
//                         decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Color(0xFF667EEA),
//                               Color(0xFF764BA2),
//                             ],
//                           ),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Center(
//                           child: Text(
//                             _getMonthNumber(value),
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: isSmallScreen ? 10 : 11,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: isSmallScreen ? 6 : 8),
//                       Expanded(
//                         child: Text(
//                           _truncateText(value, isVerySmallScreen ? 10 : 16),
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 11 : 12,
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _getMonthNumber(String monthWithYear) {
//     try {
//       final monthName = monthWithYear.split(' ')[0];
//       final months = {
//         'January': '1', 'February': '2', 'March': '3', 'April': '4',
//         'May': '5', 'June': '6', 'July': '7', 'August': '8',
//         'September': '9', 'October': '10', 'November': '11', 'December': '12'
//       };
//       return months[monthName] ?? '';
//     } catch (e) {
//       return '';
//     }
//   }
//
//   Widget _buildStatisticsCards(AttendanceProvider provider) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     // Calculate statistics from the CURRENT FILTERED attendance data
//     int presentCount = 0;
//     int lateCount = 0;
//     int absentCount = 0;
//     int totalRecords = provider.attendance.length;
//
//     for (var attendance in provider.attendance) {
//       if (attendance.isPresent) {
//         presentCount++;
//         if (attendance.lateMinutes > 0) {
//           lateCount++;
//         }
//       } else {
//         // Check if it's absent
//         if (attendance.timeIn.isEmpty && attendance.timeOut.isEmpty) {
//           absentCount++;
//         } else if (attendance.status.toLowerCase().contains('absent')) {
//           absentCount++;
//         } else if (!attendance.isPresent) {
//           // If not present and not explicitly absent, count as "Not Marked"
//           // For now, we'll count these as absent too
//           absentCount++;
//         }
//       }
//     }
//
//     // Debug output
//     print('=== ATTENDANCE STATISTICS ===');
//     print('Filtered records: $totalRecords');
//     print('Present: $presentCount');
//     print('Late (subset of present): $lateCount');
//     print('Absent/Not Marked: $absentCount');
//
//     if (provider.attendance.isNotEmpty) {
//       print('Sample record analysis:');
//       for (int i = 0; i < min(3, provider.attendance.length); i++) {
//         final record = provider.attendance[i];
//         print('  Record ${i + 1}:');
//         print('    Date: ${record.date}');
//         print('    Employee: ${record.employeeName}');
//         print('    TimeIn: "${record.timeIn}"');
//         print('    TimeOut: "${record.timeOut}"');
//         print('    Status: ${record.status}');
//         print('    isPresent: ${record.isPresent}');
//         print('    lateMinutes: ${record.lateMinutes}');
//       }
//     }
//
//     // Don't show statistics if no records
//     if (totalRecords == 0) {
//       print('No attendance records to show statistics for');
//       return const SizedBox.shrink();
//     }
//
//     // Calculate responsive height based on screen size
//     final cardHeight = isVerySmallScreen
//         ? screenHeight * 0.12
//         : (isSmallScreen ? screenHeight * 0.13 : screenHeight * 0.14);
//
//     return SizedBox(
//       height: cardHeight,
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: isVerySmallScreen ? 10 : (isSmallScreen ? 15 : 20),
//           mainAxisSpacing: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
//           childAspectRatio: isVerySmallScreen ? 0.9 : (isSmallScreen ? 1.0 : 1.1),
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20),
//           vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8),
//         ),
//         itemCount: 3,
//         itemBuilder: (context, index) {
//           final stats = [
//             {
//               'icon': Iconsax.tick_circle,
//               'title': 'Present',
//               'count': presentCount.toString(),
//               'color': const Color(0xFF4CAF50),
//               'subtitle': totalRecords > 0 ? '${((presentCount / totalRecords) * 100).toStringAsFixed(0)}%' : '0%',
//             },
//             {
//               'icon': Iconsax.clock,
//               'title': 'Late',
//               'count': lateCount.toString(),
//               'color': const Color(0xFFFF9800),
//               'subtitle': presentCount > 0 ? '${((lateCount / presentCount) * 100).toStringAsFixed(0)}% of present' : '0%',
//             },
//             {
//               'icon': Iconsax.close_circle,
//               'title': 'Absent',
//               'count': absentCount.toString(),
//               'color': const Color(0xFFF44336),
//               'subtitle': totalRecords > 0 ? '${((absentCount / totalRecords) * 100).toStringAsFixed(0)}%' : '0%',
//             },
//           ];
//
//           final stat = stats[index];
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 8,
//                   spreadRadius: 1,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             padding: EdgeInsets.all(isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 10)),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
//                   height: isVerySmallScreen ? 26 : (isSmallScreen ? 30 : 34),
//                   decoration: BoxDecoration(
//                     color: (stat['color'] as Color).withOpacity(0.1),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: (stat['color'] as Color).withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                   ),
//                   child: Center(
//                     child: Icon(
//                       stat['icon'] as IconData,
//                       color: stat['color'] as Color,
//                       size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8)),
//                 Text(
//                   stat['count'] as String,
//                   style: TextStyle(
//                     fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 SizedBox(height: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4)),
//                 Text(
//                   stat['title'] as String,
//                   style: TextStyle(
//                     fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                     color: (stat['color'] as Color).withOpacity(0.8),
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.5,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 SizedBox(height: isVerySmallScreen ? 1 : 2),
//                 Text(
//                   stat['subtitle'] as String,
//                   style: TextStyle(
//                     fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
//                     color: Colors.grey[600],
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//   Widget _buildAttendanceList(bool isStaff) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     return Consumer<AttendanceProvider>(
//       builder: (context, provider, child) {
//         if (provider.isLoading && provider.attendance.isEmpty) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//
//         if (provider.error.isNotEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Iconsax.warning_2,
//                   size: isSmallScreen ? 50 : 60,
//                   color: Colors.grey[300],
//                 ),
//                 SizedBox(height: isSmallScreen ? 12 : 16),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
//                   child: Text(
//                     'Error: ${provider.error}',
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 14 : 16,
//                       color: Colors.grey[500],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 SizedBox(height: isSmallScreen ? 12 : 16),
//                 ElevatedButton(
//                   onPressed: () => provider.fetchAllData(),
//                   child: Text(
//                     'Retry',
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 14 : 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         if (provider.attendance.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Iconsax.note_remove,
//                   size: isSmallScreen ? 50 : 60,
//                   color: Colors.grey[300],
//                 ),
//                 SizedBox(height: isSmallScreen ? 12 : 16),
//                 Text(
//                   isStaff
//                       ? 'No attendance records found for you'
//                       : 'No attendance records found',
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 14 : 16,
//                     color: Colors.grey[500],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: isSmallScreen ? 8 : 12),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
//                   child: Text(
//                     isStaff
//                         ? 'Your attendance will appear here once marked'
//                         : 'Try adding new attendance records',
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 12 : 14,
//                       color: Colors.grey[400],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         return Column(
//           children: [
//             // Table Header
//             Container(
//               padding: EdgeInsets.all(isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//                 border: Border(
//                   bottom: BorderSide(
//                     color: Colors.grey[200]!,
//                     width: 1,
//                   ),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   // Serial Number
//                   SizedBox(
//                     width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
//                     child: Text(
//                       'Sr.No',
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   SizedBox(width: isVerySmallScreen ? 4 : 8),
//                   // Date
//                   Expanded(
//                     flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//                     child: Text(
//                       'Date',
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   // Time In
//                   Expanded(
//                     flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//                     child: Text(
//                       'Time In',
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   // Time Out
//                   Expanded(
//                     flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//                     child: Text(
//                       'Time Out',
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   // Status
//                   Expanded(
//                     flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//                     child: Text(
//                       'Status',
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   // Actions (Admin only)
//                   if (!isStaff)
//                     SizedBox(
//                       width: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40),
//                       child: Text(
//                         isVerySmallScreen || isSmallScreen ? '' : 'Actions',
//                         style: TextStyle(
//                           fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Table Body
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.zero,
//                 itemCount: provider.attendance.length,
//                 itemBuilder: (context, index) {
//                   final attendance = provider.attendance[index];
//                   final serialNo = index + 1;
//                   return GestureDetector(
//                     child: _buildTableRow(attendance, !isStaff, serialNo, isStaff),
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildTableRow(Attendance attendance, bool showActions, int serialNo, bool isStaff) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//     final isVerySmallScreen = screenWidth < 400;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           bottom: BorderSide(
//             color: Colors.grey[200]!,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
//           vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12),
//         ),
//         child: Row(
//           children: [
//             // Serial Number
//             SizedBox(
//               width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
//               child: Text(
//                 serialNo.toString(),
//                 style: TextStyle(
//                   fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             SizedBox(width: isVerySmallScreen ? 4 : 8),
//             // Date Column
//             Expanded(
//               flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _formatDate(attendance.date),
//                     style: TextStyle(
//                       fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                       color: Colors.black87,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (!isStaff && attendance.employeeName.isNotEmpty) ...[
//                     SizedBox(height: 2),
//                     Text(
//                       attendance.employeeName,
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
//                         color: Colors.grey[600],
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             // Time In Column
//             Expanded(
//               flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
//                       vertical: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4),
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           attendance.timeIn.isNotEmpty
//                               ? attendance.timeIn.substring(0, 5)
//                               : '--:--',
//                           style: TextStyle(
//                             fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                             fontWeight: FontWeight.w600,
//                             color: Colors.green[700],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         if (attendance.lateMinutes > 0) ...[
//                           SizedBox(height: isVerySmallScreen ? 1 : 2),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Time Out Column
//             Expanded(
//               flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
//                       vertical: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4),
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           attendance.timeOut.isNotEmpty
//                               ? attendance.timeOut.substring(0, 5)
//                               : '--:--',
//                           style: TextStyle(
//                             fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue[700],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         if (attendance.overtimeMinutes > 0) ...[
//                           SizedBox(height: isVerySmallScreen ? 1 : 2),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               'OT: ${attendance.overtimeMinutes}m',
//                               style: TextStyle(
//                                 fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
//                                 color: Colors.blue[700],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Status Column
//             Expanded(
//               flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
//                   vertical: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6),
//                 ),
//                 decoration: BoxDecoration(
//                   color: attendance.statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       attendance.status,
//                       style: TextStyle(
//                         fontSize: isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11),
//                         fontWeight: FontWeight.w600,
//                         color: attendance.statusColor,
//                       ),
//                       textAlign: TextAlign.center,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     if (attendance.lateMinutes > 0 && attendance.status.toLowerCase() == 'late') ...[
//                       SizedBox(height: isVerySmallScreen ? 1 : 2),
//                       Text(
//                         'Late by ${attendance.lateMinutes}m',
//                         style: TextStyle(
//                           fontSize: isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 9),
//                           color: Colors.orange[700],
//                           fontWeight: FontWeight.w500,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                     if (attendance.status.toLowerCase() == 'on time') ...[
//                       SizedBox(height: isVerySmallScreen ? 1 : 2),
//                       Text(
//                         'Perfect',
//                         style: TextStyle(
//                           fontSize: isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 9),
//                           color: Colors.green[700],
//                           fontWeight: FontWeight.w500,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             // Actions (Admin only)
//             // if (showActions)
//             //   SizedBox(
//             //     width: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40),
//             //     child: Row(
//             //       mainAxisAlignment: MainAxisAlignment.center,
//             //       children: [
//             //         IconButton(
//             //           icon: Icon(
//             //             Iconsax.edit,
//             //             size: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
//             //             color: Colors.grey[600],
//             //           ),
//             //           onPressed: () {
//             //             // Edit functionality
//             //           },
//             //           padding: EdgeInsets.zero,
//             //           constraints: const BoxConstraints(),
//             //         ),
//             //       ],
//             //     ),
//             //   ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final dateDay = DateTime(date.year, date.month, date.day);
//
//     if (dateDay == today) return 'Today';
//     if (dateDay == yesterday) return 'Yesterday';
//
//     return DateFormat('dd/MM/yyyy').format(date);
//   }
// }

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../model/attendance_model/attendance_model.dart';
import '../../provider/attendance_provider/attendance_provider.dart';
import '../../provider/Auth_provider/Auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  late AttendanceProvider _provider;
  String _employeeId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _employeeId = authProvider.employeeId;
      _provider = Provider.of<AttendanceProvider>(context, listen: false);
      _provider.fetchAllData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final isLargeScreen = screenWidth >= 900;

    final authProvider = Provider.of<AuthProvider>(context);
    final isStaff = !authProvider.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), // Set scaffold background color
      // No app bar - removed completely
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith( // Changed to dark for better visibility on light background
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF), // Match scaffold background
          ),
          child: Column(
            children: [
              // Add some top padding to account for status bar
              SizedBox(height: MediaQuery.of(context).padding.top + 8),

              // Header with title and refresh button (replaces app bar)
              // Padding(
              //   padding: EdgeInsets.symmetric(
              //     horizontal: isSmallScreen ? 16 : 20,
              //   ),
              //   child: Row(
              //     children: [
              //       // Menu/Drawer icon to open drawer
              //       Builder(
              //         builder: (context) {
              //           return IconButton(
              //             icon: const Icon(Iconsax.menu_1, color: Color(0xFF667EEA)),
              //             onPressed: () {
              //               Scaffold.of(context).openDrawer();
              //             },
              //           );
              //         },
              //       ),
              //       const SizedBox(width: 8),
              //       Text(
              //         isStaff ? 'My Attendance' : 'Attendance',
              //         style: TextStyle(
              //           fontSize: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
              //           fontWeight: FontWeight.bold,
              //           color: const Color(0xFF667EEA),
              //         ),
              //       ),
              //       const Spacer(),
              //       // Refresh button
              //       Container(
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           shape: BoxShape.circle,
              //           boxShadow: [
              //             BoxShadow(
              //               color: Colors.black.withOpacity(0.05),
              //               blurRadius: 8,
              //               offset: const Offset(0, 2),
              //             ),
              //           ],
              //         ),
              //         child: IconButton(
              //           icon: Icon(
              //             Iconsax.refresh,
              //             size: isSmallScreen ? 20 : 22,
              //             color: const Color(0xFF667EEA),
              //           ),
              //           onPressed: () => _provider.fetchAllData(),
              //           tooltip: 'Refresh',
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 8),

              // Search Section
              _buildSearchSection(isStaff),

              // Statistics Cards (Admin only)
              Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  return !isStaff ? _buildStatisticsCards(provider) : const SizedBox.shrink();
                },
              ),

              SizedBox(height: isSmallScreen ? 14 : 18),

              // Attendance List
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    isSmallScreen ? 12 : 16,
                    0,
                    isSmallScreen ? 12 : 16,
                    isSmallScreen ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: isSmallScreen ? 10 : 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildAttendanceList(isStaff),
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Button (Admin only)
      floatingActionButton: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          return !isStaff
              ? FloatingActionButton(
            onPressed: () {
              provider.navigateToAddScreen(context);
            },
            backgroundColor: const Color(0xFF667EEA),
            child: Icon(
              Iconsax.add,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchSection(bool isStaff) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: isSmallScreen ? 8 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Bar (Visible for all users)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: isStaff
                        ? 'Search your attendance...'
                        : 'Search by employee name or ID...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey[500],
                      size: isSmallScreen ? 20 : 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Iconsax.close_circle,
                        color: Colors.grey[500],
                        size: isSmallScreen ? 20 : 22,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Filter Row
              if (isStaff)
              // For staff: Show only month filter
                _buildMonthFilter(provider)
              else
              // For admin: Show all filters
                _buildFilterRow(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterRow(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Always use Row with Expanded to keep 3 filters in one row
    return Row(
      children: [
        Expanded(child: _buildDepartmentFilter(provider)),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(child: _buildEmployeeFilter(provider)),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(child: _buildMonthFilter(provider)),
      ],
    );
  }

  Widget _buildEmployeeFilter(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        final isDepartmentSelected = provider.selectedDepartmentFilter != 'All';
        final employeesForDepartment = provider.filteredEmployees;
        final hasEmployees = employeesForDepartment.isNotEmpty;
        final isEnabled = isDepartmentSelected && hasEmployees;

        String displayText;
        if (!isDepartmentSelected) {
          displayText = 'Select Dept';
        } else if (!hasEmployees) {
          displayText = 'No employees';
        } else if (provider.selectedEmployeeFilter.isEmpty) {
          displayText = 'Select Emp';
        } else {
          displayText = provider.selectedEmployeeFilter;
        }

        return Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF667EEA).withOpacity(0.5)
                  : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedEmployeeFilter.isNotEmpty
                  ? provider.selectedEmployeeFilter
                  : null,
              isExpanded: true,
              icon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  Iconsax.arrow_down_1,
                  size: 16,
                  color: isEnabled
                      ? const Color(0xFF667EEA)
                      : Colors.grey[400],
                ),
              ),
              style: TextStyle(
                fontSize: 13,
                color: isEnabled ? Colors.black87 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _truncateText(displayText, 12),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? Colors.black87 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onChanged: isEnabled ? (String? value) {
                if (value != null && value.isNotEmpty) {
                  provider.setEmployeeFilter(value);
                }
              } : null,
              items: isEnabled ? employeesForDepartment.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee.name,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _truncateText(employee.name, 15),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList() : null,
            ),
          ),
        );
      },
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildDepartmentFilter(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      height: 45, // Fixed height for consistency
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedDepartmentFilter,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: const Color(0xFF667EEA),
            ),
          ),
          elevation: 2,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          onChanged: (String? value) {
            if (value != null) {
              provider.setDepartmentFilter(value);
            }
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'All',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'All Depts',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...provider.departmentNames.where((dept) => dept != 'All').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilter(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedMonthFilter,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: const Color(0xFF667EEA),
            ),
          ),
          elevation: 2,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          onChanged: (String? value) {
            if (value != null) {
              provider.setMonthFilter(value);
              provider.fetchAllData();
            }
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'All',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'All Months',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...provider.availableMonths.where((month) => month != 'All').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _truncateText(value, 10),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  String _getMonthNumber(String monthWithYear) {
    try {
      final monthName = monthWithYear.split(' ')[0];
      final months = {
        'January': '1', 'February': '2', 'March': '3', 'April': '4',
        'May': '5', 'June': '6', 'July': '7', 'August': '8',
        'September': '9', 'October': '10', 'November': '11', 'December': '12'
      };
      return months[monthName] ?? '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildStatisticsCards(AttendanceProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    // Calculate statistics from the CURRENT FILTERED attendance data
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    int totalRecords = provider.attendance.length;

    for (var attendance in provider.attendance) {
      if (attendance.isPresent) {
        presentCount++;
        if (attendance.lateMinutes > 0) {
          lateCount++;
        }
      } else {
        // Check if it's absent
        if (attendance.timeIn.isEmpty && attendance.timeOut.isEmpty) {
          absentCount++;
        } else if (attendance.status.toLowerCase().contains('absent')) {
          absentCount++;
        } else if (!attendance.isPresent) {
          // If not present and not explicitly absent, count as "Not Marked"
          // For now, we'll count these as absent too
          absentCount++;
        }
      }
    }

    // Debug output
    print('=== ATTENDANCE STATISTICS ===');
    print('Filtered records: $totalRecords');
    print('Present: $presentCount');
    print('Late (subset of present): $lateCount');
    print('Absent/Not Marked: $absentCount');

    if (provider.attendance.isNotEmpty) {
      print('Sample record analysis:');
      for (int i = 0; i < min(3, provider.attendance.length); i++) {
        final record = provider.attendance[i];
        print('  Record ${i + 1}:');
        print('    Date: ${record.date}');
        print('    Employee: ${record.employeeName}');
        print('    TimeIn: "${record.timeIn}"');
        print('    TimeOut: "${record.timeOut}"');
        print('    Status: ${record.status}');
        print('    isPresent: ${record.isPresent}');
        print('    lateMinutes: ${record.lateMinutes}');
      }
    }

    // Don't show statistics if no records
    if (totalRecords == 0) {
      print('No attendance records to show statistics for');
      return const SizedBox.shrink();
    }

    // Calculate responsive height based on screen size
    final cardHeight = isVerySmallScreen
        ? screenHeight * 0.16
        : (isSmallScreen ? screenHeight * 0.17 : screenHeight * 0.18);

    return SizedBox(
      height: cardHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: isVerySmallScreen ? 10 : (isSmallScreen ? 15 : 20),
          mainAxisSpacing: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
          childAspectRatio: isVerySmallScreen ? 0.9 : (isSmallScreen ? 1.0 : 1.1),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20),
          vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8),
        ),
        itemCount: 3,
        itemBuilder: (context, index) {
          final stats = [
            {
              'icon': Iconsax.tick_circle,
              'title': 'Present',
              'count': presentCount.toString(),
              'color': const Color(0xFF4CAF50),
              'subtitle': totalRecords > 0 ? '${((presentCount / totalRecords) * 100).toStringAsFixed(0)}%' : '0%',
            },
            {
              'icon': Iconsax.clock,
              'title': 'Late',
              'count': lateCount.toString(),
              'color': const Color(0xFFFF9800),
              'subtitle': presentCount > 0 ? '${((lateCount / presentCount) * 100).toStringAsFixed(0)}% of present' : '0%',
            },
            {
              'icon': Iconsax.close_circle,
              'title': 'Absent',
              'count': absentCount.toString(),
              'color': const Color(0xFFF44336),
              'subtitle': totalRecords > 0 ? '${((absentCount / totalRecords) * 100).toStringAsFixed(0)}%' : '0%',
            },
          ];

          final stat = stats[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
                  height: isVerySmallScreen ? 26 : (isSmallScreen ? 30 : 34),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (stat['color'] as Color).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                    ),
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8)),
                Text(
                  stat['count'] as String,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4)),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                    color: (stat['color'] as Color).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isVerySmallScreen ? 1 : 2),
                Text(
                  stat['subtitle'] as String,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceList(bool isStaff) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.attendance.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: isSmallScreen ? 50 : 60,
                  color: Colors.grey[300],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                  child: Text(
                    'Error: ${provider.error}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                ElevatedButton(
                  onPressed: () => provider.fetchAllData(),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.attendance.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.note_remove,
                  size: isSmallScreen ? 50 : 60,
                  color: Colors.grey[300],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  isStaff
                      ? 'No attendance records found for you'
                      : 'No attendance records found',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
                  child: Text(
                    isStaff
                        ? 'Your attendance will appear here once marked'
                        : 'Try adding new attendance records',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Table Header
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Serial Number
                  SizedBox(
                    width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
                    child: Text(
                      'Sr.No',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: isVerySmallScreen ? 4 : 8),
                  // Date
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Time In
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Time In',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Time Out
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Time Out',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Status
                  Expanded(
                    flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Actions (Admin only)
                  if (!isStaff)
                    SizedBox(
                      width: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40),
                      child: Text(
                        isVerySmallScreen || isSmallScreen ? '' : 'Actions',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Table Body
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: provider.attendance.length,
                itemBuilder: (context, index) {
                  final attendance = provider.attendance[index];
                  final serialNo = index + 1;
                  return GestureDetector(
                    child: _buildTableRow(attendance, !isStaff, serialNo, isStaff),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableRow(Attendance attendance, bool showActions, int serialNo, bool isStaff) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
          vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12),
        ),
        child: Row(
          children: [
            // Serial Number
            SizedBox(
              width: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 50),
              child: Text(
                serialNo.toString(),
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: isVerySmallScreen ? 4 : 8),
            // Date Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(attendance.date),
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isStaff && attendance.employeeName.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      attendance.employeeName,
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Time In Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      vertical: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          attendance.timeIn.isNotEmpty
                              ? attendance.timeIn.substring(0, 5)
                              : '--:--',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (attendance.lateMinutes > 0) ...[
                          SizedBox(height: isVerySmallScreen ? 1 : 2),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Time Out Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      vertical: isVerySmallScreen ? 2 : (isSmallScreen ? 3 : 4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          attendance.timeOut.isNotEmpty
                              ? attendance.timeOut.substring(0, 5)
                              : '--:--',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (attendance.overtimeMinutes > 0) ...[
                          SizedBox(height: isVerySmallScreen ? 1 : 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OT: ${attendance.overtimeMinutes}m',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10),
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Status Column
            Expanded(
              flex: isVerySmallScreen ? 2 : (isSmallScreen ? 2 : 3),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                  vertical: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6),
                ),
                decoration: BoxDecoration(
                  color: attendance.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      attendance.status,
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11),
                        fontWeight: FontWeight.w600,
                        color: attendance.statusColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attendance.lateMinutes > 0 && attendance.status.toLowerCase() == 'late') ...[
                      SizedBox(height: isVerySmallScreen ? 1 : 2),
                      Text(
                        'Late by ${attendance.lateMinutes}m',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 9),
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (attendance.status.toLowerCase() == 'on time') ...[
                      SizedBox(height: isVerySmallScreen ? 1 : 2),
                      Text(
                        'Perfect',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 9),
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Actions (Admin only)
            // if (showActions)
            //   SizedBox(
            //     width: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         IconButton(
            //           icon: Icon(
            //             Iconsax.edit,
            //             size: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
            //             color: Colors.grey[600],
            //           ),
            //           onPressed: () {
            //             // Edit functionality
            //           },
            //           padding: EdgeInsets.zero,
            //           constraints: const BoxConstraints(),
            //         ),
            //       ],
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == yesterday) return 'Yesterday';

    return DateFormat('dd/MM/yyyy').format(date);
  }
}

