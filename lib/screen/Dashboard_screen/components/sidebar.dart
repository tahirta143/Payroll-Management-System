// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../provider/permissions_provider/permissions.dart';
//
//
// class SidebarMenu extends StatelessWidget {
//   final int selectedIndex;
//   final Function(int) onMenuSelected;
//   final Function? onDrawerClose;
//
//   const SidebarMenu({
//     super.key,
//     required this.selectedIndex,
//     required this.onMenuSelected,
//     this.onDrawerClose,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final p = context.watch<PermissionProvider>();
//     final isDrawer = onDrawerClose != null;
//
//     final List<Map<String, dynamic>> menuItems = [
//       {'title': 'Dashboard', 'icon': Icons.dashboard, 'permission': 'can-view-dashboard'},
//       {'title': 'Approve Leave', 'icon': Icons.assignment_turned_in, 'permission': 'can-approve-leave'},
//       {'title': 'Staff Attendance', 'icon': Icons.fingerprint, 'permission': 'can-view-attendance'},
//       {'title': 'Salary', 'icon': Icons.account_balance_wallet, 'permission': 'can-view-salary'},
//       {'title': 'Attendance Report', 'icon': Icons.bar_chart, 'permission': 'can-view-reports'},
//       {'title': 'Leave Balance', 'icon': Icons.balance, 'permission': 'can-view-leave-balance'},
//       {'title': 'Logout', 'icon': Icons.logout, 'permission': 'can-logout'},
//     ];
//
//     Widget sidebarContent = Column(
//       children: [
//         // Logo
//         Container(
//           padding: const EdgeInsets.all(30),
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade200, width: 1),
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.blue.shade600, Colors.blue.shade800],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Admin Panel',
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
//               ),
//             ],
//           ),
//         ),
//
//         // Menu Items
//         Expanded(
//           child: ListView(
//             padding: const EdgeInsets.all(20),
//             children: [
//               ...menuItems.map((item) {
//                 if (!p.hasPermission(item['permission'])) return const SizedBox.shrink();
//
//                 return _buildMenuItem(
//                   title: item['title'],
//                   icon: item['icon'],
//                   isSelected: menuItems.indexOf(item) == selectedIndex,
//                   onTap: () => onMenuSelected(menuItems.indexOf(item)),
//                 );
//               }).toList(),
//             ],
//           ),
//         ),
//
//         // User Profile (only for sidebar, not drawer)
//         if (!isDrawer) _buildUserProfile(),
//       ],
//     );
//
//     // Return as Drawer or Sidebar
//     return isDrawer
//         ? Drawer(
//       width: 280,
//       backgroundColor: Colors.white,
//       child: Column(
//         children: [
//           // Drawer Header
//           Container(
//             padding: const EdgeInsets.all(30),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue.shade50, Colors.white],
//               ),
//               border: Border(
//                 bottom: BorderSide(color: Colors.grey.shade200, width: 1),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.blue.shade600, Colors.blue.shade800],
//                     ),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Icon(Icons.dashboard, color: Colors.white, size: 26),
//                 ),
//                 const SizedBox(width: 16),
//                 const Text(
//                   'Admin Panel',
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(child: sidebarContent),
//         ],
//       ),
//     )
//         : Container(
//       width: 280,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade300,
//             blurRadius: 10,
//             offset: const Offset(4, 0),
//           ),
//         ],
//       ),
//       child: sidebarContent,
//     );
//   }
//
//   Widget _buildMenuItem({
//     required String title,
//     required IconData icon,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.blue.shade50 : Colors.transparent,
//         borderRadius: BorderRadius.circular(12),
//         border: isSelected ? Border.all(color: Colors.blue.shade200, width: 1.5) : null,
//       ),
//       child: ListTile(
//         onTap: onTap,
//         leading: Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(
//             icon,
//             color: isSelected ? Colors.white : Colors.grey.shade700,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           title,
//           style: TextStyle(
//             fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//             color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
//             fontSize: 15,
//           ),
//         ),
//         trailing: isSelected
//             ? Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: Colors.blue.shade600,
//             shape: BoxShape.circle,
//           ),
//         )
//             : null,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }
//
//   Widget _buildUserProfile() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [Colors.blue.shade600, Colors.blue.shade800],
//               ),
//             ),
//             child: const Icon(Icons.person, color: Colors.white, size: 22),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Admin User',
//                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                 ),
//                 Text(
//                   'admin@company.com',
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.settings_outlined, color: Colors.grey.shade600),
//             onPressed: () {},
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../provider/permissions_provider/permissions.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final Function? onDrawerClose;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
    this.onDrawerClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PermissionProvider>();
    final isDrawer = onDrawerClose != null;

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Iconsax.home, 'permission': 'can-view-dashboard'},
      {'title': 'Approve Leave', 'icon': Iconsax.tick_circle, 'permission': 'can-approve-leave'},
      {'title': 'Staff Attendance', 'icon': Iconsax.finger_cricle, 'permission': 'can-view-attendance'},
      {'title': 'Salary', 'icon': Iconsax.wallet_money, 'permission': 'can-view-salary'},
      {'title': 'Attendance Report', 'icon': Iconsax.chart, 'permission': 'can-view-reports'},
      {'title': 'Leave Balance', 'icon': Iconsax.calendar_tick, 'permission': 'can-view-leave-balance'},
      {'title': 'Logout', 'icon': Iconsax.logout, 'permission': 'can-logout'},
    ];

    Widget sidebarContent = Container(
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
          // Logo Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.dcube,
                    color: Color(0xFF667EEA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HR Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Management Panel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  ...menuItems.map((item) {
                    if (!p.hasPermission(item['permission'])) return const SizedBox.shrink();

                    return _buildMenuItem(
                      title: item['title'],
                      icon: item['icon'],
                      isSelected: menuItems.indexOf(item) == selectedIndex,
                      onTap: () => onMenuSelected(menuItems.indexOf(item)),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // User Profile
          if (!isDrawer) _buildUserProfile(),
        ],
      ),
    );

    return isDrawer
        ? Drawer(
      width: 280,
      backgroundColor: Colors.white,
      elevation: 0,
      child: Container(
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
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.dcube,
                      color: Color(0xFF667EEA),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HR Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Management Panel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: sidebarContent),
          ],
        ),
      ),
    )
        : Container(
      width: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: sidebarContent,
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        )
            : null,
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFF667EEA) : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              gradient: const LinearGradient(
                colors: [Colors.white, Colors.white70],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Iconsax.profile_circle,
              color: Color(0xFF667EEA),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin User',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin@company.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: Icon(Iconsax.setting, color: Colors.white.withOpacity(0.9), size: 18),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}