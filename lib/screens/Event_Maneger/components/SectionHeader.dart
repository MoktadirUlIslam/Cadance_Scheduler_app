// lib/Components/section_header.dart
import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction; // Add this
  final bool isDarkMode;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction, // Add this
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.ink,
              fontFamily: 'Poppins',
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction, // Use this instead of just a static action
              child: Text(
                action!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accentLight,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }
}