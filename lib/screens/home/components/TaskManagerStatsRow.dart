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
    // Get stats from DataProvider
    final totalTasks = dataProvider.totalTasksDone;
    final totalClasses = dataProvider.totalClassesDone;
    final totalAssignments = dataProvider.totalAssignmentsDone;
    final totalLabReports = dataProvider.totalLabReportsDone;
    final totalExams = dataProvider.totalExamsDone;
    final totalOthers = dataProvider.totalOthersDone;

    // Calculate total completed
    final totalCompleted = totalClasses + totalAssignments +
        totalLabReports + totalExams + totalOthers;

    // Calculate completion rate
    final completionRate = totalTasks > 0
        ? ((totalCompleted / totalTasks) * 100).round()
        : 0;

    if (dataProvider.isLoadingTaskStats) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: const Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        children: [
          // Task Progress Card
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
              icon: Icons.class_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: Colors.green,
              value: totalClasses.toString(),
              label: 'Classes',
              sublabel: '${totalTasks > 0 ? ((totalClasses / totalTasks) * 100).round() : 0}%',
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: StatCard(
              icon: Icons.assignment_outlined,
              iconBg: const Color(0xFFF3E5F5),
              iconColor: Colors.purple,
              value: totalAssignments.toString(),
              label: 'Assignments',
              sublabel: '${totalTasks > 0 ? ((totalAssignments / totalTasks) * 100).round() : 0}%',
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: StatCard(
              icon: Icons.science_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: Colors.orange,
              value: totalLabReports.toString(),
              label: 'Lab Reports',
              sublabel: '${totalTasks > 0 ? ((totalLabReports / totalTasks) * 100).round() : 0}%',
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }
}