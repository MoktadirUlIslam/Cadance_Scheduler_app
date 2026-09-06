// lib/services/notification_service.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/calendar_models.dart';

class NotificationService {
  // ✅ Fixed: Proper singleton pattern with null safety
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

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }

  // ==================== NOTIFICATION RESPONSE HANDLERS ====================

  void _onNotificationResponse(NotificationResponse response) {
    print('📲 Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('📲 Background notification tapped: ${response.payload}');
  }

  // ==================== PERMISSIONS ====================

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();
    try {
      final permissions = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // For iOS
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
    required Color color,
  }) async {
    if (!_isInitialized) await initialize();
    if (scheduledTime.isBefore(DateTime.now())) {
      print('⏭️ Skipping notification scheduled in the past');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      // ✅ FIXED: Color should be Color? not int
      final androidDetails = AndroidNotificationDetails(
        'task_channel',
        'Task Reminders',
        channelDescription: 'Reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: color, // ✅ Fixed: Pass Color directly
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
        // ✅ FIXED: Use Int64List for vibration pattern
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        timeoutAfter: 60000,
        showWhen: true,
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Scheduled task notification #$notificationId at $scheduledTime');
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
      // ✅ FIXED: Color should be Color? not int
      final androidDetails = AndroidNotificationDetails(
        'task_channel',
        'Task Reminders',
        channelDescription: 'Reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: color, // ✅ Fixed: Pass Color directly
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
        // ✅ FIXED: Use Int64List for vibration pattern
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
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

  // ==================== SCHEDULE EVENT NOTIFICATION ====================

  Future<void> scheduleEventNotification(CalendarEventModel event) async {
    if (!_isInitialized) await initialize();
    if (!event.hasReminder) return;

    final notificationTime = event.notificationTime;
    if (notificationTime == null) return;
    if (notificationTime.isBefore(DateTime.now())) {
      print('⏭️ Skipping event notification in the past');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      final notificationId = event.id.hashCode.abs();

      // Different channel based on event category
      final channelId = 'event_${event.category.name}';
      final channelName = '${event.category.label} Events';

      // ✅ FIXED: Color should be Color? not int
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for ${event.category.label} events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: event.eventColor, // ✅ Fixed: Pass Color directly
        category: AndroidNotificationCategory.event,
        playSound: true,
        enableVibration: true,
        // ✅ FIXED: Use Int64List for vibration pattern
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
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

      // Build notification body
      final body = _buildEventNotificationBody(event);

      await _notifications.zonedSchedule(
        notificationId,
        '📅 ${_getCategoryEmoji(event.category)} ${event.title}',
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Scheduled notification for "${event.title}" at $notificationTime');
    } catch (e) {
      print('❌ Error scheduling event notification: $e');
    }
  }

  // ==================== SCHEDULE ALL NOTIFICATIONS ====================

  Future<void> scheduleAllEvents(List<CalendarEventModel> events) async {
    if (!_isInitialized) await initialize();

    try {
      // Cancel existing notifications first
      await cancelAllNotifications();

      int scheduledCount = 0;
      for (var event in events) {
        if (event.isUpcoming && event.hasReminder) {
          await scheduleEventNotification(event);
          scheduledCount++;
        }
      }

      print('✅ Scheduled notifications for $scheduledCount events');
    } catch (e) {
      print('❌ Error scheduling all events: $e');
    }
  }

  // ==================== DAILY SUMMARY NOTIFICATION ====================

  Future<void> scheduleDailySummary(List<CalendarEventModel> todayEvents) async {
    if (!_isInitialized) await initialize();
    if (todayEvents.isEmpty) return;

    final now = DateTime.now();
    final summaryTime = DateTime(now.year, now.month, now.day, 8, 0); // 8 AM daily summary

    if (now.isAfter(summaryTime)) {
      print('⏭️ Daily summary time already passed');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(summaryTime, tz.local);

      // Build summary
      final buffer = StringBuffer();
      buffer.writeln('You have ${todayEvents.length} event(s) today:');
      for (var event in todayEvents) {
        buffer.writeln('• ${_getCategoryEmoji(event.category)} ${event.title} - ${event.formattedTimeRange}');
      }

      final androidDetails = AndroidNotificationDetails(
        'daily_summary_channel',
        'Daily Summary',
        channelDescription: 'Daily summary of your events',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        9999, // Fixed ID for daily summary
        '📋 Today\'s Events',
        buffer.toString(),
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Scheduled daily summary');
    } catch (e) {
      print('❌ Error scheduling daily summary: $e');
    }
  }

  // ==================== CANCEL NOTIFICATIONS ====================

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();
    await _notifications.cancel(id);
    print('✅ Cancelled notification: $id');
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _notifications.cancelAll();
    print('✅ Cancelled all notifications');
  }

  // ==================== GET PENDING NOTIFICATIONS ====================

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> isNotificationScheduled(int notificationId) async {
    if (!_isInitialized) await initialize();
    final pending = await getPendingNotifications();
    return pending.any((p) => p.id == notificationId);
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