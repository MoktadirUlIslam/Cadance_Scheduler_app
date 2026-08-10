// lib/Components/drawer_widget.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:provider/provider.dart';

import '../core/data_provider.dart';
import '../providers/ThemeProvider.dart';
import '../providers/auth_provider.dart';
import '../screens/AboutScreen.dart';
import '../screens/starting_screen/login_screen.dart';
import '../screens/home/home_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dataProvider = context.watch<DataProvider>();
    final username = dataProvider.username ?? 'User';
    final email = dataProvider.email ?? '';

    return Drawer(
      backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.primaryDeep,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 25),
            // App Logo Header
            _buildAppLogoHeader(isDarkMode),
            const SizedBox(height: 20),

            // User Profile
            _buildUserProfile(username, email),
            const SizedBox(height: 26),

            // Dashboard
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () => _navigateToScreen(context, const HomeScreen()),
              isDarkMode: isDarkMode,
            ),

            // Dark Mode Toggle - Updated with dynamic text
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isDark = themeProvider.isDarkMode;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          size: 17,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isDark ? 'Light Mode' : 'Dark Mode', // Dynamic text
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: isDark,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeColor: Colors.white,
                            activeTrackColor: AppColors.primaryTint.withOpacity(0.5),
                            inactiveThumbColor: Colors.white.withOpacity(0.5),
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // System Details
            _buildDrawerItem(
              icon: Icons.info_outline,
              title: 'System Details',
              onTap: () => _navigateToScreen(context, const AboutScreen()),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 10),

            const Spacer(),

            // Logout
            GestureDetector(
              onTap: () => _handleLogout(context),
              child: _buildDrawerItem(
                icon: Icons.logout_outlined,
                title: 'Log out',
                onTap: () => _handleLogout(context),
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogoHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.3),
            AppColors.accentLight.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // App Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/logo/app_logo.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image doesn't exist
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      '⏱️',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pomodoro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Focus • Track • Achieve',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Version Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'v1.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(String username, String email) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.accentLight],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: Colors.white.withOpacity(0.5),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      email.isNotEmpty ? email : 'CSE · BAUST',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade400,
            size: 14,
          ),
        ),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AuthProvider>().signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}