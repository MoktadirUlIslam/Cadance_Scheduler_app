// Custom Pie Chart Painter
import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

class PieChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0.0, (sum, item) => sum + item);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final innerRadius = radius * 0.68;
    var startAngle = -pi / 2;  // Changed from -3.14159 / 2

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * pi;  // Changed from 3.14159
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final path = Path();

      // Calculate the inner arc start point
      final innerStartX = center.dx + innerRadius * cos(startAngle);  // Fixed
      final innerStartY = center.dy + innerRadius * sin(startAngle);  // Fixed

      path.moveTo(innerStartX, innerStartY);

      // Outer arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );

      // Inner arc (backwards)
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );

      path.close();

      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }

    // Draw center circle (donut hole)
    final centerPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius - 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}