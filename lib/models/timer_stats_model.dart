// lib/models/timer_stats_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStats {
  final DateTime date;
  final int totalFocusMinutes;
  final int totalTaskCount;
  final String taskTitle;

  DailyStats({
    required this.date,
    required this.totalFocusMinutes,
    required this.totalTaskCount,
    required this.taskTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalFocusMinutes': totalFocusMinutes,
      'totalTaskCount': totalTaskCount,
      'taskTitle': taskTitle,
    };
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      date: (map['date'] as Timestamp).toDate(),
      totalFocusMinutes: map['totalFocusMinutes'] ?? 0,
      totalTaskCount: map['totalTaskCount'] ?? 0,
      taskTitle: map['taskTitle'] ?? 'Focus Session',
    );
  }
}

class TimerStatsModel {
  final int grandTotalFocusMinutes;
  final int grandTotalTaskCount;
  final int streak;
  final DateTime? appStartTime; // Reference point for 24-hour cycles
  final List<DailyStats> history;

  TimerStatsModel({
    this.grandTotalFocusMinutes = 0,
    this.grandTotalTaskCount = 0,
    this.streak = 0,
    this.appStartTime,
    this.history = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'grandTotalFocusMinutes': grandTotalFocusMinutes,
      'grandTotalTaskCount': grandTotalTaskCount,
      'streak': streak,
      'appStartTime': appStartTime != null ? Timestamp.fromDate(appStartTime!) : null,
      'history': history.map((h) => h.toMap()).toList(),
    };
  }

  factory TimerStatsModel.fromMap(Map<String, dynamic> map) {
    return TimerStatsModel(
      grandTotalFocusMinutes: map['grandTotalFocusMinutes'] ?? 0,
      grandTotalTaskCount: map['grandTotalTaskCount'] ?? 0,
      streak: map['streak'] ?? 0,
      appStartTime: map['appStartTime'] != null
          ? (map['appStartTime'] as Timestamp).toDate()
          : null,
      history: (map['history'] as List<dynamic>?)
          ?.map((h) => DailyStats.fromMap(h as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}