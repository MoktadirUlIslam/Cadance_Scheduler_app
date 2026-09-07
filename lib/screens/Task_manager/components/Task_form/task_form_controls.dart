// lib/screens/TaskManager/widgets/task_form_controls.dart
import 'package:flutter/material.dart';
import '../../../../models/taskmanager_model.dart';
import '../../../../utilites/app_colors.dart';


// ==================== PRIORITY SELECTOR ====================
class PrioritySelector extends StatelessWidget {
  final Priority selectedPriority;
  final bool isDarkMode;
  final Function(Priority) onChanged;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Priority'),
        const SizedBox(height: 8),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = selectedPriority == priority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onChanged(priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [priority.color, priority.color.withOpacity(0.7)])
                          : null,
                      color: isSelected ? null : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? priority.color : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : priority.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            priority.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : priority.color,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }
}

// ==================== REMINDER SELECTOR ====================
class ReminderSelector extends StatelessWidget {
  final List<ReminderOption> selectedReminders;
  final bool isDarkMode;
  final Function(List<ReminderOption>) onChanged;

  const ReminderSelector({
    super.key,
    required this.selectedReminders,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Reminders'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ReminderOption.values.map((option) {
            final isSelected = selectedReminders.contains(option);
            return FilterChip(
              label: Text(
                option.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newReminders = List<ReminderOption>.from(selectedReminders);
                if (selected) {
                  newReminders.add(option);
                } else {
                  newReminders.remove(option);
                }
                onChanged(newReminders);
              },
              backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              selectedColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryLight : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedReminders.isEmpty
                      ? '⚠️ No reminders selected. Default: 1 day & 2 hours before'
                      : '${selectedReminders.length} reminder(s) selected',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }
}

// ==================== ALARM TOGGLE ====================
class AlarmToggle extends StatelessWidget {
  final bool alarmOn;
  final bool isDarkMode;
  final Function(bool) onChanged;

  const AlarmToggle({
    super.key,
    required this.alarmOn,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                alarmOn ? Icons.notifications_active : Icons.notifications_off,
                color: alarmOn ? AppColors.primaryLight : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Alarm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Text(
                    alarmOn ? 'Notifications will be sent' : 'Alarm is off',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: alarmOn,
            onChanged: onChanged,
            activeColor: AppColors.primaryLight,
            activeTrackColor: AppColors.primaryLight.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}