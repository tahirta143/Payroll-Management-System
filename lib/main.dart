import 'package:flutter/material.dart';
import 'package:payroll_app/provider/Auth_provider/Auth_provider.dart';
import 'package:payroll_app/provider/absents_provider/absents_provider.dart';
import 'package:payroll_app/provider/attendance_provider/attendance_provider.dart';
import 'package:payroll_app/provider/chart_provider/chart_provider.dart';
import 'package:payroll_app/provider/dashboard_provider/dashboard_summary_provider.dart';
import 'package:payroll_app/provider/employee_salary_provider/employee_salary_provider.dart';
import 'package:payroll_app/provider/leave_approve_provider/leave_approve.dart';
import 'package:payroll_app/provider/permissions_provider/permissions.dart';
import 'package:payroll_app/screen/Auth/login_screen.dart';
import 'package:payroll_app/screen/Dashboard_screen/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardSummaryProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeSalaryProvider()),
        ChangeNotifierProvider(create: (_) => AbsentProvider()),
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