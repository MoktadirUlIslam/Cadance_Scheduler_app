// lib/screens/Profile/components/edit_button.dart

import 'package:flutter/material.dart';
import '../../../utilites/app_colors.dart';

class EditButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;
  final String label; // Add this

  const EditButton({
    super.key,
    required this.onPressed,
    required this.isDarkMode,
    this.label = 'Edit Profile', // Default value
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(label), // Use custom label
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}