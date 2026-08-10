// lib/Components/time_picker_widget.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

/// Simple Time Picker using native Material Time Picker
class SimpleTimePickerWidget extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const SimpleTimePickerWidget({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<SimpleTimePickerWidget> createState() => _SimpleTimePickerWidgetState();
}

class _SimpleTimePickerWidgetState extends State<SimpleTimePickerWidget> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _showTimePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.darkCard.withOpacity(0.3)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : AppColors.ink.withOpacity(0.5),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      _formatTime(_selectedTime),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppColors.ink,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: AppColors.primaryLight,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryLight,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              surface: Color(0xFF1A2E2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A2E2E),
          )
              : Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        widget.onTimeSelected(picked);
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}