// lib/screens/TaskManager/services/task_notification_helper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';
import '../../../services/notification_service.dart';
import '../../../utilites/app_colors.dart';

class TaskNotificationHelper {
  // Use a single instance of NotificationService
  final NotificationService _notificationService = NotificationService();

  // Track if initialized
  bool _isInitialized = false;

  /// Initialize the notification helper
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _ensureInitialized();
    _isInitialized = true;
    print('✅ TaskNotificationHelper initialized');
  }

  // Initialize if needed
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _notificationService.initialize();
      _isInitialized = true;
    }
  }

  // ============================================================
  // SCHEDULE TASK NOTIFICATIONS
  // ============================================================

  Future<void> scheduleTaskNotifications(Task task) async {
    try {
      // Early return if notifications are disabled
      if (!task.alarmOn) {
        print('🔕 Notifications disabled for "${task.displayTitle}"');
        return;
      }

      // Ensure initialization
      await _ensureInitialized();

      // Get reminders - if empty, add default ones
      List<ReminderOption> reminders = List.from(task.reminders);
      if (reminders.isEmpty) {
        reminders = [ReminderOption.oneDay, ReminderOption.twoHours];
      }

      // Determine the base time for notifications
      DateTime? baseTime;

      if (task.type == TaskType.assignment) {
        // For Assignment, use the deadline date
        baseTime = task.deadline;

        // Also schedule a reminder 2 days before the deadline
        // Add "2 days before" reminder if not already present
        if (!reminders.contains(ReminderOption.twoDays)) {
          reminders.add(ReminderOption.twoDays);
        }
      } else if (task.type == TaskType.labReport) {
        // For Lab Report, use the deadline
        baseTime = task.deadline;
        // If no deadline, use the date as fallback
        if (baseTime == null) {
          baseTime = task.date;
        }
      } else {
        // For other types, use start time or date
        baseTime = task.startTime ?? task.date;
      }

      if (baseTime == null) {
        print('⚠️ No base time available for "${task.displayTitle}"');
        return;
      }

      print('📅 Scheduling notifications for "${task.displayTitle}"');
      print('   Base time: $baseTime');
      print('   Task type: ${task.type.label}');
      print('   Reminders: ${reminders.map((r) => r.label).join(', ')}');

      int baseId = task.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
      baseId = baseId.abs();

      int scheduledCount = 0;

      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        final notificationTime = baseTime.subtract(reminder.duration);

        // Only schedule if notification time is in the future
        if (notificationTime.isAfter(DateTime.now())) {
          final notificationId = (baseId + i + 1).abs();

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
          print('   ✅ Scheduled notification #${i + 1} for "${task.displayTitle}" at $notificationTime');
          print('      Reminder: ${reminder.label} (ID: $notificationId)');
        } else {
          print('   ⏭️ Skipping notification for "${task.displayTitle}" at $notificationTime (already passed)');
        }
      }

      if (scheduledCount > 0) {
        print('✅ Scheduled $scheduledCount notifications for "${task.displayTitle}"');
      } else {
        print('ℹ️ No notifications scheduled for "${task.displayTitle}" (all reminder times passed)');
      }

    } catch (e) {
      print('❌ Error scheduling task notifications for "${task.displayTitle}": $e');
    }
  }

  // ============================================================
  // HOURLY REMINDER FOR EXTENDED DEADLINES
  // ============================================================

  /// Schedule an hourly reminder for extended deadlines
  Future<void> scheduleHourlyReminder({
    required Task task,
    required int hour,
    required int totalHours,
    required int notificationId,
    required DateTime scheduledTime,
  }) async {
    try {
      await _ensureInitialized();

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
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        scheduledTime: scheduledTime,
        color: Colors.orange,
      );

      print('📬 Scheduled hourly reminder #$hour for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error scheduling hourly reminder for "${task.displayTitle}": $e');
    }
  }

  // ============================================================
  // AUTO-COMPLETION NOTIFICATION
  // ============================================================

  /// Send auto-completion notification
  Future<void> sendAutoCompletionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await _ensureInitialized();

      final title = '🤖 Task Auto-Completed!';

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

      buffer.writeln();
      buffer.writeln('💡 Auto-completed by system');
      buffer.writeln('✅ Marked as completed automatically');

      final notificationId = DateTime.now().millisecondsSinceEpoch.abs() + 100;

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
        color: Colors.purple,
      );

      print('🤖 Sent auto-completion notification for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error sending auto-completion notification: $e');
    }
  }

  // ============================================================
  // COMPLETION NOTIFICATION
  // ============================================================

  // Send task completion notification
  Future<void> sendTaskCompletionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      // Ensure initialization
      await _ensureInitialized();

      // Check if it was auto-completed
      final isAuto = task.autoCompleted;
      final title = isAuto ? '🤖 Task Auto-Completed!' : '✅ Task Completed!';

      // Better body formatting
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
        buffer.writeln('💡 This task was automatically marked as completed');
      } else {
        buffer.writeln('🎉 Great job!');
      }

      // Use a unique ID
      final notificationId = DateTime.now().millisecondsSinceEpoch.abs();

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
        color: isAuto ? Colors.purple : Colors.green,
      );

      print('${isAuto ? '🤖' : '✅'} Sent completion notification for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error sending task completion notification: $e');
    }
  }

  // ============================================================
  // DEADLINE EXTENSION NOTIFICATION
  // ============================================================

  // Send deadline extension notification
  Future<void> sendDeadlineExtensionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      // Ensure initialization
      await _ensureInitialized();

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
      buffer.writeln('⚠️ Please complete your task before the new deadline!');
      buffer.writeln('⏰ Hourly reminders will be sent until the deadline.');

      final notificationId = DateTime.now().millisecondsSinceEpoch.abs() + 1;

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        scheduledTime: DateTime.now().add(const Duration(seconds: 3)),
        color: Colors.orange,
      );

      print('✅ Sent deadline extension notification for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error sending deadline extension notification: $e');
    }
  }

  // ============================================================
  // OVERDUE REMINDER
  // ============================================================

  // Send overdue reminder notification
  Future<void> sendOverdueReminderNotification({
    required Task task,
    required String message,
  }) async {
    try {
      // Ensure initialization
      await _ensureInitialized();

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
      buffer.writeln('⏰ Please complete or update this task!');
      buffer.writeln('💡 You can swipe right on the task card to mark it as done.');

      final notificationId = DateTime.now().millisecondsSinceEpoch.abs() + 2;

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
        color: Colors.red,
      );

      print('✅ Sent overdue reminder for "${task.displayTitle}"');
    } catch (e) {
      print('❌ Error sending overdue reminder: $e');
    }
  }

  // ============================================================
  // DAILY SUMMARY
  // ============================================================

  // Send daily summary notification
  Future<void> sendDailySummaryNotification({
    required List<Task> tasks,
    required String message,
  }) async {
    try {
      // Ensure initialization
      await _ensureInitialized();

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
          final extensionIndicator = task.totalExtensions > 0 ? ' (extended)' : '';
          buffer.writeln('   • $emoji ${task.displayTitle}$extensionIndicator');
        }
        if (pendingTasks.length > 5) {
          buffer.writeln('   • ... and ${pendingTasks.length - 5} more');
        }
      }

      if (overdueCount > 0) {
        buffer.writeln();
        buffer.writeln('⚠️ You have $overdueCount overdue tasks that need attention!');
      }

      final title = '📋 Daily Task Summary';
      final notificationId = DateTime.now().millisecondsSinceEpoch.abs() + 3;

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: title,
        body: buffer.toString(),
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
        color: AppColors.primaryLight,
      );

      print('✅ Sent daily summary notification');
    } catch (e) {
      print('❌ Error sending daily summary: $e');
    }
  }

  // ============================================================
  // OVERDUE REMINDERS
  // ============================================================

  // Schedule periodic reminders for overdue tasks
  Future<void> scheduleOverdueReminders(Task task) async {
    try {
      if (!task.alarmOn) {
        print('🔕 Overdue reminders disabled for "${task.displayTitle}"');
        return;
      }

      if (task.isDone) {
        print('✅ "${task.displayTitle}" is already completed');
        return;
      }

      if (!task.isOverdue) {
        print('ℹ️ "${task.displayTitle}" is not overdue');
        return;
      }

      // Ensure initialization
      await _ensureInitialized();

      // Get interval based on task type
      final interval = task.reminderInterval;

      // Send reminder now
      await sendOverdueReminderNotification(
        task: task,
        message: '⏰ "${task.displayTitle}" is overdue! Please complete it soon.',
      );

      // Schedule next reminder after interval
      final nextReminderTime = DateTime.now().add(interval);

      // Use a unique ID for the scheduled reminder
      final notificationId = (task.id.hashCode + 999).abs();

      final buffer = StringBuffer();
      buffer.writeln('Your task "${task.displayTitle}" is still overdue!');
      buffer.writeln();
      buffer.writeln('📌 Type: ${task.type.label}');

      if (task.deadline != null) {
        buffer.writeln('📅 Original Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
      }

      buffer.writeln();
      buffer.writeln('Please complete this task as soon as possible! ⏰');

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: '⏰ Overdue Reminder: ${task.displayTitle}',
        body: buffer.toString(),
        scheduledTime: nextReminderTime,
        color: Colors.red,
      );

      print('✅ Scheduled overdue reminder for "${task.displayTitle}" at $nextReminderTime (ID: $notificationId)');
    } catch (e) {
      print('❌ Error scheduling overdue reminder for "${task.displayTitle}": $e');
    }
  }

  // ============================================================
  // CANCEL NOTIFICATIONS
  // ============================================================

  // Cancel all notifications for a task
  Future<void> cancelTaskNotifications(String taskId) async {
    try {
      // Ensure initialization
      await _ensureInitialized();

      await _notificationService.cancelAllNotifications();
      print('✅ Cancelled all notifications for task: $taskId');
    } catch (e) {
      print('❌ Error cancelling notifications for task $taskId: $e');
    }
  }

  // Cancel specific notification
  Future<void> cancelSpecificNotification(int notificationId) async {
    try {
      // Ensure initialization
      await _ensureInitialized();

      await _notificationService.cancelNotification(notificationId.abs());
      print('✅ Cancelled notification: ${notificationId.abs()}');
    } catch (e) {
      print('❌ Error cancelling notification $notificationId: $e');
    }
  }

  // ============================================================
  // BATCH SCHEDULING
  // ============================================================

  // Schedule notifications for multiple tasks
  Future<void> scheduleAllTaskNotifications(List<Task> tasks) async {
    if (tasks.isEmpty) {
      print('📋 No tasks to schedule notifications for');
      return;
    }

    try {
      // Ensure initialization
      await _ensureInitialized();

      print('📋 Scheduling notifications for ${tasks.length} tasks');

      int scheduledCount = 0;
      int overdueCount = 0;
      int extendedCount = 0;

      for (var task in tasks) {
        await scheduleTaskNotifications(task);

        // Schedule overdue reminders for overdue tasks
        if (task.isOverdue && !task.isDone) {
          await scheduleOverdueReminders(task);
          overdueCount++;
        }

        // Check if task has extensions
        if (task.totalExtensions > 0) {
          extendedCount++;
        }

        scheduledCount++;
      }

      print('✅ All notifications scheduled for $scheduledCount tasks');
      print('   📊 Overdue tasks: $overdueCount');
      print('   📊 Extended tasks: $extendedCount');
    } catch (e) {
      print('❌ Error scheduling all task notifications: $e');
    }
  }

  // ============================================================
  // CLEAR ALL NOTIFICATIONS
  // ============================================================

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _ensureInitialized();
      await _notificationService.cancelAllNotifications();
      print('✅ Cleared all notifications');
    } catch (e) {
      print('❌ Error clearing all notifications: $e');
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  // Check if notifications are enabled
  bool areNotificationsEnabled(Task task) {
    return task.alarmOn && task.reminders.isNotEmpty;
  }

  // Get next reminder time for a task
  DateTime? getNextReminderTime(Task task) {
    if (!task.alarmOn || task.reminders.isEmpty) return null;

    DateTime? baseTime;
    if (task.type == TaskType.assignment || task.type == TaskType.labReport) {
      baseTime = task.deadline ?? task.date;
    } else {
      baseTime = task.startTime ?? task.date;
    }

    if (baseTime == null) return null;

    // Get the earliest reminder
    final earliestReminder = task.reminders
        .map((r) => baseTime!.subtract(r.duration))
        .where((t) => t.isAfter(DateTime.now()))
        .toList()
      ..sort();

    return earliestReminder.isNotEmpty ? earliestReminder.first : null;
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  // Build notification title with task type and display title
  String _buildNotificationTitle(Task task) {
    final typeEmoji = _getTypeEmoji(task.type);
    final displayName = task.displayTitle.isNotEmpty ? task.displayTitle : 'Task';
    return '$typeEmoji ${task.type.label}: $displayName';
  }

  // Build notification body with all task details
  String _buildNotificationBody(Task task) {
    final buffer = StringBuffer();

    // Task Type
    buffer.writeln('📋 Type: ${task.type.label}');

    // Course Code and Title (if available)
    if (task.courseCode != null && task.courseCode!.isNotEmpty) {
      buffer.writeln('📖 Course: ${task.courseCode}');
    }
    if (task.courseTitle != null && task.courseTitle!.isNotEmpty) {
      buffer.writeln('📚 ${task.courseTitle}');
    }

    // Type-specific details
    switch (task.type) {
      case TaskType.assignment:
        if (task.title != null && task.title!.isNotEmpty) {
          buffer.writeln('📝 Topic: ${task.title}');
        }
        if (task.deadline != null) {
          buffer.writeln('📅 Submission Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
        }
        break;

      case TaskType.labReport:
        if (task.experimentNo != null && task.experimentNo!.isNotEmpty) {
          buffer.writeln('🔬 Experiment: ${task.experimentNo}');
        }
        if (task.experimentTitle != null && task.experimentTitle!.isNotEmpty) {
          buffer.writeln('📖 ${task.experimentTitle}');
        }
        if (task.deadline != null) {
          buffer.writeln('📅 Submission Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
        }
        break;

      case TaskType.exam:
        if (task.examType != null && task.examType!.isNotEmpty) {
          buffer.writeln('📝 ${task.examType}');
        }
        // Class Test details (when examType is "Class Test")
        if (task.examType == 'Class Test') {
          if (task.classTestNo != null && task.classTestNo!.isNotEmpty) {
            buffer.writeln('📝 Test #${task.classTestNo}');
          }
          if (task.testTopic != null && task.testTopic!.isNotEmpty) {
            buffer.writeln('📖 ${task.testTopic}');
          }
        }
        break;

      case TaskType.others:
        if (task.title != null && task.title!.isNotEmpty) {
          buffer.writeln('📌 ${task.title}');
        }
        if (task.deadline != null) {
          buffer.writeln('📅 Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}');
        }
        break;

      case TaskType.classes:
      // Classes don't have additional specific fields
        break;
    }

    // Time (if available) - for Classes and Exam
    if (task.startTime != null && task.endTime != null) {
      buffer.writeln('⏰ ${_formatTime(task.startTime!)} - ${_formatTime(task.endTime!)}');
    }

    // Location/Room (if available)
    if (task.location != null && task.location!.isNotEmpty) {
      buffer.writeln('📍 Room: ${task.location}');
    }

    // Teacher(s) (if available)
    if (task.teacherName != null && task.teacherName!.isNotEmpty) {
      buffer.writeln('👨‍🏫 Teacher: ${task.teacherName}');
    }
    if (task.teacherName2 != null && task.teacherName2!.isNotEmpty) {
      buffer.writeln('👨‍🏫 Second Teacher: ${task.teacherName2}');
    }

    // Description (if available)
    if (task.description != null && task.description!.isNotEmpty) {
      buffer.writeln('📝 ${task.description}');
    }

    // Status (if completed)
    if (task.isDone) {
      buffer.writeln('✅ Status: ${task.autoCompleted ? '🤖 Auto-Completed' : 'Completed'}');
    }

    // Show extension count if any
    if (task.totalExtensions > 0) {
      buffer.writeln('⏰ Extended ${task.totalExtensions} time${task.totalExtensions > 1 ? 's' : ''}');
    }

    return buffer.toString();
  }

  // Format time helper
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = time.hour == 0 ? 12 : hour;
    return '$displayHour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  // Get emoji for task type
  String _getTypeEmoji(TaskType type) {
    switch (type) {
      case TaskType.classes:
        return '🏫';
      case TaskType.assignment:
        return '📝';
      case TaskType.labReport:
        return '🔬';
      case TaskType.exam:
        return '📚';
      case TaskType.others:
        return '📌';
    }
  }
}