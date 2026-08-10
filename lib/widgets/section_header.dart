// lib/Components/section_header.dart
import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool isDarkMode;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.darkInk : AppColors.ink,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}