// lib/screens/home/components/dock_widget.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class DockWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const DockWidget({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  DockWidgetState createState() => DockWidgetState();
}

class DockWidgetState extends State<DockWidget>
    with SingleTickerProviderStateMixin {

  void _navigateToPomodoro() {
    widget.onTabSelected(0);
  }

  void _navigateToTasks() {
    widget.onTabSelected(1);
  }

  void _navigateToHome() {
    widget.onTabSelected(2);
  }

  void _navigateToCalendar() {
    widget.onTabSelected(3);
  }

  void _navigateToStatistics() {
    widget.onTabSelected(4);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF0E241E).withOpacity(0.92)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
      ),
      // ✅ CRITICAL FIX: Remove mainAxisSize: MainAxisSize.min
      // Let the Row expand to fill the parent container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space items
        children: [
          // 1. POMODORO (index 0)
          _buildPomodoroButton(isDarkMode),
          // 2. TASK MANAGER (index 1)
          _buildTasksButton(isDarkMode),
          // 3. HOME (index 2) - Prominent
          _buildHomeButton(isDarkMode),
          // 4. CALENDAR (index 3)
          _buildCalendarButton(isDarkMode),
          // 5. STATISTICS (index 4)
          _buildStatisticsButton(isDarkMode),
        ],
      ),
    );
  }

  // Pomodoro button - index 0
  Widget _buildPomodoroButton(bool isDarkMode) {
    final isActive = widget.currentIndex == 0;
    return GestureDetector(
      onTap: _navigateToPomodoro,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentLight
              : isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppColors.accentLight.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isActive ? 1.15 : 1.0,
          child: Icon(
            Icons.timer_outlined,
            size: isActive ? 28 : 24,
            color: isActive
                ? Colors.white
                : isDarkMode
                ? Colors.white.withOpacity(0.55)
                : AppColors.ink.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  // Tasks button - index 1
  Widget _buildTasksButton(bool isDarkMode) {
    final isActive = widget.currentIndex == 1;
    return GestureDetector(
      onTap: _navigateToTasks,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentLight
              : isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppColors.accentLight.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Icon(
          Icons.add_task_outlined,
          size: isActive ? 24 : 22,
          color: isActive
              ? Colors.white
              : isDarkMode
              ? Colors.white.withOpacity(0.55)
              : AppColors.ink.withOpacity(0.5),
        ),
      ),
    );
  }

  // Home button - index 2 (CENTER - Prominent)
  Widget _buildHomeButton(bool isDarkMode) {
    final isActive = widget.currentIndex == 2;
    return GestureDetector(
      onTap: _navigateToHome,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentLight
              : AppColors.accentLight.withOpacity(isDarkMode ? 0.2 : 0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentLight.withOpacity(isActive ? 0.8 : 0.3),
              blurRadius: isActive ? 25 : 10,
              spreadRadius: isActive ? 2 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isActive ? 1.1 : 1.0,
          child: Icon(
            Icons.home_outlined,
            size: isActive ? 28 : 24,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // Calendar button - index 3
  Widget _buildCalendarButton(bool isDarkMode) {
    final isActive = widget.currentIndex == 3;
    return GestureDetector(
      onTap: _navigateToCalendar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentLight
              : isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppColors.accentLight.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Icon(
          Icons.calendar_month,
          size: isActive ? 24 : 22,
          color: isActive
              ? Colors.white
              : isDarkMode
              ? Colors.white.withOpacity(0.55)
              : AppColors.ink.withOpacity(0.5),
        ),
      ),
    );
  }

  // Statistics button - index 4
  Widget _buildStatisticsButton(bool isDarkMode) {
    final isActive = widget.currentIndex == 4;
    return GestureDetector(
      onTap: _navigateToStatistics,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentLight
              : isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppColors.accentLight.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: isActive ? 24 : 22,
          color: isActive
              ? Colors.white
              : isDarkMode
              ? Colors.white.withOpacity(0.55)
              : AppColors.ink.withOpacity(0.5),
        ),
      ),
    );
  }
}