import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class CustomChips extends StatelessWidget {
  final bool isDarkMode;

  const CustomChips({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            Icons.local_fire_department_outlined,
            '12-day streak',
            AppColors.warningLight,
          ),
          const SizedBox(width: 8),
          _buildChip(
            Icons.check_circle_outline,
            '50 sessions',
            AppColors.primaryLight,
          ),
          const SizedBox(width: 8),
          _buildChip(
            Icons.star_outline,
            'Early bird',
            AppColors.accentLight,
          ),
          const SizedBox(width: 8),
          _buildChip(
            Icons.calendar_month,
            '30h this month',
            AppColors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? AppColors.darkInk : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}