import 'package:flutter/material.dart';
import '../../../core/data_provider.dart';
import '../../../utilites/app_colors.dart';

class UserDetailsSection extends StatelessWidget {
  final DataProvider dataProvider;
  final bool isDarkMode;

  const UserDetailsSection({
    super.key,
    required this.dataProvider,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final profile = dataProvider.profile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
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
              Icon(Icons.person_outline, size: 20, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Mobile', profile.mobile ?? 'Not set'),
          _buildDivider(),
          _buildDetailRow('Age', profile.age?.toString() ?? 'Not set'),
          _buildDivider(),
          _buildDetailRow('Gender', profile.gender ?? 'Not set'),
          _buildDivider(),
          _buildDetailRow('Occupation', profile.occupation ?? 'Not set'),
          _buildDivider(),
          _buildDetailRow('Address', profile.address ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
          ),
          Text(
            ':',
            style: TextStyle(
              color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkInk : AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDarkMode ? AppColors.darkBorder : AppColors.border,
    );
  }
}