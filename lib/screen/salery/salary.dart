import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMonth = 'January 2024';
  String _selectedStatus = 'All Status';

  final List<String> _months = [
    'January 2024',
    'February 2024',
    'March 2024',
    'April 2024',
    'May 2024',
    'June 2024',
  ];

  final List<String> _statuses = [
    'All Status',
    'Paid',
    'Pending',
    'Processing',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Salary Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.document_download),
            onPressed: () {
              _showBulkDownloadDialog();
            },
          ),
        ],
      ),
      body: Container(
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
            _buildSearchFilterSection(context),

            // Statistics Cards
            _buildStatisticsCards(),

            const SizedBox(height: 16),

            // Salary List
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                child: _buildSalaryList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilterSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
              decoration: InputDecoration(
                hintText: 'Search employee name or ID...',
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
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 16),

          // Filter Row
          isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        // Month Filter
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: InkWell(
            onTap: () {
              _showMonthFilterDialog(context);
            },
            child: Row(
              children: [
                Icon(Iconsax.calendar_1, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedMonth,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Iconsax.arrow_down_1, size: 16, color: Colors.grey[500]),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Status Filter
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: InkWell(
            onTap: () {
              _showStatusFilterDialog(context);
            },
            child: Row(
              children: [
                Icon(Iconsax.wallet_money, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedStatus,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Iconsax.arrow_down_1, size: 16, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: [
        // Month Filter
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: InkWell(
              onTap: () {
                _showMonthFilterDialog(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Iconsax.calendar_1, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedMonth,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Iconsax.arrow_down_1, size: 14, color: Colors.grey[500]),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Status Filter
        Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: InkWell(
            onTap: () {
              _showStatusFilterDialog(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Iconsax.wallet_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Iconsax.arrow_down_1, size: 14, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Filter Button
        InkWell(
          onTap: () {
            _showAdvancedFilterDialog(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.filter,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard(
            icon: Iconsax.wallet_money,
            title: 'Total Paid',
            value: '₹2,45,000',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            icon: Iconsax.clock,
            title: 'Pending',
            value: '₹45,000',
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            icon: Iconsax.money_send,
            title: 'This Month',
            value: '₹85,000',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            icon: Iconsax.profile_2user,
            title: 'Employees',
            value: '24',
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 140,
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
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryList(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // List Header (Desktop only)
        if (!isMobile)
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
                  flex: 2,
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
                    'Month',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Base Salary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Net Pay',
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
                SizedBox(width: 40),
              ],
            ),
          ),

        // Salary List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSalaryItem(context, isMobile, 'John Doe', 'EMP001', 'Engineering', 'Paid'),
              const SizedBox(height: 8),
              _buildSalaryItem(context, isMobile, 'Sarah Johnson', 'EMP002', 'Marketing', 'Pending'),
              const SizedBox(height: 8),
              _buildSalaryItem(context, isMobile, 'Michael Chen', 'EMP003', 'Development', 'Processing'),
              const SizedBox(height: 8),
              _buildSalaryItem(context, isMobile, 'Emma Wilson', 'EMP004', 'Design', 'Paid'),
              const SizedBox(height: 8),
              _buildSalaryItem(context, isMobile, 'Robert Brown', 'EMP005', 'Sales', 'Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryItem(BuildContext context, bool isMobile, String name, String empId, String department, String status) {
    return isMobile
        ? _buildMobileSalaryItem(name, empId, department, status)
        : _buildDesktopSalaryItem(name, empId, department, status);
  }

  Widget _buildMobileSalaryItem(String name, String empId, String department, String status) {
    Color statusColor;
    switch (status) {
      case 'Paid':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Info
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
                    name.split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$empId • $department',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Salary Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMonth,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Text(
                      '₹52,500',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Base: ₹50,000',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Deductions: ₹4,500',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showSalaryDetailsDialog(name, empId, department, status);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667EEA),
                    side: const BorderSide(color: Color(0xFF667EEA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Iconsax.eye, size: 16),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPayslipDialog(name, empId, department, status);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Iconsax.document_download, size: 16),
                  label: const Text('Payslip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSalaryItem(String name, String empId, String department, String status) {
    Color statusColor;
    switch (status) {
      case 'Paid':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Employee Info
          Expanded(
            flex: 2,
            child: Row(
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
                      name.split(' ').map((n) => n[0]).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$empId • $department',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Month
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedMonth,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Paid: 31 Jan',
                  style: TextStyle(
                    fontSize: 11,
                    color: status == 'Paid' ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Base Salary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '₹50,000',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Bonus: ₹5,000',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),

          // Net Pay
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '₹52,500',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667EEA),
                  ),
                ),
                Text(
                  'Deductions: ₹4,500',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),

          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view') {
                _showSalaryDetailsDialog(name, empId, department, status);
              } else if (value == 'payslip') {
                _showPayslipDialog(name, empId, department, status);
              } else if (value == 'download') {
                _downloadPayslip(name);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Iconsax.eye, size: 16, color: Color(0xFF667EEA)),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'payslip',
                child: Row(
                  children: [
                    Icon(Iconsax.document_text, size: 16, color: Color(0xFF667EEA)),
                    SizedBox(width: 8),
                    Text('View Payslip'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Iconsax.document_download, size: 16, color: Color(0xFF667EEA)),
                    SizedBox(width: 8),
                    Text('Download Payslip'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.more,
                size: 16,
                color: Color(0xFF667EEA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Paid':
        return Iconsax.tick_circle;
      case 'Pending':
        return Iconsax.clock;
      case 'Processing':
        return Iconsax.refresh;
      case 'Cancelled':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  // Dialog Methods
  void _showMonthFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _months.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_months[index]),
                  trailing: _selectedMonth == _months[index]
                      ? const Icon(Iconsax.tick_circle, color: Color(0xFF4CAF50))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedMonth = _months[index];
                    });
                    Navigator.pop(context);
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

  void _showStatusFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Status'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_statuses[index]),
                  trailing: _selectedStatus == _statuses[index]
                      ? const Icon(Iconsax.tick_circle, color: Color(0xFF4CAF50))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedStatus = _statuses[index];
                    });
                    Navigator.pop(context);
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

  void _showAdvancedFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.filter, color: Color(0xFF667EEA)),
              SizedBox(width: 8),
              Text('Advanced Filters'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Department Filter
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Department',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Engineering', 'Marketing', 'Development', 'Design', 'Sales']
                      .map((dept) => FilterChip(
                    label: Text(dept),
                    selected: dept == 'All',
                    onSelected: (selected) {},
                  ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Salary Range
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Salary Range',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Min',
                          prefixText: '₹',
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Max',
                          prefixText: '₹',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filters applied successfully'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  void _showSalaryDetailsDialog(String name, String empId, String department, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Iconsax.wallet_money, color: Color(0xFF667EEA)),
              const SizedBox(width: 8),
              Text('Salary Details - $name'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Employee Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
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
                              name.split(' ').map((n) => n[0]).join(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: $empId • $department',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Month: $_selectedMonth',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Salary Breakdown
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Salary Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildBreakdownRow('Basic Salary', '₹40,000', Colors.blue),
                  _buildBreakdownRow('House Rent Allowance', '₹8,000', Colors.green),
                  _buildBreakdownRow('Medical Allowance', '₹2,000', Colors.green),
                  _buildBreakdownRow('Bonus', '₹5,000', Colors.green),

                  const Divider(),

                  _buildBreakdownRow('Total Earnings', '₹55,000', Colors.green, isBold: true),

                  const SizedBox(height: 12),

                  // Deductions
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Deductions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildBreakdownRow('Provident Fund', '₹2,000', Colors.red),
                  _buildBreakdownRow('Professional Tax', '₹200', Colors.red),
                  _buildBreakdownRow('Income Tax', '₹2,300', Colors.red),

                  const Divider(),

                  _buildBreakdownRow('Total Deductions', '₹4,500', Colors.red, isBold: true),

                  const Divider(thickness: 2),

                  // Net Pay
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net Pay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹52,500',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                _downloadPayslip(name);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.document_download, size: 16),
                  SizedBox(width: 8),
                  Text('Download Payslip'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPayslipDialog(String name, String empId, String department, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Payslip Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'PAYSLIP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Salary Month: January 2024',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Employee Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Employee Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Name: $name'),
                        Text('ID: $empId'),
                        Text('Department: $department'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Company Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Afaq MIS Pvt. Ltd.'),
                        const Text('HR Management System'),
                        Text('Status: $status'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Salary Table
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Basic Salary'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('40,000', textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Allowances'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('15,000', textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Deductions'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('-4,500', textAlign: TextAlign.right, style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[50]),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Net Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('52,500', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Footer
                const Divider(),
                const Text(
                  'This is a system generated payslip. No signature required.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Issued on: 01 February 2024',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBulkDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.document_download, color: Color(0xFF667EEA)),
              SizedBox(width: 8),
              Text('Download Multiple Payslips'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select which payslips to download:'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('All Employees'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Only Paid Employees'),
                value: false,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Current Month Only'),
                value: true,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Password (if required)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payslips are being downloaded...'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Download All'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreakdownRow(String title, String amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPayslip(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading payslip for $name...'),
        backgroundColor: const Color(0xFF4CAF50),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Open the downloaded file
          },
        ),
      ),
    );
  }
}