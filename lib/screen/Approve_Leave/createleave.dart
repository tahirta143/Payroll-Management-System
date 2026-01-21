// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../provider/leave_approve_provider/leave_approve.dart';
// import '../../model/leave_approve_model/leave_approve.dart';
// import 'ApproveLeaveScreen.dart';
//
// class CreateLeaveScreen extends StatefulWidget {
//   final ApproveLeave? leaveToEdit;
//   final VoidCallback? onLeaveUpdated;
//
//   const CreateLeaveScreen({
//     super.key,
//     this.leaveToEdit,
//     this.onLeaveUpdated,
//   });
//
//   @override
//   State<CreateLeaveScreen> createState() => _CreateLeaveScreenState();
// }
//
// class _CreateLeaveScreenState extends State<CreateLeaveScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _leaveTypes = [
//     'sick_leave',
//     'annual_leave',
//     'emergency_leave',
//     'casual_leave',
//     'maternity_leave',
//     'urgent_work',
//   ];
//
//   late String _natureOfLeave;
//   late DateTime _fromDate;
//   late DateTime _toDate;
//   late String _reason;
//   late int _days;
//
//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     _natureOfLeave = widget.leaveToEdit?.natureOfLeave ?? _leaveTypes.first;
//     _fromDate = widget.leaveToEdit?.fromDate ?? now;
//     _toDate = widget.leaveToEdit?.toDate ?? now.add(const Duration(days: 1));
//     _reason = widget.leaveToEdit?.reason ?? '';
//     _days = widget.leaveToEdit?.days ?? 1;
//     _calculateDays();
//   }
//
//   void _calculateDays() {
//     final difference = _toDate.difference(_fromDate).inDays;
//     _days = difference + 1; // Include both start and end dates
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<LeaveProvider>(context);
//     final isEdit = widget.leaveToEdit != null;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isEdit ? 'Edit Leave' : 'Apply for Leave'),
//         backgroundColor: const Color(0xFF667EEA),
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Leave Type
//               _buildLeaveTypeDropdown(),
//
//               const SizedBox(height: 20),
//
//               // Date Range
//               _buildDateRangePicker(),
//
//               const SizedBox(height: 20),
//
//               // Days Display
//               _buildDaysDisplay(),
//
//               const SizedBox(height: 20),
//
//               // Reason
//               _buildReasonField(),
//
//               const SizedBox(height: 30),
//
//               // Submit Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: provider.isLoading ? null : _submitForm,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF667EEA),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     provider.isLoading
//                         ? 'Processing...'
//                         : isEdit ? 'Update Leave' : 'Submit Leave Request',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLeaveTypeDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Leave Type',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey[300]!),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: DropdownButton<String>(
//             value: _natureOfLeave,
//             isExpanded: true,
//             underline: const SizedBox(),
//             items: _leaveTypes.map((type) {
//               return DropdownMenuItem<String>(
//                 value: type,
//                 child: Text(_formatLeaveType(type)),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 _natureOfLeave = value!;
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDateRangePicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Leave Dates',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: InkWell(
//                 onTap: () => _pickDate(true),
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey[300]!),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'From Date',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${_fromDate.year}-${_fromDate.month.toString().padLeft(2, '0')}-${_fromDate.day.toString().padLeft(2, '0')}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: InkWell(
//                 onTap: () => _pickDate(false),
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey[300]!),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'To Date',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${_toDate.year}-${_toDate.month.toString().padLeft(2, '0')}-${_toDate.day.toString().padLeft(2, '0')}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDaysDisplay() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF667EEA).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             'Total Days',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           Text(
//             '$_days ${_days == 1 ? 'Day' : 'Days'}',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF667EEA),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReasonField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Reason',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           initialValue: _reason,
//           maxLines: 4,
//           decoration: InputDecoration(
//             hintText: 'Enter reason for leave...',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Please enter a reason';
//             }
//             return null;
//           },
//           onSaved: (value) => _reason = value!.trim(),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickDate(bool isFromDate) async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: isFromDate ? _fromDate : _toDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//
//     if (pickedDate != null) {
//       setState(() {
//         if (isFromDate) {
//           _fromDate = pickedDate;
//           if (_toDate.isBefore(_fromDate)) {
//             _toDate = _fromDate.add(const Duration(days: 1));
//           }
//         } else {
//           _toDate = pickedDate;
//           if (_toDate.isBefore(_fromDate)) {
//             _fromDate = _toDate.subtract(const Duration(days: 1));
//           }
//         }
//         _calculateDays();
//       });
//     }
//   }
//
//   String _formatLeaveType(String type) {
//     final typeMap = {
//       'sick_leave': 'Sick Leave',
//       'annual_leave': 'Annual Leave',
//       'emergency_leave': 'Emergency Leave',
//       'maternity_leave': 'Maternity Leave',
//       'urgent_work': 'Urgent Work',
//       'casual_leave': 'Casual Leave',
//     };
//     return typeMap[type] ?? type.replaceAll('_', ' ').toTitleCase();
//   }
//
//   void _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//
//       final provider = Provider.of<LeaveProvider>(context, listen: false);
//       final leaveData = {
//         'nature_of_leave': _natureOfLeave,
//         'from_date': _fromDate.toIso8601String(),
//         'to_date': _toDate.toIso8601String(),
//         'days': _days,
//         'reason': _reason,
//       };
//
//       try {
//         if (widget.leaveToEdit != null) {
//           await provider.updateLeave(widget.leaveToEdit!.id, leaveData);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Leave updated successfully'),
//               backgroundColor: Color(0xFF4CAF50),
//             ),
//           );
//         } else {
//           await provider.createLeave(leaveData);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Leave request submitted successfully'),
//               backgroundColor: Color(0xFF4CAF50),
//             ),
//           );
//         }
//
//         if (widget.onLeaveUpdated != null) {
//           widget.onLeaveUpdated!();
//         }
//
//         Navigator.pop(context);
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
// }