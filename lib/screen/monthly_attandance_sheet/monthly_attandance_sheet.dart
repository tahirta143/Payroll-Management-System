// lib/screen/monthly_attandance_sheet/monthly_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/monthly_attandance_sheet/monthly_attandance_sheet.dart';
import '../../provider/monthly_attandance_sheet_provider/monthly_att_provider.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  const MonthlyAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<MonthlyAttendanceScreen> createState() => _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController(); // Add this
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MonthlyReportProvider>(context, listen: false);

      // First check what's in SharedPreferences
      provider.debugPrintSharedPreferences().then((_) {
        // Then initialize from auth
        provider.initializeFromAuth().then((_) {
          // Double-check for non-admin users
          if (!provider.isAdmin) {
            print('🔵 NON-ADMIN USER: Loading own report after init...');
            // Small delay to ensure everything is set
            Future.delayed(const Duration(milliseconds: 100), () {
              provider.loadReportForCurrentUser();
            });
          }
        });
      });
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
            'Monthly Attendance',
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
                // Filter action
              },
              icon: Icon(Icons.filter_alt, color: Colors.white, size: iconSize),
              tooltip: 'Filter',
            ),

            IconButton(
              onPressed: () {
                final provider = Provider.of<MonthlyReportProvider>(context, listen: false);
                provider.refreshData();
              },
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
          child: Consumer<MonthlyReportProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
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

                  // Content
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
                        screenHeight,
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

  // ==================== FILTERS SECTION ====================
  Widget _buildFilters(
      MonthlyReportProvider provider,
      double screenWidth,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      double padding,
      double borderRadius,
      double iconSize,
      double fontSize,
      ) {
    final isAdmin = provider.isAdmin;

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
          // Month selection - show for everyone
          if (isSmallScreen)
            _buildMonthSelectionVertical(provider, padding, borderRadius, iconSize, fontSize)
          else
            _buildMonthSelectionHorizontal(provider, padding, borderRadius, iconSize, fontSize),

          // 🔴 Only show admin filters for admin users
          if (isAdmin) ...[
            SizedBox(height: padding),
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
            Row(
              children: [
                Icon(Icons.person, size: iconSize, color: const Color(0xFF667EEA)),
                SizedBox(width: padding),
                Text(
                  'Employee:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
                SizedBox(width: padding),
                Expanded(
                  child: _buildEmployeeDropdown(provider, padding, borderRadius, fontSize),
                ),
              ],
            ),
            SizedBox(height: padding * 1.5),
            Row(
              children: [
                Expanded(
                  child: _buildApplyButton(provider, padding, borderRadius, fontSize),
                ),
                SizedBox(width: padding),
                Expanded(
                  child: _buildClearButton(provider, padding, borderRadius, fontSize),
                ),
              ],
            ),
          ],

          // 🔴 Show current employee info for non-admin users
          if (!isAdmin && provider.currentUserName != null) ...[
            SizedBox(height: padding),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius / 2),
                border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: const Color(0xFF667EEA), size: iconSize * 0.8),
                  SizedBox(width: padding / 2),
                  Expanded(
                    child: Text(
                      'Viewing: ${provider.currentUserName}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF667EEA),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error widget
          if (provider.error != null) ...[
            SizedBox(height: padding),
            _buildErrorWidget(provider.error!, padding, fontSizeSmall: fontSize),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSelectionHorizontal(
      MonthlyReportProvider provider,
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
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(borderRadius / 2),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedMonth,
                isExpanded: true,
                padding: EdgeInsets.symmetric(horizontal: padding),
                icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF667EEA)),
                items: _getMonths().map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(
                      _formatMonth(month),
                      style: TextStyle(fontSize: fontSize),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.setSelectedMonth(value);
                    // 🔴 Auto-reload for non-admin users
                    if (!provider.isAdmin && provider.currentEmployeeId != null) {
                      provider.loadReport(
                        employeeId: provider.currentEmployeeId,
                        month: value,
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

// Same for vertical version
  Widget _buildMonthSelectionVertical(
      MonthlyReportProvider provider,
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(borderRadius / 2),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedMonth,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: padding),
              icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF667EEA)),
              items: _getMonths().map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(
                    _formatMonth(month),
                    style: TextStyle(fontSize: fontSize),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setSelectedMonth(value);
                  // 🔴 Auto-reload for non-admin users
                  if (!provider.isAdmin && provider.currentEmployeeId != null) {
                    provider.loadReport(
                      employeeId: provider.currentEmployeeId,
                      month: value,
                    );
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildDepartmentDropdown(
      MonthlyReportProvider provider,
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
              'All Departments',
              style: TextStyle(color: Colors.grey, fontSize: fontSize),
            ),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                child: Text(
                  'All Departments',
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
          onChanged: provider.isLoading
              ? null
              : (value) => provider.setSelectedDepartmentId(value),
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown(
      MonthlyReportProvider provider,
      double padding,
      double borderRadius,
      double fontSize,
      ) {
    // 🔴 FIX: Create unique employee list
    final uniqueEmployees = <int, Employee>{};
    for (var emp in provider.employees) {
      uniqueEmployees[emp.id] = emp;
    }
    final uniqueEmployeeList = uniqueEmployees.values.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(borderRadius / 2),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: provider.selectedEmployeeId,
          isExpanded: true,
          style: TextStyle(fontSize: fontSize, color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius / 2),
          icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF667EEA)),
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              'Select Employee',
              style: TextStyle(color: Colors.grey, fontSize: fontSize),
            ),
          ),
          items: [
            // Add "Select Employee" item
            DropdownMenuItem<int?>(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                child: Text(
                  'Select Employee',
                  style: TextStyle(color: Colors.grey, fontSize: fontSize),
                ),
              ),
            ),
            // 🔴 FIXED: Use uniqueEmployeeList instead of provider.employees
            ...uniqueEmployeeList.map((emp) {
              return DropdownMenuItem<int?>(
                value: emp.id,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                  child: Text(
                    '${emp.name} (${emp.empId})',
                    style: TextStyle(fontSize: fontSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
          ],
          onChanged: provider.isLoading || !provider.isAdmin // 🔴 Also disable for non-admin
              ? null
              : (value) => provider.setSelectedEmployeeId(value),
        ),
      ),
    );
  }
  Widget _buildApplyButton(
      MonthlyReportProvider provider,
      double padding,
      double borderRadius,
      double fontSize,
      ) {
    return ElevatedButton(
      onPressed: provider.isLoading ? null : provider.applyFilters,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: padding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
        backgroundColor: const Color(0xFF667EEA),
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
          Text('Apply', style: TextStyle(fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _buildClearButton(
      MonthlyReportProvider provider,
      double padding,
      double borderRadius,
      double fontSize,
      ) {
    return OutlinedButton(
      onPressed: provider.clearFilters,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: padding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
        side: BorderSide(color: const Color(0xFF667EEA).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.clear, size: fontSize, color: const Color(0xFF667EEA)),
          SizedBox(width: padding / 2),
          Text('Clear', style: TextStyle(fontSize: fontSize, color: const Color(0xFF667EEA))),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, double padding, {required double fontSizeSmall}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(padding / 2),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: fontSizeSmall * 1.5),
          SizedBox(width: padding / 2),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CONTENT SECTION ====================
  Widget _buildContent(
      MonthlyReportProvider provider,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      double padding,
      double fontSizeSmall,
      double fontSizeMedium,
      double fontSizeLarge,
      double borderRadius,
      ) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA))),
            SizedBox(height: padding),
            Text('Fetching attendance data...', style: TextStyle(fontSize: fontSizeMedium)),
          ],
        ),
      );
    }

    if (provider.currentReport == null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: fontSizeLarge * 3,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: padding),
                Text(
                  provider.isAdmin
                      ? 'Select employee and month to view report'
                      : 'No attendance record found for this month',
                  style: TextStyle(
                    fontSize: fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: padding / 2),
                Text(
                  provider.isAdmin
                      ? 'Choose filters to view monthly attendance report'
                      : 'Your attendance for this month is not available',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!provider.isAdmin)
                  Padding(
                    padding: EdgeInsets.only(top: padding * 1.5),
                    child: ElevatedButton.icon(
                      onPressed: () => provider.loadReportForCurrentUser(),
                      icon: Icon(Icons.refresh, size: fontSizeMedium),
                      label: Text('Load My Attendance', style: TextStyle(fontSize: fontSizeMedium)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: padding * 2, vertical: padding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius / 2),
                        ),
                        backgroundColor: const Color(0xFF667EEA),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildAttendanceTable(
      provider,
      screenWidth,
      screenHeight,
      isSmallScreen,
      isMediumScreen,
      isLargeScreen,
      padding,
      fontSizeSmall,
      fontSizeMedium,
      borderRadius,
    );
  }

  // ==================== ATTENDANCE TABLE ====================
  // ==================== ATTENDANCE TABLE ====================
  Widget _buildAttendanceTable(
      MonthlyReportProvider provider,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen,
      double padding,
      double fontSizeSmall,
      double fontSizeMedium,
      double borderRadius,
      ) {
    final report = provider.currentReport!;
    final days = report.days.where((day) =>
    day.status == 'present' ||
        day.status == 'absent' ||
        day.status == 'holiday'
    ).toList();

    if (days.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: fontSizeMedium * 3,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: padding),
            Text(
              'No attendance records for this month',
              style: TextStyle(
                fontSize: fontSizeMedium,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Column widths
    final List<double> columnWidths = [
      20,   // #
      55,   // Date
      90,  // Day & Status
      50,   // In
      50,   // Out
      70,   // Duration
      50,   // Late
      50,   // Early
      50,   // OT
      60,  // Status
    ];

    // Calculate total table width
    final totalTableWidth = columnWidths.reduce((a, b) => a + b) + (padding * (columnWidths.length - 1));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius / 2),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius / 2),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalTableWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table Header
                          Container(
                            width: totalTableWidth,
                            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 1.2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF667EEA),
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
                          ...List.generate(days.length, (index) {
                            final day = days[index];
                            return Container(
                              width: totalTableWidth,
                              color: index.isEven ? Colors.white : Colors.grey.shade50,
                              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 1.5),
                              child: Row(
                                children: _buildTableRow(
                                  index + 1,
                                  day,
                                  columnWidths,
                                  isSmallScreen,
                                  fontSizeSmall,
                                  fontSizeMedium,
                                  padding,
                                ),
                              ),
                            );
                          }),

                          // Footer
                          Container(
                            width: totalTableWidth,
                            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 1.2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667EEA).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(padding),
                                  ),
                                  child: Text(
                                    'Total Days: ${days.length}',
                                    style: TextStyle(
                                      fontSize: fontSizeSmall,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF667EEA),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
      SizedBox(width: columnWidths[0], child: Text('#', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[1], child: Text('Date', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[2], child: Text('Days', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[3], child: Text('Time In', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[4], child: Text('Time Out', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[5], child: Text('Duration', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[6], child: Text('Late', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[7], child: Text('Early', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[8], child: Text('OT', style: headerTextStyle, textAlign: TextAlign.center)),
      SizedBox(width: padding / 2),
      SizedBox(width: columnWidths[9], child: Text('Status', style: headerTextStyle, textAlign: TextAlign.center)),
    ];
  }

  List<Widget> _buildTableRow(
      int index,
      AttendanceDay day,
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

    return [
      // #
      SizedBox(
        width: columnWidths[0],
        child: Text(
          index.toString(),
          style: rowTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(width: padding / 2),

      // Date
      SizedBox(
        width: columnWidths[1],
        child: Text(
          _formatDate(day.date),
          style: rowTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(width: padding / 2),

      // Day & Status combined
      SizedBox(
        width: columnWidths[2],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatWeekday(day.weekday),
              style: rowTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(day),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getStatusBorderColor(day).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                _getStatusText(day),
                style: TextStyle(
                  color: _getStatusTextColor(day),
                  fontSize: isSmallScreen ? fontSizeSmall - 1 : fontSizeSmall,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: padding / 2),

      // In
      SizedBox(
        width: columnWidths[3],
        child: Text(
          day.timeIn ?? '-',
          style: rowTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(width: padding / 2),

      // Out
      SizedBox(
        width: columnWidths[4],
        child: Text(
          day.timeOut ?? '-',
          style: rowTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(width: padding / 2),

      // Duration
      SizedBox(
        width: columnWidths[5],
        child: Text(
          day.durationLabel ?? '-',
          style: rowTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(width: padding / 2),

      // Late
      SizedBox(
        width: columnWidths[6],
        child: day.lateMinutes > 0
            ? Container(
          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade200, width: 0.5),
          ),
          child: Text(
            day.lateLabel ?? '${day.lateMinutes}m',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: isSmallScreen ? fontSizeSmall - 1 : fontSizeSmall,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        )
            : Text('-', style: rowTextStyle, textAlign: TextAlign.center),
      ),
      SizedBox(width: padding / 2),

      // Early
      SizedBox(
        width: columnWidths[7],
        child: day.earlyMinutes > 0
            ? Container(
          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade200, width: 0.5),
          ),
          child: Text(
            day.earlyLabel ?? '${day.earlyMinutes}m',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: isSmallScreen ? fontSizeSmall - 1 : fontSizeSmall,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        )
            : Text('-', style: rowTextStyle, textAlign: TextAlign.center),
      ),
      SizedBox(width: padding / 2),

      // OT
      SizedBox(
        width: columnWidths[8],
        child: day.overtimeMinutes > 0
            ? Container(
          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.shade200, width: 0.5),
          ),
          child: Text(
            day.overtimeLabel ?? '${day.overtimeMinutes}m',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: isSmallScreen ? fontSizeSmall - 1 : fontSizeSmall,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        )
            : Text('-', style: rowTextStyle, textAlign: TextAlign.center),
      ),
      SizedBox(width: padding / 2),

      // Status (removed from here since it's now combined with day)
      SizedBox(
        width: columnWidths[9],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusBackgroundColor(day),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getStatusBorderColor(day).withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            _getDetailedStatusText(day),
            style: TextStyle(
              color: _getStatusTextColor(day),
              fontSize: isSmallScreen ? fontSizeSmall - 1 : fontSizeSmall,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];
  }

  // ==================== STATUS HELPER METHODS ====================
  Color _getStatusBackgroundColor(AttendanceDay day) {
    if (day.status == 'holiday') {
      return Colors.purple.shade50;
    }
    if (day.status == 'absent'||day.isFullAbsent) {
      return Colors.red.shade50;
    }
    if (day.status == 'present') {
      return Colors.green.shade50;
    }
    return Colors.grey.shade50;
  }

  Color _getStatusBorderColor(AttendanceDay day) {
    if (day.status == 'holiday') {
      return Colors.purple;
    }
    if (day.status == 'absent'||day.isFullAbsent) {
      return Colors.red;
    }
    if (day.status == 'present') {
      return Colors.green;
    }
    return Colors.grey;
  }

  Color _getStatusTextColor(AttendanceDay day) {
    if (day.status == 'holiday') {
      return Colors.purple.shade700;
    }
    if (day.status == 'absent') {
      return Colors.red.shade700;
    }
    if (day.status == 'present') {
      return Colors.green.shade700;
    }
    return Colors.grey.shade700;
  }

  String _getStatusText(AttendanceDay day) {
    if (day.status == 'holiday' && day.holiday != null) {
      return 'Holiday';
    }
    if (day.status == 'absent'||day.isFullAbsent) {
      return 'Absent';
    }
    if (day.status == 'present') {
      return 'Present';
    }
    return day.status.toUpperCase();
  }

  String _getDetailedStatusText(AttendanceDay day) {
    if (day.status == 'holiday' && day.holiday != null) {
      return 'HOLIDAY';
    }
    if (day.status == 'absent') {
      return 'ABSENT';
    }
    if (day.status == 'present') {
      return 'PRESENT';
    }
    return day.status.toUpperCase();
  }

  // ==================== HELPER METHODS ====================
  List<String> _getMonths() {
    final months = <String>[];
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i);
      months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
    return months;
  }

  String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      final year = parts[0];
      final monthNum = int.parse(parts[1]);
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${monthNames[monthNum - 1]} $year';
    } catch (e) {
      return month;
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      final day = parts[2];
      final month = parts[1];
      return '$day/$month';
    } catch (e) {
      return date;
    }
  }

  String _formatWeekday(String weekday) {
    if (weekday.length > 3) {
      return weekday.substring(0, 3);
    }
    return weekday;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose(); // Add this
    super.dispose();
  }
}