// lib/screens/Profile/components/delete_account_dialog.dart

import 'package:flutter/material.dart';
import '../../../services/account_deletion_service.dart';
import '../../../utilites/app_colors.dart';

class DeleteAccountDialog extends StatefulWidget {
  final VoidCallback? onDeleteSuccess;
  final bool isDarkMode;

  const DeleteAccountDialog({
    super.key,
    required this.isDarkMode,
    this.onDeleteSuccess,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final AccountDeletionService _deletionService = AccountDeletionService();
  final TextEditingController _confirmationController = TextEditingController();
  bool _isConfirmed = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _confirmationController.removeListener(_validateInput);
    _confirmationController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isConfirmed = _confirmationController.text == 'DELETE';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.isDarkMode ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info items - simple list
            _buildSimpleInfoItem('Profile information'),
            _buildSimpleInfoItem('Task history'),
            _buildSimpleInfoItem('Timer statistics'),
            _buildSimpleInfoItem('All saved data'),
            const SizedBox(height: 20),

            // Confirmation text
            const Text(
              'Type "DELETE" to confirm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Confirmation text field
            _buildConfirmationTextField(),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode
                            ? AppColors.darkInkSoft
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConfirmed && !_isDeleting ? _handleDelete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.red.shade200,
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 4,
            color: widget.isDarkMode
                ? AppColors.darkInkSoft
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: widget.isDarkMode
                  ? AppColors.darkInk
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationTextField() {
    return TextField(
      controller: _confirmationController,
      enabled: !_isDeleting,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
        fontSize: 15,
        fontWeight: _isConfirmed ? FontWeight.bold : FontWeight.normal,
        letterSpacing: _isConfirmed ? 2 : 0,
      ),
      decoration: InputDecoration(
        hintText: 'DELETE',
        hintStyle: TextStyle(
          color: widget.isDarkMode
              ? AppColors.darkInkSoft
              : Colors.grey.shade400,
          fontSize: 15,
        ),
        filled: true,
        fillColor: widget.isDarkMode
            ? AppColors.darkSurface
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isConfirmed
                ? Colors.green.shade400
                : widget.isDarkMode
                ? AppColors.darkBorder
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isConfirmed
                ? Colors.green.shade400
                : widget.isDarkMode
                ? AppColors.darkBorder
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isConfirmed
                ? Colors.green.shade500
                : Colors.red.shade300,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  'Deleting account...',
                  style: TextStyle(
                    color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await _deletionService.deleteAccount();

      // Close loading
      Navigator.pop(context);
      // Close dialog
      Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account deleted successfully'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.onDeleteSuccess != null) {
        widget.onDeleteSuccess!();
      }

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}