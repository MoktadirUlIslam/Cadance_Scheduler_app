// lib/screens/Calendar/services/event_form_helper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import '../../../models/calendar_models.dart';

class EventFormHelper {
  // ==================== ADD EVENT FORM ====================

  static void showAddEventForm({
    required BuildContext context,
    required DateTime selectedDate,
    required Function(CalendarEventModel event) onEventAdded,
  }) {
    // Form state
    EventCategory selectedCategory = EventCategory.custom;
    bool isAllDay = false;
    bool hasReminder = true;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    RecurrenceType recurrenceType = RecurrenceType.none;

    // Multiple reminders
    List<int> selectedReminders = [30]; // Default: 30 min before

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.90,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      _buildHeader(
                        isDark: isDark,
                        selectedDate: selectedDate,
                        onClose: () => Navigator.pop(dialogContext),
                        title: 'Add New Event',
                        icon: Icons.add_circle_outline,
                      ),

                      // Scrollable body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              _buildTextField(
                                controller: titleController,
                                label: 'Event Title *',
                                hint: 'e.g., Final Exam, Birthday Party',
                                icon: Icons.event_rounded,
                                isDark: isDark,
                                validator: (v) => v!.isEmpty ? 'Title is required' : null,
                              ),
                              const SizedBox(height: 18),

                              // Category
                              _buildCategorySelector(
                                selectedCategory: selectedCategory,
                                isDark: isDark,
                                onChanged: (cat) => setState(() => selectedCategory = cat),
                              ),
                              const SizedBox(height: 18),

                              // All day toggle
                              _buildAllDayToggle(
                                isAllDay: isAllDay,
                                isDark: isDark,
                                onChanged: (v) => setState(() => isAllDay = v),
                              ),

                              // Time pickers
                              if (!isAllDay) ...[
                                const SizedBox(height: 18),
                                _buildTimePickers(
                                  context: context,
                                  startTime: startTime,
                                  endTime: endTime,
                                  isDark: isDark,
                                  onStartTimeChanged: (t) => setState(() => startTime = t),
                                  onEndTimeChanged: (t) => setState(() => endTime = t),
                                ),
                              ],

                              const SizedBox(height: 18),

                              // Location
                              _buildTextField(
                                controller: locationController,
                                label: 'Location',
                                hint: 'e.g., Room 201, Downtown Cafe',
                                icon: Icons.location_on_outlined,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 18),

                              // Description
                              _buildTextField(
                                controller: descriptionController,
                                label: 'Description',
                                hint: 'Add notes, details, etc.',
                                icon: Icons.description_outlined,
                                isDark: isDark,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 18),

                              // 👇 Recurrence Selector - No end date
                              _buildRecurrenceSelector(
                                recurrenceType: recurrenceType,
                                isDark: isDark,
                                onRecurrenceChanged: (type) => setState(() => recurrenceType = type),
                              ),
                              const SizedBox(height: 18),

                              // Multiple Reminders
                              _buildMultipleReminders(
                                hasReminder: hasReminder,
                                selectedReminders: selectedReminders,
                                isDark: isDark,
                                onReminderToggled: (v) => setState(() => hasReminder = v),
                                onRemindersChanged: (list) => setState(() => selectedReminders = list),
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // Buttons footer
                      _buildFooter(
                        isDark: isDark,
                        onCancel: () => Navigator.pop(dialogContext),
                        onConfirm: () {
                          if (formKey.currentState!.validate()) {
                            // Calculate notification time
                            DateTime? notificationTime;
                            if (hasReminder && selectedReminders.isNotEmpty) {
                              notificationTime = _calculateNotificationTime(
                                selectedDate,
                                isAllDay ? null : startTime,
                                isAllDay,
                                selectedReminders.first,
                              );
                            }

                            final event = CalendarEventModel(
                              id: '',
                              title: titleController.text,
                              description: descriptionController.text.isNotEmpty
                                  ? descriptionController.text
                                  : null,
                              location: locationController.text.isNotEmpty
                                  ? locationController.text
                                  : null,
                              date: selectedDate,
                              startTime: isAllDay ? null : startTime,
                              endTime: isAllDay ? null : endTime,
                              category: selectedCategory,
                              isAllDay: isAllDay,
                              hasReminder: hasReminder,
                              reminderMinutesBefore: hasReminder && selectedReminders.isNotEmpty
                                  ? selectedReminders.first
                                  : 30,
                              allReminderMinutes: hasReminder ? selectedReminders : [],
                              recurrenceType: recurrenceType,
                              notificationTime: notificationTime,
                            );
                            onEventAdded(event);
                            Navigator.pop(dialogContext);
                          }
                        },
                        buttonText: 'Add Event',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== EDIT EVENT FORM ====================

  static void showEditEventForm({
    required BuildContext context,
    required CalendarEventModel event,
    required Function(CalendarEventModel updatedEvent) onEventUpdated,
  }) {
    EventCategory selectedCategory = event.category;
    bool isAllDay = event.isAllDay;
    bool hasReminder = event.hasReminder;
    TimeOfDay? startTime = event.startTime;
    TimeOfDay? endTime = event.endTime;
    RecurrenceType recurrenceType = event.recurrenceType;

    // Load existing reminders
    List<int> selectedReminders = event.allReminderMinutes.isNotEmpty
        ? List.from(event.allReminderMinutes)
        : (event.hasReminder ? [event.reminderMinutesBefore] : []);

    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    final locationController = TextEditingController(text: event.location ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.90,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      _buildHeader(
                        isDark: isDark,
                        selectedDate: event.date,
                        onClose: () => Navigator.pop(dialogContext),
                        title: 'Edit Event',
                        icon: Icons.edit_outlined,
                      ),

                      // Scrollable body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: titleController,
                                label: 'Event Title *',
                                hint: 'e.g., Final Exam, Birthday Party',
                                icon: Icons.event_rounded,
                                isDark: isDark,
                                validator: (v) => v!.isEmpty ? 'Title is required' : null,
                              ),
                              const SizedBox(height: 18),
                              _buildCategorySelector(
                                selectedCategory: selectedCategory,
                                isDark: isDark,
                                onChanged: (cat) => setState(() => selectedCategory = cat),
                              ),
                              const SizedBox(height: 18),
                              _buildAllDayToggle(
                                isAllDay: isAllDay,
                                isDark: isDark,
                                onChanged: (v) => setState(() => isAllDay = v),
                              ),
                              if (!isAllDay) ...[
                                const SizedBox(height: 18),
                                _buildTimePickers(
                                  context: context,
                                  startTime: startTime,
                                  endTime: endTime,
                                  isDark: isDark,
                                  onStartTimeChanged: (t) => setState(() => startTime = t),
                                  onEndTimeChanged: (t) => setState(() => endTime = t),
                                ),
                              ],
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: locationController,
                                label: 'Location',
                                hint: 'e.g., Room 201, Downtown Cafe',
                                icon: Icons.location_on_outlined,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: descriptionController,
                                label: 'Description',
                                hint: 'Add notes, details, etc.',
                                icon: Icons.description_outlined,
                                isDark: isDark,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 18),
                              _buildRecurrenceSelector(
                                recurrenceType: recurrenceType,
                                isDark: isDark,
                                onRecurrenceChanged: (type) => setState(() => recurrenceType = type),
                              ),
                              const SizedBox(height: 18),
                              _buildMultipleReminders(
                                hasReminder: hasReminder,
                                selectedReminders: selectedReminders,
                                isDark: isDark,
                                onReminderToggled: (v) => setState(() => hasReminder = v),
                                onRemindersChanged: (list) => setState(() => selectedReminders = list),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // Buttons footer
                      _buildFooter(
                        isDark: isDark,
                        onCancel: () => Navigator.pop(dialogContext),
                        onConfirm: () {
                          if (formKey.currentState!.validate()) {
                            // Calculate notification time
                            DateTime? notificationTime;
                            if (hasReminder && selectedReminders.isNotEmpty) {
                              notificationTime = _calculateNotificationTime(
                                event.date,
                                isAllDay ? null : startTime,
                                isAllDay,
                                selectedReminders.first,
                              );
                            }

                            final updatedEvent = event.copyWith(
                              title: titleController.text,
                              description: descriptionController.text.isNotEmpty
                                  ? descriptionController.text
                                  : null,
                              location: locationController.text.isNotEmpty
                                  ? locationController.text
                                  : null,
                              startTime: isAllDay ? null : startTime,
                              endTime: isAllDay ? null : endTime,
                              category: selectedCategory,
                              isAllDay: isAllDay,
                              hasReminder: hasReminder,
                              reminderMinutesBefore: hasReminder && selectedReminders.isNotEmpty
                                  ? selectedReminders.first
                                  : 30,
                              allReminderMinutes: hasReminder ? selectedReminders : [],
                              recurrenceType: recurrenceType,
                              notificationTime: notificationTime,
                            );
                            onEventUpdated(updatedEvent);
                            Navigator.pop(dialogContext);
                          }
                        },
                        buttonText: 'Update Event',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== EVENT DETAILS POPUP ====================

  static void showEventDetails({
    required BuildContext context,
    required CalendarEventModel event,
    required bool isDarkMode,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: event.eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.eventEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            event.categoryLabel,
                            style: TextStyle(
                                color: event.eventColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                            Icons.close,
                            size: 16,
                            color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.grey
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  event.title,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.ink
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                    icon: Icons.access_time,
                    title: 'Time',
                    value: event.formattedTimeRange,
                    isDark: isDarkMode
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                      icon: Icons.location_on,
                      title: 'Location',
                      value: event.location!,
                      isDark: isDarkMode
                  ),
                ],
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                      icon: Icons.description_outlined,
                      title: 'Description',
                      value: event.description!,
                      isDark: isDarkMode
                  ),
                ],
                if (event.isRecurring) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.repeat_rounded,
                    title: 'Repeats',
                    value: _getRecurrenceDisplayText(event.recurrenceType),
                    isDark: isDarkMode,
                  ),
                ],
                if (event.hasReminder) ...[
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.notifications_active,
                    title: 'Reminders',
                    value: event.allReminderMinutes.isNotEmpty
                        ? event.allReminderMinutes.map((m) => _formatReminderText(m)).join(', ')
                        : '${event.reminderMinutesBefore} minutes before',
                    isDark: isDarkMode,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(color: AppColors.primaryLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== HEADER ====================

  static Widget _buildHeader({
    required bool isDark,
    required DateTime selectedDate,
    required VoidCallback onClose,
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateShort(selectedDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FOOTER ====================

  static Widget _buildFooter({
    required bool isDark,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : AppColors.inkSoft,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECURRENCE SELECTOR ====================

  static Widget _buildRecurrenceSelector({
    required RecurrenceType recurrenceType,
    required bool isDark,
    required Function(RecurrenceType) onRecurrenceChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 18,
              color: isDark ? Colors.white.withOpacity(0.5) : AppColors.inkSoft,
            ),
            const SizedBox(width: 8),
            Text(
              'Repeat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.7) : AppColors.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRecurrenceChip(
              label: 'Never',
              type: RecurrenceType.none,
              selected: recurrenceType == RecurrenceType.none,
              isDark: isDark,
              onTap: () => onRecurrenceChanged(RecurrenceType.none),
            ),
            _buildRecurrenceChip(
              label: 'Daily',
              type: RecurrenceType.daily,
              selected: recurrenceType == RecurrenceType.daily,
              isDark: isDark,
              onTap: () => onRecurrenceChanged(RecurrenceType.daily),
            ),
            _buildRecurrenceChip(
              label: 'Weekly',
              type: RecurrenceType.weekly,
              selected: recurrenceType == RecurrenceType.weekly,
              isDark: isDark,
              onTap: () => onRecurrenceChanged(RecurrenceType.weekly),
            ),
            _buildRecurrenceChip(
              label: 'Monthly',
              type: RecurrenceType.monthly,
              selected: recurrenceType == RecurrenceType.monthly,
              isDark: isDark,
              onTap: () => onRecurrenceChanged(RecurrenceType.monthly),
            ),
            _buildRecurrenceChip(
              label: 'Yearly',
              type: RecurrenceType.yearly,
              selected: recurrenceType == RecurrenceType.yearly,
              isDark: isDark,
              onTap: () => onRecurrenceChanged(RecurrenceType.yearly),
            ),
          ],
        ),
        if (recurrenceType != RecurrenceType.none) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRecurrenceDescription(recurrenceType),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildRecurrenceChip({
    required String label,
    required RecurrenceType type,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryLight
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == RecurrenceType.yearly && selected)
              const Text('🎂 ', style: TextStyle(fontSize: 12)),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.primaryLight
                    : (isDark ? Colors.white70 : AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getRecurrenceDescription(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'This event will repeat every day forever.';
      case RecurrenceType.weekly:
        return 'This event will repeat every week on the same day forever.';
      case RecurrenceType.monthly:
        return 'This event will repeat every month on the same date forever.';
      case RecurrenceType.yearly:
        return '🎂 This event will repeat every year on the same date forever (great for birthdays and holidays)!';
      default:
        return '';
    }
  }

  static String _getRecurrenceDisplayText(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily (forever)';
      case RecurrenceType.weekly:
        return 'Weekly (forever)';
      case RecurrenceType.monthly:
        return 'Monthly (forever)';
      case RecurrenceType.yearly:
        return '🎂 Yearly (forever)';
      default:
        return '';
    }
  }

  // ==================== MULTIPLE REMINDERS WIDGET ====================

  static Widget _buildMultipleReminders({
    required bool hasReminder,
    required List<int> selectedReminders,
    required bool isDark,
    required Function(bool) onReminderToggled,
    required Function(List<int>) onRemindersChanged,
  }) {
    const allReminderOptions = [
      {'value': 0, 'label': 'At time of event'},
      {'value': 5, 'label': '5 minutes before'},
      {'value': 15, 'label': '15 minutes before'},
      {'value': 30, 'label': '30 minutes before'},
      {'value': 60, 'label': '1 hour before'},
      {'value': 120, 'label': '2 hours before'},
      {'value': 360, 'label': '6 hours before'},
      {'value': 1440, 'label': '1 day before'},
      {'value': 2880, 'label': '2 days before'},
      {'value': 10080, 'label': '1 week before'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reminder toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 18, color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 10),
                  Text('Reminders', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.ink)),
                ],
              ),
              Switch(
                value: hasReminder,
                onChanged: onReminderToggled,
                activeColor: AppColors.primaryLight,
              ),
            ],
          ),
        ),

        // Multiple reminder options
        if (hasReminder) ...[
          const SizedBox(height: 12),
          Text(
            'Select reminder times:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withOpacity(0.5) : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allReminderOptions.map((option) {
              final minutes = option['value'] as int;
              final isSelected = selectedReminders.contains(minutes);

              return GestureDetector(
                onTap: () {
                  final newList = List<int>.from(selectedReminders);
                  if (isSelected) {
                    newList.remove(minutes);
                  } else {
                    newList.add(minutes);
                  }
                  newList.sort();
                  onRemindersChanged(newList);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.15)
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle, size: 14, color: AppColors.primaryLight),
                        ),
                      Text(
                        option['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryLight
                              : (isDark ? Colors.white70 : AppColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Show selected count
          if (selectedReminders.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 6),
                  Text(
                    '${selectedReminders.length} reminder${selectedReminders.length > 1 ? 's' : ''} set',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ==================== TEXT FIELD ====================

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.7) : AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : AppColors.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primaryLight),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ==================== CATEGORY SELECTOR ====================

  static Widget _buildCategorySelector({
    required EventCategory selectedCategory,
    required bool isDark,
    required Function(EventCategory) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.7) : AppColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: EventCategory.values.map((category) {
            final isSelected = category == selectedCategory;
            return GestureDetector(
              onTap: () => onChanged(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? category.color.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? category.color : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(category.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isSelected ? category.color : (isDark ? Colors.white54 : Colors.grey))),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== ALL DAY TOGGLE ====================

  static Widget _buildAllDayToggle({
    required bool isAllDay,
    required bool isDark,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.wb_sunny, size: 18, color: isDark ? Colors.white54 : Colors.grey),
          const SizedBox(width: 10),
          Text('All Day Event', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.ink)),
        ]),
        Switch(value: isAllDay, onChanged: onChanged, activeColor: AppColors.primaryLight),
      ]),
    );
  }

  // ==================== TIME PICKERS ====================

  static Widget _buildTimePickers({
    required BuildContext context,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required bool isDark,
    required Function(TimeOfDay) onStartTimeChanged,
    required Function(TimeOfDay) onEndTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.7) : AppColors.inkSoft)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _buildTimeButton(label: 'Start', time: startTime ?? const TimeOfDay(hour: 9, minute: 0),
              isDark: isDark, onTap: () async {
                final time = await showTimePicker(context: context, initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0));
                if (time != null) onStartTimeChanged(time);
              })),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('to', style: TextStyle(color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey)),
          ),
          Expanded(child: _buildTimeButton(label: 'End', time: endTime ?? const TimeOfDay(hour: 10, minute: 0),
              isDark: isDark, onTap: () async {
                final time = await showTimePicker(context: context, initialTime: endTime ?? const TimeOfDay(hour: 10, minute: 0));
                if (time != null) onEndTimeChanged(time);
              })),
        ]),
      ],
    );
  }

  static Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = time.hour == 0 ? 12 : hour;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade500)),
          const SizedBox(height: 3),
          Text('$displayHour:${time.minute.toString().padLeft(2, '0')} $period',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.ink)),
        ]),
      ),
    );
  }

  // ==================== DETAIL ROW ====================

  static Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.ink)),
          ]),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  static String _formatDateShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatReminderText(int minutes) {
    if (minutes == 0) return 'At time of event';
    if (minutes < 60) return '$minutes min before';
    if (minutes < 1440) return '${minutes ~/ 60} hr before';
    if (minutes == 1440) return '1 day before';
    if (minutes == 2880) return '2 days before';
    return '${minutes ~/ 1440} days before';
  }

  static DateTime? _calculateNotificationTime(
      DateTime date,
      TimeOfDay? startTime,
      bool isAllDay,
      int minutesBefore,
      ) {
    if (isAllDay) {
      return DateTime(date.year, date.month, date.day, 9, 0);
    } else if (startTime != null) {
      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      return eventDateTime.subtract(Duration(minutes: minutesBefore));
    }
    return null;
  }
}