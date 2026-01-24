import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../model/attendance_model/attendance_model.dart';
import '../../model/employee_salary_model/employee_salary_model.dart';
import '../../provider/employee_salary_provider/employee_salary_provider.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final provider = Provider.of<EmployeeSalaryProvider>(
      context,
      listen: false,
    );

    try {
      if (provider.authToken == null) {
        final tokenLoaded = await provider.loadAuthToken();
        if (!tokenLoaded) {
          throw Exception('Authentication failed');
        }
      }

      await provider.fetchEmployees();
      await provider.fetchEmployeeSalaries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final isMediumScreen = mediaQuery.size.width >= 600 && mediaQuery.size.width < 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add, size: 22),
            onPressed: () => _showAddSalaryDialog(context),
            tooltip: 'Add Salary',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, size: 22),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<EmployeeSalaryProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return _buildLoadingState();
          }

          if (provider.error.isNotEmpty) {
            return _buildErrorState(provider.error);
          }

          return _buildMainContent(provider, mediaQuery);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading salaries...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(EmployeeSalaryProvider provider, MediaQueryData mediaQuery) {
    final filteredSalaries = provider.searchSalaries(_searchController.text);
    final isSmallScreen = mediaQuery.size.width < 600;

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
          // Header Section with Search
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employee name or code...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(
                        Iconsax.search_normal,
                        color: Color(0xFF667EEA),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(
                          Iconsax.close_circle,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 0),

                // Statistics Cards - Responsive layout
                _buildStatisticsCards(provider, mediaQuery),
              ],
            ),
          ),

          // Salaries List
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Salary Records',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredSalaries.length} records',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: filteredSalaries.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                      itemCount: filteredSalaries.length,
                      itemBuilder: (context, index) {
                        return _buildSalaryCard(
                          filteredSalaries[index],
                          provider,
                          mediaQuery,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(EmployeeSalaryProvider provider, MediaQueryData mediaQuery) {
    final totalSalary = provider.salaries.fold<double>(
      0.0,
          (sum, s) => sum + s.netSalary,
    );
    final avgSalary = provider.salaries.isNotEmpty
        ? totalSalary / provider.salaries.length
        : 0.0;

    final isSmallScreen = mediaQuery.size.width < 600;

    // Format number with comma separators for thousands
    String formatNumber(double value) {
      final numberFormat = NumberFormat("#,##0");
      return numberFormat.format(value);
    }

    return Container(
      height: isSmallScreen ? 100 : 90, // Fixed height
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatCard(
              icon: Iconsax.profile_2user,
              title: 'Employees',
              value: '${provider.employees.length}',
              iconColor: const Color(0xFF667EEA),
              isSmallScreen: isSmallScreen,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 10),
          Expanded(
            child: _buildCompactStatCard(
              icon: Iconsax.wallet_money,
              title: 'Total Salary',
              value: formatNumber(totalSalary),
              iconColor: Colors.green,
              isSmallScreen: isSmallScreen,
              showCurrency: true,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 10),
          Expanded(
            child: _buildCompactStatCard(
              icon: Iconsax.chart_2,
              title: 'Avg Salary',
              value: formatNumber(avgSalary),
              iconColor: Colors.orange,
              isSmallScreen: isSmallScreen,
              showCurrency: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required bool isSmallScreen,
    bool showCurrency = false,
  }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container - compact
            Container(
              width: isSmallScreen ? 32 : 36,
              height: isSmallScreen ? 32 : 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                    icon,
                    size: isSmallScreen ? 16 : 18,
                    color: iconColor
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
      
            // Text content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (showCurrency)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(
                            '',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 3),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.wallet_money, size: 80, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            'No Salary Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first salary record',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddSalaryDialog(context),
            icon: const Icon(Iconsax.add, size: 18),
            label: const Text('Add Salary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667EEA),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(
      EmployeeSalary salary,
      EmployeeSalaryProvider provider,
      MediaQueryData mediaQuery,
      ) {
    final isSmallScreen = mediaQuery.size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSalaryDetailsDialog(salary),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: isSmallScreen ? 40 : 48,
                      height: isSmallScreen ? 40 : 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          salary.employeeName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),

                    // Employee Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salary.employeeName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Basic: ${salary.basicSalary}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Salary Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${salary.netSalary.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salary.paymentMethod,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
SizedBox(width: 10,),
                    // Actions Menu
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          _showSalaryDetailsDialog(salary);
                        } else if (value == 'edit') {
                          _showEditSalaryDialog(salary, provider);
                        } else if (value == 'delete') {
                          _showDeleteDialog(salary.id, provider);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Iconsax.eye, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              const Text('View Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Iconsax.edit, size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Iconsax.trash, size: 18, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              const Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Icon(
                          Iconsax.more,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== DIALOGS ==========

  void _showAddSalaryDialog(BuildContext context) {
    final provider = Provider.of<EmployeeSalaryProvider>(
      context,
      listen: false,
    );
    final availableEmployees = provider.getAvailableEmployees();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.add_circle, color: Color(0xFF667EEA)),
            const SizedBox(width: 10),
            const Text(
              'Select Employee',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: FutureBuilder<List<Employee>>(
          future: availableEmployees,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF667EEA),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.warning_2,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading employees',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final employees = snapshot.data ?? [];

            if (employees.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'All employees have salaries',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No available employees',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              width: 400,
              height: 400,
              child: Column(
                children: [
                  // Search in dropdown
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search employees...',
                        prefixIcon: const Icon(Iconsax.search_normal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF667EEA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                employee.name.substring(0, 1),
                                style: const TextStyle(
                                  color: Color(0xFF667EEA),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            employee.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            ' ${employee.department ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showSalaryForm(context, employee, null);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSalaryForm(
      BuildContext context,
      Employee employee,
      EmployeeSalary? existingSalary,
      ) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final isEdit = existingSalary != null;
    final salary = existingSalary ?? EmployeeSalary.emptyForEmployee(employee);

    // Controllers for all fields
    final controllers = {
      'basic_salary': TextEditingController(
        text: salary.basicSalary.toStringAsFixed(2),
      ),
      'medical': TextEditingController(
        text: salary.medicalAllowance.toStringAsFixed(2),
      ),
      'mobile': TextEditingController(
        text: salary.mobileAllowance.toStringAsFixed(2),
      ),
      'conveyance': TextEditingController(
        text: salary.conveyanceAllowance.toStringAsFixed(2),
      ),
      'house': TextEditingController(
        text: salary.houseAllowance.toStringAsFixed(2),
      ),
      'utility': TextEditingController(
        text: salary.utilityAllowance.toStringAsFixed(2),
      ),
      'miscellaneous': TextEditingController(
        text: salary.miscellaneousAllowance.toStringAsFixed(2),
      ),
      'income_tax': TextEditingController(
        text: salary.incomeTax.toStringAsFixed(2),
      ),
      'salary_at_appointment': TextEditingController(
        text: salary.salaryAtAppointment?.toStringAsFixed(2) ?? '0.00',
      ),
      'increment_amount': TextEditingController(
        text: salary.incrementAmount?.toStringAsFixed(2) ?? '0.00',
      ),
      'account_number': TextEditingController(text: salary.accountNumber ?? ''),
    };

    DateTime? lastIncrementDate = salary.lastIncrementDate;
    bool noTax = salary.noTax;
    bool salaryByCash = salary.salaryByCash;
    bool salaryByCheque = salary.salaryByCheque;
    bool salaryByTransfer = salary.salaryByTransfer;
    bool allowOvertime = salary.allowOvertime;
    bool lateComingDeduction = salary.lateComingDeduction;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate totals
          double calculateGross() {
            final basic =
                double.tryParse(controllers['basic_salary']!.text) ?? 0;
            final medical = double.tryParse(controllers['medical']!.text) ?? 0;
            final mobile = double.tryParse(controllers['mobile']!.text) ?? 0;
            final conveyance =
                double.tryParse(controllers['conveyance']!.text) ?? 0;
            final house = double.tryParse(controllers['house']!.text) ?? 0;
            final utility = double.tryParse(controllers['utility']!.text) ?? 0;
            final misc =
                double.tryParse(controllers['miscellaneous']!.text) ?? 0;
            return basic +
                medical +
                mobile +
                conveyance +
                house +
                utility +
                misc;
          }

          double calculateNet() {
            final gross = calculateGross();
            final tax = noTax
                ? 0
                : (double.tryParse(controllers['income_tax']!.text) ?? 0);
            return gross - tax;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isEdit ? Iconsax.edit_2 : Iconsax.add_circle,
                  color: isEdit ? Colors.green : const Color(0xFF667EEA),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Salary' : 'Add Salary',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!isSmallScreen) Chip(
                  label: Text(employee.name),
                  backgroundColor: const Color(0xFF667EEA).withOpacity(0.1),
                  labelStyle: const TextStyle(color: Color(0xFF667EEA)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: isSmallScreen ? mediaQuery.size.width * 0.9 : 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Employee Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                employee.name.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Text(
                                //   'ID: ${employee.empId}',
                                //   style: TextStyle(color: Colors.grey[600]),
                                // ),
                                // if (employee.department != null)
                                //   Text(
                                //     'Dept: ${employee.department}',
                                //     style: TextStyle(color: Colors.grey[600]),
                                //   ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Salary Details Section
                    Row(
                      children: [
                        Icon(Iconsax.money, size: 18, color: const Color(0xFF667EEA)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Salary Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Basic Salary
                    _buildModernTextField(
                      label: 'Basic Salary *',
                      controller: controllers['basic_salary']!,
                      onChanged: (value) => setState(() {}),
                      isRequired: true,
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Iconsax.receipt_add,
                          size: 18,
                          color: const Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Allowances',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Allowances Grid - Responsive layout
                    if (isSmallScreen)
                      Column(
                        children: [
                          _buildAllowanceField(
                            'Medical',
                            controllers['medical']!,
                                (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildAllowanceField(
                            'Mobile',
                            controllers['mobile']!,
                                (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildAllowanceField(
                            'Conveyance',
                            controllers['conveyance']!,
                                (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildAllowanceField(
                            'House',
                            controllers['house']!,
                                (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildAllowanceField(
                            'Utility',
                            controllers['utility']!,
                                (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _buildAllowanceField(
                            'Miscellaneous',
                            controllers['miscellaneous']!,
                                (value) => setState(() {}),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildAllowanceField(
                            'Medical',
                            controllers['medical']!,
                                (value) => setState(() {}),
                          ),
                          _buildAllowanceField(
                            'Mobile',
                            controllers['mobile']!,
                                (value) => setState(() {}),
                          ),
                          _buildAllowanceField(
                            'Conveyance',
                            controllers['conveyance']!,
                                (value) => setState(() {}),
                          ),
                          _buildAllowanceField(
                            'House',
                            controllers['house']!,
                                (value) => setState(() {}),
                          ),
                          _buildAllowanceField(
                            'Utility',
                            controllers['utility']!,
                                (value) => setState(() {}),
                          ),
                          _buildAllowanceField(
                            'Miscellaneous',
                            controllers['miscellaneous']!,
                                (value) => setState(() {}),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Iconsax.receipt,
                          size: 18,
                          color: const Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tax',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tax Section - Responsive layout
                    if (isSmallScreen)
                      Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: noTax,
                                onChanged: (value) => setState(() {
                                  noTax = value ?? false;
                                  if (noTax) controllers['income_tax']!.text = '0';
                                }),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                activeColor: const Color(0xFF667EEA),
                              ),
                              const Text('No Tax'),
                            ],
                          ),
                          _buildModernTextField(
                            label: 'Income Tax',
                            controller: controllers['income_tax']!,
                            enabled: !noTax,
                            onChanged: (value) => setState(() {}),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Checkbox(
                            value: noTax,
                            onChanged: (value) => setState(() {
                              noTax = value ?? false;
                              if (noTax) controllers['income_tax']!.text = '0';
                            }),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            activeColor: const Color(0xFF667EEA),
                          ),
                          const Text('No Tax'),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildModernTextField(
                              label: 'Income Tax',
                              controller: controllers['income_tax']!,
                              enabled: !noTax,
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Iconsax.card, size: 18, color: const Color(0xFF667EEA)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment Mode',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payment Mode - Responsive layout
                    if (isSmallScreen)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPaymentOption(
                                label: 'Cash',
                                icon: Iconsax.money,
                                value: salaryByCash,
                                onChanged: (value) =>
                                    setState(() => salaryByCash = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPaymentOption(
                                label: 'Cheque',
                                icon: Iconsax.receipt,
                                value: salaryByCheque,
                                onChanged: (value) =>
                                    setState(() => salaryByCheque = value),
                              ),
                              const SizedBox(width: 8),
                              _buildPaymentOption(
                                label: 'Transfer',
                                icon: Iconsax.card,
                                value: salaryByTransfer,
                                onChanged: (value) =>
                                    setState(() => salaryByTransfer = value),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _buildPaymentOption(
                            label: 'Cash',
                            icon: Iconsax.money,
                            value: salaryByCash,
                            onChanged: (value) =>
                                setState(() => salaryByCash = value),
                          ),
                          const SizedBox(width: 16),
                          _buildPaymentOption(
                            label: 'Cheque',
                            icon: Iconsax.receipt,
                            value: salaryByCheque,
                            onChanged: (value) =>
                                setState(() => salaryByCheque = value),
                          ),
                          const SizedBox(width: 16),
                          _buildPaymentOption(
                            label: 'Transfer',
                            icon: Iconsax.card,
                            value: salaryByTransfer,
                            onChanged: (value) =>
                                setState(() => salaryByTransfer = value),
                          ),
                        ],
                      ),

                    // Bank Details
                    if (salaryByTransfer) ...[
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        label: 'Account Number',
                        controller: controllers['account_number']!,
                        icon: Iconsax.card,
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Iconsax.setting,
                          size: 18,
                          color: const Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Other Options',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Other Options - Responsive layout
                    if (isSmallScreen)
                      Column(
                        children: [
                          _buildOptionChip(
                            label: 'Allow Overtime',
                            value: allowOvertime,
                            onChanged: (value) =>
                                setState(() => allowOvertime = value),
                          ),
                          const SizedBox(height: 8),
                          _buildOptionChip(
                            label: 'Late Deductions',
                            value: lateComingDeduction,
                            onChanged: (value) =>
                                setState(() => lateComingDeduction = value),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _buildOptionChip(
                            label: 'Allow Overtime',
                            value: allowOvertime,
                            onChanged: (value) =>
                                setState(() => allowOvertime = value),
                          ),
                          const SizedBox(width: 12),
                          _buildOptionChip(
                            label: 'Late Deductions',
                            value: lateComingDeduction,
                            onChanged: (value) =>
                                setState(() => lateComingDeduction = value),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Iconsax.trend_up,
                          size: 18,
                          color: const Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Increments',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Increments - Responsive layout
                    if (isSmallScreen)
                      Column(
                        children: [
                          _buildModernTextField(
                            label: 'Salary at Appointment',
                            controller: controllers['salary_at_appointment']!,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Increment Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate:
                                    lastIncrementDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (selectedDate != null) {
                                    setState(
                                          () => lastIncrementDate = selectedDate,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.calendar_1,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          lastIncrementDate != null
                                              ? DateFormat(
                                            'MM/dd/yyyy',
                                          ).format(lastIncrementDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            color: lastIncrementDate != null
                                                ? Colors.black
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Iconsax.arrow_down_1,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            label: 'Increment Amount',
                            controller: controllers['increment_amount']!,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              label: 'Salary at Appointment',
                              controller: controllers['salary_at_appointment']!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last Increment Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final selectedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      lastIncrementDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (selectedDate != null) {
                                      setState(
                                            () => lastIncrementDate = selectedDate,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.calendar_1,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            lastIncrementDate != null
                                                ? DateFormat(
                                              'MM/dd/yyyy',
                                            ).format(lastIncrementDate!)
                                                : 'Select date',
                                            style: TextStyle(
                                              color: lastIncrementDate != null
                                                  ? Colors.black
                                                  : Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Iconsax.arrow_down_1,
                                          size: 16,
                                          color: Colors.grey[500],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernTextField(
                              label: 'Increment Amount',
                              controller: controllers['increment_amount']!,
                            ),
                          ),
                        ],
                      ),

                    // Summary Card
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gross Salary',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${calculateGross().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Income Tax',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${(noTax ? 0 : double.tryParse(controllers['income_tax']!.text) ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white54),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Net Salary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${calculateNet().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate
                  if (controllers['basic_salary']!.text.isEmpty) {
                    _showError(context, 'Basic salary is required');
                    return;
                  }
                  if (!salaryByCash && !salaryByCheque && !salaryByTransfer) {
                    _showError(context, 'Select at least one payment method');
                    return;
                  }

                  final updatedSalary = EmployeeSalary(
                    id: salary.id,
                    employeeId: employee.id,
                    basicSalary:
                    double.tryParse(controllers['basic_salary']!.text) ?? 0,
                    medicalAllowance:
                    double.tryParse(controllers['medical']!.text) ?? 0,
                    mobileAllowance:
                    double.tryParse(controllers['mobile']!.text) ?? 0,
                    conveyanceAllowance:
                    double.tryParse(controllers['conveyance']!.text) ?? 0,
                    houseAllowance:
                    double.tryParse(controllers['house']!.text) ?? 0,
                    utilityAllowance:
                    double.tryParse(controllers['utility']!.text) ?? 0,
                    miscellaneousAllowance:
                    double.tryParse(controllers['miscellaneous']!.text) ??
                        0,
                    incomeTax:
                    double.tryParse(controllers['income_tax']!.text) ?? 0,
                    grossSalary: calculateGross(),
                    netSalary: calculateNet(),
                    noTax: noTax,
                    salaryByCash: salaryByCash,
                    salaryByCheque: salaryByCheque,
                    salaryByTransfer: salaryByTransfer,
                    accountNumber:
                    controllers['account_number']!.text.isNotEmpty
                        ? controllers['account_number']!.text
                        : null,
                    allowOvertime: allowOvertime,
                    lateComingDeduction: lateComingDeduction,
                    salaryAtAppointment: double.tryParse(
                      controllers['salary_at_appointment']!.text,
                    ),
                    lastIncrementDate: lastIncrementDate,
                    incrementAmount: double.tryParse(
                      controllers['increment_amount']!.text,
                    ),
                    createdAt: salary.createdAt,
                    updatedAt: DateTime.now(),
                    employeeName: employee.name,
                    employeeCode: employee.empId,
                    bankId: salary.bankId,
                    bankAccountNumber: salary.bankAccountNumber,
                    bankName: salary.bankName,
                  );

                  Navigator.pop(context);
                  final provider = Provider.of<EmployeeSalaryProvider>(
                    context,
                    listen: false,
                  );

                  final success = isEdit
                      ? await provider.updateSalary(updatedSalary)
                      : await provider.createSalary(updatedSalary);

                  if (success) {
                    _showSuccess(
                      context,
                      isEdit ? 'Salary updated!' : 'Salary added!',
                    );
                    _loadData();
                  } else {
                    _showError(context, 'Error: ${provider.error}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(isEdit ? 'Update Salary' : 'Save Salary'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    IconData? icon,
    bool enabled = true,
    bool isRequired = false,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: Colors.grey[600])
                  : null,
              prefixText: prefix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAllowanceField(
      String label,
      TextEditingController controller,
      void Function(String) onChanged,
      ) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String label,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF667EEA).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? const Color(0xFF667EEA) : Colors.grey[300]!,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: value ? const Color(0xFF667EEA) : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? const Color(0xFF667EEA) : Colors.grey[700],
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: const Color(0xFF667EEA).withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: value ? const Color(0xFF667EEA) : Colors.grey[700],
        fontWeight: value ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: value ? const Color(0xFF667EEA) : Colors.grey[300]!,
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditSalaryDialog(
      EmployeeSalary salary,
      EmployeeSalaryProvider provider,
      ) {
    final employee = provider.getEmployeeById(salary.employeeId);
    if (employee != null) {
      _showSalaryForm(context, employee, salary);
    } else {
      _showError(context, 'Employee not found');
    }
  }

  void _showDeleteDialog(int id, EmployeeSalaryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.orange[400]),
            const SizedBox(width: 12),
            const Text(
              'Confirm Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this salary record? This action cannot be undone.',
        ),
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
                _showSuccess(context, 'Salary deleted successfully');
                _loadData();
              } else {
                _showError(context, 'Error: ${provider.error}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSalaryDetailsDialog(EmployeeSalary salary) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: isSmallScreen ? mediaQuery.size.width * 0.9 : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          salary.employeeName.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${salary.employeeCode}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Salary Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Net Salary',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${salary.netSalary.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Gross Salary',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${salary.grossSalary.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details Grid
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isSmallScreen ? 2.5 : 3,
                      children: [
                        _buildDetailItem(
                          'Basic Salary',
                          '${salary.basicSalary.toStringAsFixed(2)}',
                        ),
                        _buildDetailItem(
                          'Medical',
                          '${salary.medicalAllowance.toStringAsFixed(2)}',
                        ),
                        _buildDetailItem(
                          'House',
                          '${salary.houseAllowance.toStringAsFixed(2)}',
                        ),
                        _buildDetailItem(
                          'Mobile',
                          '${salary.mobileAllowance.toStringAsFixed(2)}',
                        ),
                        _buildDetailItem(
                          'Income Tax',
                          '${salary.incomeTax.toStringAsFixed(2)}',
                        ),
                        _buildDetailItem(
                          'Total Allowances',
                          '${salary.totalAllowances.toStringAsFixed(2)}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),

                    // Other Information
                    Column(
                      children: [
                        _buildInfoRow('Payment Method', salary.paymentMethod),
                        _buildInfoRow(
                          'Allow Overtime',
                          salary.allowOvertime ? 'Yes' : 'No',
                        ),
                        _buildInfoRow(
                          'Late Deductions',
                          salary.lateComingDeduction ? 'Yes' : 'No',
                        ),
                        _buildInfoRow('No Tax', salary.noTax ? 'Yes' : 'No'),
                        if (salary.lastIncrementDate != null)
                          _buildInfoRow(
                            'Last Increment',
                            DateFormat(
                              'MM/dd/yyyy',
                            ).format(salary.lastIncrementDate!),
                          ),
                        if (salary.incrementAmount != null)
                          _buildInfoRow(
                            'Increment Amount',
                            '${salary.incrementAmount!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Created: ${DateFormat('MMM dd, yyyy').format(salary.createdAt)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}