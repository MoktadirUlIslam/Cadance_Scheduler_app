// lib/screens/Profile/components/delete_account_button.dart

import 'package:flutter/material.dart';
import '../../../utilites/app_colors.dart';
import 'DeleteAccountDialog.dart';

class DeleteAccountButton extends StatelessWidget {
  final VoidCallback? onDeleteSuccess;
  final bool isDarkMode;

  const DeleteAccountButton({
    super.key,
    required this.isDarkMode,
    this.onDeleteSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(
          thickness: 0.5,
          height: 1,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(
                color: Colors.red.shade300,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This action cannot be undone',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAccountDialog(
        isDarkMode: isDarkMode,
        onDeleteSuccess: onDeleteSuccess,
      ),
    );
  }
}