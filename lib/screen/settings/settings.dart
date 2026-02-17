// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:iconsax_flutter/iconsax_flutter.dart';
// // import '../../provider/Auth_provider/Auth_provider.dart';
// //
// // class SettingsScreen extends StatefulWidget {
// //   const SettingsScreen({super.key});
// //
// //   @override
// //   State<SettingsScreen> createState() => _SettingsScreenState();
// // }
// //
// // class _SettingsScreenState extends State<SettingsScreen> {
// //   final TextEditingController _currentPasswordController = TextEditingController();
// //   final TextEditingController _newPasswordController = TextEditingController();
// //   final TextEditingController _confirmPasswordController = TextEditingController();
// //   final _formKey = GlobalKey<FormState>();
// //
// //   @override
// //   void dispose() {
// //     _currentPasswordController.dispose();
// //     _newPasswordController.dispose();
// //     _confirmPasswordController.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final auth = Provider.of<AuthProvider>(context);
// //
// //     // Get user information
// //     String userName = auth.userName.isNotEmpty ? auth.userName : 'User Name';
// //     String userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'user@example.com';
// //     String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
// //
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       // appBar: AppBar(
// //       //   title: const Text(
// //       //     'Profile',
// //       //     style: TextStyle(
// //       //       fontSize: 22,
// //       //       fontWeight: FontWeight.w700,
// //       //       color: Colors.white,
// //       //     ),
// //       //   ),
// //       //   centerTitle: true,
// //       //   backgroundColor: const Color(0xFF667EEA),
// //       //   iconTheme: const IconThemeData(color: Colors.white),
// //       //   elevation: 0,
// //       // ),
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //             colors: [
// //               Color(0xFF667EEA),
// //               Color(0xFF764BA2),
// //             ],
// //           ),
// //         ),
// //         child: SingleChildScrollView(
// //           child: Column(
// //             children: [
// //               // Profile Header Section
// //               Container(
// //                 padding: const EdgeInsets.all(30),
// //                 child: Column(
// //                   children: [
// //                     // Profile Circle with First Letter
// //                     Container(
// //                       width: 100,
// //                       height: 100,
// //                       decoration: BoxDecoration(
// //                         gradient: const LinearGradient(
// //                           colors: [
// //                             Color(0xFF667EEA),
// //                             Color(0xFF764BA2),
// //                           ],
// //                         ),
// //                         shape: BoxShape.circle,
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: Colors.black.withOpacity(0.2),
// //                             blurRadius: 15,
// //                             spreadRadius: 2,
// //                           ),
// //                         ],
// //                       ),
// //                       child: Center(
// //                         child: Text(
// //                           firstLetter,
// //                           style: const TextStyle(
// //                             color: Colors.white,
// //                             fontSize: 40,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20),
// //
// //                     // User Name
// //                     Text(
// //                       userName,
// //                       style: const TextStyle(
// //                         fontSize: 28,
// //                         fontWeight: FontWeight.w800,
// //                         color: Colors.white,
// //                       ),
// //                     ),
// //
// //                     const SizedBox(height: 8),
// //
// //                     // User Email
// //                     Text(
// //                       userEmail,
// //                       style: TextStyle(
// //                         fontSize: 16,
// //                         color: Colors.white.withOpacity(0.9),
// //                         fontWeight: FontWeight.w400,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //
// //               // Change Password Card
// //               Container(
// //                 margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //                 padding: const EdgeInsets.all(24),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(24),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black.withOpacity(0.1),
// //                       blurRadius: 20,
// //                       offset: const Offset(0, 8),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Form(
// //                   key: _formKey,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // Change Password Title
// //                       Row(
// //                         children: [
// //                           Icon(
// //                             Iconsax.lock_1,
// //                             size: 24,
// //                             color: const Color(0xFF667EEA),
// //                           ),
// //                           const SizedBox(width: 12),
// //                           const Text(
// //                             'Change Password',
// //                             style: TextStyle(
// //                               fontSize: 20,
// //                               fontWeight: FontWeight.w700,
// //                               color: Colors.black87,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 24),
// //
// //                       // Current Password Field
// //                       _buildPasswordField(
// //                         controller: _currentPasswordController,
// //                         label: 'Current Password',
// //                         hintText: 'Enter current password',
// //                         prefixIcon: Iconsax.lock,
// //                       ),
// //                       const SizedBox(height: 16),
// //
// //                       // New Password Field
// //                       _buildPasswordField(
// //                         controller: _newPasswordController,
// //                         label: 'New Password',
// //                         hintText: 'Enter new password',
// //                         prefixIcon: Iconsax.lock_1,
// //                       ),
// //                       const SizedBox(height: 16),
// //
// //                       // Confirm Password Field
// //                       _buildPasswordField(
// //                         controller: _confirmPasswordController,
// //                         label: 'Confirm Password',
// //                         hintText: 'Confirm new password',
// //                         prefixIcon: Iconsax.lock_circle,
// //                         validator: (value) {
// //                           if (value != _newPasswordController.text) {
// //                             return 'Passwords do not match';
// //                           }
// //                           return null;
// //                         },
// //                       ),
// //                       const SizedBox(height: 32),
// //
// //                       // Change Password Button
// //                       SizedBox(
// //                         width: double.infinity,
// //                         child: ElevatedButton(
// //                           onPressed: _changePassword,
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: const Color(0xFF667EEA),
// //                             foregroundColor: Colors.white,
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                           ),
// //                           child: const Row(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               Icon(Iconsax.key, size: 20),
// //                               SizedBox(width: 8),
// //                               Text(
// //                                 'Change Password',
// //                                 style: TextStyle(
// //                                   fontSize: 16,
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //
// //               // Logout Button
// //               Container(
// //                 margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //                 child: SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: () => _showLogoutDialog(context),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.red,
// //                       foregroundColor: Colors.white,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                     ),
// //                     child: const Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Icon(Iconsax.logout, size: 20),
// //                         SizedBox(width: 8),
// //                         Text(
// //                           'Logout',
// //                           style: TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.w600,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //
// //               const SizedBox(height: 30),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildPasswordField({
// //     required TextEditingController controller,
// //     required String label,
// //     required String hintText,
// //     required IconData prefixIcon,
// //     String? Function(String?)? validator,
// //   }) {
// //     bool isObscure = true;
// //
// //     return StatefulBuilder(
// //       builder: (context, setState) {
// //         return Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               label,
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Colors.grey[700],
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //             const SizedBox(height: 6),
// //             Container(
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[50],
// //                 borderRadius: BorderRadius.circular(10),
// //                 border: Border.all(color: Colors.grey[300]!),
// //               ),
// //               child: TextFormField(
// //                 controller: controller,
// //                 obscureText: isObscure,
// //                 validator: validator,
// //                 decoration: InputDecoration(
// //                   hintText: hintText,
// //                   hintStyle: TextStyle(color: Colors.grey[500]),
// //                   prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF667EEA)),
// //                   suffixIcon: IconButton(
// //                     icon: Icon(
// //                       isObscure ? Iconsax.eye : Iconsax.eye_slash,
// //                       size: 18,
// //                       color: Colors.grey[500],
// //                     ),
// //                     onPressed: () {
// //                       setState(() {
// //                         isObscure = !isObscure;
// //                       });
// //                     },
// //                   ),
// //                   border: InputBorder.none,
// //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   void _changePassword() {
// //     if (_formKey.currentState!.validate()) {
// //       // Show loading
// //       showDialog(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (context) => const Center(
// //           child: CircularProgressIndicator(
// //             color: Color(0xFF667EEA),
// //           ),
// //         ),
// //       );
// //
// //       // Simulate API call
// //       Future.delayed(const Duration(seconds: 2), () {
// //         Navigator.of(context, rootNavigator: true).pop();
// //
// //         // Clear fields
// //         _currentPasswordController.clear();
// //         _newPasswordController.clear();
// //         _confirmPasswordController.clear();
// //
// //         // Show success message
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: const Text('Password changed successfully!'),
// //             backgroundColor: Colors.green,
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //           ),
// //         );
// //       });
// //     }
// //   }
// //
// //   void _showLogoutDialog(BuildContext context) {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext dialogContext) {
// //         return Dialog(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           child: Container(
// //             padding: const EdgeInsets.all(24),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 // Warning Icon
// //                 Container(
// //                   width: 60,
// //                   height: 60,
// //                   decoration: BoxDecoration(
// //                     color: Colors.red.withOpacity(0.1),
// //                     shape: BoxShape.circle,
// //                   ),
// //                   child: const Center(
// //                     child: Icon(
// //                       Iconsax.logout,
// //                       size: 30,
// //                       color: Colors.red,
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //
// //                 // Title
// //                 const Text(
// //                   'Logout?',
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.w700,
// //                     color: Colors.black87,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //
// //                 // Message
// //                 const Text(
// //                   'Are you sure you want to logout?',
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     fontSize: 14,
// //                     color: Colors.grey,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 24),
// //
// //                 // Buttons
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: OutlinedButton(
// //                         onPressed: () => Navigator.of(dialogContext).pop(),
// //                         style: OutlinedButton.styleFrom(
// //                           foregroundColor: Colors.grey[700],
// //                           side: BorderSide(color: Colors.grey[300]!),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           padding: const EdgeInsets.symmetric(vertical: 12),
// //                         ),
// //                         child: const Text('Cancel'),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 12),
// //                     Expanded(
// //                       child: ElevatedButton(
// //                         onPressed: () async {
// //                           final auth = Provider.of<AuthProvider>(context, listen: false);
// //                           Navigator.of(dialogContext).pop();
// //
// //                           // Show loading indicator
// //                           showDialog(
// //                             context: context,
// //                             barrierDismissible: false,
// //                             builder: (context) => const Center(
// //                               child: CircularProgressIndicator(
// //                                 color: Color(0xFF667EEA),
// //                               ),
// //                             ),
// //                           );
// //
// //                           // Perform logout
// //                           await auth.logout();
// //
// //                           // Navigate to login screen
// //                           Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
// //                             '/login',
// //                                 (route) => false,
// //                           );
// //                         },
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.red,
// //                           foregroundColor: Colors.white,
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           padding: const EdgeInsets.symmetric(vertical: 12),
// //                         ),
// //                         child: const Text('Logout'),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:iconsax_flutter/iconsax_flutter.dart';
// import '../../provider/Auth_provider/Auth_provider.dart';
//
// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});
//
//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends State<SettingsScreen> {
//   final TextEditingController _currentPasswordController = TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   void dispose() {
//     _currentPasswordController.dispose();
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider>(context);
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 600;
//
//     // Get user information
//     String userName = auth.userName.isNotEmpty ? auth.userName : 'User Name';
//     String userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'user@example.com';
//     String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFF), // Light background like attendance screen
//       // No app bar
//       body: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: SystemUiOverlayStyle.dark.copyWith(
//           statusBarColor: Colors.transparent,
//           statusBarIconBrightness: Brightness.dark,
//         ),
//
//         child: Container(
//           padding: EdgeInsets.only(top: 20),
//           decoration: const BoxDecoration(
//             color: Color(0xFFF8FAFF), // Match scaffold background
//           ),
//           child: Column(
//             children: [
//               // Add some top padding to account for status bar
//               // SizedBox(height: MediaQuery.of(context).padding.top + 8),
//
//               // Custom Header with Menu Icon (like attendance screen)
//               // Padding(
//               //   padding: EdgeInsets.symmetric(
//               //     horizontal: isSmallScreen ? 16 : 20,
//               //   ),
//               //   child: Row(
//               //     children: [
//               //       // Menu/Drawer icon to open drawer
//               //       Builder(
//               //         builder: (context) {
//               //           return Container(
//               //             decoration: BoxDecoration(
//               //               color: Colors.white,
//               //               borderRadius: BorderRadius.circular(12),
//               //               boxShadow: [
//               //                 BoxShadow(
//               //                   color: Colors.black.withOpacity(0.05),
//               //                   blurRadius: 8,
//               //                   offset: const Offset(0, 2),
//               //                 ),
//               //               ],
//               //             ),
//               //             child: IconButton(
//               //               icon: const Icon(Iconsax.menu_1, color: Color(0xFF667EEA)),
//               //               onPressed: () {
//               //                 Scaffold.of(context).openDrawer();
//               //               },
//               //             ),
//               //           );
//               //         },
//               //       ),
//               //       const SizedBox(width: 12),
//               //       Text(
//               //         'Profile',
//               //         style: TextStyle(
//               //           fontSize: isSmallScreen ? 20 : 24,
//               //           fontWeight: FontWeight.bold,
//               //           color: const Color(0xFF667EEA),
//               //         ),
//               //       ),
//               //       const Spacer(),
//               //       // Empty container for symmetry (like attendance screen has refresh)
//               //       Container(
//               //         width: 40,
//               //         height: 40,
//               //       ),
//               //     ],
//               //   ),
//               // ),
//
//               // const SizedBox(height: 16),
//
//               // Scrollable Content
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // Profile Header Card
//                       Container(
//                         margin: EdgeInsets.symmetric(
//                           horizontal: isSmallScreen ? 12 : 16,
//                         ),
//                         padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               Color(0xFF667EEA),
//                               Color(0xFF764BA2),
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF667EEA).withOpacity(0.3),
//                               blurRadius: 15,
//                               offset: const Offset(0, 8),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           children: [
//                             // Profile Circle with First Letter
//                             Container(
//                               width: 100,
//                               height: 100,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.2),
//                                     blurRadius: 15,
//                                     spreadRadius: 2,
//                                   ),
//                                 ],
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   firstLetter,
//                                   style: const TextStyle(
//                                     color: Color(0xFF667EEA),
//                                     fontSize: 40,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//
//                             // User Name
//                             Text(
//                               userName,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.w800,
//                                 color: Colors.white,
//                               ),
//                             ),
//
//                             const SizedBox(height: 8),
//
//                             // User Email
//                             Text(
//                               userEmail,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//
//                             const SizedBox(height: 12),
//
//                             // Role Badge
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                   color: Colors.white.withOpacity(0.3),
//                                 ),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(
//                                     auth.isAdmin ? Iconsax.shield_tick : Iconsax.user,
//                                     size: 14,
//                                     color: Colors.white,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     auth.isAdmin ? 'Administrator' : 'Staff Member',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       // Change Password Card
//                       Container(
//                         margin: EdgeInsets.symmetric(
//                           horizontal: isSmallScreen ? 12 : 16,
//                         ),
//                         padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Form(
//                           key: _formKey,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Change Password Title
//                               Row(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(8),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFF667EEA).withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     child: const Icon(
//                                       Iconsax.lock_1,
//                                       size: 20,
//                                       color: Color(0xFF667EEA),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   const Text(
//                                     'Change Password',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//
//                               // Current Password Field
//                               _buildPasswordField(
//                                 controller: _currentPasswordController,
//                                 label: 'Current Password',
//                                 hintText: 'Enter current password',
//                                 prefixIcon: Iconsax.lock,
//                                 isSmallScreen: isSmallScreen,
//                               ),
//                               const SizedBox(height: 16),
//
//                               // New Password Field
//                               _buildPasswordField(
//                                 controller: _newPasswordController,
//                                 label: 'New Password',
//                                 hintText: 'Enter new password',
//                                 prefixIcon: Iconsax.lock_1,
//                                 isSmallScreen: isSmallScreen,
//                               ),
//                               const SizedBox(height: 16),
//
//                               // Confirm Password Field
//                               _buildPasswordField(
//                                 controller: _confirmPasswordController,
//                                 label: 'Confirm Password',
//                                 hintText: 'Confirm new password',
//                                 prefixIcon: Iconsax.lock_circle,
//                                 validator: (value) {
//                                   if (value != _newPasswordController.text) {
//                                     return 'Passwords do not match';
//                                   }
//                                   return null;
//                                 },
//                                 isSmallScreen: isSmallScreen,
//                               ),
//                               const SizedBox(height: 24),
//
//                               // Change Password Button
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   onPressed: _changePassword,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF667EEA),
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     padding: EdgeInsets.symmetric(
//                                       vertical: isSmallScreen ? 14 : 16,
//                                     ),
//                                   ),
//                                   child: const Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Iconsax.key, size: 18),
//                                       SizedBox(width: 8),
//                                       Text(
//                                         'Change Password',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       // Account Information Card
//                       // Container(
//                       //   margin: EdgeInsets.symmetric(
//                       //     horizontal: isSmallScreen ? 12 : 16,
//                       //   ),
//                       //   padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//                       //   decoration: BoxDecoration(
//                       //     color: Colors.white,
//                       //     borderRadius: BorderRadius.circular(20),
//                       //     boxShadow: [
//                       //       BoxShadow(
//                       //         color: Colors.black.withOpacity(0.05),
//                       //         blurRadius: 10,
//                       //         offset: const Offset(0, 4),
//                       //       ),
//                       //     ],
//                       //   ),
//                       //   child: Column(
//                       //     crossAxisAlignment: CrossAxisAlignment.start,
//                       //     children: [
//                       //       // Account Info Title
//                       //       Row(
//                       //         children: [
//                       //           Container(
//                       //             padding: const EdgeInsets.all(8),
//                       //             decoration: BoxDecoration(
//                       //               color: const Color(0xFF667EEA).withOpacity(0.1),
//                       //               borderRadius: BorderRadius.circular(10),
//                       //             ),
//                       //             child: const Icon(
//                       //               Iconsax.profile_2user,
//                       //               size: 20,
//                       //               color: Color(0xFF667EEA),
//                       //             ),
//                       //           ),
//                       //           const SizedBox(width: 12),
//                       //           const Text(
//                       //             'Account Information',
//                       //             style: TextStyle(
//                       //               fontSize: 18,
//                       //               fontWeight: FontWeight.w700,
//                       //               color: Colors.black87,
//                       //             ),
//                       //           ),
//                       //         ],
//                       //       ),
//                       //       const SizedBox(height: 20),
//                       //
//                       //       // Employee ID
//                       //       _buildInfoRow(
//                       //         icon: Iconsax.card,
//                       //         label: 'Employee ID',
//                       //         value: auth.employeeId.isNotEmpty ? auth.employeeId : 'Not Available',
//                       //         isSmallScreen: isSmallScreen,
//                       //       ),
//                       //       const SizedBox(height: 16),
//                       //
//                       //       // Department
//                       //       _buildInfoRow(
//                       //         icon: Iconsax.building,
//                       //         label: 'Department',
//                       //         value: auth.department.isNotEmpty ? auth.department : 'Not Assigned',
//                       //         isSmallScreen: isSmallScreen,
//                       //       ),
//                       //       const SizedBox(height: 16),
//                       //
//                       //       // Join Date
//                       //       _buildInfoRow(
//                       //         icon: Iconsax.calendar_1,
//                       //         label: 'Join Date',
//                       //         value: auth.joinDate.isNotEmpty ? auth.joinDate : 'Not Available',
//                       //         isSmallScreen: isSmallScreen,
//                       //       ),
//                       //       const SizedBox(height: 16),
//                       //
//                       //       // Phone Number
//                       //       _buildInfoRow(
//                       //         icon: Iconsax.call,
//                       //         label: 'Phone',
//                       //         value: auth.phoneNumber.isNotEmpty ? auth.phoneNumber : 'Not Available',
//                       //         isSmallScreen: isSmallScreen,
//                       //       ),
//                       //     ],
//                       //   ),
//                       // ),
//
//                       const SizedBox(height: 16),
//
//                       // Logout Button
//                       Container(
//                         margin: EdgeInsets.symmetric(
//                           horizontal: isSmallScreen ? 12 : 16,
//                           vertical: 10,
//                         ),
//                         child: SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () => _showLogoutDialog(context),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               padding: EdgeInsets.symmetric(
//                                 vertical: isSmallScreen ? 14 : 16,
//                               ),
//                             ),
//                             child: const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Iconsax.logout, size: 18),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'Logout',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//                     ],
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
//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     required bool isSmallScreen,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: const Color(0xFF667EEA).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             size: 18,
//             color: const Color(0xFF667EEA),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 11 : 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 13 : 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPasswordField({
//     required TextEditingController controller,
//     required String label,
//     required String hintText,
//     required IconData prefixIcon,
//     required bool isSmallScreen,
//     String? Function(String?)? validator,
//   }) {
//     bool isObscure = true;
//
//     return StatefulBuilder(
//       builder: (context, setState) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: isSmallScreen ? 13 : 14,
//                 color: Colors.grey[700],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: TextFormField(
//                 controller: controller,
//                 obscureText: isObscure,
//                 validator: validator,
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 14 : 15,
//                 ),
//                 decoration: InputDecoration(
//                   hintText: hintText,
//                   hintStyle: TextStyle(
//                     fontSize: isSmallScreen ? 13 : 14,
//                     color: Colors.grey[500],
//                   ),
//                   prefixIcon: Icon(
//                     prefixIcon,
//                     size: isSmallScreen ? 18 : 20,
//                     color: const Color(0xFF667EEA),
//                   ),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       isObscure ? Iconsax.eye : Iconsax.eye_slash,
//                       size: isSmallScreen ? 16 : 18,
//                       color: Colors.grey[500],
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         isObscure = !isObscure;
//                       });
//                     },
//                   ),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: isSmallScreen ? 14 : 16,
//                     vertical: isSmallScreen ? 12 : 14,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _changePassword() {
//     if (_formKey.currentState!.validate()) {
//       // Show loading
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFF667EEA),
//           ),
//         ),
//       );
//
//       // Simulate API call
//       Future.delayed(const Duration(seconds: 2), () {
//         Navigator.of(context, rootNavigator: true).pop();
//
//         // Clear fields
//         _currentPasswordController.clear();
//         _newPasswordController.clear();
//         _confirmPasswordController.clear();
//
//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Password changed successfully!'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       });
//     }
//   }
//
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Warning Icon
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Center(
//                     child: Icon(
//                       Iconsax.logout,
//                       size: 30,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Title
//                 const Text(
//                   'Logout?',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//
//                 // Message
//                 const Text(
//                   'Are you sure you want to logout?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//
//                 // Buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.of(dialogContext).pop(),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.grey[700],
//                           side: BorderSide(color: Colors.grey[300]!),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Cancel'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () async {
//                           final auth = Provider.of<AuthProvider>(context, listen: false);
//                           Navigator.of(dialogContext).pop();
//
//                           // Show loading indicator
//                           showDialog(
//                             context: context,
//                             barrierDismissible: false,
//                             builder: (context) => const Center(
//                               child: CircularProgressIndicator(
//                                 color: Color(0xFF667EEA),
//                               ),
//                             ),
//                           );
//
//                           // Perform logout
//                           await auth.logout();
//
//                           // Navigate to login screen
//                           Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
//                             '/login',
//                                 (route) => false,
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Logout'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../model/settings/settings-model.dart';
import '../../provider/Auth_provider/Auth_provider.dart';
import '../../provider/settings/settings-provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load settings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<AttendanceSettingsProvider>(context, listen: false);
      settingsProvider.fetchAttendanceSettings(context: context);
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<AttendanceSettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Get user information
    String userName = auth.userName.isNotEmpty ? auth.userName : 'User Name';
    String userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'user@example.com';
    String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Container(
          padding: EdgeInsets.only(top: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header Card
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Circle with First Letter
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    color: Color(0xFF667EEA),
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // User Name
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // User Email
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    auth.isAdmin ? Iconsax.shield_tick : Iconsax.user,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    auth.isAdmin ? 'Administrator' : 'Staff Member',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Attendance Settings Card (Admin only)
                      if (auth.isAdmin) ...[
                        _buildAttendanceSettingsCard(settingsProvider, isSmallScreen),
                        const SizedBox(height: 16),
                      ],

                      // Change Password Card
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Change Password Title
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF667EEA).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Iconsax.lock_1,
                                      size: 20,
                                      color: Color(0xFF667EEA),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Current Password Field
                              _buildPasswordField(
                                controller: _currentPasswordController,
                                label: 'Current Password',
                                hintText: 'Enter current password',
                                prefixIcon: Iconsax.lock,
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 16),

                              // New Password Field
                              _buildPasswordField(
                                controller: _newPasswordController,
                                label: 'New Password',
                                hintText: 'Enter new password',
                                prefixIcon: Iconsax.lock_1,
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password Field
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hintText: 'Confirm new password',
                                prefixIcon: Iconsax.lock_circle,
                                validator: (value) {
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                isSmallScreen: isSmallScreen,
                              ),
                              const SizedBox(height: 24),

                              // Change Password Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667EEA),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Iconsax.key, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Change Password',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logout Button
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: 10,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showLogoutDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.logout, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Attendance Settings Card
  Widget _buildAttendanceSettingsCard(AttendanceSettingsProvider provider, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.setting_2,
                      size: 20,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Attendance Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (provider.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF667EEA),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF667EEA)),
                  onPressed: () => provider.refreshSettings(context: context),
                  tooltip: 'Refresh Settings',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading or Error or Data
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF667EEA)),
              ),
            )
          else if (provider.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.refreshSettings(context: context),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else if (provider.hasData)
              _buildSettingsContent(provider.settings!, isSmallScreen)
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No settings data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // Settings Content
  Widget _buildSettingsContent(AttendanceSettings settings, bool isSmallScreen) {
    return Column(
      children: [
        // Max Late Time
        _buildSettingRow(
          icon: Iconsax.clock,
          label: 'Max Late Time',
          value: settings.formattedMaxLateTime,
        ),
        const Divider(height: 24),

        // Deductions
        _buildSettingRow(
          icon: Iconsax.money_remove,
          label: 'Half Day Deduction',
          value: '${settings.halfDayDeductionPercent}%',
        ),
        const Divider(height: 24),

        _buildSettingRow(
          icon: Iconsax.money_remove,
          label: 'Full Day Deduction',
          value: '${settings.fullDayDeductionPercent}%',
        ),
        const Divider(height: 24),

        // Overtime
        _buildSettingRow(
          icon: Iconsax.timer_start,
          label: 'Overtime Starts After',
          value: settings.formattedOvertimeStart,
        ),
        const Divider(height: 24),

        _buildSettingRow(
          icon: Iconsax.money_add,
          label: 'Overtime Rate',
          value: '${settings.overtimeRate}/hr',
        ),
        const Divider(height: 24),

        // Last Updated
        Row(
          children: [
            Icon(Iconsax.calendar_1, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Last Updated: ${settings.formattedUpdatedAt}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF667EEA)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required bool isSmallScreen,
    String? Function(String?)? validator,
  }) {
    bool isObscure = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: isObscure,
                validator: validator,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    prefixIcon,
                    size: isSmallScreen ? 18 : 20,
                    color: const Color(0xFF667EEA),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscure ? Iconsax.eye : Iconsax.eye_slash,
                      size: isSmallScreen ? 16 : 18,
                      color: Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        isObscure = !isObscure;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 14 : 16,
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF667EEA),
          ),
        ),
      );

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context, rootNavigator: true).pop();

        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.logout,
                      size: 30,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Logout?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                const Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          Navigator.of(dialogContext).pop();

                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF667EEA),
                              ),
                            ),
                          );

                          // Perform logout
                          await auth.logout();

                          // Navigate to login screen
                          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                            '/login',
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}