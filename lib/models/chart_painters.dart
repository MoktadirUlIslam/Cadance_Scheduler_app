import 'dart:math';
import 'package:flutter/material.dart';
import '../../../utilites/app_colors.dart';

// Custom Line Chart Painter
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
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..color = areaColor
      ..style = PaintingStyle.fill;

    final padding = const EdgeInsets.all(12);
    final chartWidth = size.width - padding.horizontal;
    final chartHeight = size.height - padding.vertical;
    final xStep = chartWidth / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + (i * xStep);
      final y = padding.top + chartHeight -
          ((data[i] - minValue) / (maxValue - minValue) * chartHeight);
      points.add(Offset(x, y));
    }

    final areaPath = Path();
    areaPath.moveTo(points.first.dx, size.height - padding.bottom);
    for (var point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(points.last.dx, size.height - padding.bottom);
    areaPath.close();
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }

    final textStyle = TextStyle(
      fontSize: 10,
      color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < labels.length; i++) {
      final textSpan = TextSpan(text: labels[i], style: textStyle);
      textPainter.text = textSpan;
      textPainter.layout();
      final x = padding.left + (i * xStep) - (textPainter.width / 2);
      textPainter.paint(canvas, Offset(x, size.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final Color centerColor;

  PieChartPainter({
    required this.data,
    required this.colors,
    this.centerColor = AppColors.card,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0.0, (sum, item) => sum + item);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final innerRadius = radius * 0.68;
    var startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final path = Path();
      final innerStartX = center.dx + innerRadius * cos(startAngle);
      final innerStartY = center.dy + innerRadius * sin(startAngle);

      path.moveTo(innerStartX, innerStartY);
      path.arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false);
      path.arcTo(Rect.fromCircle(center: center, radius: innerRadius), startAngle + sweepAngle, -sweepAngle, false);
      path.close();

      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }

    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius - 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Ring Painter for Timer
class RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const double startAngle = -3 * 3.14159 / 2;
    double sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}