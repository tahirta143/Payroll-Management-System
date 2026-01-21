import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../provider/Auth_provider/Auth_provider.dart'; // Import your AuthProvider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables for switches
  bool _notificationsEnabled = true;
  bool _offlineModeEnabled = false;
  bool _biometricLoginEnabled = true;
  String _selectedTheme = 'System Default';
  String _selectedLanguage = 'English (US)';
  String _syncFrequency = 'Auto-sync every 15 minutes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
            // User Profile Card
            _buildUserProfileCard(context),

            // Settings Options List
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildSettingsList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final auth = context.read<AuthProvider>();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile ? _buildMobileProfile(auth) : _buildDesktopProfile(auth),
    );
  }

  Widget _buildMobileProfile(AuthProvider auth) {
    String userName = auth.userName.isNotEmpty ? auth.userName : 'User';
    String userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'user@company.com';
    String initials = _getInitials(userName);

    return Column(
      children: [
        // Profile Picture and Info
        Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  initials,
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
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildProfileStat('28', 'Employees'),
            _buildProfileStat('245', 'Attendance'),
            _buildProfileStat('24', 'Projects'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopProfile(AuthProvider auth) {
    String userName = auth.userName.isNotEmpty ? auth.userName : 'User';
    String userEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'user@company.com';
    String initials = _getInitials(userName);

    return Row(
      children: [
        // Profile Picture
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Profile Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Senior Administrator • $userEmail',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'HR Department',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Stats
        Row(
          children: [
            _buildProfileStat('28', 'Employees'),
            const SizedBox(width: 20),
            _buildProfileStat('245', 'Attendance'),
            const SizedBox(width: 20),
            _buildProfileStat('24', 'Projects'),
          ],
        ),

        const SizedBox(width: 20),

        // Edit Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              _showEditProfileDialog(context, auth);
            },
            icon: const Icon(
              Iconsax.edit_2,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.setting_2,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings & Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Settings Options
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Settings
              _buildSettingsSection(
                title: 'Account Settings',
                icon: Iconsax.profile_circle,
                items: [
                  _buildSettingsItem(
                    icon: Iconsax.user,
                    title: 'Personal Information',
                    subtitle: 'Update your personal details',
                    isMobile: isMobile,
                    onTap: () => _showPersonalInfoDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.shield_tick,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your account security',
                    isMobile: isMobile,
                    onTap: () => _showPrivacySecurityDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subtitle: 'Configure notification preferences',
                    isMobile: isMobile,
                    hasToggle: true,
                    toggleValue: _notificationsEnabled,
                    onToggleChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _showToast(context, 'Notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.language_square,
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    isMobile: isMobile,
                    onTap: () => _showLanguageDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // App Settings
              _buildSettingsSection(
                title: 'App Settings',
                icon: Iconsax.mobile,
                items: [
                  _buildSettingsItem(
                    icon: Iconsax.home,
                    title: 'Theme',
                    subtitle: _selectedTheme,
                    isMobile: isMobile,
                    onTap: () => _showThemeDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.cloud,
                    title: 'Data & Sync',
                    subtitle: _syncFrequency,
                    isMobile: isMobile,
                    onTap: () => _showSyncDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.cloud_lightning,
                    title: 'Offline Mode',
                    subtitle: 'Access data without internet',
                    isMobile: isMobile,
                    hasToggle: true,
                    toggleValue: _offlineModeEnabled,
                    onToggleChanged: (value) {
                      setState(() {
                        _offlineModeEnabled = value;
                      });
                      _showToast(context, 'Offline mode ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.finger_cricle,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face ID',
                    isMobile: isMobile,
                    hasToggle: true,
                    toggleValue: _biometricLoginEnabled,
                    onToggleChanged: (value) {
                      setState(() {
                        _biometricLoginEnabled = value;
                      });
                      _showToast(context, 'Biometric login ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Company Settings
              _buildSettingsSection(
                title: 'Company Settings',
                icon: Iconsax.building,
                items: [
                  _buildSettingsItem(
                    icon: Iconsax.people,
                    title: 'Departments',
                    subtitle: 'Manage company departments',
                    isMobile: isMobile,
                    onTap: () => _showDepartmentsDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.calendar,
                    title: 'Work Schedule',
                    subtitle: 'Set working hours and shifts',
                    isMobile: isMobile,
                    onTap: () => _showWorkScheduleDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.dollar_circle,
                    title: 'Payroll Settings',
                    subtitle: 'Configure salary and deductions',
                    isMobile: isMobile,
                    onTap: () => _showPayrollSettingsDialog(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.chart_2,
                    title: 'Reports & Analytics',
                    subtitle: 'Customize reporting preferences',
                    isMobile: isMobile,
                    onTap: () => _showReportsDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Support Section
              _buildSettingsSection(
                title: 'Support',
                icon: Iconsax.support,
                items: [
                  _buildSettingsItem(
                    icon: Iconsax.message_question,
                    title: 'Help Center',
                    subtitle: 'Get help and documentation',
                    isMobile: isMobile,
                    onTap: () => _showHelpCenter(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.message,
                    title: 'Contact Support',
                    subtitle: 'Get in touch with our team',
                    isMobile: isMobile,
                    onTap: () => _showContactSupport(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.document_text,
                    title: 'Terms & Policies',
                    subtitle: 'View terms and privacy policy',
                    isMobile: isMobile,
                    onTap: () => _showTermsPolicies(context),
                  ),
                  _buildSettingsItem(
                    icon: Iconsax.info_circle,
                    title: 'About App',
                    subtitle: 'Version 2.1.4 (Build 421)',
                    isMobile: isMobile,
                    onTap: () => _showAboutApp(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              isMobile ? _buildMobileLogoutButton(context) : _buildDesktopLogoutButton(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isMobile,
    VoidCallback? onTap,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: isMobile
          ? _buildMobileSettingsItem(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        hasToggle: hasToggle,
        toggleValue: toggleValue,
        onToggleChanged: onToggleChanged,
      )
          : _buildDesktopSettingsItem(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        hasToggle: hasToggle,
        toggleValue: toggleValue,
        onToggleChanged: onToggleChanged,
      ),
    );
  }

  Widget _buildMobileSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF667EEA)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (hasToggle)
              Switch(
                value: toggleValue,
                onChanged: onToggleChanged,
                activeColor: const Color(0xFF667EEA),
              )
            else
              IconButton(
                onPressed: onTap,
                icon: const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF667EEA)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (hasToggle)
          Switch(
            value: toggleValue,
            onChanged: onToggleChanged,
            activeColor: const Color(0xFF667EEA),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: onTap,
              child: Text(
                'Configure',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF667EEA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLogoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.logout,
              size: 20,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign out from your account',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(
              Iconsax.arrow_right_3,
              size: 20,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLogoutButton(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.logout,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Logout Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.red.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sign out from all devices',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 60,
          child: ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Iconsax.logout, size: 24),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  // Dialog Methods
  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: auth.userName),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: TextEditingController(text: auth.userEmail),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save changes logic
              Navigator.pop(context);
              _showToast(context, 'Profile updated successfully');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Iconsax.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667EEA),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
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
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF667EEA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Other dialog methods (you can implement these as needed)
  void _showPersonalInfoDialog(BuildContext context) {
    _showToast(context, 'Personal Information dialog');
  }

  void _showPrivacySecurityDialog(BuildContext context) {
    _showToast(context, 'Privacy & Security dialog');
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English (US)'),
              onTap: () {
                setState(() => _selectedLanguage = 'English (US)');
                Navigator.pop(context);
                _showToast(context, 'Language changed to English (US)');
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              onTap: () {
                setState(() => _selectedLanguage = 'Spanish');
                Navigator.pop(context);
                _showToast(context, 'Language changed to Spanish');
              },
            ),
            ListTile(
              title: const Text('French'),
              onTap: () {
                setState(() => _selectedLanguage = 'French');
                Navigator.pop(context);
                _showToast(context, 'Language changed to French');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              onTap: () {
                setState(() => _selectedTheme = 'System Default');
                Navigator.pop(context);
                _showToast(context, 'Theme set to System Default');
              },
            ),
            ListTile(
              title: const Text('Light'),
              onTap: () {
                setState(() => _selectedTheme = 'Light');
                Navigator.pop(context);
                _showToast(context, 'Theme set to Light');
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                setState(() => _selectedTheme = 'Dark');
                Navigator.pop(context);
                _showToast(context, 'Theme set to Dark');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Auto-sync every 15 minutes'),
              onTap: () {
                setState(() => _syncFrequency = 'Auto-sync every 15 minutes');
                Navigator.pop(context);
                _showToast(context, 'Sync frequency updated');
              },
            ),
            ListTile(
              title: const Text('Auto-sync every 30 minutes'),
              onTap: () {
                setState(() => _syncFrequency = 'Auto-sync every 30 minutes');
                Navigator.pop(context);
                _showToast(context, 'Sync frequency updated');
              },
            ),
            ListTile(
              title: const Text('Manual sync only'),
              onTap: () {
                setState(() => _syncFrequency = 'Manual sync only');
                Navigator.pop(context);
                _showToast(context, 'Sync frequency updated');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentsDialog(BuildContext context) {
    _showToast(context, 'Departments settings');
  }

  void _showWorkScheduleDialog(BuildContext context) {
    _showToast(context, 'Work Schedule settings');
  }

  void _showPayrollSettingsDialog(BuildContext context) {
    _showToast(context, 'Payroll Settings');
  }

  void _showReportsDialog(BuildContext context) {
    _showToast(context, 'Reports & Analytics');
  }

  void _showHelpCenter(BuildContext context) {
    _showToast(context, 'Opening Help Center');
  }

  void _showContactSupport(BuildContext context) {
    _showToast(context, 'Contacting Support');
  }

  void _showTermsPolicies(BuildContext context) {
    _showToast(context, 'Opening Terms & Policies');
  }

  void _showAboutApp(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'HR Management System',
      applicationVersion: 'Version 2.1.4 (Build 421)',
      applicationLegalese: '© 2024 Afaq MIS. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text('A comprehensive HR management solution for businesses.'),
        const SizedBox(height: 8),
        const Text('Features include:'),
        const SizedBox(height: 4),
        const Text('• Attendance tracking'),
        const Text('• Leave management'),
        const Text('• Salary processing'),
        const Text('• Employee management'),
      ],
    );
  }
}