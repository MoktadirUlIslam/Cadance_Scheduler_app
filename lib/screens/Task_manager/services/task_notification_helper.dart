// lib/screens/TaskManager/services/task_notification_helper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../models/taskmanager_model.dart';
import '../../../services/notification_service.dart';
import '../../../utilites/app_colors.dart';

class TaskNotificationHelper {
  final NotificationService _notificationService =
      NotificationService.instance;

  bool _isInitialized = false;
  Future<void>? _initializing;

  static int _lastImmediateId = 0;

  bool get isAvailable => _isInitialized;

  // Keep task notification IDs below the calendar notification range.
  int _clampId(int id) => id & 0x3fffffff;

  /// Stable hash for scheduled notification IDs.
  /// Unlike String.hashCode, this explicitly defines the algorithm.
  ///
  /// Hash-based IDs still have a small collision risk.
  int _stableId(String value) {
    int hash = 0x811c9dc5;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    // Lower half of the task range for normal/overdue reminders.
    return hash & 0x1fffffff;
  }

  int _nextImmediateId() {
    // Upper half of the task range for immediate notifications.
    final candidate = 0x20000000 |
    (DateTime.now().millisecondsSinceEpoch & 0x1fffffff);

    _lastImmediateId = candidate == _lastImmediateId
        ? 0x20000000 | ((_lastImmediateId + 1) & 0x1fffffff)
        : candidate;

    return _lastImmediateId;
  }

  String? _taskId(Task task) {
    final id = task.id;

    if (id == null || id.isEmpty) {
      debugPrint(
        'Cannot schedule notifications without a saved task ID: '
            '${task.displayTitle}',
      );
      return null;
    }

    return id;
  }

  String _payload(String taskId, String kind) {
    return 'task:$taskId:$kind';
  }

  String _formatBangladeshTime(DateTime date) {
    final bangladeshTime = tz.TZDateTime.from(
      date,
      tz.getLocation('Asia/Dhaka'),
    );

    return '${DateFormat('MMM d, yyyy h:mm a').format(
      bangladeshTime,
    )} BDT';
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    final existing = _initializing;

    if (existing != null) {
      await existing;
      return;
    }

    final initialization = _notificationService.initialize();
    _initializing = initialization;

    try {
      await initialization;
      _isInitialized = true;
    } finally {
      _initializing = null;
    }
  }

  // ============================================================
  // SCHEDULE TASK NOTIFICATIONS
  // ============================================================

  Future<void> scheduleTaskNotifications(Task task) async {
    await initialize();

    final taskId = _taskId(task);
    if (taskId == null) return;

    if (!task.alarmOn || task.isDone) {
      // Clear all reminder types when disabled or completed.
      await cancelTaskNotifications(taskId);
      return;
    }

    // Replace only normal reminders.
    // Preserve separately scheduled hourly/overdue reminders.
    await _cancelReminderKind(taskId, 'normal');

    final reminders = <ReminderOption>[
      ...task.reminders,
    ];

    if (reminders.isEmpty) {
      reminders.addAll([
        ReminderOption.oneDay,
        ReminderOption.twoHours,
      ]);
    }

    DateTime? baseTime;

    switch (task.type) {
      case TaskType.assignment:
        baseTime = task.deadline;

        if (!reminders.contains(ReminderOption.twoDays)) {
          reminders.add(ReminderOption.twoDays);
        }
        break;

      case TaskType.labReport:
        baseTime = task.deadline ?? task.date;
        break;

      case TaskType.others:
        baseTime = task.deadline ?? task.startTime ?? task.date;
        break;

      case TaskType.classes:
      case TaskType.exam:
        baseTime = task.startTime ?? task.date;
        break;
    }

    if (baseTime == null) {
      debugPrint(
        'No reminder base time for "${task.displayTitle}"',
      );
      return;
    }

    // Avoid duplicate reminders with the same duration.
    final scheduledDurations = <int>{};
    int scheduledCount = 0;

    for (final reminder in reminders) {
      final durationKey = reminder.duration.inMicroseconds;

      if (!scheduledDurations.add(durationKey)) {
        continue;
      }

      final notificationTime =
      baseTime.subtract(reminder.duration);

      if (!notificationTime.isAfter(DateTime.now())) {
        continue;
      }

      final notificationId = _stableId(
        '$taskId|normal|$durationKey',
      );

      await _notificationService.scheduleTaskNotification(
        notificationId: notificationId,
        title: _buildNotificationTitle(task),
        body: _buildNotificationBody(task),
        scheduledTime: notificationTime,
        color: task.typeColor,
        payload: _payload(taskId, 'normal'),
      );

      scheduledCount++;
    }

    debugPrint(
      'Scheduled $scheduledCount reminders for '
          '"${task.displayTitle}"',
    );
  }

  // ============================================================
  // CANCEL TASK NOTIFICATIONS
  // ============================================================

  Future<void> _cancelReminderKind(
      String taskId,
      String kind,
      ) async {
    await initialize();

    final expectedPayload = _payload(taskId, kind);
    final pending =
    await _notificationService.getPendingNotifications();

    for (final notification in pending) {
      if (notification.payload == expectedPayload) {
        await _notificationService.cancelNotification(
          notification.id,
        );
      }
    }
  }

  /// Cancels normal, hourly, and overdue reminders for one task.
  /// Calendar notifications are not affected.
  Future<void> cancelTaskNotifications(String taskId) async {
    await initialize();

    final ownedPayloads = <String>{
      _payload(taskId, 'normal'),
      _payload(taskId, 'hourly'),
      _payload(taskId, 'overdue'),

      // Support the simple payload from the earlier code.
      'task:$taskId',
    };

    final pending =
    await _notificationService.getPendingNotifications();

    int cancelledCount = 0;

    for (final notification in pending) {
      if (ownedPayloads.contains(notification.payload)) {
        await _notificationService.cancelNotification(
          notification.id,
        );

        cancelledCount++;
      }
    }

    debugPrint(
      'Cancelled $cancelledCount reminders for task $taskId',
    );
  }

  Future<void> cancelSpecificNotification(
      int notificationId,
      ) async {
    await initialize();

    await _notificationService.cancelNotification(
      _clampId(notificationId),
    );
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
    await initialize();

    final taskId = _taskId(task);
    if (taskId == null) return;

    if (!task.alarmOn || task.isDone) {
      await cancelTaskNotifications(taskId);
      return;
    }

    final deadline = task.deadline;
    if (deadline == null) return;

    if (hour < 1 ||
        !scheduledTime.isAfter(DateTime.now()) ||
        scheduledTime.isAfter(deadline)) {
      return;
    }

    final remainingMinutes =
        deadline.difference(scheduledTime).inMinutes;

    final remainingText = remainingMinutes >= 60
        ? '${remainingMinutes ~/ 60}h '
        '${remainingMinutes % 60}m remaining'
        : remainingMinutes > 0
        ? '${remainingMinutes}m remaining'
        : 'Deadline reached';

    final buffer = StringBuffer()
      ..writeln('📋 Task: ${task.displayTitle}')
      ..writeln('📌 Type: ${task.type.label}');

    if (task.courseCode?.isNotEmpty ?? false) {
      buffer.writeln('📖 Course: ${task.courseCode}');
    }

    buffer
      ..writeln(
        '📅 Deadline: ${_formatBangladeshTime(deadline)}',
      )
      ..writeln()
      ..writeln('⏰ Reminder $hour — $remainingText')
      ..writeln('Please complete your task before the deadline.');

    // Keep the caller-provided ID for compatibility with
    // cancelSpecificNotification().
    await _notificationService.scheduleTaskNotification(
      notificationId: _clampId(notificationId),
      title: '⏰ Deadline Reminder: ${task.displayTitle}',
      body: buffer.toString(),
      scheduledTime: scheduledTime,
      color: Colors.orange,
      payload: _payload(taskId, 'hourly'),
    );
  }

  // ============================================================
  // COMPLETION NOTIFICATION
  // ============================================================

  Future<void> sendTaskCompletionNotification({
    required Task task,
    required String message,
  }) async {
    await initialize();

    final taskId = task.id;

    if (taskId != null && taskId.isNotEmpty) {
      await cancelTaskNotifications(taskId);
    }

    final isAuto = task.autoCompleted;

    final buffer = StringBuffer()
      ..writeln(message)
      ..writeln()
      ..writeln('📋 Task: ${task.displayTitle}')
      ..writeln('📌 Type: ${task.type.label}');

    if (task.courseCode?.isNotEmpty ?? false) {
      buffer.writeln('📖 Course: ${task.courseCode}');
    }

    final deadline = task.deadline;

    if (deadline != null) {
      buffer.writeln(
        '📅 Deadline: ${_formatBangladeshTime(deadline)}',
      );
    }

    buffer
      ..writeln(
        '📊 Status: ${isAuto ? 'Auto-Completed' : 'Completed'}',
      )
      ..writeln()
      ..writeln(
        isAuto
            ? 'Automatically marked as completed.'
            : '🎉 Great job!',
      );

    await _notificationService.showImmediateNotification(
      notificationId: _nextImmediateId(),
      title: isAuto
          ? '🤖 Task Auto-Completed!'
          : '✅ Task Completed!',
      body: buffer.toString(),
      color: isAuto ? Colors.purple : Colors.green,
    );
  }

  // ============================================================
  // DEADLINE EXTENSION NOTIFICATION
  // ============================================================

  Future<void> sendDeadlineExtensionNotification({
    required Task task,
    required String message,
  }) async {
    await initialize();

    final taskId = task.id;

    // The old deadline's reminders are now stale.
    // Schedule new reminders AFTER calling this method.
    if (taskId != null && taskId.isNotEmpty) {
      await cancelTaskNotifications(taskId);
    }

    final buffer = StringBuffer()
      ..writeln(message)
      ..writeln()
      ..writeln('📋 Task: ${task.displayTitle}')
      ..writeln('📌 Type: ${task.type.label}');

    final deadline = task.deadline;

    if (deadline != null) {
      buffer.writeln(
        '📅 New Deadline: ${_formatBangladeshTime(deadline)}',
      );
    }

    if (task.totalExtensions > 0) {
      buffer.writeln('📊 Extension #${task.totalExtensions}');
    }

    buffer
      ..writeln()
      ..writeln('Please complete before the new deadline.');

    await _notificationService.showImmediateNotification(
      notificationId: _nextImmediateId(),
      title: '⏰ Deadline Extended!',
      body: buffer.toString(),
      color: Colors.orange,
    );
  }

  // ============================================================
  // IMMEDIATE OVERDUE NOTIFICATION
  // ============================================================

  Future<void> sendOverdueReminderNotification({
    required Task task,
    required String message,
  }) async {
    await initialize();

    if (!task.alarmOn || task.isDone) return;

    final buffer = StringBuffer()
      ..writeln(message)
      ..writeln()
      ..writeln('📋 Task: ${task.displayTitle}')
      ..writeln('📌 Type: ${task.type.label}');

    final deadline = task.deadline;

    if (deadline != null) {
      buffer.writeln(
        '📅 Deadline: ${_formatBangladeshTime(deadline)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('Please complete this task.');

    await _notificationService.showImmediateNotification(
      notificationId: _nextImmediateId(),
      title: '⚠️ Task Overdue!',
      body: buffer.toString(),
      color: Colors.red,
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  /// Summarizes the supplied list.
  /// Pass a date-filtered list if you want a daily-only summary.
  Future<void> sendDailySummaryNotification({
    required List<Task> tasks,
    required String message,
  }) async {
    await initialize();

    final completedCount =
        tasks.where((task) => task.isDone).length;

    final autoCompletedCount = tasks
        .where((task) => task.isDone && task.autoCompleted)
        .length;

    final pendingTasks =
    tasks.where((task) => !task.isDone).toList();

    final overdueCount = pendingTasks
        .where((task) => task.isOverdue)
        .length;

    final extendedCount = tasks
        .where((task) => task.totalExtensions > 0)
        .length;

    final buffer = StringBuffer()
      ..writeln(message)
      ..writeln()
      ..writeln('📊 Task Summary:')
      ..writeln('• Total: ${tasks.length}')
      ..writeln('• ✅ Completed: $completedCount')
      ..writeln('• 🤖 Auto-Completed: $autoCompletedCount')
      ..writeln('• ⏳ Pending: ${pendingTasks.length}')
      ..writeln('• ⚠️ Overdue: $overdueCount')
      ..writeln('• ⏰ Extended: $extendedCount');

    if (pendingTasks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('📋 Pending Tasks:');

      for (final task in pendingTasks.take(5)) {
        final emoji = task.isOverdue ? '⚠️' : '⏳';

        buffer.writeln('• $emoji ${task.displayTitle}');
      }

      if (pendingTasks.length > 5) {
        buffer.writeln(
          '• ...and ${pendingTasks.length - 5} more',
        );
      }
    }

    await _notificationService.showImmediateNotification(
      notificationId: _nextImmediateId(),
      title: '📋 Task Summary',
      body: buffer.toString(),
      color: AppColors.primaryLight,
    );
  }

  // ============================================================
  // SCHEDULE NEXT OVERDUE REMINDER
  // ============================================================

  /// Schedules ONE future overdue reminder.
  /// It does not create an indefinite repeating reminder.
  Future<void> scheduleOverdueReminders(Task task) async {
    await initialize();

    final taskId = _taskId(task);
    if (taskId == null) return;

    if (!task.alarmOn || task.isDone) {
      await cancelTaskNotifications(taskId);
      return;
    }

    if (!task.isOverdue) {
      await _cancelReminderKind(taskId, 'overdue');
      return;
    }

    final interval = task.reminderInterval;

    if (interval.inMicroseconds <= 0) {
      debugPrint(
        'Invalid overdue reminder interval for '
            '"${task.displayTitle}"',
      );
      return;
    }

    final notificationId = _stableId(
      '$taskId|overdue',
    );

    // Do not postpone an existing reminder every time
    // the task list refreshes.
    if (await _notificationService.isNotificationScheduled(
      notificationId,
    )) {
      return;
    }

    final nextReminderTime = DateTime.now().add(interval);

    final buffer = StringBuffer()
      ..writeln(
        'Your task "${task.displayTitle}" is still overdue.',
      )
      ..writeln()
      ..writeln('📌 Type: ${task.type.label}');

    final deadline = task.deadline;

    if (deadline != null) {
      buffer.writeln(
        '📅 Deadline: ${_formatBangladeshTime(deadline)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('Please complete this task soon.');

    await _notificationService.scheduleTaskNotification(
      notificationId: notificationId,
      title: '⏰ Overdue Reminder: ${task.displayTitle}',
      body: buffer.toString(),
      scheduledTime: nextReminderTime,
      color: Colors.red,
      payload: _payload(taskId, 'overdue'),
    );
  }

  // ============================================================
  // BATCH SCHEDULING
  // ============================================================

  Future<void> scheduleAllTaskNotifications(
      List<Task> tasks,
      ) async {
    await initialize();

    for (final task in tasks) {
      try {
        await scheduleTaskNotifications(task);

        if (task.alarmOn && !task.isDone) {
          // Also removes a stale overdue reminder when
          // the task is no longer overdue.
          await scheduleOverdueReminders(task);
        }
      } catch (error, stackTrace) {
        // One task failing should not prevent the others
        // from being scheduled.
        debugPrint(
          'Failed scheduling "${task.displayTitle}": $error',
        );

        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  // ============================================================
  // CLEAR NOTIFICATIONS
  // ============================================================

  /// Clears only task-owned pending reminders.
  /// Does not cancel calendar reminders.
  Future<void> clearTaskNotifications() async {
    await initialize();

    final pending =
    await _notificationService.getPendingNotifications();

    for (final notification in pending) {
      if (notification.payload?.startsWith('task:') ?? false) {
        await _notificationService.cancelNotification(
          notification.id,
        );
      }
    }
  }

  /// Global cleanup: cancels task AND calendar notifications.
  /// Use only when intentionally clearing everything.
  Future<void> clearAllNotifications() async {
    await initialize();
    await _notificationService.cancelAllNotifications();
  }

  // ============================================================
  // CONTENT HELPERS
  // ============================================================

  String _buildNotificationTitle(Task task) {
    return '${_getTypeEmoji(task.type)} '
        '${task.type.label}: ${task.displayTitle}';
  }

  String _buildNotificationBody(Task task) {
    final buffer = StringBuffer()
      ..writeln('📋 ${task.displayTitle}')
      ..writeln('📌 ${task.type.label}');

    if (task.courseCode?.isNotEmpty ?? false) {
      buffer.writeln('📖 ${task.courseCode}');
    }

    if (task.type == TaskType.classes ||
        task.type == TaskType.exam) {
      final startTime = task.startTime;
      final endTime = task.endTime;

      if (startTime != null) {
        buffer.writeln(
          '🕒 Starts: ${_formatBangladeshTime(startTime)}',
        );
      }

      if (endTime != null) {
        buffer.writeln(
          '🕓 Ends: ${_formatBangladeshTime(endTime)}',
        );
      }
    } else {
      final deadline = task.deadline;

      if (deadline != null) {
        buffer.writeln(
          '📅 Deadline: ${_formatBangladeshTime(deadline)}',
        );
      }
    }

    if (task.location?.isNotEmpty ?? false) {
      buffer.writeln('📍 ${task.location}');
    }

    return buffer.toString();
  }

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