import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ApproveLeaveScreen extends StatefulWidget {
  const ApproveLeaveScreen({super.key});

  @override
  State<ApproveLeaveScreen> createState() => _ApproveLeaveScreenState();
}

class _ApproveLeaveScreenState extends State<ApproveLeaveScreen> {
  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      employeeName: 'John Smith',
      employeeId: 'EMP-001',
      leaveType: 'Sick Leave',
      days: 3,
      startDate: '2026-01-15',
      endDate: '2026-01-17',
      reason: 'High fever and flu symptoms',
      status: 'Pending',
      department:'Developer',
    ),
    LeaveRequest(
      employeeName: 'Sarah Johnson',
      employeeId: 'EMP-002',
      leaveType: 'Annual Leave',
      days: 7,
      startDate: '2026-01-20',
      endDate: '2026-01-26',
      reason: 'Family vacation',
      status: 'Approved',
      department:'Developer',
    ),
    LeaveRequest(
      employeeName: 'Michael Chen',
      employeeId: 'EMP-003',
      leaveType: 'Emergency Leave',
      days: 1,
      startDate: '2026-01-18',
      endDate: '2026-01-18',
      reason: 'Medical emergency',
      status: 'Pending',
      department:'Developer',
    ),
    LeaveRequest(
      employeeName: 'Emma Wilson',
      employeeId: 'EMP-004',
      leaveType: 'Maternity Leave',
      days: 90,
      startDate: '2026-02-01',
      endDate: '2026-04-30',
      reason: 'Maternity period',
      status: 'Pending',
      department:'Intern',
    ),
    LeaveRequest(
      employeeName: 'Robert Brown',
      employeeId: 'EMP-005',
      leaveType: 'Casual Leave',
      days: 2,
      startDate: '2026-01-22',
      endDate: '2026-01-23',
      reason: 'Personal work',
      status: 'Rejected',
      department:'Intern',
    ),
    LeaveRequest(
      employeeName: 'Lisa Anderson',
      employeeId: 'EMP-006',
      leaveType: 'Sick Leave',
      days: 1,
      startDate: '2026-01-19',
      endDate: '2026-01-19',
      reason: 'Doctor appointment',
      status: 'Pending',
      department:'Office Boy',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Developer', 'Intern', 'Office Boy'];
  String _selectedFilterEmployee = 'All';
  final List<String> _filterEmployeeOptions = ['All', 'John Smith', 'Sarah Johnson', 'Michael Chen','Emma Wilson','Robert Brown','Lisa Anderson'];

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _leaveRequests.where((request) {
      final matchesSearch = _searchController.text.isEmpty ||
          request.employeeName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          request.employeeId
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          request.department == _selectedFilter;
      final matchesFilterEmployee = _selectedFilterEmployee == 'All' ||
          request.employeeName == _selectedFilterEmployee;



      return matchesSearch && matchesFilter && matchesFilterEmployee;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Approve Leave',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
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
              _buildSearchFilterSection(),

              // Statistics Cards
              //_buildStatisticsCards(),

              //const SizedBox(height: 25),

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
                  child: Column(
                    children: [
                      // List Header - Only show on larger screens
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
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
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
                              Expanded(
                                child: Text(
                                  'Leave Type',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(width: 60),
                            ],
                          ),
                        ),

                      // Leave Requests List
                      Expanded(
                        child: filteredRequests.isEmpty
                            ? Center(
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
                                'No leave requests found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = filteredRequests[index];
                            return _buildLeaveRequestCard(request, index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilterSection() {
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
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by employee name or ID...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Iconsax.close_circle, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
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
              // Date Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
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
                      value: _selectedFilterEmployee,
                      isExpanded: true,
                      icon: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        // padding: const EdgeInsets.all(4),
                        // child: Icon(
                        //   Iconsax.arrow_down_1,
                        //   size: 16,
                        //   color: const Color(0xFF667EEA),
                        // ),
                      ),
                      elevation: 2,
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedFilterEmployee == 'All'
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      menuMaxHeight: 300,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFilterEmployee = value!;
                        });
                      },
                      items: _filterEmployeeOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: value == _filterEmployeeOptions.last ? 0 : 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
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
                                    value == 'All' ? 'Employee' : value,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (value == _selectedFilterEmployee && value != 'All')
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

              const SizedBox(width: 8),

              // Status Filter
              Container(
                width: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
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
                    value: _selectedFilter,
                    isExpanded: true,
                    icon: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      //padding: const EdgeInsets.all(4),
                      // child: Icon(
                      //   Iconsax.arrow_down_1,
                      //   size: 14,
                      //   color: const Color(0xFF667EEA),
                      // ),
                    ),
                    elevation: 2,
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedFilter == 'All'
                          ? Colors.grey[600]
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 300,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                    items: _filterOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: value == _filterOptions.last ? 0 : 1,
                              ),
                            ),
                          ),
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
                                  value == 'All' ? 'Department' : value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (value == _selectedFilter && value != 'All')
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

              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final pendingCount = _leaveRequests.where((r) => r.status == 'Pending').length;
    final approvedCount = _leaveRequests.where((r) => r.status == 'Approved').length;
    final rejectedCount = _leaveRequests.where((r) => r.status == 'Rejected').length;
    final totalDays = _leaveRequests.fold(0, (sum, r) => sum + r.days);

    final stats = [
      {
        'icon': Iconsax.clock,
        'title': 'Pending',
        'count': pendingCount.toString(),
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Iconsax.tick_circle,
        'title': 'Approved',
        'count': approvedCount.toString(),
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Iconsax.close_circle,
        'title': 'Rejected',
        'count': rejectedCount.toString(),
        'color': const Color(0xFFF44336),
      },
      {
        'icon': Iconsax.calendar,
        'title': 'Total Days',
        'count': totalDays.toString(),
        'color': const Color(0xFF2196F3),
      },
    ];

    return SizedBox(
      height: 110, // Further reduced height
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0, // Square cards
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stats.length,
        itemBuilder: (context, index) {
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
            padding: const EdgeInsets.all(8), // Reduced padding
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

  Widget _buildLeaveRequestCard(LeaveRequest request, int index) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    Color statusColor;
    switch (request.status) {
      case 'Approved':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Rejected':
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusColor = const Color(0xFFFF9800);
    }

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
      child: isWideScreen ? _buildWideCard(request, statusColor) : _buildCompactCard(request, statusColor),
    );
  }

  Widget _buildWideCard(LeaveRequest request, Color statusColor) {
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
                          request.employeeName.split(' ').map((n) => n[0]).join(),
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
                            request.employeeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            request.employeeId,
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
                color: _getLeaveTypeColor(request.leaveType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getLeaveTypeColor(request.leaveType).withOpacity(0.3),
                ),
              ),
              child: Text(
                request.leaveType,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getLeaveTypeColor(request.leaveType),
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
                  '${request.days}d',
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
                request.status,
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

          // Action Buttons
          SizedBox(
            width: 60,
            child: request.status == 'Pending'
                ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _approveLeave(request),
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
                ),
                IconButton(
                  onPressed: () => _rejectLeave(request),
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
                ),
              ],
            )
                : const SizedBox(width: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(LeaveRequest request, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    request.employeeName.split(' ').map((n) => n[0]).join(),
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
                      request.employeeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      request.department,
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

          // Details Row
          Row(
            children: [
              // Leave Type
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLeaveTypeColor(request.leaveType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getLeaveTypeColor(request.leaveType).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    request.leaveType,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getLeaveTypeColor(request.leaveType),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Days
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${request.days} ${request.days == 1 ? 'Day' : 'Days'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status,
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

          // Date and Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Iconsax.calendar,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${request.startDate} to ${request.endDate}',
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
              ),

              if (request.status == 'Pending')
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _approveLeave(request),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.tick_circle,
                              size: 14,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Approve',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      onPressed: () => _rejectLeave(request),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.close_circle,
                              size: 14,
                              color: Color(0xFFF44336),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFFF44336),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'Sick Leave':
        return const Color(0xFF2196F3);
      case 'Annual Leave':
        return const Color(0xFF4CAF50);
      case 'Emergency Leave':
        return const Color(0xFFF44336);
      case 'Maternity Leave':
        return const Color(0xFF9C27B0);
      case 'Casual Leave':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF667EEA);
    }
  }



  void _approveLeave(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Leave'),
        content: Text('Are you sure you want to approve ${request.employeeName}\'s leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                request.status = 'Approved';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Leave request approved for ${request.employeeName}'),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectLeave(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: Text('Are you sure you want to reject ${request.employeeName}\'s leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                request.status = 'Rejected';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Leave request rejected for ${request.employeeName}'),
                  backgroundColor: const Color(0xFFF44336),
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class LeaveRequest {
  final String employeeName;
  final String employeeId;
  final String leaveType;
  final int days;
  final String startDate;
  final String endDate;
  final String reason;
  String status;
  final String department;

  LeaveRequest({
    required this.employeeName,
    required this.employeeId,
    required this.leaveType,
    required this.days,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.department,
  });
}