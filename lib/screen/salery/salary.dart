import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../model/employee_salary_model/employee_salary_model.dart';
import '../../provider/employee_salary_provider/employee_salary_provider.dart';


class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _basicSalaryController = TextEditingController();
  final TextEditingController _employeeCodeController = TextEditingController();

  String _selectedMonth = 'January 2024';
  String _selectedStatus = 'All Status';
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    // Use post frame callback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalaries();
    });
  }

  Future<void> _loadSalaries() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final provider = Provider.of<EmployeeSalaryProvider>(context, listen: false);
    await provider.fetchEmployeeSalaries();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _basicSalaryController.dispose();
    _employeeCodeController.dispose();
    super.dispose();
  }

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
            icon: const Icon(Iconsax.add),
            onPressed: () {
              _showAddSalaryDialog();
            },
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              _loadSalaries();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Consumer<EmployeeSalaryProvider>(
        builder: (context, provider, child) {
          if (provider.error.isNotEmpty && provider.salaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadSalaries,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredSalaries = provider.searchSalaries(_searchController.text);

          return Container(
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
                _buildStatisticsCards(provider.salaries),

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
                    child: _buildSalaryList(context, filteredSalaries, provider),
                  ),
                ),
              ],
            ),
          );
        },
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
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(List<EmployeeSalary> salaries) {
    final totalSalary = salaries.fold(0.0, (sum, salary) => sum + salary.netSalary);
    final pendingCount = salaries.where((s) => s.netSalary > 0).length;
    final avgSalary = salaries.isNotEmpty ? totalSalary / salaries.length : 0;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard(
            icon: Iconsax.wallet_money,
            title: 'Total Salary',
            value: '₹${totalSalary.toStringAsFixed(0)}',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            icon: Iconsax.profile_2user,
            title: 'Employees',
            value: '${salaries.length}',
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            icon: Iconsax.money_send,
            title: 'Avg Salary',
            value: '₹${avgSalary.toStringAsFixed(0)}',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            icon: Iconsax.clock,
            title: 'Active',
            value: '$pendingCount',
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

  Widget _buildSalaryList(BuildContext context, List<EmployeeSalary> salaries, EmployeeSalaryProvider provider) {
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
                    'Employee Code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Basic Salary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Net Salary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Payment Method',
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
          child: salaries.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.document, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No salaries found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'Try a different search'
                      : 'Add your first salary record',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: salaries.length,
            itemBuilder: (context, index) {
              return _buildSalaryItem(
                context,
                isMobile,
                salaries[index],
                provider,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryItem(
      BuildContext context,
      bool isMobile,
      EmployeeSalary salary,
      EmployeeSalaryProvider provider,
      ) {
    return isMobile
        ? _buildMobileSalaryItem(salary, provider)
        : _buildDesktopSalaryItem(salary, provider);
  }

  Widget _buildMobileSalaryItem(EmployeeSalary salary, EmployeeSalaryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
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
                    salary.employeeName.split(' ').map((n) => n[0]).join(),
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
                      salary.employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Code: ${salary.employeeCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'ID: ${salary.employeeId}',
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

          const SizedBox(height: 12),

          // Salary Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Salary',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₹${salary.basicSalary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Salary',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₹${salary.netSalary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Allowances & Deductions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allowances: ₹${salary.totalAllowances.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[600],
                      ),
                    ),
                    Text(
                      'Tax: ₹${salary.incomeTax.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[600],
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
                      salary.paymentMethod,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (salary.bankName != null)
                      Text(
                        salary.bankName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
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
                    _showSalaryDetailsDialog(salary);
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
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEditSalaryDialog(salary, provider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Iconsax.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmDialog(salary.id, provider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Iconsax.trash, size: 16),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDesktopSalaryItem(EmployeeSalary salary, EmployeeSalaryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
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
                      salary.employeeName.split(' ').map((n) => n[0]).join(),
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
                        salary.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'ID: ${salary.employeeId}',
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

          // Employee Code
          Expanded(
            child: Text(
              salary.employeeCode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Basic Salary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${salary.basicSalary.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Allowances: ₹${salary.totalAllowances.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),

          // Net Salary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${salary.netSalary.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  'Tax: ₹${salary.incomeTax.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),

          // Payment Method
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salary.paymentMethod,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (salary.bankName != null)
                  Text(
                    salary.bankName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view') {
                _showSalaryDetailsDialog(salary);
              } else if (value == 'edit') {
                _showEditSalaryDialog(salary, provider);
              } else if (value == 'delete') {
                _showDeleteConfirmDialog(salary.id, provider);
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
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Iconsax.edit, size: 16, color: Color(0xFF4CAF50)),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Iconsax.trash, size: 16, color: Color(0xFFF44336)),
                    SizedBox(width: 8),
                    Text('Delete'),
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

  // CRUD Dialog Methods
  void _showAddSalaryDialog() {
    _nameController.clear();
    _basicSalaryController.clear();
    _employeeCodeController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.add, color: Color(0xFF667EEA)),
              SizedBox(width: 8),
              Text('Add New Salary'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Iconsax.user),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _employeeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Iconsax.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _basicSalaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Basic Salary',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Iconsax.money),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _basicSalaryController.text.isNotEmpty) {
                  final provider = Provider.of<EmployeeSalaryProvider>(context, listen: false);

                  final newSalary = EmployeeSalary(
                    id: 0, // Will be assigned by server
                    employeeId: 0, // Should get from employee selection
                    basicSalary: double.parse(_basicSalaryController.text),
                    medicalAllowance: 0,
                    mobileAllowance: 0,
                    conveyanceAllowance: 0,
                    houseAllowance: 0,
                    utilityAllowance: 0,
                    miscellaneousAllowance: 0,
                    incomeTax: 0,
                    grossSalary: double.parse(_basicSalaryController.text),
                    netSalary: double.parse(_basicSalaryController.text),
                    noTax: false,
                    salaryByCash: true,
                    salaryByCheque: false,
                    salaryByTransfer: false,
                    accountNumber: null,
                    allowOvertime: false,
                    lateComingDeduction: false,
                    salaryAtAppointment: null,
                    lastIncrementDate: null,
                    incrementAmount: null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    employeeName: _nameController.text,
                    employeeCode: _employeeCodeController.text,
                    bankId: null,
                    bankAccountNumber: null,
                    bankName: null,
                  );

                  final success = await provider.createSalary(newSalary);
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Salary added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add salary: ${provider.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Salary'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSalaryDialog(EmployeeSalary salary, EmployeeSalaryProvider provider) {
    _nameController.text = salary.employeeName;
    _basicSalaryController.text = salary.basicSalary.toString();
    _employeeCodeController.text = salary.employeeCode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.edit, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Edit Salary'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Iconsax.user),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _employeeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Iconsax.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _basicSalaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Basic Salary',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Iconsax.money),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _basicSalaryController.text.isNotEmpty) {

                  final updatedSalary = EmployeeSalary(
                    id: salary.id,
                    employeeId: salary.employeeId,
                    basicSalary: double.parse(_basicSalaryController.text),
                    medicalAllowance: salary.medicalAllowance,
                    mobileAllowance: salary.mobileAllowance,
                    conveyanceAllowance: salary.conveyanceAllowance,
                    houseAllowance: salary.houseAllowance,
                    utilityAllowance: salary.utilityAllowance,
                    miscellaneousAllowance: salary.miscellaneousAllowance,
                    incomeTax: salary.incomeTax,
                    grossSalary: double.parse(_basicSalaryController.text),
                    netSalary: double.parse(_basicSalaryController.text),
                    noTax: salary.noTax,
                    salaryByCash: salary.salaryByCash,
                    salaryByCheque: salary.salaryByCheque,
                    salaryByTransfer: salary.salaryByTransfer,
                    accountNumber: salary.accountNumber,
                    allowOvertime: salary.allowOvertime,
                    lateComingDeduction: salary.lateComingDeduction,
                    salaryAtAppointment: salary.salaryAtAppointment,
                    lastIncrementDate: salary.lastIncrementDate,
                    incrementAmount: salary.incrementAmount,
                    createdAt: salary.createdAt,
                    updatedAt: DateTime.now(),
                    employeeName: _nameController.text,
                    employeeCode: _employeeCodeController.text,
                    bankId: salary.bankId,
                    bankAccountNumber: salary.bankAccountNumber,
                    bankName: salary.bankName,
                  );

                  final success = await provider.updateSalary(updatedSalary);
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Salary updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update salary: ${provider.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(int id, EmployeeSalaryProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.warning_2, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirm Delete'),
            ],
          ),
          content: const Text('Are you sure you want to delete this salary record? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteSalary(id);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Salary deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete salary: ${provider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSalaryDetailsDialog(EmployeeSalary salary) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Iconsax.wallet_money, color: Color(0xFF667EEA)),
              const SizedBox(width: 8),
              Text('Salary Details - ${salary.employeeName}'),
            ],
          ),
          content: SizedBox(
            width: 500,
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
                              salary.employeeName.split(' ').map((n) => n[0]).join(),
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
                                salary.employeeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Code: ${salary.employeeCode} • ID: ${salary.employeeId}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${salary.createdAt.toLocal().toString().split(' ')[0]}',
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

                  _buildBreakdownRow('Basic Salary', '₹${salary.basicSalary.toStringAsFixed(2)}', Colors.blue),
                  _buildBreakdownRow('House Allowance', '₹${salary.houseAllowance.toStringAsFixed(2)}', Colors.green),
                  _buildBreakdownRow('Medical Allowance', '₹${salary.medicalAllowance.toStringAsFixed(2)}', Colors.green),
                  _buildBreakdownRow('Mobile Allowance', '₹${salary.mobileAllowance.toStringAsFixed(2)}', Colors.green),
                  _buildBreakdownRow('Conveyance Allowance', '₹${salary.conveyanceAllowance.toStringAsFixed(2)}', Colors.green),
                  _buildBreakdownRow('Utility Allowance', '₹${salary.utilityAllowance.toStringAsFixed(2)}', Colors.green),
                  _buildBreakdownRow('Miscellaneous Allowance', '₹${salary.miscellaneousAllowance.toStringAsFixed(2)}', Colors.green),

                  const Divider(),

                  _buildBreakdownRow('Total Allowances', '₹${salary.totalAllowances.toStringAsFixed(2)}', Colors.green),
                  _buildBreakdownRow('Gross Salary', '₹${salary.grossSalary.toStringAsFixed(2)}', Colors.blue, isBold: true),

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

                  _buildBreakdownRow('Income Tax', '₹${salary.incomeTax.toStringAsFixed(2)}', Colors.red),

                  const Divider(),

                  _buildBreakdownRow('Total Deductions', '₹${salary.incomeTax.toStringAsFixed(2)}', Colors.red, isBold: true),

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
                          '₹${salary.netSalary.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Information
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Payment Method:', salary.paymentMethod),
                        if (salary.bankName != null)
                          _buildInfoRow('Bank:', salary.bankName!),
                        if (salary.accountNumber != null)
                          _buildInfoRow('Account Number:', salary.accountNumber!),
                        _buildInfoRow('Late Coming Deduction:', salary.lateComingDeduction ? 'Yes' : 'No'),
                        _buildInfoRow('Allow Overtime:', salary.allowOvertime ? 'Yes' : 'No'),
                        _buildInfoRow('No Tax:', salary.noTax ? 'Yes' : 'No'),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}