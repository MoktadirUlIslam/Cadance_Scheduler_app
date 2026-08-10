// lib/screens/TaskManager/services/task_notification_helper.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';
import '../../../services/notification_service.dart';
import '../../../utilites/app_colors.dart';

class TaskNotificationHelper {
  final NotificationService _notificationService = NotificationService();

  // Schedule notifications for a task
  Future<void> scheduleTaskNotifications(Task task) async {
    if (!task.alarmOn) return;

    try {
      await _notificationService.initialize();

      // Get reminders - if empty, add default ones
      List<ReminderOption> reminders = List.from(task.reminders);
      if (reminders.isEmpty) {
        reminders = [ReminderOption.oneDay, ReminderOption.twoHours];
      }

      // Determine the base time for notifications
      // For Assignment and Lab Report: Use deadline
      // For all other types: Use start time or date
      DateTime? baseTime;

      if (task.type == TaskType.assignment || task.type == TaskType.labReport) {
        // For Assignment and Lab Report, use the deadline
        baseTime = task.deadline;

        // If no deadline is set, use the date as fallback
        if (baseTime == null) {
          baseTime = task.date;
        }
      } else {
        // For other types, use start time or date
        baseTime = task.startTime ?? task.date;
      }

      if (baseTime == null) return;

      print('📅 Scheduling notifications for "${task.displayTitle}"');
      print('   Base time: $baseTime');
      print('   Task type: ${task.type.label}');
      print('   Reminders: ${reminders.map((r) => r.label).join(', ')}');

      int baseId = task.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        final notificationTime = baseTime.subtract(reminder.duration);

        // Only schedule if notification time is in the future
        if (notificationTime.isAfter(DateTime.now())) {
          final title = _buildNotificationTitle(task);
          final body = _buildNotificationBody(task);

          await _notificationService.scheduleTaskNotification(
            notificationId: baseId + i + 1,
            title: title,
            body: body,
            scheduledTime: notificationTime,
            color: task.typeColor,
          );

          print('   ✅ Scheduled notification for "${task.displayTitle}" at $notificationTime');
          print('      Reminder: ${reminder.label}');
        } else {
          print('   ⏭️ Skipping notification for "${task.displayTitle}" at $notificationTime (already passed)');
        }
      }
    } catch (e) {
      print('❌ Error scheduling task notifications: $e');
    }
  }

  // Send task completion notification
  Future<void> sendTaskCompletionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await _notificationService.initialize();

      final title = task.isDone ? '✅ Task Completed!' : '⏳ Task Pending';
      final body = '''
$message

Task: ${task.displayTitle}
Type: ${task.type.label}
${task.deadline != null ? 'Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}' : ''}
${task.isDone ? 'Status: ✅ Completed' : 'Status: ⏳ Pending'}

${task.isDone ? '🎉 Great job!' : '💪 Keep going!'}
''';

      await _notificationService.scheduleTaskNotification(
        notificationId: DateTime.now().millisecondsSinceEpoch.hashCode.abs(),
        title: title,
        body: body,
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
        color: task.isDone ? Colors.green : Colors.orange,
      );

      print('✅ Sent task completion notification for ${task.displayTitle}');
    } catch (e) {
      print('❌ Error sending task completion notification: $e');
    }
  }

  // Send deadline extension notification
  Future<void> sendDeadlineExtensionNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await _notificationService.initialize();

      final title = '⏰ Reminder !';
      final body = '''
$message

Task: ${task.displayTitle}
Type: ${task.type.label}
New Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}

⚠️ Please complete your task before the new deadline!
''';

      await _notificationService.scheduleTaskNotification(
        notificationId: DateTime.now().millisecondsSinceEpoch.hashCode.abs() + 1,
        title: title,
        body: body,
        scheduledTime: DateTime.now().add(const Duration(seconds: 3)),
        color: Colors.orange,
      );

      print('✅ Sent deadline extension notification for ${task.displayTitle}');
    } catch (e) {
      print('❌ Error sending deadline extension notification: $e');
    }
  }

  // Send overdue reminder notification
  Future<void> sendOverdueReminderNotification({
    required Task task,
    required String message,
  }) async {
    try {
      await _notificationService.initialize();

      final title = '⚠️ Task Overdue!';
      final body = '''
$message

Task: ${task.displayTitle}
Type: ${task.type.label}
Original Deadline: ${task.deadline != null ? DateFormat('MMM d, yyyy h:mm a').format(task.deadline!) : 'Not set'}

⏰ Please complete or update this task!
''';

      await _notificationService.scheduleTaskNotification(
        notificationId: DateTime.now().millisecondsSinceEpoch.hashCode.abs() + 2,
        title: title,
        body: body,
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
        color: Colors.red,
      );

      print('✅ Sent overdue reminder for ${task.displayTitle}');
    } catch (e) {
      print('❌ Error sending overdue reminder: $e');
    }
  }

  // Send daily summary notification
  Future<void> sendDailySummaryNotification({
    required List<Task> tasks,
    required String message,
  }) async {
    try {
      await _notificationService.initialize();

      final completedCount = tasks.where((t) => t.isDone).length;
      final pendingCount = tasks.where((t) => !t.isDone).length;
      final overdueCount = tasks.where((t) => !t.isDone && t.isOverdue).length;

      final buffer = StringBuffer();
      buffer.writeln('$message');
      buffer.writeln('');
      buffer.writeln('📊 Today\'s Summary:');
      buffer.writeln('   • Total Tasks: ${tasks.length}');
      buffer.writeln('   • ✅ Completed: $completedCount');
      buffer.writeln('   • ⏳ Pending: $pendingCount');
      buffer.writeln('   • ⚠️ Overdue: $overdueCount');

      if (pendingCount > 0) {
        buffer.writeln('');
        buffer.writeln('📋 Pending Tasks:');
        final pendingTasks = tasks.where((t) => !t.isDone).toList();
        for (var task in pendingTasks.take(5)) {
          buffer.writeln('   • ${task.displayTitle} ${task.isOverdue ? '⚠️' : ''}');
        }
        if (pendingTasks.length > 5) {
          buffer.writeln('   • ... and ${pendingTasks.length - 5} more');
        }
      }

      final title = '📋 Daily Task Summary';

      await _notificationService.scheduleTaskNotification(
        notificationId: DateTime.now().millisecondsSinceEpoch.hashCode.abs() + 3,
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

  // Schedule periodic reminders for overdue tasks
  Future<void> scheduleOverdueReminders(Task task) async {
    if (!task.alarmOn) return;
    if (task.isDone) return;
    if (!task.isOverdue) return;

    try {
      await _notificationService.initialize();

      // Get interval based on task type
      final interval = task.reminderInterval;

      // Schedule reminder now
      await sendOverdueReminderNotification(
        task: task,
        message: '⏰ "${task.displayTitle}" is overdue! Please complete it soon.',
      );

      // Schedule next reminder after interval
      final nextReminderTime = DateTime.now().add(interval);

      await _notificationService.scheduleTaskNotification(
        notificationId: task.id.hashCode + 999,
        title: '⏰ Overdue Reminder: ${task.displayTitle}',
        body: '''
Your task "${task.displayTitle}" is still overdue!

Type: ${task.type.label}
${task.deadline != null ? 'Original Deadline: ${DateFormat('MMM d, yyyy h:mm a').format(task.deadline!)}' : ''}

Please complete this task as soon as possible! ⏰
''',
        scheduledTime: nextReminderTime,
        color: Colors.red,
      );

      print('✅ Scheduled overdue reminder for ${task.displayTitle} at $nextReminderTime');
    } catch (e) {
      print('❌ Error scheduling overdue reminder: $e');
    }
  }

  // Cancel all notifications for a task
  Future<void> cancelTaskNotifications(String taskId) async {
    try {
      await _notificationService.cancelAllNotifications();
      print('✅ Cancelled all notifications for task: $taskId');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  // Cancel specific notification
  Future<void> cancelSpecificNotification(int notificationId) async {
    try {
      await _notificationService.cancelNotification(notificationId);
      print('✅ Cancelled notification: $notificationId');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  // Schedule notifications for multiple tasks
  Future<void> scheduleAllTaskNotifications(List<Task> tasks) async {
    print('📋 Scheduling notifications for ${tasks.length} tasks');
    for (var task in tasks) {
      await scheduleTaskNotifications(task);

      // Schedule overdue reminders for overdue tasks
      if (task.isOverdue && !task.isDone) {
        await scheduleOverdueReminders(task);
      }
    }
    print('✅ All notifications scheduled');
  }

  // Build notification title with task type and display title
  String _buildNotificationTitle(Task task) {
    final typeEmoji = _getTypeEmoji(task.type);
    return '$typeEmoji ${task.type.label}: ${task.displayTitle}';
  }

  // Build notification body with all task details (without Priority and Reminder)
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
        break;

      case TaskType.classTest:
        if (task.classTestNo != null && task.classTestNo!.isNotEmpty) {
          buffer.writeln('📝 Test #${task.classTestNo}');
        }
        if (task.testTopic != null && task.testTopic!.isNotEmpty) {
          buffer.writeln('📖 ${task.testTopic}');
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

    // Time (if available) - for Classes, Exam, Class Test
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
      buffer.writeln('✅ Status: Completed');
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
      case TaskType.classTest:
        return '📝';
      case TaskType.others:
        return '📌';
    }
  }
}