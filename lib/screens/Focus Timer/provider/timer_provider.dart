// lib/providers/timer_provider.dart

import 'package:flutter/material.dart';
import '../../../models/timer_stats_model.dart';
import '../../../services/firebase_service.dart';

class TimerProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  TimerStatsModel? _stats;
  bool _isLoading = false;
  String? _error;

  // Getters
  TimerStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get streak => _stats?.streak ?? 0;
  int get grandTotalFocusMinutes => _stats?.grandTotalFocusMinutes ?? 0;
  int get grandTotalTaskCount => _stats?.grandTotalTaskCount ?? 0;
  List<DailyStats> get history => _stats?.history ?? [];

  // ─── INITIALIZATION ───

  Future<void> initialize() async {
    await loadStats();
  }

  Future<void> loadStats() async {
    _setLoading(true);
    _error = null;

    try {
      _stats = await _firebaseService.getTimerStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── STATS OPERATIONS ───

  Future<void> recordSession({
    required int focusMinutes,
    required int taskCount,
    required String taskTitle,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final currentStats = await _firebaseService.getTimerStats();

      final updatedStats = _calculateUpdatedStats(
        currentStats: currentStats,
        focusMinutes: focusMinutes,
        taskCount: taskCount,
        taskTitle: taskTitle,
      );

      await _firebaseService.saveTimerStats(updatedStats);
      _stats = updatedStats;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeStats() async {
    try {
      await _firebaseService.initializeTimerStats();
      await loadStats();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<DailyStats?> getDailyStats(DateTime date) async {
    try {
      if (_stats == null) await loadStats();
      return _stats?.history
          .where((s) => _isSameDay(s.date, date))
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  List<DailyStats> getStatsInRange(DateTime start, DateTime end) {
    if (_stats == null) return [];
    return _stats!.history.where((s) {
      return s.date.isAfter(start) && s.date.isBefore(end);
    }).toList();
  }

  Future<DailyStats?> getTodayStats() async {
    return getDailyStats(DateTime.now());
  }

  // ─── STATS CALCULATION LOGIC ───

  TimerStatsModel _calculateUpdatedStats({
    required TimerStatsModel currentStats,
    required int focusMinutes,
    required int taskCount,
    required String taskTitle,
  }) {
    final now = DateTime.now();
    final appStartTime = currentStats.appStartTime ?? now;

    List<DailyStats> updatedHistory = List.from(currentStats.history);

    updatedHistory.add(DailyStats(
      date: now,
      totalFocusMinutes: focusMinutes,
      totalTaskCount: taskCount,
      taskTitle: taskTitle,
    ));

    final newStreak = _calculateStreak(
      currentStats: currentStats,
      history: updatedHistory,
      appStartTime: appStartTime,
    );

    return TimerStatsModel(
      grandTotalFocusMinutes: currentStats.grandTotalFocusMinutes + focusMinutes,
      grandTotalTaskCount: currentStats.grandTotalTaskCount + taskCount,
      streak: newStreak,
      appStartTime: appStartTime,
      history: updatedHistory,
    );
  }

  int _calculateStreak({
    required TimerStatsModel currentStats,
    required List<DailyStats> history,
    required DateTime appStartTime,
  }) {
    if (history.isEmpty) return 1;

    final currentCycle = _calculateCurrentCycle(appStartTime);

    final currentCycleStart = appStartTime.add(Duration(hours: 24 * currentCycle));
    final currentCycleEnd = appStartTime.add(Duration(hours: 24 * (currentCycle + 1)));

    bool hasCurrentCycleActivity = _hasActivityInCycle(history, currentCycleStart, currentCycleEnd);

    if (hasCurrentCycleActivity && currentStats.streak > 0) {
      return currentStats.streak;
    }

    final previousCycleStart = appStartTime.add(Duration(hours: 24 * (currentCycle - 1)));
    final previousCycleEnd = appStartTime.add(Duration(hours: 24 * currentCycle));

    bool hasPreviousCycleActivity = _hasActivityInCycle(history, previousCycleStart, previousCycleEnd);

    if (hasPreviousCycleActivity) {
      if (!hasCurrentCycleActivity) {
        return currentStats.streak + 1;
      } else {
        return currentStats.streak;
      }
    } else {
      return 1;
    }
  }

  int _calculateCurrentCycle(DateTime appStartTime) {
    final now = DateTime.now();
    final difference = now.difference(appStartTime);
    return (difference.inHours / 24).floor();
  }

  bool _hasActivityInCycle(
      List<DailyStats> history,
      DateTime cycleStart,
      DateTime cycleEnd,
      ) {
    for (var stats in history) {
      if (stats.date.isAfter(cycleStart.subtract(const Duration(hours: 1))) &&
          stats.date.isBefore(cycleEnd)) {
        final dayStart = DateTime(stats.date.year, stats.date.month, stats.date.day);
        if (dayStart.isBefore(cycleEnd) &&
            dayStart.add(const Duration(days: 1)).isAfter(cycleStart)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ─── HELPER METHODS ───

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── RESET ───

  void reset() {
    _stats = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}