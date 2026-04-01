import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../provider/short_leaves_provider/short_leaves_provider.dart';
import '../../provider/permissions_provider/permissions.dart';
import '../../provider/Auth_provider/Auth_provider.dart';
import '../../model/short_leave_model.dart';

class ShortLeavesScreen extends StatefulWidget {
  const ShortLeavesScreen({super.key});

  @override
  State<ShortLeavesScreen> createState() => _ShortLeavesScreenState();
}

class _ShortLeavesScreenState extends State<ShortLeavesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'all';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ShortLeavesProvider>().initializeUser();
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchData() {
    final provider = context.read<ShortLeavesProvider>();
    provider.fetchShortLeaves(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    _fetchData();
    setState(() => _isRefreshing = false);
  }

  void _deleteLeave(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.trash, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Short Leave'),
          ],
        ),
        content: const Text('Are you sure you want to delete this short leave entry? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ShortLeavesProvider>().deleteShortLeave(id).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Short leave deleted successfully'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<ShortLeavesProvider>().error), backgroundColor: Colors.red));
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShortLeavesProvider>();
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchFilterSection(isSmallScreen),
            if (provider.isAdmin)
              _buildStatisticsCards(provider, isSmallScreen),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF667EEA),
                    child: _buildList(provider, isSmallScreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_short_leave_fab',
        onPressed: () => _showShortLeaveDialog(null),
        backgroundColor: const Color(0xFF667EEA),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchFilterSection(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, date or type...',
              prefixIcon: const Icon(Iconsax.search_normal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'approved', child: Text('Approved')),
            DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedStatus = val);
              _fetchData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(ShortLeavesProvider provider, bool isSmallScreen) {
    final pending = provider.shortLeaves.where((l) => l.status.toLowerCase() == 'pending').length;
    final approved = provider.shortLeaves.where((l) => l.status.toLowerCase() == 'approved').length;
    final rejected = provider.shortLeaves.where((l) => l.status.toLowerCase() == 'rejected').length;

    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('Pending', pending, Colors.orange),
          const SizedBox(width: 8),
          _statCard('Approved', approved, Colors.green),
          const SizedBox(width: 8),
          _statCard('Rejected', rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ShortLeavesProvider provider, bool isSmallScreen) {
    if (provider.isLoading && !_isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = provider.shortLeaves.where((l) {
      final query = _searchController.text.toLowerCase();
      return (l.employeeName?.toLowerCase().contains(query) ?? false) ||
             (l.leaveDate?.toLowerCase().contains(query) ?? false) ||
             (l.leaveType.toLowerCase().contains(query));
    }).toList();

    if (list.isEmpty) {
      return const Center(child: Text('No short leaves found'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final leave = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Text(
              leave.employeeName ?? 'Unknown Employee',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(leave.leaveType, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    _buildStatusBadge(leave.status),
                  ],
                ),
                // const SizedBox(height: 4),
                // Text(leave.leaveDate ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isAdmin) ...[
                  IconButton(
                    icon: const Icon(Iconsax.edit, size: 20, color: Colors.blue),
                    onPressed: () => _showShortLeaveDialog(leave),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                    onPressed: () => _deleteLeave(leave.id),
                  ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Time: ${leave.fromTime} - ${leave.toTime}', style: const TextStyle(fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (leave.isPaid ?? true) ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (leave.isPaid ?? true) ? 'PAID' : 'UNPAID',
                            style: TextStyle(color: (leave.isPaid ?? true) ? Colors.blue : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Duration: ${leave.totalMinutes} mins', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Reason: ${leave.reason}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showShortLeaveDialog(ShortLeaveModel? leave) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShortLeaveDialog(leave: leave),
    );
  }
}

class ShortLeaveDialog extends StatefulWidget {
  final ShortLeaveModel? leave;
  const ShortLeaveDialog({super.key, this.leave});

  @override
  State<ShortLeaveDialog> createState() => _ShortLeaveDialogState();
}

class _ShortLeaveDialogState extends State<ShortLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;
  late String _leaveType;
  late String _reason;
  late String _status;
  late bool _isPaid;
  int? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.leave != null;
    
    if (isEdit) {
      _selectedDate = DateTime.tryParse(widget.leave!.leaveDate ?? '') ?? DateTime.now();
      _fromTime = _parseTime(widget.leave!.fromTime) ?? const TimeOfDay(hour: 9, minute: 0);
      _toTime = _parseTime(widget.leave!.toTime) ?? const TimeOfDay(hour: 10, minute: 0);
      _leaveType = widget.leave!.leaveType;
      _reason = widget.leave!.reason ?? '';
      _status = widget.leave!.status;
      _isPaid = widget.leave!.isPaid ?? true;
      _selectedEmployeeId = widget.leave!.employeeId;
      _selectedEmployeeName = widget.leave!.employeeName;
    } else {
      _selectedDate = DateTime.now();
      _fromTime = const TimeOfDay(hour: 9, minute: 0);
      _toTime = const TimeOfDay(hour: 10, minute: 0);
      _leaveType = '';
      _reason = '';
      _status = 'pending';
      _isPaid = true;
      
      final provider = context.read<ShortLeavesProvider>();
      final auth = context.read<AuthProvider>();

      if (!provider.isAdmin) {
        _selectedEmployeeName = auth.userData?['name'] ?? auth.userData?['username'] ?? 'You';
        _fetchCurrentEmployeeId(auth);
      } else {
        provider.fetchAllEmployees();
      }
    }
  }

  void _fetchCurrentEmployeeId(AuthProvider auth) async {
    final provider = context.read<ShortLeavesProvider>();
    
    // Prioritize the robustly-identified ID from the provider
    if (provider.currentEmployeeId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedEmployeeId = int.tryParse(provider.currentEmployeeId);
        });
      }
      return;
    }

    // Fallback to auth if provider doesn't have it yet
    final id = await auth.getEmployeeId();
    if (mounted) {
      setState(() {
        _selectedEmployeeId = int.tryParse(id);
      });
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  String _formatMinutes(int mins) {
    if (mins <= 0) return '—';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShortLeavesProvider>();
    final isEdit = widget.leave != null;
    final duration = (_toTime.hour * 60 + _toTime.minute) - (_fromTime.hour * 60 + _fromTime.minute);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.clock, color: Color(0xFF667EEA), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isEdit ? 'Edit Short Leave' : 'Add Short Leave', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isEdit ? 'Update leave details and status' : 'Record a new short leave entry', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Iconsax.close_circle, color: Colors.grey)),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSectionHeader('Employee & Date', Iconsax.user),
                      const SizedBox(height: 12),
                      if (provider.isAdmin && !isEdit) ...[
                        _buildEmployeeDropdown(provider),
                      ] else if (_selectedEmployeeName != null) ...[
                        _buildInfoTile('Selected Employee', _selectedEmployeeName!),
                      ],
                      const SizedBox(height: 12),
                      _buildDatePicker(),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('Time Range', Iconsax.timer),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTimePicker('From Time', _fromTime, (t) => setState(() => _fromTime = t))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimePicker('To Time', _toTime, (t) => setState(() => _toTime = t))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: duration > 0 ? const Color(0xFF667EEA).withOpacity(0.05) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: duration > 0 ? const Color(0xFF667EEA).withOpacity(0.1) : Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.clock, size: 18, color: duration > 0 ? const Color(0xFF667EEA) : Colors.grey),
                            const SizedBox(width: 10),
                            Text('Total Duration:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const Spacer(),
                            Text(_formatMinutes(duration), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (duration > 0) ...[
                              const SizedBox(width: 8),
                              Text('($duration mins)', style: const TextStyle(fontSize: 12, color: Color(0xFF667EEA))),
                            ],
                          ],
                        ),
                      ),
                      if (duration <= 0) 
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 4),
                          child: Align(alignment: Alignment.centerLeft, child: Text('⚠ "To time" must be later than "From time".', style: TextStyle(color: Colors.red, fontSize: 11))),
                        ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Details', Iconsax.document_text),
                      const SizedBox(height: 12),
                      _buildTextField('Leave Type', (val) => _leaveType = val ?? '', initialValue: _leaveType, hint: 'e.g. Personal, Medical'),
                      const SizedBox(height: 12),
                      _buildTextField('Reason (Optional)', (val) => _reason = val ?? '', initialValue: _reason, hint: 'Provide a reason...', maxLines: 2),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Pay & Status', Iconsax.card),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildPayToggle()),
                          if (provider.isAdmin) ...[
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatusSelector()),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (provider.isLoading || (!provider.isAdmin && _selectedEmployeeId == null)) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: (provider.isLoading || (!provider.isAdmin && _selectedEmployeeId == null))
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : Text(isEdit ? 'UPDATE' : 'SAVE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmployeeDropdown(ShortLeavesProvider provider) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select Employee',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      value: _selectedEmployeeId,
      items: provider.allEmployees.map((e) {
        return DropdownMenuItem<int>(value: e['id'], child: Text(e['name'], style: const TextStyle(fontSize: 14)));
      }).toList(),
      onChanged: (val) => setState(() => _selectedEmployeeId = val),
      validator: (val) => val == null ? 'Selection required' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar, size: 18, color: Color(0xFF667EEA)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leave Date', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Spacer(),
            const Icon(Iconsax.arrow_down_1, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onChanged(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved, {String? initialValue, String? hint, int maxLines = 1}) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      onSaved: onSaved,
      validator: (val) => label.contains('Type') && (val == null || val.trim().isEmpty) ? 'Required field' : null,
    );
  }

  Widget _buildPayToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pay Type', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPaid = true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isPaid ? const Color(0xFF667EEA) : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                    ),
                    alignment: Alignment.center,
                    child: Text('PAID', style: TextStyle(color: _isPaid ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPaid = false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_isPaid ? const Color(0xFF667EEA) : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                    ),
                    alignment: Alignment.center,
                    child: Text('UNPAID', style: TextStyle(color: !_isPaid ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          value: _status.toLowerCase(),
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'approved', child: Text('Approved')),
            DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
          ],
          onChanged: (val) => setState(() => _status = val!),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an employee')));
      return;
    }

    final fromMins = _fromTime.hour * 60 + _fromTime.minute;
    final toMins = _toTime.hour * 60 + _toTime.minute;
    final duration = toMins - fromMins;

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    final payload = {
      'employee_id': _selectedEmployeeId,
      'leave_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'from_time': '${_fromTime.hour.toString().padLeft(2, '0')}:${_fromTime.minute.toString().padLeft(2, '0')}:00',
      'to_time': '${_toTime.hour.toString().padLeft(2, '0')}:${_toTime.minute.toString().padLeft(2, '0')}:00',
      'total_minutes': duration,
      'leave_type': _leaveType,
      'reason': _reason,
      'is_paid': _isPaid ? 1 : 0,
      'status': _status.toLowerCase(),
    };

    final provider = context.read<ShortLeavesProvider>();
    final isEdit = widget.leave != null;
    
    final Future<bool> action = isEdit 
        ? provider.updateShortLeave(widget.leave!.id, payload)
        : provider.addShortLeave(payload);

    action.then((success) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(isEdit ? 'Short leave updated successfully' : 'Short leave added successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error), backgroundColor: Colors.red));
      }
    });
  }
}
