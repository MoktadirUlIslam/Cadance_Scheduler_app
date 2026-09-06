// lib/screens/TaskManager/services/task_completion_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/taskmanager_model.dart';
import 'TaskManagerStatsService.dart' hide TaskFirestoreService;
import 'task_firestore_service.dart';
import 'task_notification_helper.dart';

class TaskCompletionService {
  final TaskFirestoreService _taskService = TaskFirestoreService();
  final TaskNotificationHelper _notificationHelper = TaskNotificationHelper();
  Timer? _periodicTimer;
  bool _isRunning = false;
  bool _isInitialized = false;

  // ✅ FIXED: Use lazy getter
  TaskManagerStatsService? _statsService;
  TaskManagerStatsService get statsService {
    _statsService ??= TaskManagerStatsService();
    return _statsService!;
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _notificationHelper.initialize();
      await statsService.initializeStats();
      _isInitialized = true;
      print('✅ TaskCompletionService initialized');
    } catch (e) {
      print('❌ Error initializing TaskCompletionService: $e');
    }
  }

  /// Start the auto-completion service with periodic checks
  void startAutoCompletion({Duration interval = const Duration(minutes: 5)}) {
    if (_periodicTimer != null) {
      print('⚠️ Auto-completion service already running');
      return;
    }

    print('🚀 Starting auto-completion service...');

    // Initialize first
    initialize().then((_) {
      // Run immediately
      runAllChecks();

      // Then run periodically
      _periodicTimer = Timer.periodic(interval, (timer) {
        runAllChecks();
      });

      print('✅ Auto-completion service started (interval: ${interval.inMinutes} minutes)');
    });
  }

  /// Stop the auto-completion service
  void stopAutoCompletion() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    print('⏹️ Auto-completion service stopped');
  }

  /// Check and auto-complete classes after end time
  Future<void> checkAndCompleteClasses() async {
    if (_isRunning) {
      print('⚠️ Class completion check already in progress');
      return;
    }

    try {
      _isRunning = true;
      final now = DateTime.now();
      print('🔍 Running auto-completion check at: ${_formatDateTime(now)}');

      // ✅ FIXED: Get ALL tasks with proper error handling
      final allTasks = await _taskService.getTasks().first;
      print('📊 Total tasks retrieved: ${allTasks.length}');

      if (allTasks.isEmpty) {
        print('ℹ️ No tasks found');
        _isRunning = false;
        return;
      }

      // Filter for classes that are not done yet
      final pendingClasses = allTasks.where((task) =>
      task.type == TaskType.classes &&
          !task.isDone
      ).toList();

      print('📊 Found ${pendingClasses.length} pending classes');

      if (pendingClasses.isEmpty) {
        print('ℹ️ No pending classes to check');
        _isRunning = false;
        return;
      }

      int completedCount = 0;

      for (var task in pendingClasses) {
        print('\n━━━ Checking class: ${task.displayTitle} ━━━');

        if (task.endTime == null) {
          print('   ⚠️ No end time set');
          continue;
        }

        final endTime = task.endTime!;
        print('   📅 Date: ${_formatDate(endTime)}');
        print('   ⏰ End time: ${_formatTime(endTime)}');
        print('   ⏰ Current: ${_formatTime(now)}');

        // Check if end time has passed
        final isOver = now.isAfter(endTime);
        print('   🔄 Is end time passed? $isOver');

        if (isOver) {
          print('   ✅ Class should be auto-completed!');

          // Check if it's within the same day
          final isSameDay = _isSameDay(now, endTime);

          if (isSameDay) {
            print('   📅 Same day class - auto-completing');
          } else {
            print('   📅 Class from previous day - auto-completing');
          }

          final updatedTask = task.copyWith(
            isDone: true,
            completedAt: now,
            updatedAt: now,
          );

          try {
            await _taskService.updateTask(updatedTask);
            completedCount++;
            print('✅ Auto-completed class: ${task.displayTitle}');

            // Send notification about auto-completion
            await _notificationHelper.sendTaskCompletionNotification(
              task: updatedTask,
              message: '🎓 Class "${task.displayTitle}" has been automatically marked as completed.',
            );
          } catch (e) {
            print('❌ Failed to update task: $e');
          }
        } else {
          final timeLeft = endTime.difference(now);
          print('   ⏱️ Time left: ${timeLeft.inMinutes} minutes');
        }
      }

      if (completedCount > 0) {
        print('✅ Auto-completed $completedCount classes');
      } else {
        print('ℹ️ No classes to auto-complete at this time');
      }
    } catch (e) {
      print('❌ Error checking class completion: $e');
      print('📋 Stack trace: ${StackTrace.current}');
    } finally {
      _isRunning = false;
    }
  }

  /// Check and extend deadlines for overdue tasks
  Future<void> checkAndExtendDeadlines() async {
    if (_isRunning) {
      print('⚠️ Deadline check already in progress');
      return;
    }

    try {
      _isRunning = true;
      final now = DateTime.now();
      print('🔍 Running deadline check at: ${_formatDateTime(now)}');

      // ✅ FIXED: Get ALL tasks with proper error handling
      final allTasks = await _taskService.getTasks().first;
      print('📊 Total tasks retrieved: ${allTasks.length}');

      if (allTasks.isEmpty) {
        print('ℹ️ No tasks found');
        _isRunning = false;
        return;
      }

      // Filter for overdue tasks that are not done yet and have deadlines
      final overdueTasks = allTasks.where((task) =>
      !task.isDone &&
          task.deadline != null &&
          now.isAfter(task.deadline!)
      ).toList();

      print('📊 Found ${overdueTasks.length} overdue tasks');

      if (overdueTasks.isEmpty) {
        print('ℹ️ No overdue tasks to process');
        _isRunning = false;
        return;
      }

      int extendedCount = 0;

      for (var task in overdueTasks) {
        print('\n━━━ Checking overdue task: ${task.displayTitle} ━━━');
        print('   📅 Deadline: ${_formatDateTime(task.deadline!)}');
        print('   📋 Type: ${task.type.label}');

        // Only extend deadlines for Assignment, Lab Report, and Others
        if (task.type == TaskType.assignment ||
            task.type == TaskType.labReport ||
            task.type == TaskType.others) {

          DateTime newDeadline;
          String message;

          switch (task.type) {
            case TaskType.assignment:
            case TaskType.labReport:
              newDeadline = task.deadline!.add(const Duration(days: 1));
              message = '⏰ You have missed your ${task.type.label} deadline! Please submit your ${task.type.label} as soon as possible.';
              break;

            case TaskType.others:
              newDeadline = task.deadline!.add(const Duration(hours: 5));
              message = '⏰ You have missed your ${task.type.label} deadline! Please complete your task as soon as possible.';
              break;

            default:
              continue;
          }

          // Update task with new deadline
          final updatedTask = task.copyWith(
            deadline: newDeadline,
            updatedAt: now,
          );

          try {
            await _taskService.updateTask(updatedTask);
            extendedCount++;
            print('✅ Extended deadline for ${task.type.label}: ${task.displayTitle}');
            print('   📅 New deadline: ${_formatDateTime(newDeadline)}');

            // Send notification about deadline extension
            await _notificationHelper.sendDeadlineExtensionNotification(
              task: updatedTask,
              message: message,
            );

            // Schedule new notifications for the extended deadline
            await _notificationHelper.scheduleTaskNotifications(updatedTask);
          } catch (e) {
            print('❌ Failed to extend deadline: $e');
          }
        } else {
          print('   ⏭️ Skipping deadline extension for ${task.type.label} (not supported)');
        }
      }

      if (extendedCount > 0) {
        print('✅ Extended deadlines for $extendedCount tasks');
      } else {
        print('ℹ️ No deadlines to extend at this time');
      }
    } catch (e) {
      print('❌ Error checking deadline extensions: $e');
      print('📋 Stack trace: ${StackTrace.current}');
    } finally {
      _isRunning = false;
    }
  }

  /// Toggle task completion status (manual toggle)
  Future<Task?> toggleTaskCompletion(Task task) async {
    try {
      final now = DateTime.now();
      print('🔄 Toggling completion for: ${task.displayTitle}');

      // If marking as done, check if it's overdue
      if (!task.isDone) {
        // Check if task has a deadline and is overdue
        if (task.deadline != null && now.isAfter(task.deadline!)) {
          // For overdue assignments/lab reports, extend deadline before marking done
          if (task.type == TaskType.assignment || task.type == TaskType.labReport) {
            final newDeadline = now.add(const Duration(days: 1));
            final updatedTask = task.copyWith(
              isDone: true,
              deadline: newDeadline,
              completedAt: now,
              updatedAt: now,
            );

            final result = await _taskService.updateTask(updatedTask);

            // Send notification about auto-extension
            await _notificationHelper.sendDeadlineExtensionNotification(
              task: result,
              message: '⚠️ Deadline extended by 1 day for submitting your ${task.type.label}!',
            );

            // Send completion notification
            await _notificationHelper.sendTaskCompletionNotification(
              task: result,
              message: '✅ ${task.type.label} "${task.displayTitle}" has been submitted!',
            );

            print('✅ Extended deadline and marked done for overdue ${task.type.label}: ${task.displayTitle}');
            return result;
          }

          // For others, extend by 5 hours
          if (task.type == TaskType.others) {
            final newDeadline = now.add(const Duration(hours: 5));
            final updatedTask = task.copyWith(
              isDone: true,
              deadline: newDeadline,
              completedAt: now,
              updatedAt: now,
            );

            final result = await _taskService.updateTask(updatedTask);

            await _notificationHelper.sendDeadlineExtensionNotification(
              task: result,
              message: '⚠️ Deadline extended by 5 hours! Complete your task now!',
            );

            await _notificationHelper.sendTaskCompletionNotification(
              task: result,
              message: '✅ Task "${task.displayTitle}" has been completed!',
            );

            print('✅ Extended deadline and marked done for overdue task: ${task.displayTitle}');
            return result;
          }
        }

        // Check if it's a class that should be auto-completed
        if (task.type == TaskType.classes && task.endTime != null && now.isAfter(task.endTime!)) {
          // Already overdue, just mark as done
          final updatedTask = task.copyWith(
            isDone: true,
            completedAt: now,
            updatedAt: now,
          );

          final result = await _taskService.updateTask(updatedTask);

          await _notificationHelper.sendTaskCompletionNotification(
            task: result,
            message: '✅ Class "${task.displayTitle}" has been marked as completed!',
          );

          print('✅ Marked overdue class as done: ${task.displayTitle}');
          return result;
        }

        // Normal completion (not overdue)
        final updatedTask = task.copyWith(
          isDone: true,
          completedAt: now,
          updatedAt: now,
        );

        final result = await _taskService.updateTask(updatedTask);

        // Send completion notification
        final completionMessage = task.type == TaskType.assignment
            ? '✅ Assignment "${task.displayTitle}" has been submitted!'
            : task.type == TaskType.classes
            ? '✅ Class "${task.displayTitle}" has been marked as completed!'
            : '✅ Task "${task.displayTitle}" has been completed!';

        await _notificationHelper.sendTaskCompletionNotification(
          task: result,
          message: completionMessage,
        );

        print('✅ Marked task as done: ${task.displayTitle}');
        return result;
      } else {
        // Mark as pending (undo completion)
        final updatedTask = task.copyWith(
          isDone: false,
          completedAt: null,
          updatedAt: now,
        );

        final result = await _taskService.updateTask(updatedTask);

        // Send notification about undo
        await _notificationHelper.sendTaskCompletionNotification(
          task: result,
          message: '⏳ "${task.displayTitle}" has been marked as pending again.',
        );

        print('✅ Marked task as pending: ${task.displayTitle}');
        return result;
      }
    } catch (e) {
      print('❌ Error toggling task completion: $e');
      print('📋 Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Run all checks (call this periodically)
  Future<void> runAllChecks() async {
    try {
      print('🔄 Running all completion checks...');
      await checkAndCompleteClasses();
      await checkAndExtendDeadlines();
      print('✅ All completion checks completed');
    } catch (e) {
      print('❌ Error running all checks: $e');
      print('📋 Stack trace: ${StackTrace.current}');
    }
  }

  /// Manual check for a specific task
  Future<Task?> checkAndCompleteSingleTask(Task task) async {
    try {
      final now = DateTime.now();

      // Only process if it's a class and not done yet
      if (task.type == TaskType.classes && !task.isDone) {
        if (task.endTime != null && now.isAfter(task.endTime!)) {
          final updatedTask = task.copyWith(
            isDone: true,
            completedAt: now,
            updatedAt: now,
          );

          final result = await _taskService.updateTask(updatedTask);
          print('✅ Manually completed class: ${task.displayTitle}');

          await _notificationHelper.sendTaskCompletionNotification(
            task: result,
            message: '✅ Class "${task.displayTitle}" has been marked as completed!',
          );

          return result;
        }
      }
      return task;
    } catch (e) {
      print('❌ Error checking single task: $e');
      return null;
    }
  }

  /// Mark a task as done manually (without deadline extension logic)
  Future<Task?> markTaskAsDone(Task task) async {
    try {
      final now = DateTime.now();
      final updatedTask = task.copyWith(
        isDone: true,
        completedAt: now,
        updatedAt: now,
      );

      final result = await _taskService.updateTask(updatedTask);

      await _notificationHelper.sendTaskCompletionNotification(
        task: result,
        message: '✅ "${task.displayTitle}" has been marked as done!',
      );

      print('✅ Marked task as done: ${task.displayTitle}');
      return result;
    } catch (e) {
      print('❌ Error marking task as done: $e');
      return null;
    }
  }

  /// Mark a task as pending (undo completion)
  Future<Task?> markTaskAsPending(Task task) async {
    try {
      final updatedTask = task.copyWith(
        isDone: false,
        completedAt: null,
        updatedAt: DateTime.now(),
      );

      final result = await _taskService.updateTask(updatedTask);

      await _notificationHelper.sendTaskCompletionNotification(
        task: result,
        message: '⏳ "${task.displayTitle}" has been marked as pending.',
      );

      print('✅ Marked task as pending: ${task.displayTitle}');
      return result;
    } catch (e) {
      print('❌ Error marking task as pending: $e');
      return null;
    }
  }

  /// Auto-extend deadline for a specific task
  Future<Task?> extendDeadline(Task task, {Duration? duration}) async {
    try {
      final extensionDuration = duration ?? task.extensionDuration;
      final newDeadline = (task.deadline ?? DateTime.now()).add(extensionDuration);

      final updatedTask = task.copyWith(
        deadline: newDeadline,
        updatedAt: DateTime.now(),
      );

      final result = await _taskService.updateTask(updatedTask);

      await _notificationHelper.sendDeadlineExtensionNotification(
        task: result,
        message: '⏰ Deadline extended by ${extensionDuration.inDays} days! Please complete your task.',
      );

      print('✅ Extended deadline for ${task.displayTitle} by ${extensionDuration.inDays} days');
      return result;
    } catch (e) {
      print('❌ Error extending deadline: $e');
      return null;
    }
  }

  /// Get all overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    try {
      final allTasks = await _taskService.getTasks().first;
      final now = DateTime.now();
      return allTasks.where((task) =>
      !task.isDone &&
          (task.isOverdue || (task.deadline != null && now.isAfter(task.deadline!)))
      ).toList();
    } catch (e) {
      print('❌ Error getting overdue tasks: $e');
      return [];
    }
  }

  /// Get all pending tasks
  Future<List<Task>> getPendingTasks() async {
    try {
      final allTasks = await _taskService.getTasks().first;
      return allTasks.where((task) => !task.isDone).toList();
    } catch (e) {
      print('❌ Error getting pending tasks: $e');
      return [];
    }
  }

  /// Get all completed tasks
  Future<List<Task>> getCompletedTasks() async {
    try {
      final allTasks = await _taskService.getTasks().first;
      return allTasks.where((task) => task.isDone).toList();
    } catch (e) {
      print('❌ Error getting completed tasks: $e');
      return [];
    }
  }

  /// Get completion statistics
  Future<Map<String, dynamic>> getCompletionStats() async {
    try {
      final allTasks = await _taskService.getTasks().first;
      final total = allTasks.length;
      final completed = allTasks.where((t) => t.isDone).length;
      final pending = total - completed;
      final overdue = allTasks.where((t) => !t.isDone && t.isOverdue).length;

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
        'completionRate': total == 0 ? 0.0 : (completed / total * 100).toStringAsFixed(1),
      };
    } catch (e) {
      print('❌ Error getting completion stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'overdue': 0,
        'completionRate': 0.0,
      };
    }
  }

  // Helper methods
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}