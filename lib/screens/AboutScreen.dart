// lib/screens/about/about_screen.dart

import 'package:flutter/material.dart';
import '../../utilites/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? AppColors.darkInk : AppColors.ink,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'System Details',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkInk : AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App Logo
            _buildAppLogo(isDarkMode),
            const SizedBox(height: 20),

            // App Name
            _buildAppTitle(isDarkMode),
            const SizedBox(height: 32),

            // Developer Info
            _buildDeveloperCard(isDarkMode),
            const SizedBox(height: 16),

            // App Info
            _buildAppInfoCard(isDarkMode),
            const SizedBox(height: 16),

            // Footer
            _buildFooter(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(bool isDarkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.accentLight,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            'assets/logo/app_logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image doesn't exist
              return const Center(
                child: Text(
                  '⏱️',
                  style: TextStyle(fontSize: 44),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppTitle(bool isDarkMode) {
    return Column(
      children: [
        Text(
          'Pomodoro Timer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkInk : AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: AppColors.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Developer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline_rounded, 'Name', 'Moktadir Ul Islam', isDarkMode),
          _buildInfoRow(Icons.email_outlined, 'Email', 'mahinmoktadir6991@gmail.com', isDarkMode),
          _buildInfoRow(Icons.phone_outlined, 'Phone', '+8801768-784686', isDarkMode),
          _buildInfoRow(Icons.location_on_outlined, 'Location', 'Alamdanga, Chuadanga', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkInk : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: AppColors.accentLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About This App',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A focused productivity app using the Pomodoro technique to help you manage time effectively. Track your progress, earn achievements, and stay productive.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag('Focus Timer', isDarkMode),
              _buildTag('Task Manager', isDarkMode),
              _buildTag('Calander', isDarkMode),
              _buildTag('Dark Mode', isDarkMode),
              _buildTag('Activity Tracking', isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkBorder : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 Perficient',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Made with ',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
            const Text(
              '❤️',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              ' in Bangladesh',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Built with ',
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
            const Icon(
              Icons.flutter_dash,
              color: Colors.blue,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Flutter',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}