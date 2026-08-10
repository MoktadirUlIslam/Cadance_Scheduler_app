// lib/screens/home/components/stats_row.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/stat_card.dart';

class StatsRow extends StatelessWidget {
  final int totalFocusMinutes;
  final int totalCompletedTasks;
  final int totalFocusSessions;
  final int streak;
  final Animation<double> fadeAnimation;

  const StatsRow({
    super.key,
    required this.totalFocusMinutes,
    required this.totalCompletedTasks,
    required this.totalFocusSessions,
    required this.streak,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.timer_outlined,
              iconBg: const Color(0xFFE1F5EE),
              iconColor: AppColors.primaryLight,
              value: _formatTime(totalFocusMinutes),
              label: 'Focus time',
              sublabel: '${totalFocusMinutes ~/ 60}h ${totalFocusMinutes % 60}m total',
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: StatCard(
              icon: Icons.check_circle_outline,
              iconBg: const Color(0xFFE8F0FE),
              iconColor: Colors.green,
              value: totalCompletedTasks.toString(),
              label: 'Tasks Done',
              sublabel: '${totalFocusSessions} sessions',
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: StatCard(
              icon: Icons.timer_rounded,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: Colors.orange,
              value: totalFocusSessions.toString(),
              label: 'Sessions',
              sublabel: '${(totalFocusSessions > 0 ? (totalFocusMinutes / totalFocusSessions).round() : 0)} min avg',
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: StatCard(
              icon: Icons.local_fire_department_outlined,
              iconBg: const Color(0xFFFAEEDA),
              iconColor: AppColors.warningLight,
              value: '$streak🔥',
              label: 'Day streak',
              sublabel: streak > 0 ? 'Keep going!' : 'Start today',
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      }
      return '${hours}h${remainingMinutes}m';
    }
    return '${minutes}m';
  }
}