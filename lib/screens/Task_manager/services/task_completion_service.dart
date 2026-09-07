// lib/screens/TaskManager/services/task_completion_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/data_provider.dart';
import '../../../models/taskmanager_model.dart';
import '../providers/Task_provider.dart';
import 'task_notification_helper.dart';

class TaskCompletionService {
  static TaskCompletionService? _instance;

  // Singleton pattern
  factory TaskCompletionService() {
    _instance ??= TaskCompletionService._internal();
    return _instance!;
  }

  TaskCompletionService._internal();

  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskNotificationHelper _notificationHelper = TaskNotificationHelper();

  // References to providers (set via initialize)
  DataProvider? _dataProvider;
  TaskProvider? _taskProvider;

  // Timer for auto-complete checks
  Timer? _autoCompleteTimer;
  bool _isRunning = false;
  bool _isInitialized = false;

  // Callback to update UI
  Function(List<Task>)? _onTasksUpdated;

  /// Initialize the service with providers
  Future<void> initialize({
    required DataProvider dataProvider,
    required TaskProvider taskProvider,
    Function(List<Task>)? onTasksUpdated,
  }) async {
    if (_isInitialized) return;

    _dataProvider = dataProvider;
    _taskProvider = taskProvider;
    _onTasksUpdated = onTasksUpdated;
    await _notificationHelper.initialize();

    _isInitialized = true;
    debugPrint('✅ TaskCompletionService initialized with DataProvider and TaskProvider');

    // Start auto-complete timer
    startAutoCompleteTimer();
  }

  // ============================================================
  // AUTO-COMPLETE TIMER
  // ============================================================

  /// Start auto-complete timer (runs every 10 minutes)
  void startAutoCompleteTimer() {
    _stopAutoCompleteTimer();

    // Run immediately on start
    _checkAndAutoCompleteTasks();

    // Then run every 1 minute for faster response
    _autoCompleteTimer = Timer.periodic(
      const Duration(minutes: 1),
          (timer) => _checkAndAutoCompleteTasks(),
    );

    debugPrint('⏰ Auto-complete timer started (runs every 1 minute)');
  }

  /// Stop auto-complete timer
  void _stopAutoCompleteTimer() {
    _autoCompleteTimer?.cancel();
    _autoCompleteTimer = null;
    _isRunning = false;
    debugPrint('⏰ Auto-complete timer stopped');
  }

  /// Check and auto-complete tasks
  Future<void> _checkAndAutoCompleteTasks() async {
    // Prevent multiple concurrent runs
    if (_isRunning) return;
    _isRunning = true;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isRunning = false;
        return;
      }

      // Check if providers are available
      if (_dataProvider == null || _taskProvider == null) {
        debugPrint('❌ Providers not available for auto-complete');
        _isRunning = false;
        return;
      }

      final now = getBangladeshTime();
      debugPrint('🔍 Checking auto-complete at: ${now.toLocal()}');

      // ✅ Get tasks from DataProvider
      final tasks = _dataProvider!.tasks;

      if (tasks.isEmpty) {
        debugPrint('📋 No tasks to check for auto-complete');
        _isRunning = false;
        return;
      }

      // Find tasks that need auto-completion (classes and exams)
      final tasksToComplete = tasks.where((task) {
        return !task.isDone && _shouldAutoComplete(task, now);
      }).toList();

      if (tasksToComplete.isEmpty) {
        debugPrint('ℹ️ No tasks need auto-completion at this time');
        _isRunning = false;
        return;
      }

      debugPrint('✅ Found ${tasksToComplete.length} tasks to auto-complete');

      int autoCompletedCount = 0;

      // Auto-complete each task
      for (final task in tasksToComplete) {
        final result = await _completeTask(task, isAuto: true);
        if (result) {
          autoCompletedCount++;
        }
      }

      // ✅ Process extension tasks (assignment, lab report, others)
      final extensionTasks = tasks.where((task) {
        return !task.isDone && _shouldExtendDeadline(task, now);
      }).toList();

      int extendedCount = 0;
      for (final task in extensionTasks) {
        final result = await _extendDeadlineAndNotify(task);
        if (result) {
          extendedCount++;
        }
      }

      if (autoCompletedCount > 0 || extendedCount > 0) {
        debugPrint('✅ Auto-completed: $autoCompletedCount, Extended: $extendedCount');

        // ✅ Notify DataProvider to refresh stats
        await _dataProvider!.updateTaskStats();

        // ✅ Update TaskProvider with fresh data
        _taskProvider!.setTasks(_dataProvider!.tasks);

        // Notify UI about updates
        _notifyTasksUpdated();

        // Send daily summary if multiple tasks completed
        if (autoCompletedCount > 1 || extendedCount > 1) {
          await _sendDailySummary();
        }
      }

    } catch (e) {
      debugPrint('❌ Error in auto-complete check: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// Schedule notifications for a task
  Future<void> scheduleNotificationsForTask(Task task) async {
    try {
      // Schedule reminder notifications
      await _notificationHelper.scheduleTaskNotifications(task);

      // Schedule overdue reminders if needed
      if (task.isOverdue && !task.isDone) {
        await _notificationHelper.scheduleOverdueReminders(task);
      }
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
    }
  }

  /// Check if a task should be auto-completed
  bool _shouldAutoComplete(Task task, DateTime now) {
    // Already done? Skip
    if (task.isDone) return false;

    // Convert current time to UTC for consistent comparison
    final nowUtc = now.toUtc();

    // Check based on task type
    switch (task.type) {
      case TaskType.classes:
      // Classes: Auto-complete when endTime is passed
        if (task.endTime != null) {
          // Ensure both times are in UTC for comparison
          final taskEndTimeUtc = task.endTime!.toUtc();
          return nowUtc.isAfter(taskEndTimeUtc);
        }
        // If no endTime, use date + 23:59
        final endOfDay = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          23,
          59,
        ).toUtc();
        return nowUtc.isAfter(endOfDay);

      case TaskType.exam:
      // Exam: Auto-complete when endTime is passed (not startTime)
        if (task.endTime != null) {
          final taskEndTimeUtc = task.endTime!.toUtc();
          return nowUtc.isAfter(taskEndTimeUtc);
        }
        // If no endTime, use date + 23:59
        final endOfExamDay = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          23,
          59,
        ).toUtc();
        return nowUtc.isAfter(endOfExamDay);

      case TaskType.assignment:
      case TaskType.labReport:
      case TaskType.others:
      // These types should be extended, not auto-completed
        return false;

      default:
        return false;
    }
  }

  /// Check if a task should have its deadline extended
  bool _shouldExtendDeadline(Task task, DateTime now) {
    // Already done? Skip
    if (task.isDone) return false;

    // Only for types with deadlines
    if (!task.type.hasDeadline) return false;

    // Check deadline
    final deadline = task.deadline;
    if (deadline == null) return false;

    // Extend if deadline is passed (using UTC for consistent comparison)
    final nowUtc = now.toUtc();
    final deadlineUtc = deadline.toUtc();
    return nowUtc.isAfter(deadlineUtc);
  }

  /// Complete a single task
  Future<bool> _completeTask(Task task, {bool isAuto = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (task.id == null || task.id!.isEmpty) {
        debugPrint('❌ Task ID is null for "${task.displayTitle}"');
        return false;
      }

      if (_taskProvider == null) {
        debugPrint('❌ TaskProvider not available');
        return false;
      }

      final mode = isAuto ? 'Auto-completing' : 'Completing';
      debugPrint('✅ $mode: "${task.displayTitle}" (${task.type.label})');

      final now = getBangladeshTime(); // Use Bangladesh time

      // ✅ Create updated task directly instead of using toggleTaskDone
      Task updatedTask = task.copyWith(
        isDone: true,
        completedAt: now,
        autoCompleted: isAuto,
        autoCompletedAt: isAuto ? now : null,
        autoCompletionSource: isAuto ? 'system' : 'manual',
        updatedAt: now,
      );

      // Update in Firestore
      await _taskProvider!.updateTask(updatedTask);

      // ✅ Update DataProvider's cache
      _dataProvider?.refreshTasks();

      // Send completion notification
      final message = isAuto
          ? '🎉 "${task.displayTitle}" auto-completed!'
          : '🎉 "${task.displayTitle}" completed!';

      await _notificationHelper.sendTaskCompletionNotification(
        task: updatedTask,
        message: message,
      );
      debugPrint('📬 Completion notification sent for "${task.displayTitle}"');

      return true;

    } catch (e) {
      debugPrint('❌ Error completing "${task.displayTitle}": $e');
      return false;
    }
  }

  /// Extend deadline and send notification
  Future<bool> _extendDeadlineAndNotify(Task task) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (task.id == null || task.id!.isEmpty) {
        debugPrint('❌ Task ID is null for "${task.displayTitle}"');
        return false;
      }

      if (_taskProvider == null) {
        debugPrint('❌ TaskProvider not available');
        return false;
      }

      final now = getBangladeshTime();

      // ✅ Extend deadline using TaskProvider
      final extendedTask = task.extendDeadlineWithHistory();
      await _taskProvider!.updateTask(extendedTask);

      // ✅ Update DataProvider's cache
      _dataProvider?.refreshTasks();

      // Send deadline extension notification
      await _notificationHelper.sendDeadlineExtensionNotification(
        task: extendedTask,
        message: '⏰ Deadline extended for "${task.displayTitle}"!',
      );
      debugPrint('📬 Deadline extension notification sent for "${task.displayTitle}"');

      // Schedule 1-hour interval reminders until new deadline
      await _scheduleHourlyReminders(extendedTask);

      return true;

    } catch (e) {
      debugPrint('❌ Error extending deadline for "${task.displayTitle}": $e');
      return false;
    }
  }

  // ============================================================
  // HOURLY REMINDERS FOR EXTENDED DEADLINES
  // ============================================================

  /// Schedule hourly reminders until the new deadline
  Future<void> _scheduleHourlyReminders(Task task) async {
    if (task.deadline == null) return;

    final now = getBangladeshTime();
    final deadline = task.deadline!;

    // Only schedule if deadline is in the future
    if (deadline.isBefore(now)) return;

    // Calculate time until deadline
    final timeUntilDeadline = deadline.difference(now);
    final hoursUntilDeadline = timeUntilDeadline.inHours;

    // Schedule reminders every hour, but limit to prevent too many
    final maxReminders = hoursUntilDeadline.clamp(1, 24);

    for (int i = 1; i <= maxReminders; i++) {
      final reminderTime = now.add(Duration(hours: i));

      // Skip if past deadline
      if (reminderTime.isAfter(deadline)) break;

      // Use a unique ID for each reminder
      final notificationId = (task.id.hashCode + i).abs();

      await _notificationHelper.scheduleHourlyReminder(
        task: task,
        hour: i,
        totalHours: hoursUntilDeadline,
        notificationId: notificationId,
        scheduledTime: reminderTime,
      );
    }

    debugPrint('📬 Scheduled $maxReminders hourly reminders for "${task.displayTitle}"');
  }

  // ============================================================
  // MANUAL COMPLETE / UNCOMPLETE (Called from UI)
  // ============================================================

  /// Complete a task manually (called from UI)
  Future<bool> completeTaskManually(Task task) async {
    final success = await _completeTask(task, isAuto: false);
    if (success) {
      // ✅ Update stats via DataProvider
      await _dataProvider?.updateTaskStats();
      // ✅ Update TaskProvider
      _taskProvider?.setTasks(_dataProvider?.tasks ?? []);
      _notifyTasksUpdated();
    }
    return success;
  }

  /// Uncomplete a task (undo completion)
  Future<bool> uncompleteTask(Task task) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (task.id == null || task.id!.isEmpty) {
        debugPrint('❌ Task ID is null for "${task.displayTitle}"');
        return false;
      }

      if (_taskProvider == null) {
        debugPrint('❌ TaskProvider not available');
        return false;
      }

      debugPrint('🔄 Uncompleting: "${task.displayTitle}" (${task.type.label})');

      final now = getBangladeshTime();

      // Create updated task
      Task updatedTask = task.copyWith(
        isDone: false,
        completedAt: null,
        autoCompleted: false,
        autoCompletedAt: null,
        autoCompletionSource: null,
        updatedAt: now,
      );

      // Update in Firestore
      await _taskProvider!.updateTask(updatedTask);

      // ✅ Update DataProvider's cache
      _dataProvider?.refreshTasks();

      // ✅ Update stats via DataProvider
      await _dataProvider?.updateTaskStats();

      // Notify UI
      _notifyTasksUpdated();

      return true;

    } catch (e) {
      debugPrint('❌ Error uncompleting "${task.displayTitle}": $e');
      return false;
    }
  }

  // ============================================================
  // GET BANGLADESH TIME
  // ============================================================

  /// Get current Bangladesh Time (UTC+6)
  DateTime getBangladeshTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 6));
  }

  // ============================================================
  // BATCH OPERATIONS
  // ============================================================

  /// Complete all overdue tasks
  Future<int> completeAllOverdueTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      if (_dataProvider == null || _taskProvider == null) {
        debugPrint('❌ Providers not available');
        return 0;
      }

      final tasks = _dataProvider!.tasks;
      final now = getBangladeshTime();

      final overdueTasks = tasks.where((task) {
        return !task.isDone && _shouldAutoComplete(task, now);
      }).toList();

      if (overdueTasks.isEmpty) {
        debugPrint('ℹ️ No overdue tasks to complete');
        return 0;
      }

      debugPrint('📋 Completing ${overdueTasks.length} overdue tasks');

      int completedCount = 0;
      for (final task in overdueTasks) {
        final success = await _completeTask(task, isAuto: true);
        if (success) completedCount++;
      }

      if (completedCount > 0) {
        await _dataProvider!.updateTaskStats();
        _taskProvider!.setTasks(_dataProvider!.tasks);
        _notifyTasksUpdated();
        await _sendDailySummary();
      }

      return completedCount;

    } catch (e) {
      debugPrint('❌ Error completing all overdue tasks: $e');
      return 0;
    }
  }

  /// Run all checks (auto-complete and deadline extensions)
  Future<void> runAllChecks() async {
    await _checkAndAutoCompleteTasks();
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  /// Send daily summary notification
  Future<void> _sendDailySummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (_dataProvider == null) {
        debugPrint('❌ DataProvider not available for daily summary');
        return;
      }

      final tasks = _dataProvider!.tasks;

      await _notificationHelper.sendDailySummaryNotification(
        tasks: tasks,
        message: '📊 Today\'s Task Summary',
      );
      debugPrint('📬 Daily summary notification sent');

    } catch (e) {
      debugPrint('❌ Error sending daily summary: $e');
    }
  }

  /// Send daily summary manually (called from UI)
  Future<void> sendDailySummaryManually() async {
    await _sendDailySummary();
  }

  /// Notify UI about task updates
  void _notifyTasksUpdated() {
    if (_onTasksUpdated != null && _dataProvider != null) {
      _onTasksUpdated!(_dataProvider!.tasks);
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Dispose the service
  void dispose() {
    _stopAutoCompleteTimer();
    _isInitialized = false;
    _dataProvider = null;
    _taskProvider = null;
    debugPrint('🗑️ TaskCompletionService disposed');
  }

  /// Reset the service
  void reset() {
    _stopAutoCompleteTimer();
    _isRunning = false;
    _isInitialized = false;
    _dataProvider = null;
    _taskProvider = null;
    _onTasksUpdated = null;
    debugPrint('🔄 TaskCompletionService reset');
  }
}