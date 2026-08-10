// lib/screens/Profile/profilescreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data_provider.dart';
import '../../models/profile_model.dart';
import '../../utilites/app_colors.dart';
import 'components/BadgeSection.dart';
import 'components/activity_stats.dart';
import 'components/edit_profile_dialog.dart';
import 'components/profile_header.dart';
import 'components/user_details_section.dart';
import 'components/edit_button.dart';
import 'components/delete_account_button.dart';


class Profilescreen extends StatefulWidget {
  const Profilescreen({super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<DataProvider>();
      dataProvider.refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final profile = dataProvider.profile;

    final bool hasNoData = _isProfileEmpty(profile);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProfileHeader(dataProvider: dataProvider, isDarkMode: isDarkMode),
              const SizedBox(height: 24),

              UserDetailsSection(
                dataProvider: dataProvider,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),


              // Add EditButton here
              EditButton(
                onPressed: () => _showEditDialog(context, dataProvider),
                isDarkMode: isDarkMode,
                label: 'Edit Profile',
              ),
              const SizedBox(height: 16),

              // Contribution Graph
              ContributionGraph(
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),

              // Badge Section
              BadgeSection(
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),



              DeleteAccountButton(
                isDarkMode: isDarkMode,
                onDeleteSuccess: _handleAccountDeletion,
              ),

              const SizedBox(height: 16),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  bool _isProfileEmpty(ProfileModel profile) {
    final bool mobileEmpty = profile.mobile == null ||
        profile.mobile == 'Not set' ||
        profile.mobile!.isEmpty;

    final bool ageEmpty = profile.age == null;

    final bool genderEmpty = profile.gender == null ||
        profile.gender == 'Not set' ||
        profile.gender!.isEmpty;

    final bool occupationEmpty = profile.occupation == null ||
        profile.occupation == 'Not set' ||
        profile.occupation!.isEmpty;

    final bool addressEmpty = profile.address == null ||
        profile.address == 'Not set' ||
        profile.address!.isEmpty;

    return mobileEmpty && ageEmpty && genderEmpty && occupationEmpty && addressEmpty;
  }

  Widget _buildEmptyStateMessage(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.1),
            AppColors.accentLight.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_alt_1,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your personal details to get started',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(dataProvider: dataProvider),
    );
  }

  void _handleAccountDeletion() {
    final dataProvider = context.read<DataProvider>();
    dataProvider.reset();
    Navigator.pushReplacementNamed(context, '/login');
  }
}