// lib/screens/home/components/weekly_chart.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/utilites/line_chart.dart';

class WeeklyChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;

  const WeeklyChart({
    super.key,
    required this.data,
    required this.labels,
    required this.isDarkMode,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: CustomLineChart(
        data: data,
        labels: labels,
        color: AppColors.primaryLight,
        isDarkMode: isDarkMode,
      ),
    );
  }
}