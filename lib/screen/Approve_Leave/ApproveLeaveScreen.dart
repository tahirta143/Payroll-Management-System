import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../model/leave_approve_model/leave_approve.dart';
import '../../provider/leave_approve_provider/leave_approve.dart';

class ApproveLeaveScreen extends StatefulWidget {
  const ApproveLeaveScreen({super.key});

  @override
  State<ApproveLeaveScreen> createState() => _ApproveLeaveScreenState();
}

class _ApproveLeaveScreenState extends State<ApproveLeaveScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<LeaveProvider>(context, listen: false);

      // Initialize user role
      await provider.initializeUserRole();

      // Debug
      print('=== INIT COMPLETE ===');
      print('User Role: ${provider.userRole}');
      print('isAdmin: ${provider.isAdmin}');
      print('User ID: ${provider.currentUserId}');

      // Fetch leaves
      await provider.fetchLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveProvider>(context);

    // Debug: Print admin status
    print('=== SCREEN BUILD ===');
    print('isAdmin: ${leaveProvider.isAdmin}');
    print('leaves count: ${leaveProvider.leaves.length}');
    if (leaveProvider.leaves.isNotEmpty) {
      print('First leave status: ${leaveProvider.leaves.first.status}');
    }

    // Show success/error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (leaveProvider.successMessage.isNotEmpty) {
        _showSnackBar(leaveProvider.successMessage);
        leaveProvider.clearMessages();
      }
      if (leaveProvider.error.isNotEmpty) {
        _showSnackBar(leaveProvider.error, isError: true);
        leaveProvider.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          leaveProvider.isAdmin ? 'Approve Leave' : 'My Leaves',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Debug button
          // IconButton(
          //   onPressed: () {
          //     print('=== DEBUG INFO ===');
          //     print('isAdmin: ${leaveProvider.isAdmin}');
          //     print('currentUserId: ${leaveProvider.currentUserId}');
          //     print('Total leaves: ${leaveProvider.leaves.length}');
          //     print('Pending leaves: ${leaveProvider.pendingCount}');
          //     if (leaveProvider.leaves.isNotEmpty) {
          //       for (var i = 0; i < min(3, leaveProvider.leaves.length); i++) {
          //         print('Leave $i: ${leaveProvider.leaves[i].status} - ${leaveProvider.leaves[i].employeeName}');
          //       }
          //     }
          //     _showSnackBar('Admin: ${leaveProvider.isAdmin}, Leaves: ${leaveProvider.leaves.length}');
          //   },
          //   icon: const Icon(Iconsax.info_circle, color: Colors.white),
          //   tooltip: 'Debug Info',
          // ),
          // New Leave Button
          IconButton(
            onPressed: () {
              print('=== NEW LEAVE BUTTON PRESSED ===');
              print('isAdmin: ${leaveProvider.isAdmin}');
              print('isLoading: ${leaveProvider.isLoading}');

              // Wrap in try-catch to see any errors
              try {
                _showNewLeaveDialog(context, leaveProvider);
              } catch (e, stackTrace) {
                print('Error showing dialog: $e');
                print('Stack trace: $stackTrace');
                _showSnackBar('Error: $e', isError: true);
              }
            },
            icon: const Icon(Iconsax.add, color: Colors.white),
            tooltip: 'New Leave Request',
          ),
          // Refresh button
          IconButton(
            onPressed: () => leaveProvider.fetchLeaves(),
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
          if (leaveProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
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
              // Search and Filter Section
              _buildSearchFilterSection(leaveProvider),

              // Statistics Cards - Only show for admin
              if (leaveProvider.isAdmin) _buildStatisticsCards(leaveProvider),

              const SizedBox(height: 16),

              // Leave Requests List
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
                  child: _buildLeaveList(leaveProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilterSection(LeaveProvider provider) {
    // Debug: Print filter section info
    print('=== FILTER SECTION ===');
    print('isAdmin: ${provider.isAdmin}');
    print('employees count: ${provider.employees.length}');

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
          // Search Bar
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
                hintText: 'Search by employee name or ID...',
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
          // Filter Row
          Row(
            children: [
              // Employee Filter - Only show for admin
              if (provider.isAdmin)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF8F9FA)],
                      ),
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
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.arrow_down_1,
                            size: 16,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                        elevation: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: provider.selectedEmployeeFilter == 'All'
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        menuMaxHeight: 300,
                        onChanged: (String? value) {
                          if (value != null) {
                            provider.setEmployeeFilter(value);
                          }
                        },
                        items: provider.employees.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: value == provider.employees.last ? 0 : 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
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
                                        value == 'All' ? '👥' : value.substring(0, 1),
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
                                      value == 'All' ? 'All Employees' : value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (value == provider.selectedEmployeeFilter &&
                                      value != 'All')
                                    Icon(
                                      Iconsax.tick_circle,
                                      size: 16,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              if (provider.isAdmin) const SizedBox(width: 8),
              // Department Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                    ),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.arrow_down_1,
                          size: 14,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      elevation: 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.selectedDepartmentFilter == 'All'
                            ? Colors.grey[600]
                            : Colors.black87,
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
                      items: provider.departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: value == provider.departments.last ? 0 : 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 28,
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
                                      value.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    value == 'All' ? 'All Departments' : value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (value == provider.selectedDepartmentFilter &&
                                    value != 'All')
                                  Icon(
                                    Iconsax.tick_circle,
                                    size: 14,
                                    color: const Color(0xFF4CAF50),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Filter
              Container(
                width: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                    ),
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
                      value: provider.selectedStatusFilter,
                      isExpanded: true,
                      icon: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.arrow_down_1,
                          size: 14,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      elevation: 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.selectedStatusFilter == 'All'
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      menuMaxHeight: 300,
                      onChanged: (String? value) {
                        if (value != null) {
                          provider.setStatusFilter(value);
                        }
                      },
                      items: provider.statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(
                              value == 'All' ? 'All Status' : value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(LeaveProvider provider) {
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
              'icon': Iconsax.clock,
              'title': 'Pending',
              'count': provider.pendingCount.toString(),
              'color': const Color(0xFFFF9800),
            },
            {
              'icon': Iconsax.tick_circle,
              'title': 'Approved',
              'count': provider.approvedCount.toString(),
              'color': const Color(0xFF4CAF50),
            },
            {
              'icon': Iconsax.close_circle,
              'title': 'Rejected',
              'count': provider.rejectedCount.toString(),
              'color': const Color(0xFFF44336),
            },
            {
              'icon': Iconsax.calendar,
              'title': 'Total Days',
              'count': provider.totalDays.toString(),
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

  Widget _buildLeaveList(LeaveProvider provider) {
    if (provider.isLoading && provider.leaves.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.error}',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchLeaves(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.note_remove, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No leave requests found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isAdmin
                  ? 'Try adjusting your filters'
                  : 'You have no leave requests yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (MediaQuery.of(context).size.width > 600)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Employee',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Leave Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (provider.isAdmin) const SizedBox(width: 60),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.leaves.length,
            itemBuilder: (context, index) {
              final leave = provider.leaves[index];
              return _buildLeaveRequestCard(leave, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestCard(ApproveLeave leave, LeaveProvider provider) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final statusColor = _getStatusColor(leave.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWideScreen
          ? _buildWideCard(leave, statusColor, provider)
          : _buildCompactCard(leave, statusColor, provider),
    );
  }

  Widget _buildWideCard(ApproveLeave leave, Color statusColor, LeaveProvider provider) {
    final isPending = leave.status.toLowerCase() == 'pending';
    final shouldShowButtons = provider.isAdmin && isPending;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                          leave.employeeName.split(' ').map((n) => n[0]).join(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            leave.employeeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            leave.employeeCode,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Leave Type
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: _getLeaveTypeColor(leave.natureOfLeave).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getLeaveTypeColor(leave.natureOfLeave).withOpacity(0.3),
                ),
              ),
              child: Text(
                _formatLeaveType(leave.natureOfLeave),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getLeaveTypeColor(leave.natureOfLeave),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Days
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${leave.days}d',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667EEA),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _capitalizeStatus(leave.status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Action Buttons - Only show if admin and leave is pending
          SizedBox(
            width: 60,
            child: shouldShowButtons
                ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _approveLeave(leave.id, provider),
                  icon: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Iconsax.tick_circle,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Approve',
                ),
                IconButton(
                  onPressed: () => _rejectLeave(leave.id, provider),
                  icon: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Iconsax.close_circle,
                      size: 16,
                      color: Color(0xFFF44336),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Reject',
                ),
              ],
            )
                : Container(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                isPending ? 'Pending' : _capitalizeStatus(leave.status),
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(ApproveLeave leave, Color statusColor, LeaveProvider provider) {
    final shouldShowButtons = provider.isAdmin && _isPendingStatus(leave.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                      leave.employeeName.split(' ').map((n) => n[0]).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.employeeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        leave.departmentName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Pay mode indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: leave.payMode == 'with_pay'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    leave.payMode == 'with_pay' ? Iconsax.money_add : Iconsax.money_remove,
                    size: 12,
                    color: leave.payMode == 'with_pay' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatPayMode(leave.payMode),
                    style: TextStyle(
                      fontSize: 11,
                      color: leave.payMode == 'with_pay' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Leave type, days, status row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLeaveTypeColor(leave.natureOfLeave).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getLeaveTypeColor(leave.natureOfLeave).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _formatLeaveType(leave.natureOfLeave),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getLeaveTypeColor(leave.natureOfLeave),
                    ),
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${leave.days} ${leave.days == 1 ? 'Day' : 'Days'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalizeStatus(leave.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date range
            Row(
              children: [
                Icon(Iconsax.calendar, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatDate(leave.fromDate)} to ${_formatDate(leave.toDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action Buttons - Only show if admin and leave is pending
            if (shouldShowButtons && leave.id != null)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveLeave(leave.id!, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Iconsax.tick_circle, size: 16,color: Colors.white,),
                          label: const Text(
                            'Approve',
                            style: TextStyle(fontSize: 12,color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectLeave(leave.id!, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Iconsax.close_circle, size: 16,color: Colors.white,),
                          label: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 12,color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _isPendingStatus(String status) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus.contains('pending') ||
        lowerStatus == 'p' ||
        lowerStatus == '0' ||
        lowerStatus.contains('waiting') ||
        lowerStatus.contains('request');
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('approved') || lowerStatus == '1') {
      return const Color(0xFF4CAF50);
    } else if (lowerStatus.contains('rejected') || lowerStatus == '2') {
      return const Color(0xFFF44336);
    } else if (_isPendingStatus(status)) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFF9E9E9E);
    }
  }

  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'sick_leave':
        return const Color(0xFF2196F3);
      case 'annual_leave':
        return const Color(0xFF4CAF50);
      case 'emergency_leave':
        return const Color(0xFFF44336);
      case 'maternity_leave':
        return const Color(0xFF9C27B0);
      case 'urgent_work':
        return const Color(0xFFFF9800);
      case 'casual_leave':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF667EEA);
    }
  }

  String _formatLeaveType(String type) {
    final typeMap = {
      'sick_leave': 'Sick Leave',
      'annual_leave': 'Annual Leave',
      'emergency_leave': 'Emergency Leave',
      'maternity_leave': 'Maternity Leave',
      'urgent_work': 'Urgent Work',
      'casual_leave': 'Casual Leave',
    };
    return typeMap[type] ?? type.replaceAll('_', ' ').toTitleCase();
  }

  String _formatPayMode(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'with_pay':
      case 'with pay':
        return 'With Pay';
      case 'without_pay':
      case 'without pay':
        return 'Without Pay';
      default:
        return payMode.replaceAll('_', ' ').toTitleCase();
    }
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return status;
    if (_isPendingStatus(status)) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _approveLeave(int leaveId, LeaveProvider provider) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Leave'),
        content: const Text('Are you sure you want to approve this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await provider.approveLeave(leaveId);
      _showSnackBar('Leave approved successfully!');
    } catch (e) {
      _showSnackBar('Failed to approve leave: $e', isError: true);
    }
  }

  Future<void> _rejectLeave(int leaveId, LeaveProvider provider) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: const Text('Are you sure you want to reject this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await provider.rejectLeave(leaveId);
      _showSnackBar('Leave rejected successfully!');
    } catch (e) {
      _showSnackBar('Failed to reject leave: $e', isError: true);
    }
  }

  // FIXED: New Leave Dialog with all features
  Future<void> _showNewLeaveDialog(BuildContext context, LeaveProvider provider) async {
    print('=== SHOW NEW LEAVE DIALOG START ===');

    // For admin users, fetch employees first
    if (provider.isAdmin) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Loading employees...'),
              ],
            ),
          ),
        );

        await provider.fetchAllEmployees();

        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Check if we have employees
        if (provider.allEmployees.isEmpty) {
          _showSnackBar('No employees found. Please try again.', isError: true);
          return;
        }

      } catch (e) {
        print('Error fetching employees: $e');
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        _showSnackBar('Failed to load employees: $e', isError: true);
        return;
      }
    }

    // Variables for form
    int? selectedEmployeeId;
    String? selectedLeaveType;
    String? selectedPayMode;
    DateTime? fromDate;
    DateTime? toDate;
    int days = 0;
    String reason = '';

    void calculateDays() {
      if (fromDate != null && toDate != null) {
        days = toDate!.difference(fromDate!).inDays + 1;
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF667EEA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.note_add, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'New Leave Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Employee Dropdown - Only for admin
                            if (provider.isAdmin) ...[
                              const Text(
                                'Select Employee *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedEmployeeId,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    icon: const Icon(Iconsax.arrow_down_1),
                                    elevation: 2,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    hint: const Text('Select Employee'),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedEmployeeId = value;
                                      });
                                    },
                                    items: provider.allEmployees.map((employee) {
                                      return DropdownMenuItem<int>(
                                        value: employee['id'],
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
                                                  employee['name'].toString().substring(0, 1),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    employee['name'].toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'ID: ${employee['employee_code']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Leave Type Dropdown
                            const Text(
                              'Leave Type *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedLeaveType,
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  icon: const Icon(Iconsax.arrow_down_1),
                                  elevation: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  hint: const Text('Select Leave Type'),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedLeaveType = value;
                                    });
                                  },
                                  items: provider.leaveTypes.map((type) {
                                    String displayName = type.replaceAll('_', ' ').toTitleCase();
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(displayName),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date Range
                            const Text(
                              'Date Range *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'From Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () async {
                                          final selectedDate = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (selectedDate != null) {
                                            setState(() {
                                              fromDate = selectedDate;
                                              calculateDays();
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Iconsax.calendar_1, size: 18, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                fromDate == null ? 'Select Date' : _formatDate(fromDate!),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: fromDate == null ? Colors.grey : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'To Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () async {
                                          final selectedDate = await showDatePicker(
                                            context: context,
                                            initialDate: fromDate ?? DateTime.now(),
                                            firstDate: fromDate ?? DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (selectedDate != null) {
                                            setState(() {
                                              toDate = selectedDate;
                                              calculateDays();
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Iconsax.calendar_1, size: 18, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                toDate == null ? 'Select Date' : _formatDate(toDate!),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: toDate == null ? Colors.grey : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Days Counter
                            if (days > 0)
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF667EEA).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF667EEA).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Days:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF667EEA),
                                          ),
                                        ),
                                        Text(
                                          '$days ${days == 1 ? 'Day' : 'Days'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF667EEA),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            // Pay Mode Dropdown
                            const Text(
                              'Pay Mode *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPayMode,
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  icon: const Icon(Iconsax.arrow_down_1),
                                  elevation: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  hint: const Text('Select Pay Mode'),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPayMode = value;
                                    });
                                  },
                                  items: provider.payModes.map((mode) {
                                    return DropdownMenuItem<String>(
                                      value: mode,
                                      child: Row(
                                        children: [
                                          Icon(
                                            mode == 'With Pay' ? Iconsax.money_add : Iconsax.money_remove,
                                            color: mode == 'With Pay' ? Colors.green : Colors.orange,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(mode),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Reason TextField
                            const Text(
                              'Reason (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(12),
                                  border: InputBorder.none,
                                  hintText: 'Enter reason for leave...',
                                ),
                                onChanged: (value) {
                                  reason = value;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Validation
                                if (provider.isAdmin && selectedEmployeeId == null) {
                                  _showSnackBar('Please select an employee', isError: true);
                                  return;
                                }
                                if (selectedLeaveType == null) {
                                  _showSnackBar('Please select leave type', isError: true);
                                  return;
                                }
                                if (selectedPayMode == null) {
                                  _showSnackBar('Please select pay mode', isError: true);
                                  return;
                                }
                                if (fromDate == null) {
                                  _showSnackBar('Please select from date', isError: true);
                                  return;
                                }
                                if (toDate == null) {
                                  _showSnackBar('Please select to date', isError: true);
                                  return;
                                }
                                if (toDate!.isBefore(fromDate!)) {
                                  _showSnackBar('To date cannot be before from date', isError: true);
                                  return;
                                }
                                if (days <= 0) {
                                  _showSnackBar('Please select valid dates', isError: true);
                                  return;
                                }

                                bool success;

                                // Call appropriate method based on user role
                                if (provider.isAdmin) {
                                  success = await provider.submitLeave(
                                    selectedEmployeeId: selectedEmployeeId!,
                                    natureOfLeave: selectedLeaveType!,
                                    fromDate: fromDate!,
                                    toDate: toDate!,
                                    days: days,
                                    payMode: selectedPayMode!,
                                    reason: reason.isNotEmpty ? reason : null,
                                  );
                                } else {
                                  success = await provider.submitLeaveForSelf(
                                    natureOfLeave: selectedLeaveType!,
                                    fromDate: fromDate!,
                                    toDate: toDate!,
                                    days: days,
                                    payMode: selectedPayMode!,
                                    reason: reason.isNotEmpty ? reason : null,
                                  );
                                }

                                if (success && mounted) {
                                  _showSnackBar('Leave request submitted successfully!');
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Submit Request'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    print('=== SHOW NEW LEAVE DIALOG END ===');
  }
}

extension StringExtension on String {
  String toTitleCase() {
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}