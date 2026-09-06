// lib/screens/TaskManager/widgets/weekly_calendar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utilites/app_colors.dart';
import '../providers/task_provider.dart';

class WeeklyCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool isDarkMode;

  const WeeklyCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(selectedDate);
    final today = DateTime.now();
    final taskProvider = context.watch<TaskProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Week header with navigation
          _buildWeekHeader(context),
          const SizedBox(height: 12),
          // Days of the week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((date) {
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final hasTasks = taskProvider.hasTasksOnDate(date);

              return _buildDayCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                hasTasks: hasTasks,
                onTap: () => onDateSelected(date),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final weekStart = _getWeekStart(selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            final newDate = selectedDate.subtract(const Duration(days: 7));
            onDateSelected(newDate);
          },
          icon: Icon(
            Icons.chevron_left,
            color: isDarkMode ? Colors.white70 : AppColors.ink,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
        Text(
          '${_monthName(weekStart.month)} ${weekStart.day} - ${_monthName(weekEnd.month)} ${weekEnd.day}, ${weekEnd.year}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.ink,
          ),
        ),
        IconButton(
          onPressed: () {
            final newDate = selectedDate.add(const Duration(days: 7));
            onDateSelected(newDate);
          },
          icon: Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.white70 : AppColors.ink,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
    required bool hasTasks,
    required VoidCallback onTap,
  }) {
    final dayName = _dayName(date.weekday);
    final dayNumber = date.day;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? (isSelected ? Colors.white : Colors.white54)
                  : (isSelected ? Colors.white : AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isToday ? AppColors.primaryLight.withOpacity(0.15) : Colors.transparent),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primaryLight, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.white : AppColors.ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Task indicator dots
          if (hasTasks)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : AppColors.primaryLight,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Helper methods
  List<DateTime> _getWeekDays(DateTime date) {
    final start = _getWeekStart(date);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Saturday as start of week
    final daysFromSaturday = (date.weekday % 7) + 1;
    return date.subtract(Duration(days: daysFromSaturday));
  }

  String _dayName(int weekday) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday % 7];
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}