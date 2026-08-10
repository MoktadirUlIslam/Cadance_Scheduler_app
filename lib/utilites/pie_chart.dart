import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/models/chart_painters.dart';

import '../../models/SubjectData.dart';

class CustomPieChart extends StatelessWidget {
  final List<SubjectData> subjectData;
  final bool isDarkMode;

  const CustomPieChart({
    super.key,
    required this.subjectData,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final total = subjectData.fold(0.0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: PieChartPainter(
                data: subjectData.map((e) => e.value).toList(),
                colors: subjectData.map((e) => e.color).toList(),
                centerColor: isDarkMode ? AppColors.darkCard : AppColors.card,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subjectData.map((subject) {
                final percentage = ((subject.value / total) * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: subject.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${subject!.label} · $percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? AppColors.darkInkSoft
                              : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}