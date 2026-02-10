import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../model/salary_sheet/salary_sheet.dart';
import '../../provider/salary_sheet_provider/salary_sheet_provider.dart';

class SalarySheetScreen extends StatefulWidget {
  const SalarySheetScreen({super.key});

  @override
  State<SalarySheetScreen> createState() => _SalarySheetScreenState();
}

class _SalarySheetScreenState extends State<SalarySheetScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _tempSelectedMonth;
  int? _tempSelectedDepartmentId;
  bool _showDebugPanel = false;
  bool _showApiDataPanel = false;
  Map<String, dynamic>? _apiTestResults;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🚀 SalaryScreen initState: Starting initialization...');
      final provider = context.read<SalarySheetProvider>();

      try {
        await provider.initialize();
        print('✅ Provider initialization complete');
        print('📊 Departments loaded: ${provider.departments.length}');
        print('📅 Selected month: ${provider.selectedMonth}');
        print('🏢 Selected department: ${provider.selectedDepartmentId}');

        // Set initial temp values
        _tempSelectedMonth = provider.selectedMonth;
        _tempSelectedDepartmentId = provider.selectedDepartmentId;

        if (provider.selectedMonth.isNotEmpty && provider.selectedDepartmentId != null) {
          await provider.fetchSalarySheet();
        }
      } catch (e) {
        print('❌ Error initializing provider: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error initializing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final isLargeScreen = screenWidth >= 900;

    // Calculate responsive values
    final paddingValue = isSmallScreen ? 12.0 : isMediumScreen ? 16.0 : 20.0;
    final iconSize = isSmallScreen ? 22.0 : isMediumScreen ? 24.0 : 26.0;
    final fontSizeSmall = isSmallScreen ? 11.0 : isMediumScreen ? 12.0 : 13.0;
    final fontSizeMedium = isSmallScreen ? 13.0 : isMediumScreen ? 14.0 : 15.0;
    final fontSizeLarge = isSmallScreen ? 16.0 : isMediumScreen ? 18.0 : 20.0;
    final borderRadius = isSmallScreen ? 12.0 : isMediumScreen ? 16.0 : 20.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Salary Sheet',
            style: TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF667EEA),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showDebugPanel = !_showDebugPanel;
                });
              },
              icon: Icon(Icons.bug_report, color: Colors.white, size: iconSize),
              tooltip: 'Debug Panel',
            ),
            IconButton(
              onPressed: () async {
                setState(() {
                  _showApiDataPanel = !_showApiDataPanel;
                });
                if (_showApiDataPanel) {
                  await _runApiTests(context);
                }
              },
              icon: Icon(Icons.api, color: Colors.white, size: iconSize),
              tooltip: 'API Data',
            ),
            IconButton(
              onPressed: _showFilterDialog,
              icon: Icon(Icons.filter_alt, color: Colors.white, size: iconSize),
              tooltip: 'Filter',
            ),
            IconButton(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh, color: Colors.white, size: iconSize),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
          child: Consumer<SalarySheetProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Debug Panel
                  if (_showDebugPanel)
                    _buildDebugPanel(provider, screenWidth, isSmallScreen),

                  // API Data Panel
                  if (_showApiDataPanel && _apiTestResults != null)
                    _buildApiDataPanel(provider, screenWidth, isSmallScreen),

                  // Filters Section
                  _buildFilters(
                    provider,
                    screenWidth,
                    isSmallScreen,
                    isMediumScreen,
                    isLargeScreen,
                    paddingValue,
                    borderRadius,
                    iconSize,
                    fontSizeMedium,
                  ),

                  SizedBox(height: paddingValue),

                  // Loading/Error/Salary Sheet - THIS NEEDS TO BE EXPANDED
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(paddingValue),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: paddingValue,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildContent(
                        provider,
                        screenWidth,
                        isSmallScreen,
                        isMediumScreen,
                        isLargeScreen,
                        paddingValue,
                        fontSizeSmall,
                        fontSizeMedium,
                        fontSizeLarge,
                        borderRadius,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDebugPanel(SalarySheetProvider provider, double screenWidth, bool isSmallScreen) {
    final padding = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    return Container(
      margin: EdgeInsets.all(padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(padding),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: padding,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Debug Panel',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Departments: ${provider.departments.length}', style: TextStyle(fontSize: fontSize)),
          Text('Selected Dept ID: ${provider.selectedDepartmentId}', style: TextStyle(fontSize: fontSize)),
          Text('Selected Month: ${provider.selectedMonth}', style: TextStyle(fontSize: fontSize)),
          Text('Salary Sheet: ${provider.salarySheet != null ? "Loaded" : "NULL"}', style: TextStyle(fontSize: fontSize)),
          Text('Error: ${provider.error}', style: TextStyle(fontSize: fontSize)),
          Text('Loading: ${provider.isLoading}', style: TextStyle(fontSize: fontSize)),
          Text('Loading Departments: ${provider.isLoadingDepartments}', style: TextStyle(fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _buildApiDataPanel(SalarySheetProvider provider, double screenWidth, bool isSmallScreen) {
    final padding = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;
    final maxHeight = screenWidth * 0.6;

    if (_apiTestResults == null) {
      return Container(
        margin: EdgeInsets.all(padding),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(padding),
        ),
        child: Center(
          child: Text(
            'Run API tests first',
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(padding),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(padding),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: padding,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(padding),
                topRight: Radius.circular(padding),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.api, color: Colors.white, size: 16),
                SizedBox(width: padding),
                Text(
                  'API Test Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _apiTestResults = null;
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.white, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: _buildApiDataContent(_apiTestResults!, fontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiDataContent(Map<String, dynamic> data, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.containsKey('summary'))
          _buildApiSection('Summary', data['summary'], fontSize),
        if (data.containsKey('authTest'))
          _buildApiSection('Authentication Test', data['authTest'], fontSize),
        if (data.containsKey('departmentsTest'))
          _buildApiSection('Departments API Test', data['departmentsTest'], fontSize),
        if (data.containsKey('salarySheetTest'))
          _buildApiSection('Salary Sheet API Test', data['salarySheetTest'], fontSize),
      ],
    );
  }

  Widget _buildApiSection(String title, dynamic data, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: const Color(0xFF667EEA),
          ),
        ),
        const SizedBox(height: 4),
        if (data is Map)
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '${entry.key}: ${_formatApiValue(entry.value)}',
                style: TextStyle(fontSize: fontSize - 1),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatApiValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? '✅ Yes' : '❌ No';
    if (value is List) return '[List of ${value.length} items]';
    if (value is Map) return '{Map with ${value.length} keys}';
    return value.toString();
  }

  Future<void> _runApiTests(BuildContext context) async {
    final provider = context.read<SalarySheetProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Running API tests...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final results = await provider.testAllEndpointsDetailed();
      setState(() {
        _apiTestResults = results;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('API tests completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilters(
      SalarySheetProvider provider,
      double screenWidth,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      double padding,
      double borderRadius,
      double iconSize,
      double fontSize,
      ) {
    return Container(
      margin: EdgeInsets.all(padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: padding,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selection with responsive layout
          if (isSmallScreen)
            _buildMonthSelectionVertical(provider, padding, borderRadius, iconSize, fontSize)
          else
            _buildMonthSelectionHorizontal(provider, padding, borderRadius, iconSize, fontSize),

          SizedBox(height: padding),

          // Department Selection
          Row(
            children: [
              Icon(Icons.business, size: iconSize, color: const Color(0xFF667EEA)),
              SizedBox(width: padding),
              Text(
                'Department:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ),
              ),
              SizedBox(width: padding),
              Expanded(
                child: _buildDepartmentDropdown(provider, padding, borderRadius, fontSize),
              ),
            ],
          ),

          SizedBox(height: padding),

          // Search Bar
          _buildSearchBar(padding, borderRadius, fontSize),

          SizedBox(height: padding * 1.5),

          // Info Card
          // _buildInfoCard(provider, padding, borderRadius, iconSize, fontSize),

          // SizedBox(height: padding * 1.5),

          // Fetch Button
          _buildFetchButton(provider, padding, borderRadius, fontSize),
        ],
      ),
    );
  }

  Widget _buildMonthSelectionVertical(
      SalarySheetProvider provider,
      double padding,
      double borderRadius,
      double iconSize,
      double fontSize,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: iconSize, color: const Color(0xFF667EEA)),
            SizedBox(width: padding),
            Text(
              'Month:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
        SizedBox(height: padding / 2),
        GestureDetector(
          onTap: () => _showMonthPicker(context, provider),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(borderRadius / 2),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    provider.selectedMonth.isNotEmpty
                        ? _formatMonth(provider.selectedMonth)
                        : 'Select Month',
                    style: TextStyle(
                      color: provider.selectedMonth.isNotEmpty ? Colors.black : Colors.grey,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: iconSize, color: const Color(0xFF667EEA)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelectionHorizontal(
      SalarySheetProvider provider,
      double padding,
      double borderRadius,
      double iconSize,
      double fontSize,
      ) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: iconSize, color: const Color(0xFF667EEA)),
        SizedBox(width: padding),
        Text(
          'Month:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        SizedBox(width: padding),
        Expanded(
          child: GestureDetector(
            onTap: () => _showMonthPicker(context, provider),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(borderRadius / 2),
                color: Colors.grey[50],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      provider.selectedMonth.isNotEmpty
                          ? _formatMonth(provider.selectedMonth)
                          : 'Select Month',
                      style: TextStyle(
                        color: provider.selectedMonth.isNotEmpty ? Colors.black : Colors.grey,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: iconSize, color: const Color(0xFF667EEA)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown(
      SalarySheetProvider provider,
      double padding,
      double borderRadius,
      double fontSize,
      ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(borderRadius / 2),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: provider.selectedDepartmentId,
          isExpanded: true,
          style: TextStyle(fontSize: fontSize, color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius / 2),
          icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF667EEA)),
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              'Select Department',
              style: TextStyle(color: Colors.grey, fontSize: fontSize),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                child: Text(
                  '-- Select Department --',
                  style: TextStyle(color: Colors.grey, fontSize: fontSize),
                ),
              ),
            ),
            ...provider.departments.map((dept) {
              return DropdownMenuItem<int?>(
                value: dept.id,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                  child: Text(dept.name, style: TextStyle(fontSize: fontSize)),
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            provider.selectedDepartmentId = value;
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(double padding, double borderRadius, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: padding / 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search employees...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: fontSize),
          prefixIcon: Icon(Icons.search, color: const Color(0xFF667EEA)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            icon: Icon(Icons.clear, color: const Color(0xFF667EEA)),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      SalarySheetProvider provider,
      double padding,
      double borderRadius,
      double iconSize,
      double fontSize,
      ) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius / 2),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize * 2,
            height: iconSize * 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people, color: Colors.white, size: iconSize),
          ),
          SizedBox(width: padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Salary Sheet',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF667EEA),
                  ),
                ),
                SizedBox(height: padding / 4),
                Text(
                  provider.selectedMonth.isNotEmpty && provider.selectedDepartmentId != null
                      ? '${_formatMonth(provider.selectedMonth)} • ${provider.getDepartmentName(provider.selectedDepartmentId)}'
                      : 'Select month and department',
                  style: TextStyle(fontSize: fontSize - 2, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (provider.salarySheet != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                '${provider.salarySheet!.rows.length}',
                style: TextStyle(color: Colors.white, fontSize: fontSize),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFetchButton(
      SalarySheetProvider provider,
      double padding,
      double borderRadius,
      double fontSize,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isLoading || provider.selectedMonth.isEmpty || provider.selectedDepartmentId == null
            ? null
            : () => provider.fetchSalarySheet(),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: padding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius / 2),
          ),
          backgroundColor: provider.selectedMonth.isNotEmpty && provider.selectedDepartmentId != null
              ? const Color(0xFF667EEA)
              : Colors.grey,
        ),
        child: provider.isLoading
            ? SizedBox(
          width: fontSize * 1.5,
          height: fontSize * 1.5,
          child: const CircularProgressIndicator(color: Colors.white),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: fontSize),
            SizedBox(width: padding / 2),
            Text('Get Salary Sheet', style: TextStyle(fontSize: fontSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      SalarySheetProvider provider,
      double screenWidth,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      double padding,
      double fontSizeSmall,
      double fontSizeMedium,
      double fontSizeLarge,
      double borderRadius,
      ) {
    // Show loading state
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA))),
            SizedBox(height: padding),
            Text('Fetching salary data...', style: TextStyle(fontSize: fontSizeMedium)),
          ],
        ),
      );
    }

    // Show error state
    if (provider.error.isNotEmpty && provider.salarySheet == null) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: fontSizeLarge * 3, color: Colors.orange),
              SizedBox(height: padding),
              Text('Error Loading Data', style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
              SizedBox(height: padding / 2),
              Text(provider.error, textAlign: TextAlign.center, style: TextStyle(fontSize: fontSizeMedium)),
              SizedBox(height: padding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => provider.fetchSalarySheet(),
                    child: Text('Retry', style: TextStyle(fontSize: fontSizeMedium)),
                  ),
                  SizedBox(width: padding),
                  OutlinedButton(
                    onPressed: () => provider.clear(),
                    child: Text('Clear', style: TextStyle(fontSize: fontSizeMedium)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state (no filters selected)
    if (provider.selectedMonth.isEmpty || provider.selectedDepartmentId == null) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_alt, size: fontSizeLarge * 3, color: Colors.grey),
              SizedBox(height: padding),
              Text('Select Filters', style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
              SizedBox(height: padding / 2),
              Text(
                'Choose month and department to view salary sheet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey),
              ),
              SizedBox(height: padding),
              ElevatedButton.icon(
                onPressed: _showFilterDialog,
                icon: Icon(Icons.filter_alt, size: fontSizeMedium),
                label: Text('Select Filters', style: TextStyle(fontSize: fontSizeMedium)),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state (no data found)
    if (provider.salarySheet == null || provider.salarySheet!.rows.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: fontSizeLarge * 3, color: Colors.grey),
              SizedBox(height: padding),
              Text('No Data Found', style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
              SizedBox(height: padding / 2),
              Text(
                'No salary records found for selected criteria',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show data in table format
    final filteredRows = provider.filterEmployees(_searchQuery);
    final summary = provider.getSummary();

    if (filteredRows.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: fontSizeLarge * 3, color: Colors.grey),
              SizedBox(height: padding),
              Text('No Results', style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
              SizedBox(height: padding / 2),
              Text('Try a different search term', style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Define table column widths based on screen size
    final List<double> columnWidths = _getColumnWidths(
      screenWidth,
      isSmallScreen,
      isMediumScreen,
      isLargeScreen,
    );

    return Column(
      children: [
        // Summary Cards
        Container(
          padding: EdgeInsets.all(padding),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isSmallScreen ? 2 : isMediumScreen ? 3 : 4,
            childAspectRatio: isSmallScreen ? 1.2 : isMediumScreen ? 1.5 : 1.8,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
            children: [
              _buildSummaryCard(
                title: 'Total Salary',
                value: '₹${_formatNumber(summary['totalSalary'] ?? 0)}',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
                fontSizeSmall: fontSizeSmall,
                fontSizeMedium: fontSizeMedium,
                isSmallScreen: isSmallScreen,
              ),
              _buildSummaryCard(
                title: 'Net Salary',
                value: '₹${_formatNumber(summary['netSalary'] ?? 0)}',
                icon: Icons.payments,
                color: Colors.blue,
                fontSizeSmall: fontSizeSmall,
                fontSizeMedium: fontSizeMedium,
                isSmallScreen: isSmallScreen,
              ),
              _buildSummaryCard(
                title: 'Employees',
                value: '${summary['employees'] ?? 0}',
                icon: Icons.people,
                color: Colors.purple,
                fontSizeSmall: fontSizeSmall,
                fontSizeMedium: fontSizeMedium,
                isSmallScreen: isSmallScreen,
              ),
              _buildSummaryCard(
                title: 'Deductions',
                value: '₹${_formatNumber(summary['deductions'] ?? 0)}',
                icon: Icons.remove_circle,
                color: Colors.red,
                fontSizeSmall: fontSizeSmall,
                fontSizeMedium: fontSizeMedium,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),

        // Search Results Count
        if (_searchQuery.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
            child: Row(
              children: [
                Icon(Icons.search, size: fontSizeMedium, color: Colors.grey),
                SizedBox(width: padding / 2),
                Text(
                  '${filteredRows.length} result${filteredRows.length != 1 ? 's' : ''} for "$_searchQuery"',
                  style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '${provider.salarySheet!.rows.length} total employees',
                  style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Table Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius / 2),
              topRight: Radius.circular(borderRadius / 2),
            ),
          ),
          child: Row(
            children: _buildTableHeader(
              columnWidths,
              isSmallScreen,
              fontSizeSmall,
              fontSizeMedium,
              padding,
            ),
          ),
        ),

        // Table Rows
        Expanded(
          child: Scrollbar(
            child: ListView.separated(
              itemCount: filteredRows.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final employee = filteredRows[index];
                return Container(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // You can add employee detail view here if needed
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: padding / 1.5,
                        ),
                        child: _buildTableRow(
                          employee,
                          columnWidths,
                          isSmallScreen,
                          fontSizeSmall,
                          fontSizeMedium,
                          padding,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Footer with totals
        Container(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
          decoration: BoxDecoration(
            color: const Color(0xFF764BA2).withOpacity(0.1),
            border: Border.all(color: const Color(0xFF764BA2).withOpacity(0.2)),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(borderRadius / 2),
              bottomRight: Radius.circular(borderRadius / 2),
            ),
          ),
          child: Row(
            children: _buildTableFooter(
              provider,
              columnWidths,
              isSmallScreen,
              fontSizeSmall,
              fontSizeMedium,
              padding,
            ),
          ),
        ),
      ],
    );
  }

  List<double> _getColumnWidths(
      double screenWidth,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      ) {
    if (isSmallScreen) {
      return [60, 120, 80, 60, 70, 70];
    } else if (isMediumScreen) {
      return [60, 180, 120, 70, 80, 80];
    } else {
      return [60, 200, 150, 80, 90, 90];
    }
  }

  List<Widget> _buildTableHeader(
      List<double> columnWidths,
      bool isSmallScreen,
      double fontSizeSmall,
      double fontSizeMedium,
      double padding,
      ) {
    final headerTextStyle = TextStyle(
      color: Colors.white,
      fontSize: isSmallScreen ? fontSizeSmall : fontSizeMedium,
      fontWeight: FontWeight.bold,
    );

    return [
      SizedBox(
        width: columnWidths[0],
        child: Text('#', style: headerTextStyle),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[1],
        child: Text('Employee', style: headerTextStyle),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[2],
        child: Text('Designation', style: headerTextStyle),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[3],
        child: Text('Days', style: headerTextStyle),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[4],
        child: Text('Salary', style: headerTextStyle),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[5],
        child: Text('Net Salary', style: headerTextStyle),
      ),
    ];
  }

  Widget _buildTableRow(
      SalaryRow employee,
      List<double> columnWidths,
      bool isSmallScreen,
      double fontSizeSmall,
      double fontSizeMedium,
      double padding,
      ) {
    final rowTextStyle = TextStyle(
      fontSize: isSmallScreen ? fontSizeSmall : fontSizeMedium,
      color: Colors.black87,
    );

    final amountTextStyle = TextStyle(
      fontSize: isSmallScreen ? fontSizeSmall : fontSizeMedium,
      fontWeight: FontWeight.w600,
      color: employee.isCalculated ? Colors.green.shade700 : Colors.orange.shade700,
    );

    return Row(
      children: [
        SizedBox(
          width: columnWidths[0],
          child: Text(
            employee.meta.empId,
            style: rowTextStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: padding / 2),
        SizedBox(
          width: columnWidths[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.employee,
                style: rowTextStyle.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 2),
              Text(
                employee.unit,
                style: rowTextStyle.copyWith(
                  fontSize: fontSizeSmall - 1,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: padding / 2),
        SizedBox(
          width: columnWidths[2],
          child: Text(
            employee.designation ?? '--',
            style: rowTextStyle.copyWith(color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        SizedBox(width: padding / 2),
        SizedBox(
          width: columnWidths[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${employee.days}',
                    style: rowTextStyle,
                  ),
                  if (employee.late > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'L:${employee.late}',
                        style: TextStyle(
                          fontSize: fontSizeSmall - 1,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              if (employee.leaves > 0)
                Text(
                  'H:${employee.leaves}',
                  style: TextStyle(
                    fontSize: fontSizeSmall - 1,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: padding / 2),
        SizedBox(
          width: columnWidths[4],
          child: Text(
            '₹${_formatNumber(employee.salary)}',
            style: amountTextStyle.copyWith(color: Colors.blue.shade700),
          ),
        ),
        SizedBox(width: padding / 2),
        SizedBox(
          width: columnWidths[5],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${_formatNumber(employee.total)}',
                style: amountTextStyle.copyWith(
                  color: employee.isCalculated ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              if (employee.deductions > 0)
                Text(
                  '-₹${_formatNumber(employee.deductions)}',
                  style: TextStyle(
                    fontSize: fontSizeSmall - 1,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTableFooter(
      SalarySheetProvider provider,
      List<double> columnWidths,
      bool isSmallScreen,
      double fontSizeSmall,
      double fontSizeMedium,
      double padding,
      ) {
    final footerTextStyle = TextStyle(
      fontSize: isSmallScreen ? fontSizeSmall : fontSizeMedium,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF764BA2),
    );

    return [
      SizedBox(
        width: columnWidths[0] + columnWidths[1] + columnWidths[2] + columnWidths[3] + (padding / 2 * 4),
        child: Text(
          'TOTAL (${provider.salarySheet!.rows.length} employees)',
          style: footerTextStyle,
          textAlign: TextAlign.right,
        ),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[4],
        child: Text(
          '₹${_formatNumber(provider.salarySheet!.totals.salarySum)}',
          style: footerTextStyle.copyWith(color: Colors.blue.shade700),
        ),
      ),
      SizedBox(width: padding / 2),
      SizedBox(
        width: columnWidths[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${_formatNumber(provider.salarySheet!.totals.totalSum)}',
              style: footerTextStyle.copyWith(color: Colors.green.shade700),
            ),
            Text(
              '-₹${_formatNumber(provider.salarySheet!.totals.salarySum - provider.salarySheet!.totals.totalSum)}',
              style: TextStyle(
                fontSize: fontSizeSmall,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ];
  }
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double fontSizeSmall,
    required double fontSizeMedium,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fontSizeSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: fontSizeSmall,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(fontSizeSmall),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: fontSizeMedium * 1.5,
              height: fontSizeMedium * 1.5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(fontSizeSmall / 2),
              ),
              child: Icon(icon, size: fontSizeMedium, color: color),
            ),
            SizedBox(height: fontSizeSmall),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? fontSizeMedium : fontSizeMedium * 1.2,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: fontSizeSmall / 2),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSizeSmall,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
      SalaryRow employee,
      bool isSmallScreen,
      bool isMediumScreen,
      double padding,
      double fontSizeSmall,
      double fontSizeMedium,
      double borderRadius,
      ) {
    final cardPadding = isSmallScreen ? padding : padding * 1.2;
    final statusSize = isSmallScreen ? fontSizeSmall : fontSizeMedium;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: padding / 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    employee.employee,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? fontSizeMedium : fontSizeMedium * 1.1,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding / 2,
                    vertical: padding / 4,
                  ),
                  decoration: BoxDecoration(
                    color: employee.isCalculated
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(statusSize / 2),
                    border: Border.all(
                      color: employee.isCalculated ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    employee.isCalculated ? '✓' : '…',
                    style: TextStyle(
                      color: employee.isCalculated ? Colors.green : Colors.orange,
                      fontSize: statusSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: padding / 2),

            // Employee details
            Row(
              children: [
                Icon(Icons.badge, size: fontSizeSmall, color: Colors.grey),
                SizedBox(width: padding / 4),
                Text(employee.meta.empId, style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey)),
                SizedBox(width: padding),
                Icon(Icons.work, size: fontSizeSmall, color: Colors.grey),
                SizedBox(width: padding / 4),
                Expanded(
                  child: Text(
                    employee.designation ?? 'No Designation',
                    style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: padding),

            Divider(color: Colors.grey.shade300, height: 1),

            SizedBox(height: padding),

            // Salary stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  label: 'Salary',
                  value: '₹${_formatNumber(employee.salary)}',
                  color: Colors.black87,
                  fontSizeSmall: fontSizeSmall,
                  fontSizeMedium: fontSizeMedium,
                ),
                _buildStatColumn(
                  label: 'Net Salary',
                  value: '₹${_formatNumber(employee.total)}',
                  color: const Color(0xFF667EEA),
                  fontSizeSmall: fontSizeSmall,
                  fontSizeMedium: fontSizeMedium,
                ),
                _buildStatColumn(
                  label: 'Days',
                  value: employee.days.toString(),
                  color: Colors.black87,
                  fontSizeSmall: fontSizeSmall,
                  fontSizeMedium: fontSizeMedium,
                  additionalInfo: Column(
                    children: [
                      Text(
                        'L:${employee.late}',
                        style: TextStyle(fontSize: fontSizeSmall - 2, color: Colors.orange),
                      ),
                      Text(
                        'H:${employee.leaves}',
                        style: TextStyle(fontSize: fontSizeSmall - 2, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
    required double fontSizeSmall,
    required double fontSizeMedium,
    Widget? additionalInfo,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold, color: color)),
        if (additionalInfo != null) additionalInfo,
      ],
    );
  }

  Future<void> _showMonthPicker(BuildContext context, SalarySheetProvider provider) async {
    final now = DateTime.now();
    DateTime initialDate;

    try {
      if (provider.selectedMonth.isNotEmpty) {
        final parts = provider.selectedMonth.split('-');
        if (parts.length == 2) {
          initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        } else {
          initialDate = now;
        }
      } else {
        initialDate = now;
      }
    } catch (e) {
      initialDate = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final month = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      provider.selectedMonth = month;
    }
  }

  Future<void> _refreshData() async {
    final provider = context.read<SalarySheetProvider>();

    if (provider.selectedMonth.isNotEmpty && provider.selectedDepartmentId != null) {
      await provider.fetchSalarySheet();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showFilterDialog();
    }
  }

  void _showFilterDialog() {
    final provider = context.read<SalarySheetProvider>();

    _tempSelectedMonth = provider.selectedMonth.isNotEmpty
        ? provider.selectedMonth
        : (provider.availableMonths.isNotEmpty ? provider.availableMonths.last : '');

    _tempSelectedDepartmentId = provider.selectedDepartmentId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Filters'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _tempSelectedMonth,
                      items: provider.availableMonths.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(_formatMonth(month)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _tempSelectedMonth = value),
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: _tempSelectedDepartmentId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('-- Select Department --'),
                        ),
                        ...provider.departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept.id,
                            child: Text(dept.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) => setState(() => _tempSelectedDepartmentId = value),
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
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
                  onPressed: _tempSelectedMonth != null && _tempSelectedDepartmentId != null
                      ? () {
                    provider.selectedMonth = _tempSelectedMonth!;
                    provider.selectedDepartmentId = _tempSelectedDepartmentId;
                    Navigator.pop(context);
                    provider.fetchSalarySheet();
                  }
                      : null,
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatMonth(String month) {
    try {
      final date = DateTime.parse('$month-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return month;
    }
  }

  String _formatNumber(double number) {
    return NumberFormat('#,##,##0').format(number);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}