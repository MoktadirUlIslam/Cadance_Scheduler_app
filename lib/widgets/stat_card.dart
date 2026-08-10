// lib/widgets/stat_card.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String? sublabel;
  final bool isDarkMode;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.sublabel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkInk : AppColors.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            ),
          ),
          if (sublabel != null)
            Text(
              sublabel!,
              style: TextStyle(
                fontSize: 7,
                color: isDarkMode
                    ? AppColors.darkInkSoft.withOpacity(0.7)
                    : AppColors.inkSoft.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}