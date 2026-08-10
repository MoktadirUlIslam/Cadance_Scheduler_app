// lib/screens/home/components/date_time_header.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class DateTimeHeader extends StatefulWidget {
  final Animation<double> fadeAnimation;

  const DateTimeHeader({
    super.key,
    required this.fadeAnimation,
  });

  @override
  State<DateTimeHeader> createState() => _DateTimeHeaderState();
}

class _DateTimeHeaderState extends State<DateTimeHeader> {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    final dateStr = _formatDateFull(now);

    if (_currentTime != timeStr || _currentDate != dateStr) {
      setState(() {
        _currentTime = timeStr;
        _currentDate = dateStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : AppColors.primaryLight.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : AppColors.primaryLight.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Time section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time display
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Text(
                      _currentTime,
                      key: ValueKey(_currentTime),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : AppColors.ink,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date display
                  Text(
                    _currentDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white60 : AppColors.inkSoft,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Modern clock icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primaryLight.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $amPm';
  }

  String _formatDateFull(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}