// lib/screens/TaskManager/services/task_notification_helper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';
import '../../../services/notification_service.dart';
import '../../../utilites/app_colors.dart';

class TaskNotificationHelper {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  bool _isInitializing = false;

  // ============================================================
  // HELPER: Clamp to 32-bit signed positive integer
  // ============================================================
  int _clampId(int id) => id.abs() & 0x7FFFFFFF;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    _isInitializing = true;
    try {
      await _notificationService.initialize();
      _isInitialized = true;
      print('✅ TaskNotificationHelper initialized');
    } catch (e) {
      print('⚠️ NotificationService initialization failed: $e');
    } finally {
      _isInitializing = false;
    }
  }

  bool get isAvailable => _isInitialized;

  // ============================================================
  // SCHEDULE TASK NOTIFICATIONS
  // ============================================================

  Future<void> scheduleTaskNotifications(Task task) async {
    try {
      if (!task.alarmOn) {
        print('🔕 Notifications disabled for "${task.displayTitle}"');
        return;
      }

      await initialize();
      if (!_isInitialized) {
        print('⚠️ Notifications not available');
        return;
      }

      List<ReminderOption> reminders = List.from(task.reminders);
      if (reminders.isEmpty) {
        reminders = [ReminderOption.oneDay, ReminderOption.twoHours];
      }

      DateTime? baseTime;

      if (task.type == TaskType.assignment) {
        baseTime = task.deadline;
        if (!reminders.contains(ReminderOption.twoDays)) {
          reminders.add(ReminderOption.twoDays);
        }
      } else if (task.type == TaskType.labReport) {
        baseTime = task.deadline ?? task.date;
      } else {
        baseTime = task.startTime ?? task.date;
      }

      if (baseTime == null) {
        print('⚠️ No base time for "${task.displayTitle}"');
        return;
      }

      print('📅 Scheduling notifications for "${task.displayTitle}"');
      print('   Base time: $baseTime');
      print('   Task type: ${task.type.label}');
      print('   Reminders: ${reminders.map((r) => r.label).join(', ')}');

      int baseId = task.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
      baseId = _clampId(baseId); // ✅ Clamp to 32-bit

      int scheduledCount = 0;

      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        final notificationTime = baseTime.subtract(reminder.duration);

        if (notificationTime.isAfter(DateTime.now())) {
          final notificationId = _clampId(baseId + i + 1); // ✅ Clamp

          final title = _buildNotificationTitle(task);
          final body = _buildNotificationBody(task);

          await _notificationService.scheduleTaskNotification(
            notificationId: notificationId,
            title: title,
            body: body,
            scheduledTime: notificationTime,
            color: task.typeColor,
          );

          scheduledCount++;
          print('   ✅ Scheduled #${i + 1}: ${reminder.label} at $notificationTime');
        } else {
          print('   ⏭️ Skipping ${reminder.label} (already passed)');
        }
      }

      print('✅ Scheduled $scheduledCount notifications for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
    }
  }

  // ============================================================
  // CANCEL TASK NOTIFICATIONS
  // ============================================================

  Future<void> cancelTaskNotifications(String taskId) async {
    try {
      await initialize();
      if (!_isInitialized) return;

      final pending = await _notificationService.getPendingNotifications();

      final taskIdHash = _clampId(taskId.hashCode); // ✅ Clamp

      int cancelledCount = 0;
      for (final notification in pending) {
        for (int i = 1; i <= 10; i++) {
          final expectedId = _clampId(taskIdHash + i); // ✅ Clamp
          if (notification.id == expectedId) {
            await _notificationService.cancelNotification(notification.id);
            cancelledCount++;
            break;
          }
        }
      }

      print('✅ Cancelled $cancelledCount notifications for task: $taskId');
    } catch (e) {
      print('❌ Error cancelling notifications for task $taskId: $e');
    }
  }

  Future<void> cancelSpecificNotification(int notificationId) async {
    try {
      await initialize();
      if (!_isInitialized) return;

      final clamped = _clampId(notificationId); // ✅ Clamp
      await _notificationService.cancelNotification(clamped);
      print('✅ Cancelled notification: $clamped');
    } catch (e) {
      print('❌ Error cancelling notification $notificationId: $e');
    }
  }

  // ============================================================
  // HOURLY REMINDER
  // ============================================================

  Future<void> scheduleHourlyReminder({
    required Task task,
    required int hour,
    required int totalHours,
    required int notificationId,
    required DateTime scheduledTime,
  }) async {
    try {
      await initialize();
      if (!_isInitialized) return;

      final clampedId = _clampId(notificationId); // ✅ Clamp

      final title = '⏰ Deadline Reminder: ${task.displayTitle}';
      final buffer = StringBuffer();
      buffer.writeln('📋 Task: ${task.displayTitle}');
      buffer.writeln('📌 Type: ${task.type.label}');
      buffer.writeln();

      if (task.courseCode != null && task.courseCode!.isNotEmpty) {
        buffer.writeln('📖 Course: ${task.courseCode}');
      }

      buffer.writeln('📅 Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
      buffer.writeln();
      buffer.writeln('⏰ ${hour}h reminder (${totalHours - hour}h remaining)');
      buffer.writeln();
      buffer.writeln('⚠️ Please complete your task before the deadline!');

      await _notificationService.scheduleTaskNotification(
        notificationId: clampedId,
        title: title,
        body: buffer.toString(),
        scheduledTime: scheduledTime,
        color: Colors.orange,
      );

      print('📬 Scheduled hourly reminder #$hour');
    } catch (e) {
      print('❌ Error scheduling hourly reminder: $e');
    }
  }

  // ============================================================
  // SEND COMPLETION NOTIFICATION
  // ============================================================

  Future<void> sendTaskCompletionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await initialize();
      if (!_isInitialized) {
        print('⚠️ Notifications not available');
        return;
      }

      final isAuto = task.autoCompleted;
      final title = isAuto ? '🤖 Task Auto-Completed!' : '✅ Task Completed!';

      final buffer = StringBuffer();
      buffer.writeln(message);
      buffer.writeln();
      buffer.writeln('📋 Task: ${task.displayTitle}');
      buffer.writeln('📌 Type: ${task.type.label}');

      if (task.courseCode != null && task.courseCode!.isNotEmpty) {
        buffer.writeln('📖 Course: ${task.courseCode}');
      }

      if (task.deadline != null) {
        buffer.writeln('📅 Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
      }

      buffer.writeln('📊 Status: ${isAuto ? '🤖 Auto-Completed' : '✅ Completed'}');
      buffer.writeln();

      if (isAuto) {
        buffer.writeln('💡 Automatically marked as completed');
      } else {
        buffer.writeln('🎉 Great job!');
      }

      final notificationId = _clampId(DateTime.now().millisecondsSinceEpoch); // ✅ Clamp

      await _notificationService.showImmediateNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        color: isAuto ? Colors.purple : Colors.green,
      );

      print('${isAuto ? '🤖' : '✅'} Sent completion notification for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error sending completion notification: $e');
    }
  }

  // ============================================================
  // SEND DEADLINE EXTENSION NOTIFICATION
  // ============================================================

  Future<void> sendDeadlineExtensionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await initialize();
      if (!_isInitialized) return;

      final title = '⏰ Deadline Extended!';

      final buffer = StringBuffer();
      buffer.writeln(message);
      buffer.writeln();
      buffer.writeln('📋 Task: ${task.displayTitle}');
      buffer.writeln('📌 Type: ${task.type.label}');

      if (task.deadline != null) {
        buffer.writeln('📅 New Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
      }

      if (task.totalExtensions > 0) {
        buffer.writeln('📊 Extension #${task.totalExtensions}');
      }

      buffer.writeln();
      buffer.writeln('⚠️ Please complete before the new deadline!');

      final notificationId = _clampId(DateTime.now().millisecondsSinceEpoch + 1); // ✅ Clamp

      await _notificationService.showImmediateNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        color: Colors.orange,
      );

      print('✅ Sent deadline extension notification');
    } catch (e) {
      print('❌ Error sending deadline extension: $e');
    }
  }

  // ============================================================
  // SEND OVERDUE REMINDER
  // ============================================================

  Future<void> sendOverdueReminderNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await initialize();
      if (!_isInitialized) return;

      final title = '⚠️ Task Overdue!';

      final buffer = StringBuffer();
      buffer.writeln(message);
      buffer.writeln();
      buffer.writeln('📋 Task: ${task.displayTitle}');
      buffer.writeln('📌 Type: ${task.type.label}');

      if (task.deadline != null) {
        buffer.writeln('📅 Original Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
      }

      buffer.writeln();
      buffer.writeln('⏰ Please complete this task!');

      final notificationId = _clampId(DateTime.now().millisecondsSinceEpoch + 2); // ✅ Clamp

      await _notificationService.showImmediateNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        color: Colors.red,
      );

      print('✅ Sent overdue reminder');
    } catch (e) {
      print('❌ Error sending overdue reminder: $e');
    }
  }

  // ============================================================
  // SEND DAILY SUMMARY
  // ============================================================

  Future<void> sendDailySummaryNotification({
    required List<Task> tasks,
    required String message,
  }) async {
    try {
      await initialize();
      if (!_isInitialized) return;

      final completedCount = tasks.where((t) => t.isDone).length;
      final autoCompletedCount = tasks.where((t) => t.isDone && t.autoCompleted).length;
      final pendingCount = tasks.where((t) => !t.isDone).length;
      final overdueCount = tasks.where((t) => !t.isDone && t.isOverdue).length;
      final extendedCount = tasks.where((t) => t.totalExtensions > 0).length;

      final buffer = StringBuffer();
      buffer.writeln(message);
      buffer.writeln();
      buffer.writeln('📊 Today\'s Summary:');
      buffer.writeln('   • Total Tasks: ${tasks.length}');
      buffer.writeln('   • ✅ Completed: $completedCount');
      if (autoCompletedCount > 0) {
        buffer.writeln('   • 🤖 Auto-Completed: $autoCompletedCount');
      }
      buffer.writeln('   • ⏳ Pending: $pendingCount');
      buffer.writeln('   • ⚠️ Overdue: $overdueCount');
      if (extendedCount > 0) {
        buffer.writeln('   • ⏰ Extended: $extendedCount');
      }

      if (pendingCount > 0) {
        buffer.writeln();
        buffer.writeln('📋 Pending Tasks:');
        final pendingTasks = tasks.where((t) => !t.isDone).toList();
        for (var task in pendingTasks.take(5)) {
          final emoji = task.isOverdue ? '⚠️' : '⏳';
          buffer.writeln('   • $emoji ${task.displayTitle}');
        }
        if (pendingTasks.length > 5) {
          buffer.writeln('   • ... and ${pendingTasks.length - 5} more');
        }
      }

      final notificationId = _clampId(DateTime.now().millisecondsSinceEpoch + 3); // ✅ Clamp

      await _notificationService.showImmediateNotification(
        notificationId: notificationId,
        title: '📋 Daily Task Summary',
        body: buffer.toString(),
        color: AppColors.primaryLight,
      );

      print('✅ Sent daily summary');
    } catch (e) {
      print('❌ Error sending daily summary: $e');
    }
  }

  // ============================================================
  // SCHEDULE OVERDUE REMINDERS
  // ============================================================

  Future<void> scheduleOverdueReminders(Task task) async {
    try {
      if (!task.alarmOn || task.isDone || !task.isOverdue) return;

      await initialize();
      if (!_isInitialized) return;

      final interval = task.reminderInterval;

      await sendOverdueReminderNotification(
        task: task,
        message: '⏰ "${task.displayTitle}" is overdue!',
      );

      final nextReminderTime = DateTime.now().add(interval);
      final notificationId = _clampId(task.id.hashCode + 999); // ✅ Clamp

      final buffer = StringBuffer();
      buffer.writeln('Your task "${task.displayTitle}" is still overdue!');
      buffer.writeln();
      buffer.writeln('📌 Type: ${task.type.label}');

      if (task.deadline != null) {
        buffer.writeln('📅 Original Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
      }

      buffer.writeln();
      buffer.writeln('Please complete this task soon! ⏰');

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: '⏰ Overdue Reminder: ${task.displayTitle}',
        body: buffer.toString(),
        scheduledTime: nextReminderTime,
        color: Colors.red,
      );

      print('✅ Scheduled overdue reminder');
    } catch (e) {
      print('❌ Error scheduling overdue reminder: $e');
    }
  }

  // ============================================================
  // BATCH SCHEDULING
  // ============================================================

  Future<void> scheduleAllTaskNotifications(List<Task> tasks) async {
    if (tasks.isEmpty) {
      print('📋 No tasks to schedule');
      return;
    }

    try {
      await initialize();
      if (!_isInitialized) {
        print('⚠️ Notifications not available');
        return;
      }

      print('📋 Scheduling ${tasks.length} tasks');

      for (var task in tasks) {
        await scheduleTaskNotifications(task);
        if (task.isOverdue && !task.isDone) {
          await scheduleOverdueReminders(task);
        }
      }

      print('✅ All notifications scheduled');
    } catch (e) {
      print('❌ Error scheduling all: $e');
    }
  }

  // ============================================================
  // CLEAR ALL NOTIFICATIONS
  // ============================================================

  Future<void> clearAllNotifications() async {
    try {
      await initialize();
      if (!_isInitialized) return;
      await _notificationService.cancelAllNotifications();
      print('✅ Cleared all notifications');
    } catch (e) {
      print('❌ Error clearing: $e');
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  String _buildNotificationTitle(Task task) {
    final typeEmoji = _getTypeEmoji(task.type);
    return '$typeEmoji ${task.type.label}: ${task.displayTitle}';
  }

  String _buildNotificationBody(Task task) {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${task.displayTitle}');
    buffer.writeln('📌 ${task.type.label}');

    if (task.courseCode != null && task.courseCode!.isNotEmpty) {
      buffer.writeln('📖 ${task.courseCode}');
    }

    if (task.deadline != null) {
      buffer.writeln('📅 ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
    }

    if (task.location != null && task.location!.isNotEmpty) {
      buffer.writeln('📍 ${task.location}');
    }

    return buffer.toString();
  }

  String _getTypeEmoji(TaskType type) {
    switch (type) {
      case TaskType.classes: return '🏫';
      case TaskType.assignment: return '📝';
      case TaskType.labReport: return '🔬';
      case TaskType.exam: return '📚';
      case TaskType.others: return '📌';
    }
  }
}