// lib/models/chart_painters.dart - Add null/NaN checks

import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final Color areaColor;
  final double maxValue;
  final double minValue;
  final bool isDarkMode;

  LineChartPainter({
    required this.data,
    required this.labels,
    required this.color,
    required this.areaColor,
    required this.maxValue,
    required this.minValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..color = areaColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final padding = 8.0;
    final chartWidth = width - padding * 2;
    final chartHeight = height - padding * 2;

    // Check for valid range
    final range = maxValue - minValue;
    if (range <= 0) return;

    final points = <Offset>[];
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;

      // Safely calculate y value
      double y;
      if (range == 0) {
        y = padding + chartHeight / 2;
      } else {
        final normalizedValue = (data[i] - minValue) / range;
        y = padding + chartHeight - (normalizedValue * chartHeight);
      }

      // Ensure y is not NaN or infinite
      if (y.isNaN || y.isInfinite) {
        y = padding + chartHeight / 2;
      }

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    // Draw area fill
    final areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, padding + chartHeight);
    areaPath.lineTo(points.first.dx, padding + chartHeight);
    areaPath.close();
    canvas.drawPath(areaPath, areaPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (point.dx.isNaN || point.dy.isNaN) continue;

      // Border
      canvas.drawCircle(point, 6, dotBorderPaint);

      // Inner dot
      canvas.drawCircle(point, 4, dotPaint);

      // Label
      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelX = point.dx - textPainter.width / 2;
      final labelY = padding + chartHeight + 4;

      if (!labelX.isNaN && !labelY.isNaN) {
        textPainter.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}