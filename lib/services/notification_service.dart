import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/calendar_models.dart';

// ✅ TOP-LEVEL FUNCTION - MUST be outside the class (REQUIRED for Android)
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  print('📲 Background notification tapped: ${response.payload}');
  // Handle background notification here
}

class NotificationService {
  static NotificationService? _instance;

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  static NotificationService get instance {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // ✅ CRITICAL FIX: Use top-level function, NOT static method
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
      );

      await _createNotificationChannels();
      await _requestIosPermissions();

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }

  // ==================== CHANNEL CREATION ====================

  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();

      if (androidPlugin == null) {
        print('⚠️ Android plugin not available');
        return;
      }

      const taskChannel = AndroidNotificationChannel(
        'task_channel',
        'Task Reminders',
        description: 'Reminders for your tasks',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(taskChannel);

      const summaryChannel = AndroidNotificationChannel(
        'daily_summary_channel',
        'Daily Summary',
        description: 'Daily summary of your tasks',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(summaryChannel);

      const overdueChannel = AndroidNotificationChannel(
        'overdue_channel',
        'Overdue Reminders',
        description: 'Reminders for overdue tasks',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(overdueChannel);

      const autoCompleteChannel = AndroidNotificationChannel(
        'autocomplete_channel',
        'Auto-Complete',
        description: 'Tasks auto-completed by the system',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(autoCompleteChannel);

      const extensionChannel = AndroidNotificationChannel(
        'extension_channel',
        'Deadline Extensions',
        description: 'Deadline extension notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(extensionChannel);

      print('✅ Created all notification channels');
    } catch (e) {
      print('❌ Error creating notification channels: $e');
    }
  }

  // ==================== IOS PERMISSIONS ====================

  Future<void> _requestIosPermissions() async {
    try {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
      >();

      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('✅ iOS permissions requested');
      }
    } catch (e) {
      print('⚠️ Error requesting iOS permissions: $e');
    }
  }

  // ==================== NOTIFICATION RESPONSE HANDLERS ====================

  void _onNotificationResponse(NotificationResponse response) {
    print('📲 Notification tapped: ${response.payload}');
  }

  // ==================== PERMISSIONS ====================

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();
    try {
      final permissions = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      if (permissions == null) {
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
        >();
        if (ios != null) {
          final granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
        return true;
      }

      return permissions;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  // ==================== SCHEDULE TASK NOTIFICATION ====================

  Future<void> scheduleTaskNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Color color = Colors.blue,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      print('⏭️ Skipping notification scheduled in the past');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      String channelId = 'task_channel';
      if (title.contains('Overdue')) {
        channelId = 'overdue_channel';
      } else if (title.contains('Auto-Completed')) {
        channelId = 'autocomplete_channel';
      } else if (title.contains('Deadline Extended')) {
        channelId = 'extension_channel';
      } else if (title.contains('Daily Summary')) {
        channelId = 'daily_summary_channel';
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'Notifications',
        channelDescription: 'Task notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: color,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId.abs(),
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Scheduled notification #${notificationId.abs()} at $scheduledTime');
      print('   Title: $title');
    } catch (e) {
      print('❌ Error scheduling task notification: $e');
    }
  }

  // ==================== SHOW IMMEDIATE NOTIFICATION ====================

  Future<void> showImmediateNotification({
    required int notificationId,
    required String title,
    required String body,
    Color color = Colors.blue,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final androidDetails = AndroidNotificationDetails(
        'task_channel',
        'Task Reminders',
        channelDescription: 'Reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: color,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId.abs(),
        title,
        body,
        details,
        payload: 'immediate_notification_$notificationId',
      );

      print('✅ Showed immediate notification: "$title"');
    } catch (e) {
      print('❌ Error showing immediate notification: $e');
    }
  }

  // ==================== CANCEL NOTIFICATIONS ====================

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();
    await _notifications.cancel(id.abs());
    print('✅ Cancelled notification: ${id.abs()}');
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _notifications.cancelAll();
    print('✅ Cancelled all notifications');
  }

  // Add this method to the NotificationService class in notification_service.dart

// ==================== SCHEDULE ALL EVENTS ====================

  Future<void> scheduleAllEvents(List<CalendarEventModel> events) async {
    if (!_isInitialized) await initialize();

    // Cancel all existing notifications first to avoid duplicates
    await cancelAllNotifications();

    int notificationId = 1;
    int scheduledCount = 0;
    final now = DateTime.now();

    for (var event in events) {
      // Skip events that are in the past
      if (event.date.isBefore(now) && !event.isAllDay) {
        continue;
      }

      // For all-day events, schedule at 9 AM on the event day
      DateTime scheduleTime;
      if (event.isAllDay) {
        scheduleTime = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
          9, 0, 0, // 9:00 AM
        );
      } else {
        // For events with specific time, use the event's date and time
        // Note: Your CalendarEventModel should have a time property
        // If not, you'll need to adjust this
        scheduleTime = event.date;
      }

      // Skip if scheduled time is in the past
      if (scheduleTime.isBefore(now)) {
        continue;
      }

      final title = '${_getCategoryEmoji(event.category)} ${event.title}';
      final body = _buildEventNotificationBody(event);
      final color = event.category.color;

      await scheduleTaskNotification(
        notificationId: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduleTime,
        color: color,
      );

      notificationId++;
      scheduledCount++;
    }

    print('✅ Scheduled $scheduledCount events');
  }

// ==================== SCHEDULE EVENT NOTIFICATION ====================

  Future<void> scheduleEventNotification(CalendarEventModel event) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();

    // Skip if event is in the past
    if (event.date.isBefore(now) && !event.isAllDay) {
      return;
    }

    // For all-day events, schedule at 9 AM on the event day
    DateTime scheduleTime;
    if (event.isAllDay) {
      scheduleTime = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        9, 0, 0,
      );
    } else {
      scheduleTime = event.date;
    }

    if (scheduleTime.isBefore(now)) {
      return;
    }

    final title = '${_getCategoryEmoji(event.category)} ${event.title}';
    final body = _buildEventNotificationBody(event);
    final color = event.category.color;

    final notificationId = event.id is int
        ? event.id as int
        : DateTime.now().millisecondsSinceEpoch.abs();

    await scheduleTaskNotification(
      notificationId: notificationId,
      title: title,
      body: body,
      scheduledTime: scheduleTime,
      color: color,
    );
  }

  // ==================== GET PENDING NOTIFICATIONS ====================

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> isNotificationScheduled(int notificationId) async {
    if (!_isInitialized) await initialize();
    final pending = await getPendingNotifications();
    return pending.any((p) => p.id == notificationId.abs());
  }

  // ==================== HELPERS ====================

  String _buildEventNotificationBody(CalendarEventModel event) {
    final buffer = StringBuffer();

    if (event.isAllDay) {
      buffer.writeln('📆 All Day Event');
    } else {
      buffer.writeln('⏰ ${event.formattedTimeRange}');
    }

    if (event.location != null && event.location!.isNotEmpty) {
      buffer.writeln('📍 ${event.location}');
    }

    if (event.description != null && event.description!.isNotEmpty) {
      buffer.writeln('📝 ${event.description}');
    }

    buffer.writeln('🏷 ${event.categoryLabel}');

    return buffer.toString();
  }



  String _getCategoryEmoji(EventCategory category) {
    switch (category) {
      case EventCategory.holiday: return '🏖️';
      case EventCategory.birthday: return '🎂';
      case EventCategory.exam: return '📚';
      case EventCategory.meeting: return '👥';
      case EventCategory.appointment: return '📋';
      case EventCategory.celebration: return '🎉';
      case EventCategory.travel: return '✈️';
      case EventCategory.custom: return '📌';
    }
  }

  // ==================== GETTERS ====================

  bool get isInitialized => _isInitialized;
}