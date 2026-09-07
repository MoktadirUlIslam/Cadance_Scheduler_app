// lib/screens/home/components/TaskManagerStatsRow.dart

import 'package:flutter/material.dart';
import '../../../core/data_provider.dart';
import '../../../utilites/app_colors.dart';
import '../../../widgets/stat_card.dart';

class TaskManagerStatsRow extends StatelessWidget {
  final DataProvider dataProvider;
  final bool isDarkMode;

  const TaskManagerStatsRow({
    super.key,
    required this.dataProvider,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final stats = dataProvider.taskStats;

    final totalTasks = stats?.totalTasks ?? 0;
    final totalCompleted = stats?.totalCompleted ?? 0;
    final totalOverdue = stats?.totalOverdue ?? 0;
    final completionRate = totalTasks > 0 ? ((totalCompleted / totalTasks) * 100).round() : 0;

    if (totalTasks == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard.withOpacity(0.5) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDarkMode ? AppColors.darkBorder : Colors.grey.shade200, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
              const SizedBox(width: 8),
              Text(
                'No tasks yet. Add your first task!',
                style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          // Row 1: Progress & Overdue
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.assignment_outlined,
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: Colors.blue,
                  value: '$totalCompleted/$totalTasks',
                  label: 'Progress',
                  sublabel: '$completionRate% complete',
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StatCard(
                  icon: Icons.more_horiz_outlined,
                  iconBg: Colors.grey.withOpacity(0.1),
                  iconColor: Colors.grey,
                  value: (stats?.totalOthers ?? 0).toString(),
                  label: 'Others',
                  sublabel: totalTasks > 0 ? '${((stats?.totalOthers ?? 0) / totalTasks * 100).round()}%' : '0%',
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Task Types (Classes, Assignments, Lab Reports, Exams)
          Row(
            children: [
              _buildTypeCard(Icons.class_outlined, AppColors.primaryLight, stats?.totalClasses ?? 0, totalTasks, 'Classes'),
              const SizedBox(width: 6),
              _buildTypeCard(Icons.assignment_outlined, AppColors.purple, stats?.totalAssignments ?? 0, totalTasks, 'Assignments'),
              const SizedBox(width: 6),
              _buildTypeCard(Icons.science_outlined, AppColors.successLight, stats?.totalLabReports ?? 0, totalTasks, 'Lab Reports'),
              const SizedBox(width: 6),
              _buildTypeCard(Icons.quiz_outlined, AppColors.accentLight, stats?.totalExams ?? 0, totalTasks, 'Exams'),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildTypeCard(IconData icon, Color color, int count, int total, String label) {
    return Expanded(
      child: StatCard(
        icon: icon,
        iconBg: color.withOpacity(0.1),
        iconColor: color,
        value: count.toString(),
        label: label,
        sublabel: total > 0 ? '${(count / total * 100).round()}%' : '0%',
        isDarkMode: isDarkMode,
      ),
    );
  }
}