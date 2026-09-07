// lib/providers/timer_provider.dart

import 'package:flutter/material.dart';
import '../../../models/timer_stats_model.dart';
import '../../../services/firebase_service.dart';
import 'dart:async';

class TimerProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  TimerStatsModel? _stats;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Cache for today's stats to reduce Firebase calls
  DailyStats? _cachedTodayStats;
  DateTime? _cacheDate;

  // Getters
  TimerStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  int get streak => _stats?.streak ?? 0;
  int get grandTotalFocusMinutes => _stats?.grandTotalFocusMinutes ?? 0;
  int get grandTotalTaskCount => _stats?.grandTotalTaskCount ?? 0;
  List<DailyStats> get history => _stats?.history ?? [];

  // Today's stats with caching
  int get todayFocusMinutes {
    if (_cachedTodayStats != null && _cacheDate != null && _isSameDay(_cacheDate!, DateTime.now())) {
      return _cachedTodayStats!.totalFocusMinutes;
    }
    return 0;
  }

  int get todayTaskCount {
    if (_cachedTodayStats != null && _cacheDate != null && _isSameDay(_cacheDate!, DateTime.now())) {
      return _cachedTodayStats!.totalTaskCount;
    }
    return 0;
  }

  // ─── INITIALIZATION ───

  Future<void> initialize() async {
    if (_isInitialized) return;
    await loadStats();
    _isInitialized = true;
  }

  Future<void> loadStats() async {
    _setLoading(true);
    _error = null;

    try {
      _stats = await _firebaseService.getTimerStats();
      _cacheTodayStats();
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }

  // ─── CACHE MANAGEMENT ───

  void _cacheTodayStats() {
    if (_stats != null) {
      final now = DateTime.now();
      _cachedTodayStats = _stats!.history
          .where((s) => _isSameDay(s.date, now))
          .firstOrNull;
      _cacheDate = now;
    }
  }

  // ─── STATS OPERATIONS ───

  Future<void> recordSession({
    required int focusMinutes,
    required int taskCount,
    required String taskTitle,
  }) async {
    if (focusMinutes <= 0) {
      print('⚠️ Cannot record session with 0 minutes');
      return;
    }

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
      _cacheTodayStats();

      print('✅ Session recorded: ${focusMinutes}min - $taskTitle');
    } catch (e) {
      _error = e.toString();
      print('❌ Error recording session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeStats() async {
    try {
      await _firebaseService.initializeTimerStats();
      await loadStats();
      _isInitialized = true;
      print('✅ Timer stats initialized');
    } catch (e) {
      _error = e.toString();
      print('❌ Error initializing stats: $e');
      rethrow;
    }
  }

  Future<DailyStats?> getDailyStats(DateTime date) async {
    try {
      // Check cache first
      if (_cachedTodayStats != null &&
          _cacheDate != null &&
          _isSameDay(_cacheDate!, date)) {
        return _cachedTodayStats;
      }

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

  // ─── WEEKLY STATS ───

  int getWeekFocusMinutes() {
    if (_stats == null) return 0;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _stats!.history
        .where((s) => s.date.isAfter(weekStart) && s.date.isBefore(weekEnd))
        .fold(0, (sum, s) => sum + s.totalFocusMinutes);
  }

  int getMonthFocusMinutes() {
    if (_stats == null) return 0;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    return _stats!.history
        .where((s) => s.date.isAfter(monthStart) && s.date.isBefore(monthEnd))
        .fold(0, (sum, s) => sum + s.totalFocusMinutes);
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

    // Check if we already have stats for today
    final existingTodayIndex = updatedHistory.indexWhere(
            (s) => _isSameDay(s.date, now)
    );

    if (existingTodayIndex != -1) {
      // Update existing today's stats
      final existing = updatedHistory[existingTodayIndex];
      updatedHistory[existingTodayIndex] = DailyStats(
        date: now,
        totalFocusMinutes: existing.totalFocusMinutes + focusMinutes,
        totalTaskCount: existing.totalTaskCount + taskCount,
        taskTitle: existing.taskTitle,
      );
    } else {
      // Add new entry for today
      updatedHistory.add(DailyStats(
        date: now,
        totalFocusMinutes: focusMinutes,
        totalTaskCount: taskCount,
        taskTitle: taskTitle,
      ));
    }

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

    // Sort history by date
    final sortedHistory = List<DailyStats>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate consecutive days with activity
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Check from today backwards
    while (true) {
      final dayStats = sortedHistory.where((s) => _isSameDay(s.date, checkDate)).firstOrNull;
      if (dayStats != null && dayStats.totalFocusMinutes > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak > 0 ? streak : 1;
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
    _isInitialized = false;
    _cachedTodayStats = null;
    _cacheDate = null;
    notifyListeners();
  }

  // ─── DISPOSE ───

  @override
  void dispose() {
    _stats = null;
    _cachedTodayStats = null;
    _cacheDate = null;
    super.dispose();
  }
}