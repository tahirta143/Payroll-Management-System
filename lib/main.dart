// import 'package:flutter/material.dart';
// import 'package:payroll_app/provider/Auth_provider/Auth_provider.dart';
// import 'package:payroll_app/provider/absents_provider/absents_provider.dart';
// import 'package:payroll_app/provider/attendance_provider/attendance_provider.dart';
// import 'package:payroll_app/provider/chart_provider/chart_provider.dart';
// import 'package:payroll_app/provider/dashboard_provider/dashboard_summary_provider.dart';
// import 'package:payroll_app/provider/employee_chart_data/employee_chart_data.dart';
// import 'package:payroll_app/provider/employee_salary_provider/employee_salary_provider.dart';
// import 'package:payroll_app/provider/leave_approve_provider/leave_approve.dart';
// import 'package:payroll_app/provider/monthly_attandance_sheet_provider/monthly_att_provider.dart';
// import 'package:payroll_app/provider/permissions_provider/permissions.dart';
// import 'package:payroll_app/provider/regular_user_provider/regular_user.dart';
// import 'package:payroll_app/provider/salary_sheet_provider/salary_sheet_provider.dart';
// import 'package:payroll_app/provider/salary_slip_provider/salary_slip_provider.dart';
// import 'package:payroll_app/screen/Auth/login_screen.dart';
// import 'package:payroll_app/screen/Dashboard_screen/dashboard_screen.dart';
// import 'package:provider/provider.dart';
// import 'theme.dart';
//
// void main() async {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => PermissionProvider()),
//         ChangeNotifierProvider(create: (_) => LeaveProvider()),
//         ChangeNotifierProvider(create: (_) => AttendanceProvider()),
//         ChangeNotifierProvider(create: (_) => DashboardSummaryProvider()),
//         ChangeNotifierProvider(create: (_) => ChartProvider()),
//         ChangeNotifierProvider(create: (_) => EmployeeSalaryProvider()),
//         ChangeNotifierProvider(create: (_) => AbsentProvider()),
//         ChangeNotifierProvider(create: (_) => SalarySlipProvider()),
//         ChangeNotifierProvider(create: (_) => SalarySheetProvider()),
//         ChangeNotifierProvider(create: (context) => MonthlyReportProvider()),
//         ChangeNotifierProvider(create: (_) => NonAdminDashboardProvider()),
//         ChangeNotifierProvider(create: (_) => AttendanceChartProvider()),
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Afaq MIS',
//         theme: appTheme,
//         // Use home with conditional logic
//         home: Consumer<AuthProvider>(
//           builder: (context, auth, child) {
//             if (auth.token != null) {
//               return const DashboardScreen();
//             } else {
//               return const LoginScreen();
//             }
//           },
//         ),
//         // Define routes for navigation
//         routes: {
//           '/login': (context) => const LoginScreen(),
//           '/dashboard': (context) => const DashboardScreen(),
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:payroll_app/provider/Auth_provider/Auth_provider.dart';
import 'package:payroll_app/provider/absents_provider/absents_provider.dart';
import 'package:payroll_app/provider/attendance_provider/attendance_provider.dart';
import 'package:payroll_app/provider/chart_provider/chart_provider.dart';
import 'package:payroll_app/provider/dashboard_provider/dashboard_summary_provider.dart';
import 'package:payroll_app/provider/employee_chart_data/employee_chart_data.dart';
import 'package:payroll_app/provider/employee_salary_provider/employee_salary_provider.dart';
import 'package:payroll_app/provider/leave_approve_provider/leave_approve.dart';
import 'package:payroll_app/provider/monthly_attandance_sheet_provider/monthly_att_provider.dart';
import 'package:payroll_app/provider/permissions_provider/permissions.dart';
import 'package:payroll_app/provider/regular_user_provider/regular_user.dart';
import 'package:payroll_app/provider/salary_sheet_provider/salary_sheet_provider.dart';
import 'package:payroll_app/provider/salary_slip_provider/salary_slip_provider.dart';
import 'package:payroll_app/screen/Auth/login_screen.dart';
import 'package:payroll_app/screen/Dashboard_screen/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize providers with saved data
  final authProvider = AuthProvider();
  final permissionProvider = PermissionProvider();

  // Load saved permissions before app starts
  await permissionProvider.loadFromPrefs();

  // Try to auto-login with saved token
  await authProvider.autoLogin(permissionProvider);

  runApp(MyApp(
    authProvider: authProvider,
    permissionProvider: permissionProvider,
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final PermissionProvider? permissionProvider;

  const MyApp({
    super.key,
    this.authProvider,
    this.permissionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use the pre-initialized providers if provided, otherwise create new ones
        if (authProvider != null)
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider!)
        else
          ChangeNotifierProvider(create: (_) => AuthProvider()),

        if (permissionProvider != null)
          ChangeNotifierProvider<PermissionProvider>.value(value: permissionProvider!)
        else
          ChangeNotifierProvider(create: (_) => PermissionProvider()),

        // Other providers (created fresh each time)
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardSummaryProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeSalaryProvider()),
        ChangeNotifierProvider(create: (_) => AbsentProvider()),
        ChangeNotifierProvider(create: (_) => SalarySlipProvider()),
        ChangeNotifierProvider(create: (_) => SalarySheetProvider()),
        ChangeNotifierProvider(create: (context) => MonthlyReportProvider()),
        ChangeNotifierProvider(create: (_) => NonAdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceChartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Afaq MIS',
        theme: appTheme,
        // Use home with conditional logic
        home: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.token != null) {
              return const DashboardScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
        // Define routes for navigation
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}