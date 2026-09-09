// lib/screens/TaskManager/widgets/task_form_pickers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/taskmanager_model.dart';
import '../../../../utilites/app_colors.dart';
import '../../../../widgets/time_picker_widget.dart';

// ==================== DATE PICKER ====================
class DatePicker extends StatelessWidget {
  final DateTime date;
  final bool isDarkMode;
  final Function(DateTime) onChanged;

  const DatePicker({
    super.key,
    required this.date,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryLight,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

// ==================== DATE PICKER WITH RECURRING ====================
class DatePickerWithRecurring extends StatefulWidget {
  final DateTime date;
  final bool isRecurring;
  final RecurrenceFrequency recurrenceFrequency;
  final DateTime? recurringEndDate;
  final bool isDarkMode;
  final Function(DateTime) onDateChanged;
  final Function(bool) onRecurringToggled;
  final Function(RecurrenceFrequency) onFrequencyChanged;
  final Function(DateTime?) onEndDateChanged;

  const DatePickerWithRecurring({
    super.key,
    required this.date,
    required this.isRecurring,
    required this.recurrenceFrequency,
    this.recurringEndDate,
    required this.isDarkMode,
    required this.onDateChanged,
    required this.onRecurringToggled,
    required this.onFrequencyChanged,
    required this.onEndDateChanged,
  });

  @override
  State<DatePickerWithRecurring> createState() => _DatePickerWithRecurringState();
}

class _DatePickerWithRecurringState extends State<DatePickerWithRecurring> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Class Date'),
        const SizedBox(height: 8),
        DatePicker(
          date: widget.date,
          isDarkMode: widget.isDarkMode,
          onChanged: widget.onDateChanged,
        ),
        const SizedBox(height: 16),
        _buildRecurringToggle(),
        if (widget.isRecurring) ...[
          const SizedBox(height: 12),
          _buildRecurrenceFrequencySelector(),
          const SizedBox(height: 12),
          _buildRecurringEndDatePicker(),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: widget.isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isRecurring
              ? AppColors.primaryLight
              : (widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
          width: widget.isRecurring ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isRecurring ? Icons.repeat : Icons.repeat_outlined,
            color: widget.isRecurring ? AppColors.primaryLight : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recurring Class',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : AppColors.ink,
                  ),
                ),
                Text(
                  widget.isRecurring ? 'Repeats weekly/bi-weekly' : 'Enable recurring for this class',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? Colors.white54 : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.isRecurring,
            onChanged: widget.onRecurringToggled,
            activeColor: AppColors.primaryLight,
            activeTrackColor: AppColors.primaryLight.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Repeat Every'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFrequencyOption(
                RecurrenceFrequency.weekly,
                'Weekly',
                Icons.repeat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFrequencyOption(
                RecurrenceFrequency.biWeekly,
                'Bi-Weekly',
                Icons.repeat_on,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyOption(RecurrenceFrequency frequency, String label, IconData icon) {
    final isSelected = widget.recurrenceFrequency == frequency;

    return GestureDetector(
      onTap: () => widget.onFrequencyChanged(frequency),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.1)
              : (widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : (widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryLight : (widget.isDarkMode ? Colors.white54 : Colors.grey),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryLight
                    : (widget.isDarkMode ? Colors.white70 : AppColors.ink),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringEndDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('End Date (Last Class)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: widget.recurringEndDate ?? widget.date.add(const Duration(days: 120)),
              firstDate: widget.date,
              lastDate: DateTime(2030),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primaryLight,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) widget.onEndDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recurringEndDate != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(widget.recurringEndDate!)
                            : 'Select end date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.recurringEndDate != null ? FontWeight.w600 : FontWeight.w400,
                          color: widget.recurringEndDate != null
                              ? (widget.isDarkMode ? Colors.white : AppColors.ink)
                              : (widget.isDarkMode ? Colors.white54 : AppColors.inkSoft),
                        ),
                      ),
                      if (widget.recurringEndDate != null)
                        Text(
                          '${_calculateDaysBetween(widget.date, widget.recurringEndDate!)} classes',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: widget.isDarkMode ? Colors.white54 : AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calculateDaysBetween(DateTime start, DateTime end) {
    final interval = widget.recurrenceFrequency.days;
    if (interval == 0) return 1;
    final daysBetween = end.difference(start).inDays;
    return (daysBetween / interval).floor() + 1;
  }
}

// ==================== TIME RANGE PICKER ====================
class TimeRangePicker extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isDarkMode;
  final Function(TimeOfDay) onStartTimeChanged;
  final Function(TimeOfDay) onEndTimeChanged;

  const TimeRangePicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.isDarkMode,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Time Range'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SimpleTimePickerWidget(
                initialTime: startTime,
                onTimeSelected: onStartTimeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SimpleTimePickerWidget(
                initialTime: endTime,
                onTimeSelected: onEndTimeChanged,
              ),
            ),
          ],
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

// ==================== DEADLINE PICKER ====================
class DeadlinePicker extends StatelessWidget {
  final DateTime? deadline;
  final TaskType taskType;
  final bool isDarkMode;
  final Function(DateTime?) onChanged;

  const DeadlinePicker({
    super.key,
    this.deadline,
    required this.taskType,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String label = 'Deadline';
    String hint = 'Select deadline date';

    if (taskType == TaskType.assignment) {
      label = 'Submission Deadline';
      hint = 'Select submission deadline';
    } else if (taskType == TaskType.labReport) {
      label = 'Lab Report Deadline';
      hint = 'Select lab report submission date';
    } else if (taskType == TaskType.others) {
      label = 'Task Deadline';
      hint = 'Select task deadline';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: deadline ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primaryLight,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deadline != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(deadline!)
                            : hint,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: deadline != null ? FontWeight.w600 : FontWeight.w400,
                          color: deadline != null
                              ? (isDarkMode ? Colors.white : AppColors.ink)
                              : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
                        ),
                      ),
                      if (deadline != null)
                        Text(
                          _getDaysUntilDeadline(deadline!),
                          style: TextStyle(fontSize: 11, color: _getDeadlineColor(deadline!)),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
              ],
            ),
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

  String _getDaysUntilDeadline(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return '⚠️ Deadline has passed!';
    if (difference == 0) return '⏰ Deadline is today!';
    if (difference == 1) return '⏰ 1 day remaining';
    return '$difference days remaining';
  }

  Color _getDeadlineColor(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return Colors.red;
    if (difference <= 2) return Colors.orange;
    return Colors.green;
  }
}

/// ==================== DEADLINE WITH TIME PICKER ====================
class DeadlineWithTimePicker extends StatelessWidget {
  final DateTime? deadline;
  final TimeOfDay? submissionTime;
  final bool isDarkMode;
  final Function(DateTime?) onDeadlineChanged;
  final Function(TimeOfDay?) onTimeChanged;

  const DeadlineWithTimePicker({
    super.key,
    this.deadline,
    this.submissionTime,
    required this.isDarkMode,
    required this.onDeadlineChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Submission Deadline'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildSimpleDatePicker(context), // <-- Pass context here
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: SimpleTimePickerWidget(
                initialTime: submissionTime ?? TimeOfDay(hour: 23, minute: 59),
                onTimeSelected: (picked) {
                  onTimeChanged(picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Shows on schedule 2 days before deadline',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryLight,
                  ),
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

  Widget _buildSimpleDatePicker(BuildContext context) { // <-- Add context parameter
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, // <-- Now context is available
          initialDate: deadline ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryLight,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDeadlineChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                deadline != null
                    ? DateFormat('MMM d, yyyy').format(deadline!)
                    : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  color: deadline != null
                      ? (isDarkMode ? Colors.white : AppColors.ink)
                      : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}