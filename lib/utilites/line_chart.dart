import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/models/chart_painters.dart';

class CustomLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final bool isDarkMode;

  const CustomLineChart({
    super.key,
    required this.data,
    required this.labels,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final padding = (maxValue - minValue) * 0.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      height: 160,
      child: CustomPaint(
        painter: LineChartPainter(
          data: data,
          labels: labels,
          color: color,
          areaColor: color.withOpacity(0.08),
          maxValue: maxValue + padding,
          minValue: minValue - padding,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }
}