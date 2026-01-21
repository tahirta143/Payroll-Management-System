import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../model/attendance_model/attendance_model.dart';
import '../../provider/attendance_provider/attendance_provider.dart';

class AddEditAttendanceScreen extends StatefulWidget {
  final AttendanceMode mode;
  final Attendance? attendance;
  final VoidCallback onAttendanceSaved;

  const AddEditAttendanceScreen({
    super.key,
    required this.mode,
    this.attendance,
    required this.onAttendanceSaved,
  });

  @override
  State<AddEditAttendanceScreen> createState() => _AddEditAttendanceScreenState();
}

class _AddEditAttendanceScreenState extends State<AddEditAttendanceScreen> {
  late final TextEditingController _dateController;
  late final TextEditingController _timeInController;
  late final TextEditingController _timeOutController;
  late final TextEditingController _machineCodeController;
  late final TextEditingController _notesController;

  int? _selectedEmployeeId;
  int? _selectedDutyShiftId;
  String? _selectedDepartment;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTimeIn;
  TimeOfDay? _selectedTimeOut;
  String? _machineCode;
  String? _notes;

  bool _isLoading = false;
  bool _isDataLoaded = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _dateController = TextEditingController();
    _timeInController = TextEditingController();
    _timeOutController = TextEditingController();
    _machineCodeController = TextEditingController();
    _notesController = TextEditingController();

    // Initialize with default values first
    _selectedDate = DateTime.now();
    _selectedTimeIn = const TimeOfDay(hour: 9, minute: 0);
    _selectedTimeOut = const TimeOfDay(hour: 17, minute: 0);
    // Initialize department to "All Departments" for add mode
    _selectedDepartment = 'All Departments';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _loadData() async {
    if (_isDataLoaded) return;

    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    // Fetch required data if not already loaded
    if (provider.employees.isEmpty) {
      await provider.fetchEmployees();
    }
    if (provider.departments.isEmpty) {
      await provider.fetchDepartments();
    }
    if (provider.dutyShifts.isEmpty) {
      await provider.fetchDutyShifts();
    }

    // Initialize data from attendance record if in edit mode
    if (widget.mode == AttendanceMode.edit && widget.attendance != null) {
      _initializeFromAttendance(provider);
    }

    // Update controllers with proper context
    _updateControllers();

    setState(() {
      _isDataLoaded = true;
    });
  }

  void _initializeFromAttendance(AttendanceProvider provider) {
    final attendance = widget.attendance!;

    print('=== INITIALIZING EDIT MODE ===');
    print('Attendance employee ID: ${attendance.employeeId}');
    print('Attendance employee name: ${attendance.employeeName}');
    print('Attendance department: ${attendance.departmentName}');

    // Set employee ID - This is the most important part
    _selectedEmployeeId = attendance.employeeId;

    // Set duty shift ID
    _selectedDutyShiftId = attendance.dutyShiftId;

    // Set date
    _selectedDate = attendance.date;

    // Set department from attendance
    _selectedDepartment = attendance.departmentName;

    // Parse time from string
    if (attendance.timeIn.isNotEmpty) {
      try {
        final timeInParts = attendance.timeIn.split(':');
        _selectedTimeIn = TimeOfDay(
          hour: int.parse(timeInParts[0]),
          minute: int.parse(timeInParts[1]),
        );
      } catch (e) {
        _selectedTimeIn = const TimeOfDay(hour: 9, minute: 0);
      }
    }

    if (attendance.timeOut.isNotEmpty) {
      try {
        final timeOutParts = attendance.timeOut.split(':');
        _selectedTimeOut = TimeOfDay(
          hour: int.parse(timeOutParts[0]),
          minute: int.parse(timeOutParts[1]),
        );
      } catch (e) {
        _selectedTimeOut = const TimeOfDay(hour: 17, minute: 0);
      }
    }

    // Set machine code
    _machineCode = attendance.machineCode ?? '';
    _machineCodeController.text = _machineCode ?? '';

    // Debug: Find the employee in the provider's list
    final matchingEmployee = provider.employees.firstWhere(
          (emp) => emp.id == _selectedEmployeeId,
      orElse: () => Employee(
        id: 0,
        name: 'Not Found',
        empId: '',
        department: '',
      ),
    );

    print('Found matching employee: ${matchingEmployee.name} (ID: ${matchingEmployee.id})');
    print('Total employees in provider: ${provider.employees.length}');
  }

  void _updateControllers() {
    // Date
    if (_selectedDate != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    } else {
      _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    // Time In - Use manual format to avoid context issues
    if (_selectedTimeIn != null) {
      _timeInController.text = _formatTime(_selectedTimeIn!);
    } else {
      _timeInController.text = '09:00';
    }

    // Time Out - Use manual format to avoid context issues
    if (_selectedTimeOut != null) {
      _timeOutController.text = _formatTime(_selectedTimeOut!);
    } else {
      _timeOutController.text = '17:00';
    }

    // Machine Code - ensure it's not null
    if (_machineCode != null && _machineCode!.isNotEmpty) {
      _machineCodeController.text = _machineCode!;
    } else {
      _machineCodeController.text = '';
    }

    // Notes
    if (_notes != null) {
      _notesController.text = _notes!;
    } else {
      _notesController.text = '';
    }
  }

  // Helper method to format time manually (without using context)
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeInController.dispose();
    _timeOutController.dispose();
    _machineCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTimeIn(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeIn ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTimeIn = picked;
        _timeInController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _selectTimeOut(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOut ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTimeOut = picked;
        _timeOutController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _saveAttendance() async {
    print('=== ATTEMPTING TO SAVE ATTENDANCE ===');

    // First validate the form
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    print('Form validation passed');

    // Check if employee is selected
    if (_selectedEmployeeId == null || _selectedEmployeeId == 0) {
      print('Employee validation failed: $_selectedEmployeeId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('Employee validation passed: $_selectedEmployeeId');

    // Check if duty shift is selected
    if (_selectedDutyShiftId == null) {
      print('Duty shift validation failed: $_selectedDutyShiftId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a duty shift'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('Duty shift validation passed: $_selectedDutyShiftId');

    // Check if date is selected
    if (_selectedDate == null) {
      print('Date validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('Date validation passed: $_selectedDate');

    // Check if times are selected
    if (_selectedTimeIn == null || _selectedTimeOut == null) {
      print('Time validation failed: TimeIn=$_selectedTimeIn, TimeOut=$_selectedTimeOut');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both time in and time out'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('Time validation passed: TimeIn=$_selectedTimeIn, TimeOut=$_selectedTimeOut');

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);

      // 1. Get department ID from selected employee or department
      int? departmentId;

      if (_selectedEmployeeId != null) {
        // Find the selected employee
        final selectedEmployee = provider.employees.firstWhere(
              (emp) => emp.id == _selectedEmployeeId,
          orElse: () => Employee(
            id: 0,
            name: '',
            empId: '',
            department: '',
            departmentId: 0,
          ),
        );

        // Check if employee has departmentId
        if (selectedEmployee.departmentId != null && selectedEmployee.departmentId! > 0) {
          departmentId = selectedEmployee.departmentId;
          print('Found departmentId from employee: $departmentId');
        } else {
          // Try to get departmentId from department name
          print('Employee has no departmentId, trying to get from department name: ${selectedEmployee.department}');
          departmentId = _getDepartmentIdByName(selectedEmployee.department, provider.departments);
        }
      }

      // If still no departmentId, try to get from selected department
      if (departmentId == null || departmentId == 0) {
        departmentId = _getDepartmentIdByName(_selectedDepartment, provider.departments);
      }

      // Validate departmentId
      if (departmentId == null || departmentId == 0) {
        print('Department ID validation failed: $departmentId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not determine department. Please ensure employee has a department assigned.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      print('Department ID validation passed: $departmentId');

      // 2. Format times for API
      final timeInFormatted = '${_selectedTimeIn!.hour.toString().padLeft(2, '0')}:${_selectedTimeIn!.minute.toString().padLeft(2, '0')}:00';
      final timeOutFormatted = '${_selectedTimeOut!.hour.toString().padLeft(2, '0')}:${_selectedTimeOut!.minute.toString().padLeft(2, '0')}:00';

      // 3. Format date for API
      final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // 4. Get machine code if provided
      final machineCode = _machineCodeController.text.isNotEmpty ? _machineCodeController.text : null;

      // 5. Create DTO with departmentId
      final dto = AttendanceCreateDTO(
        date: _selectedDate!,
        employeeId: _selectedEmployeeId!,
        dutyShiftId: _selectedDutyShiftId!,
        departmentId: departmentId, // ADD DEPARTMENT ID HERE
        timeIn: timeInFormatted,
        timeOut: timeOutFormatted,
        machineCode: machineCode,
      );

      print('=== SAVING ATTENDANCE DATA ===');
      print('Formatted Date: $dateFormatted');
      print('Employee ID: $_selectedEmployeeId');
      print('Department ID: $departmentId');
      print('Duty Shift ID: $_selectedDutyShiftId');
      print('Time In: $timeInFormatted');
      print('Time Out: $timeOutFormatted');
      print('Machine Code: $machineCode');
      print('DTO to JSON: ${dto.toJson()}');

      bool success;
      if (widget.mode == AttendanceMode.edit && widget.attendance != null) {
        print('Updating attendance ID: ${widget.attendance!.id}');
        success = await provider.updateAttendance(widget.attendance!.id, dto);
      } else {
        print('Creating new attendance');
        success = await provider.createAttendance(dto);
      }

      if (success) {
        print('Attendance saved successfully!');
        widget.onAttendanceSaved();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.mode == AttendanceMode.edit
                ? 'Attendance updated successfully!'
                : 'Attendance added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('Attendance save failed (provider returned false)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save attendance. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving attendance: $e');
      print('Stack trace: ${e.toString()}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Helper method to get department ID by name
  int? _getDepartmentIdByName(String? departmentName, List<Department> departments) {
    if (departmentName == null || departmentName.isEmpty) return null;

    print('Looking for department: "$departmentName"');
    print('Available departments: ${departments.map((d) => d.name).toList()}');

    // Try exact match first
    for (var dept in departments) {
      if (dept.name.toLowerCase().trim() == departmentName.toLowerCase().trim()) {
        print('Found exact match: ${dept.name} (ID: ${dept.id})');
        return dept.id;
      }
    }

    // Try partial match
    for (var dept in departments) {
      if (dept.name.toLowerCase().contains(departmentName.toLowerCase()) ||
          departmentName.toLowerCase().contains(dept.name.toLowerCase())) {
        print('Found partial match: ${dept.name} (ID: ${dept.id})');
        return dept.id;
      }
    }

    print('No department found for name: "$departmentName"');
    return null;
  }
  // Get filtered employees based on selected department
  List<Employee> _getFilteredEmployees(List<Employee> employees, String? selectedDepartment) {
    print('=== FILTERING EMPLOYEES ===');
    print('Selected department: $selectedDepartment');
    print('Total employees: ${employees.length}');

    // Log all employees' departments for debugging
    final uniqueDepartments = <String>{};
    for (var emp in employees) {
      if (emp.department != null && emp.department!.isNotEmpty) {
        uniqueDepartments.add(emp.department!);
      }
    }
    print('Unique departments found: $uniqueDepartments');

    if (selectedDepartment == null ||
        selectedDepartment.isEmpty ||
        selectedDepartment == 'All Departments') {
      print('Showing all ${employees.length} employees');
      return employees;
    }

    // Filter employees by department (case-insensitive)
    final filtered = employees.where((employee) {
      final empDept = employee.department?.toLowerCase().trim() ?? '';
      final selectedDept = selectedDepartment.toLowerCase().trim();

      // Try different matching strategies
      final exactMatch = empDept == selectedDept;
      final containsMatch = empDept.contains(selectedDept) || selectedDept.contains(empDept);

      final matches = exactMatch || containsMatch;

      if (matches) {
        print('✓ Employee "${employee.name}" matches department "$selectedDepartment"');
      }
      return matches;
    }).toList();

    print('Filtered employees: ${filtered.length}');
    if (filtered.isEmpty) {
      print('⚠️ No employees found for department: $selectedDepartment');
      // Fallback: show all employees if filtering returns none
      return employees;
    }

    return filtered;
  }

  // Get the employee name by ID
  String? _getEmployeeNameById(int? employeeId, List<Employee> employees) {
    if (employeeId == null) return null;
    final employee = employees.firstWhere(
          (e) => e.id == employeeId,
      orElse: () => Employee(
        id: 0,
        name: 'Unknown Employee',
        empId: '',
        department: '',
      ),
    );
    return employee.name;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final isEdit = widget.mode == AttendanceMode.edit;
    final size = MediaQuery.of(context).size;

    // Show loading if provider is still loading or data not loaded
    if (!_isDataLoaded ||
        provider.isLoadingEmployees ||
        provider.isLoadingDepartments ||
        provider.isLoadingDutyShifts) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }

    final departments = provider.departments.map((d) => d.name).toList();
    departments.sort();

    final dutyShifts = provider.dutyShifts;
    final allEmployees = provider.employees;

    // For edit mode, always include all employees to ensure current employee is shown
    final employeesToShow = isEdit ? allEmployees : _getFilteredEmployees(allEmployees, _selectedDepartment);

    // Debug information
    print('=== BUILDING SCREEN ===');
    print('Mode: ${isEdit ? "Edit" : "Add"}');
    print('Selected department: $_selectedDepartment');
    print('Selected employee ID: $_selectedEmployeeId');
    print('Total employees in provider: ${allEmployees.length}');
    print('Employees to show in dropdown: ${employeesToShow.length}');

    if (isEdit && widget.attendance != null) {
      print('Edit mode - Attendance employee ID: ${widget.attendance!.employeeId}');
      print('Edit mode - Attendance employee name: ${widget.attendance!.employeeName}');

      // Ensure current employee is selected
      if (_selectedEmployeeId == null) {
        _selectedEmployeeId = widget.attendance!.employeeId;
        _selectedDepartment = widget.attendance!.departmentName;
      }
    }

    // Get current employee name for display
    final currentEmployeeName = _getEmployeeNameById(_selectedEmployeeId, allEmployees);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Attendance' : 'Add Attendance',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isEdit && widget.attendance != null)
            IconButton(
              icon: const Icon(Iconsax.trash),
              onPressed: () => _showDeleteDialog(context),
              color: Colors.white,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Responsive
              Container(
                padding: EdgeInsets.all(size.width > 600 ? 24 : 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: size.width > 600 ? 70 : 50,
                      height: size.width > 600 ? 70 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(size.width > 600 ? 35 : 25),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isEdit ? Iconsax.edit : Iconsax.add,
                        size: size.width > 600 ? 32 : 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: size.width > 600 ? 20 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Attendance Record' : 'New Attendance Record',
                            style: TextStyle(
                              fontSize: size.width > 600 ? 20 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isEdit && currentEmployeeName != null)
                            Text(
                              'Employee: $currentEmployeeName',
                              style: TextStyle(
                                fontSize: size.width > 600 ? 14 : 12,
                                color: Colors.white70,
                              ),
                            )
                          else
                            Text(
                              isEdit
                                  ? 'Update employee attendance details'
                                  : 'Add new attendance record for employee',
                              style: TextStyle(
                                fontSize: size.width > 600 ? 14 : 12,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Department Filter - Responsive
              _buildSectionTitle('Department Filter'),
              const SizedBox(height: 12),
              _buildDepartmentDropdown(departments, size, isEdit),

              const SizedBox(height: 20),

              // Employee Selection - Responsive
              _buildSectionTitle('Employee Information'),
              const SizedBox(height: 12),
              _buildEmployeeDropdown(employeesToShow, size, isEdit),

              const SizedBox(height: 20),

              // Date and Shift - Responsive row
              _buildSectionTitle('Date & Shift Details'),
              const SizedBox(height: 12),
              if (size.width > 600)
              // Desktop/Tablet layout
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildDateField(size),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildDutyShiftDropdown(dutyShifts, size),
                    ),
                  ],
                )
              else
              // Mobile layout
                Column(
                  children: [
                    _buildDateField(size),
                    const SizedBox(height: 16),
                    _buildDutyShiftDropdown(dutyShifts, size),
                  ],
                ),

              const SizedBox(height: 20),

              // Time In/Out - Responsive row
              _buildSectionTitle('Time Details'),
              const SizedBox(height: 12),
              if (size.width > 600)
              // Desktop/Tablet layout
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildTimeField(
                        label: 'Time In',
                        controller: _timeInController,
                        onTap: () => _selectTimeIn(context),
                        size: size,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildTimeField(
                        label: 'Time Out',
                        controller: _timeOutController,
                        onTap: () => _selectTimeOut(context),
                        size: size,
                      ),
                    ),
                  ],
                )
              else
              // Mobile layout
                Column(
                  children: [
                    _buildTimeField(
                      label: 'Time In',
                      controller: _timeInController,
                      onTap: () => _selectTimeIn(context),
                      size: size,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeField(
                      label: 'Time Out',
                      controller: _timeOutController,
                      onTap: () => _selectTimeOut(context),
                      size: size,
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Machine Code
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _machineCodeController,
                decoration: InputDecoration(
                  labelText: 'Machine Code (Optional)',
                  prefixIcon: const Icon(Iconsax.cpu),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => _machineCode = value,
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Iconsax.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => _notes = value,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF667EEA).withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    isEdit ? 'Update Attendance' : 'Save Attendance',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF667EEA),
      ),
    );
  }

  Widget _buildDepartmentDropdown(List<String> departments, Size size, bool isEdit) {
    // Add "All Departments" option at the beginning
    final allDepartments = ['All Departments', ...departments];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDepartment ?? 'All Departments',
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: isEdit ? 'Employee Department' : 'Filter by Department',
          hintText: departments.isEmpty ? 'No departments found' : 'Select Department',
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        items: allDepartments.map((department) {
          return DropdownMenuItem<String>(
            value: department,
            child: SizedBox(
              height: 48, // Fixed height to prevent overflow
              child: Row(
                children: [
                  Container(
                    width: size.width > 600 ? 40 : 32,
                    height: size.width > 600 ? 40 : 32,
                    decoration: BoxDecoration(
                      color: department == 'All Departments'
                          ? Colors.grey.withOpacity(0.1)
                          : const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(size.width > 600 ? 20 : 16),
                    ),
                    child: Center(
                      child: Text(
                        department == 'All Departments' ? '🏢' : department.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: department == 'All Departments'
                              ? Colors.grey
                              : const Color(0xFF667EEA),
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 600 ? 16 : 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width > 600 ? 16 : 8),
                  Expanded(
                    child: Text(
                      department,
                      style: TextStyle(
                        fontSize: size.width > 600 ? 14 : 12,
                        color: department == 'All Departments'
                            ? Colors.grey
                            : Colors.black87,
                        fontWeight: department == 'All Departments'
                            ? FontWeight.normal
                            : FontWeight.w500,
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
        onChanged: isEdit ? null : (value) {
          // In edit mode, don't allow changing the department
          // In add mode, allow filtering by department
          setState(() {
            _selectedDepartment = value;
            // Reset employee selection when department changes
            _selectedEmployeeId = null;

            print('Department changed to: $value');
            print('Employee selection reset');
          });
        },
      ),
    );
  }

  Widget _buildEmployeeDropdown(List<Employee> employeesToShow, Size size, bool isEdit) {
    // Remove duplicate employees based on ID
    final uniqueEmployees = _removeDuplicates(employeesToShow);

    // Debug logging
    print('Employees to show count: ${employeesToShow.length}');
    print('Unique employees after deduplication: ${uniqueEmployees.length}');
    print('Selected department: $_selectedDepartment');
    print('Selected employee ID: $_selectedEmployeeId');

    // In edit mode, ensure current employee is in the list
    if (isEdit && widget.attendance != null && _selectedEmployeeId != null) {
      final currentEmployeeExists = uniqueEmployees.any((e) => e.id == _selectedEmployeeId);
      if (!currentEmployeeExists) {
        print('Adding current employee to dropdown list');
        // Add current employee from attendance record
        uniqueEmployees.insert(0, Employee(
          id: widget.attendance!.employeeId,
          name: widget.attendance!.employeeName,
          empId: widget.attendance!.empId,
          department: widget.attendance!.departmentName,
        ));
      }
    }

    // If no employees, show a better error message
    if (uniqueEmployees.isEmpty) {
      return Container(
        height: 100, // Fixed height
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.people,
              size: 28,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              'No employees available',
              style: TextStyle(
                fontSize: size.width > 600 ? 13 : 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              isEdit
                  ? 'Current employee not found'
                  : 'Select different department',
              style: TextStyle(
                fontSize: size.width > 600 ? 11 : 9,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    // Sort employees by name
    uniqueEmployees.sort((a, b) => a.name.compareTo(b.name));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedEmployeeId,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: 'Select Employee',
          hintText: 'Choose an employee',
          contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          labelStyle: TextStyle(
            fontSize: size.width > 600 ? 14 : 12,
          ),
        ),
        style: TextStyle(
          fontSize: size.width > 600 ? 14 : 12,
          color: Colors.black87,
        ),
        dropdownColor: Colors.blue.shade50,
        icon: const Icon(Iconsax.arrow_down_1, size: 18),
        items: uniqueEmployees.map((employee) {
          return DropdownMenuItem<int>(
            value: employee.id,
            child: SizedBox(
              height: 50, // Fixed height
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 49,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        employee.name.isNotEmpty ? employee.name.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(
                          color: const Color(0xFF667EEA),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 14 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 0),
                        // Text(
                        //   'ID: ${employee.empId} • ${employee.department ?? "No Department"}',
                        //   style: TextStyle(
                        //     fontSize: size.width > 600 ? 11 : 9,
                        //     color: Colors.grey[600],
                        //   ),
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedEmployeeId = value;
            print('Employee selected: $value');
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select an employee';
          }
          return null;
        },
      ),
    );
  }

  // Helper method to remove duplicates
  List<Employee> _removeDuplicates(List<Employee> employees) {
    final Map<int, Employee> uniqueEmployees = {};
    for (var employee in employees) {
      if (!uniqueEmployees.containsKey(employee.id) && employee.id != 0) {
        uniqueEmployees[employee.id] = employee;
      }
    }
    return uniqueEmployees.values.toList();
  }

  Widget _buildDutyShiftDropdown(List<DutyShift> dutyShifts, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedDutyShiftId,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: 'Duty Shift',
          hintText: dutyShifts.isEmpty ? 'No shifts found' : 'Select a shift',
          errorText: dutyShifts.isEmpty ? 'No duty shifts available' : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        items: dutyShifts.map((shift) {
          return DropdownMenuItem<int>(
            value: shift.id,
            child: SizedBox(
              height: 48, // Fixed height
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: size.width > 600 ? 36 : 28,
                        height: size.width > 600 ? 32 : 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(size.width > 600 ? 18 : 14),
                        ),
                        child: Icon(
                          Iconsax.clock,
                          size: size.width > 600 ? 18 : 14,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                      SizedBox(width: size.width > 600 ? 12 : 8),
                      Expanded(
                        child: Text(
                          shift.name,
                          style: TextStyle(
                            fontSize: size.width > 600 ? 14 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Padding(
                  //   padding: EdgeInsets.only(left: size.width > 600 ? 48 : 36),
                  //   child: Text(
                  //     '${shift.startTime} - ${shift.endTime}',
                  //     style: TextStyle(
                  //       fontSize: size.width > 600 ? 12 : 10,
                  //       color: Colors.grey[600],
                  //     ),
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: dutyShifts.isEmpty
            ? null
            : (value) {
          setState(() {
            _selectedDutyShiftId = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a duty shift';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(Size size) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Date',
        prefixIcon: const Icon(Iconsax.calendar),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      onTap: () => _selectDate(context),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required Size size,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Iconsax.clock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Iconsax.trash, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Attendance'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this attendance record for ${widget.attendance?.employeeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<AttendanceProvider>(context, listen: false);
              final success = await provider.deleteAttendance(widget.attendance!.id);
              if (success) {
                widget.onAttendanceSaved();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}