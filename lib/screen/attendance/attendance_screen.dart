// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import '../../model/attendance_model/attendance_model.dart';
// import '../../provider/attendance_provider/attendance_provider.dart';
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
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
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
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Attendance',
//           style: TextStyle(
//             fontSize: 24,
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
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           provider.isAdmin ? Iconsax.shield_tick : Iconsax.user,
//                           size: 16,
//                           color: Colors.white,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           provider.isAdmin ? 'Admin' : 'User',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   IconButton(
//                     icon: const Icon(Iconsax.refresh),
//                     onPressed: () => provider.fetchAttendance(),
//                     tooltip: 'Refresh',
//                   ),
//                   const SizedBox(width: 16),
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
//               _buildSearchSection(),
//
//               // Statistics Cards (Admin only)
//               Consumer<AttendanceProvider>(
//                 builder: (context, provider, child) {
//                   return provider.isAdmin ? _buildStatisticsCards(provider) : const SizedBox.shrink();
//                 },
//               ),
//
//               const SizedBox(height: 16),
//
//               // Attendance List
//               Expanded(
//                 child: Container(
//                   margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 15,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: _buildAttendanceList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       // Floating Action Button (Admin only)
//       floatingActionButton: Consumer<AttendanceProvider>(
//         builder: (context, provider, child) {
//           return provider.isAdmin
//               ? FloatingActionButton(
//             onPressed: () {
//               provider.navigateToAddScreen(context);
//             },
//             backgroundColor: const Color(0xFF667EEA),
//             child: const Icon(Iconsax.add, color: Colors.white),
//           )
//               : const SizedBox.shrink();
//         },
//       ),
//     );
//   }
//
//   Widget _buildSearchSection() {
//     return Consumer<AttendanceProvider>(
//       builder: (context, provider, child) {
//         final isAdmin = provider.isAdmin;
//
//         return Container(
//           margin: const EdgeInsets.all(16),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
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
//                     hintText: isAdmin
//                         ? 'Search by employee name or ID...'
//                         : 'Search your attendance...',
//                     hintStyle: TextStyle(color: Colors.grey[500]),
//                     prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[500]),
//                     suffixIcon: _searchController.text.isNotEmpty
//                         ? IconButton(
//                       icon: Icon(Iconsax.close_circle, color: Colors.grey[500]),
//                       onPressed: () {
//                         _searchController.clear();
//                         provider.setSearchQuery('');
//                       },
//                     )
//                         : null,
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 14,
//                     ),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Filter Row (Admin only)
//               if (isAdmin) ...[
//                 Row(
//                   children: [
//                     // Employee Filter
//                     Expanded(
//                       child: _buildEmployeeFilter(provider),
//                     ),
//                     const SizedBox(width: 8),
//                     // Department Filter
//                     Container(
//                       width: 160,
//                       child: _buildDepartmentFilter(provider),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildEmployeeFilter(AttendanceProvider provider) {
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
//           value: provider.selectedEmployeeFilter,
//           isExpanded: true,
//           icon: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF667EEA).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Icon(
//               Iconsax.arrow_down_1,
//               size: 16,
//               color: Color(0xFF667EEA),
//             ),
//           ),
//           style: TextStyle(
//             fontSize: 13,
//             color: provider.selectedEmployeeFilter == 'All'
//                 ? Colors.grey[600]
//                 : Colors.black87,
//             fontWeight: FontWeight.w500,
//           ),
//           onChanged: (String? value) {
//             if (value != null) {
//               provider.setEmployeeFilter(value);
//             }
//           },
//           items: [
//             DropdownMenuItem<String>(
//               value: 'All',
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF667EEA),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Center(
//                         child: Text(
//                           '👥',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     const Expanded(
//                       child: Text(
//                         'All Employees',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             ...provider.employeeNames.where((name) => name != 'All').map((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
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
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           value,
//                           style: const TextStyle(
//                             fontSize: 13,
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
//   Widget _buildDepartmentFilter(AttendanceProvider provider) {
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
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF667EEA).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Icon(
//               Iconsax.arrow_down_1,
//               size: 14,
//               color: Color(0xFF667EEA),
//             ),
//           ),
//           style: TextStyle(
//             fontSize: 12,
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
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 28,
//                       height: 28,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Center(
//                         child: Text(
//                           '🏢',
//                           style: TextStyle(fontSize: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Expanded(
//                       child: Text(
//                         'All Depts',
//                         style: TextStyle(
//                           fontSize: 12,
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
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 28,
//                         height: 28,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
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
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           value,
//                           style: const TextStyle(
//                             fontSize: 12,
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
//   Widget _buildStatisticsCards(AttendanceProvider provider) {
//     return SizedBox(
//       height: 110,
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 4,
//           crossAxisSpacing: 8,
//           mainAxisSpacing: 8,
//           childAspectRatio: 1.0,
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         itemCount: 4,
//         itemBuilder: (context, index) {
//           final stats = [
//             {
//               'icon': Iconsax.tick_circle,
//               'title': 'Present',
//               'count': provider.totalPresent.toString(),
//               'color': const Color(0xFF4CAF50),
//             },
//             {
//               'icon': Iconsax.clock,
//               'title': 'Late',
//               'count': provider.totalLate.toString(),
//               'color': const Color(0xFFFF9800),
//             },
//             {
//               'icon': Iconsax.close_circle,
//               'title': 'Absent',
//               'count': provider.totalAbsent.toString(),
//               'color': const Color(0xFFF44336),
//             },
//             {
//               'icon': Iconsax.timer,
//               'title': 'Overtime',
//               'count': provider.totalOvertime.toString(),
//               'color': const Color(0xFF2196F3),
//             },
//           ];
//
//           final stat = stats[index];
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 6,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             padding: const EdgeInsets.all(8),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 28,
//                   height: 28,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         (stat['color'] as Color).withOpacity(0.2),
//                         (stat['color'] as Color).withOpacity(0.1),
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     stat['icon'] as IconData,
//                     color: stat['color'] as Color,
//                     size: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   stat['count'] as String,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                   maxLines: 1,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   stat['title'] as String,
//                   style: TextStyle(
//                     fontSize: 9,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 1,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildAttendanceList() {
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
//                   size: 60,
//                   color: Colors.grey[300],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error: ${provider.error}',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[500],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => provider.fetchAttendance(),
//                   child: const Text('Retry'),
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
//                   size: 60,
//                   color: Colors.grey[300],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   provider.isAdmin
//                       ? 'No attendance records found'
//                       : 'No attendance records for you',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   provider.isAdmin
//                       ? 'Try adding new attendance records'
//                       : 'Contact admin if you think this is an error',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[400],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         return Column(
//           children: [
//             // List Header
//             Container(
//               padding: const EdgeInsets.all(16),
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
//                   Expanded(
//                     flex: provider.isAdmin ? 3 : 4,
//                     child: Text(
//                       'Employee',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Date',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Time',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Status',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   if (provider.isAdmin) const SizedBox(width: 60),
//                 ],
//               ),
//             ),
//
//             // Attendance List
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: provider.attendance.length,
//                 itemBuilder: (context, index) {
//                   final attendance = provider.attendance[index];
//                   return GestureDetector(
//                     onTap: () {
//                       provider.navigateToViewScreen(context, attendance);
//                     },
//                     child: _buildAttendanceCard(attendance, provider.isAdmin),
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
//   Widget _buildAttendanceCard(Attendance attendance, bool isAdmin) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             // First Row: Employee Info and Actions
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Employee Info
//                 Expanded(
//                   flex: isAdmin ? 3 : 4,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 36,
//                             height: 36,
//                             decoration: const BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   Color(0xFF667EEA),
//                                   Color(0xFF764BA2),
//                                 ],
//                               ),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Center(
//                               child: Text(
//                                 attendance.employeeName.split(' ').map((n) => n[0]).join(),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   attendance.employeeName,
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black87,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 Text(
//                                   attendance.empId,
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.grey[600],
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (isAdmin) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           attendance.departmentName,
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//
//                 // Actions - Only show if admin
//                 if (isAdmin)
//                   PopupMenuButton(
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(
//                         value: 'edit',
//                         child: Row(
//                           children: [
//                             Icon(Iconsax.edit, size: 16),
//                             SizedBox(width: 8),
//                             Text('Edit'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'view',
//                         child: Row(
//                           children: [
//                             Icon(Iconsax.eye, size: 16),
//                             SizedBox(width: 8),
//                             Text('View Details'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'delete',
//                         child: Row(
//                           children: [
//                             Icon(Iconsax.trash, size: 16, color: Colors.red),
//                             SizedBox(width: 8),
//                             Text('Delete', style: TextStyle(color: Colors.red)),
//                           ],
//                         ),
//                       ),
//                     ],
//                     onSelected: (value) {
//                       if (value == 'edit') {
//                         _provider.navigateToEditScreen(context, attendance);
//                       } else if (value == 'view') {
//                         _provider.navigateToViewScreen(context, attendance);
//                       } else if (value == 'delete') {
//                         _showDeleteDialog(attendance);
//                       }
//                     },
//                     child: Container(
//                       width: 32,
//                       height: 32,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(
//                         Iconsax.more,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // Second Row: Date and Shift
//             Row(
//               children: [
//                 Icon(
//                   Iconsax.calendar,
//                   size: 14,
//                   color: Colors.grey[500],
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _formatDate(attendance.date),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     attendance.dutyShiftName,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // Third Row: Time In/Out
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Time In
//                 Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.green.withOpacity(0.3)),
//                       ),
//                       child: Column(
//                         children: [
//                           Icon(Iconsax.login, size: 14, color: Colors.green[700]),
//                           const SizedBox(height: 4),
//                           Text(
//                             attendance.timeIn.isNotEmpty
//                                 ? attendance.timeIn.substring(0, 5)
//                                 : '--:--',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'IN',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // Arrow
//                 const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.grey),
//
//                 // Time Out
//                 Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                       ),
//                       child: Column(
//                         children: [
//                           Icon(Iconsax.logout, size: 14, color: Colors.blue[700]),
//                           const SizedBox(height: 4),
//                           Text(
//                             attendance.timeOut.isNotEmpty
//                                 ? attendance.timeOut.substring(0, 5)
//                                 : '--:--',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'OUT',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // Fourth Row: Status and Stats
//             Row(
//               children: [
//                 // Status
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: attendance.statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       attendance.status,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: attendance.statusColor,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//
//                 // Working Hours
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       attendance.workingHours,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const Text(
//                       'Hours',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//
//             // Late/Overtime badges
//             if (attendance.lateMinutes > 0 || attendance.overtimeMinutes > 0)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Wrap(
//                   spacing: 8,
//                   runSpacing: 4,
//                   children: [
//                     if (attendance.lateMinutes > 0)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Iconsax.clock, size: 12, color: Colors.orange[700]),
//                             const SizedBox(width: 4),
//                             Text(
//                               'Late: ${attendance.lateMinutes}m',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.orange[700],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     if (attendance.overtimeMinutes > 0)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Iconsax.timer, size: 12, color: Colors.blue[700]),
//                             const SizedBox(width: 4),
//                             Text(
//                               'OT: ${attendance.overtimeMinutes}m',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.blue[700],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showDeleteDialog(Attendance attendance) {
//     final provider = Provider.of<AttendanceProvider>(context, listen: false);
//
//     if (!provider.isAdmin) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Only administrators can delete attendance records'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Iconsax.trash, color: Colors.red),
//             SizedBox(width: 12),
//             Text('Delete Attendance'),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to delete attendance record for ${attendance.employeeName} on ${_formatDate(attendance.date)}?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               final success = await _provider.deleteAttendance(attendance.id);
//               if (success) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Attendance deleted successfully!'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(_provider.error),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../model/attendance_model/attendance_model.dart';
import '../../provider/attendance_provider/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  late AttendanceProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 24,
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
                  // User role indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.isAdmin ? Iconsax.shield_tick : Iconsax.user,
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
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Iconsax.refresh),
                    onPressed: () => provider.fetchAttendance(),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 16),
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
              // Search Section
              _buildSearchSection(),

              // Statistics Cards (Admin only)
              Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  return provider.isAdmin ? _buildStatisticsCards(provider) : const SizedBox.shrink();
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
      // Floating Action Button (Admin only)
      floatingActionButton: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          return provider.isAdmin
              ? FloatingActionButton(
            onPressed: () {
              provider.navigateToAddScreen(context);
            },
            backgroundColor: const Color(0xFF667EEA),
            child: const Icon(Iconsax.add, color: Colors.white),
          )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        final isAdmin = provider.isAdmin;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
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
                    hintText: isAdmin
                        ? 'Search by employee name or ID...'
                        : 'Search your attendance...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[500]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Iconsax.close_circle, color: Colors.grey[500]),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Row (Admin only)
              if (isAdmin) ...[
                Row(
                  children: [
                    // Employee Filter
                    Expanded(
                      child: _buildEmployeeFilter(provider),
                    ),
                    const SizedBox(width: 8),
                    // Department Filter
                    Container(
                      width: 160,
                      child: _buildDepartmentFilter(provider),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeeFilter(AttendanceProvider provider) {
    return Container(
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
          value: provider.selectedEmployeeFilter,
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: Color(0xFF667EEA),
            ),
          ),
          style: TextStyle(
            fontSize: 13,
            color: provider.selectedEmployeeFilter == 'All'
                ? Colors.grey[600]
                : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? value) {
            if (value != null) {
              provider.setEmployeeFilter(value);
            }
          },
          items: [
            DropdownMenuItem<String>(
              value: 'All',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '👥',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'All Employees',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...provider.employeeNames.where((name) => name != 'All').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            value.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentFilter(AttendanceProvider provider) {
    return Container(
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Iconsax.arrow_down_1,
              size: 14,
              color: Color(0xFF667EEA),
            ),
          ),
          style: TextStyle(
            fontSize: 12,
            color: provider.selectedDepartmentFilter == 'All'
                ? Colors.grey[600]
                : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? value) {
            if (value != null) {
              provider.setDepartmentFilter(value);
            }
          },
          items: [
            DropdownMenuItem<String>(
              value: 'All',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🏢',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'All Depts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...provider.departmentNames.where((dept) => dept != 'All').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            value.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AttendanceProvider provider) {
    return SizedBox(
      height: 110,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        itemBuilder: (context, index) {
          final stats = [
            {
              'icon': Iconsax.tick_circle,
              'title': 'Present',
              'count': provider.totalPresent.toString(),
              'color': const Color(0xFF4CAF50),
            },
            {
              'icon': Iconsax.clock,
              'title': 'Late',
              'count': provider.totalLate.toString(),
              'color': const Color(0xFFFF9800),
            },
            {
              'icon': Iconsax.close_circle,
              'title': 'Absent',
              'count': provider.totalAbsent.toString(),
              'color': const Color(0xFFF44336),
            },
            {
              'icon': Iconsax.timer,
              'title': 'Overtime',
              'count': provider.totalOvertime.toString(),
              'color': const Color(0xFF2196F3),
            },
          ];

          final stat = stats[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
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
                    size: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['count'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: 9,
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

  Widget _buildAttendanceList() {
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
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchAttendance(),
                  child: const Text('Retry'),
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
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  provider.isAdmin
                      ? 'No attendance records found'
                      : 'No attendance records for you',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isAdmin
                      ? 'Try adding new attendance records'
                      : 'Contact admin if you think this is an error',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        return Column(
          children: [
            // Table Header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                    width: isSmallScreen ? 40 : 50,
                    child: Text(
                      'Sr.No',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date
                  Expanded(
                    flex: isSmallScreen ? 2 : 3,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Time In
                  Expanded(
                    flex: isSmallScreen ? 2 : 3,
                    child: Text(
                      'Time In',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Time Out
                  Expanded(
                    flex: isSmallScreen ? 2 : 3,
                    child: Text(
                      'Time Out',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Status
                  Expanded(
                    flex: isSmallScreen ? 2 : 3,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Actions (Admin only)
                  if (provider.isAdmin)
                    SizedBox(
                      width: isSmallScreen ? 30 : 40,
                      child: Text(
                        isSmallScreen ? '' : 'Actions',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
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
                    // onTap: () {
                    //   provider.navigateToViewScreen(context, attendance);
                    // },
                    child: _buildTableRow(attendance, provider.isAdmin, serialNo),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableRow(Attendance attendance, bool isAdmin, int serialNo) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
        child: Row(
          children: [
            // Serial Number
            SizedBox(
              width: isSmallScreen ? 40 : 50,
              child: Text(
                serialNo.toString(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // Date Column
            Expanded(
              flex: isSmallScreen ? 2 : 3,
              child: Text(
                _formatDate(attendance.date),
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            // Time In Column
            Expanded(
              flex: isSmallScreen ? 2 : 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 8,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          attendance.timeIn.isNotEmpty
                              ? attendance.timeIn.substring(0, 5)
                              : '--:--',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (attendance.lateMinutes > 0) ...[
                          const SizedBox(height: 2),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          //   decoration: BoxDecoration(
                          //     color: Colors.orange.withOpacity(0.1),
                          //     borderRadius: BorderRadius.circular(4),
                          //   ),
                          //   // child: Text(
                          //   //   '${attendance.lateMinutes}m',
                          //   //   style: TextStyle(
                          //   //     fontSize: isSmallScreen ? 9 : 10,
                          //   //     color: Colors.orange[700],
                          //   //     fontWeight: FontWeight.w500,
                          //   //   ),
                          //   //   textAlign: TextAlign.center,
                          //   // ),
                          // ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Time Out Column
            Expanded(
              flex: isSmallScreen ? 2 : 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 8,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          attendance.timeOut.isNotEmpty
                              ? attendance.timeOut.substring(0, 5)
                              : '--:--',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (attendance.overtimeMinutes > 0) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OT: ${attendance.overtimeMinutes}m',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 10,
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
              flex: isSmallScreen ? 2 : 3,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 4 : 8,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: attendance.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attendance.status,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: attendance.statusColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attendance.lateMinutes > 0 && attendance.status.toLowerCase() == 'late') ...[
                      const SizedBox(height: 2),
                      Text(
                        'Late by ${attendance.lateMinutes}m',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 9,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (attendance.status.toLowerCase() == 'on time') ...[
                      const SizedBox(height: 2),
                      Text(
                        'Perfect',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 9,
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
            // Actions Column (for Admin only)
            // if (isAdmin)
            //   SizedBox(
            //     width: isSmallScreen ? 30 : 40,
            //     child: PopupMenuButton(
            //       itemBuilder: (context) => [
            //         const PopupMenuItem(
            //           value: 'edit',
            //           child: Row(
            //             children: [
            //               Icon(Iconsax.edit, size: 16),
            //               SizedBox(width: 8),
            //               Text('Edit'),
            //             ],
            //           ),
            //         ),
            //         const PopupMenuItem(
            //           value: 'view',
            //           child: Row(
            //             children: [
            //               Icon(Iconsax.eye, size: 16),
            //               SizedBox(width: 8),
            //               Text('View Details'),
            //             ],
            //           ),
            //         ),
            //         const PopupMenuItem(
            //           value: 'delete',
            //           child: Row(
            //             children: [
            //               Icon(Iconsax.trash, size: 16, color: Colors.red),
            //               SizedBox(width: 8),
            //               Text('Delete', style: TextStyle(color: Colors.red)),
            //             ],
            //           ),
            //         ),
            //       ],
            //       onSelected: (value) {
            //         if (value == 'edit') {
            //           _provider.navigateToEditScreen(context, attendance);
            //         } else if (value == 'view') {
            //           _provider.navigateToViewScreen(context, attendance);
            //         } else if (value == 'delete') {
            //           _showDeleteDialog(attendance);
            //         }
            //       },
            //       child: Container(
            //         width: isSmallScreen ? 28 : 32,
            //         height: isSmallScreen ? 28 : 32,
            //         decoration: BoxDecoration(
            //           color: Colors.grey[100],
            //           borderRadius: BorderRadius.circular(8),
            //         ),
            //         child: Icon(
            //           Iconsax.more,
            //           size: isSmallScreen ? 14 : 16,
            //           color: Colors.grey,
            //         ),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  // void _showDeleteDialog(Attendance attendance) {
  //   final provider = Provider.of<AttendanceProvider>(context, listen: false);
  //
  //   if (!provider.isAdmin) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Only administrators can delete attendance records'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Row(
  //         children: [
  //           Icon(Iconsax.trash, color: Colors.red),
  //           SizedBox(width: 12),
  //           Text('Delete Attendance'),
  //         ],
  //       ),
  //       content: Text(
  //         'Are you sure you want to delete attendance record for ${attendance.employeeName} on ${_formatDate(attendance.date)}?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             final success = await _provider.deleteAttendance(attendance.id);
  //             if (success) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Attendance deleted successfully!'),
  //                   backgroundColor: Colors.green,
  //                 ),
  //               );
  //             } else {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text(_provider.error),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //             }
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.red,
  //           ),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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