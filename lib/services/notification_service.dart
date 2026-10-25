import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/calendar_models.dart';

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  // Handles notification actions configured for background execution.
  // This does not run task auto-completion checks.
  debugPrint('Background notification response: ${response.payload}');
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() => _instance;

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Future<void>? _initializing;

  static const String _calendarPrefix = 'calendar_event:';

  bool get isInitialized => _isInitialized;

  tz.Location get _dhaka => tz.getLocation('Asia/Dhaka');

  int _normalizeId(int id) => id & 0x7fffffff;

  // Stable across app launches.
  // Calendar IDs occupy the upper half of the positive 31-bit range.
  int _calendarNotificationId(String eventId) {
    int hash = 0x811c9dc5;

    for (final unit in eventId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return 0x40000000 | (hash & 0x3fffffff);
  }

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    final existing = _initializing;
    if (existing != null) {
      await existing;
      return;
    }

    final initialization = _initializeInternal();
    _initializing = initialization;

    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializeInternal() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    // Uses the resource already declared in your manifest.
    // A dedicated monochrome drawable is preferable for production.
    const androidSettings =
    AndroidInitializationSettings('@mipmap/launcher_icon');

    // Ask permission later, from an explicit user action.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
      onBackgroundNotificationResponse,
    );

    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> _createNotificationChannels() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'task_channel',
        'Task Reminders',
        description: 'Reminders for tasks and events',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'daily_summary_channel',
        'Daily Summary',
        description: 'Task summaries',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'overdue_channel',
        'Overdue Reminders',
        description: 'Reminders for overdue tasks',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'autocomplete_channel',
        'Auto-Complete',
        description: 'Task completion notifications',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'extension_channel',
        'Deadline Extensions',
        description: 'Deadline extension notifications',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Add navigation handling here if required.
  }

  // ==================== PERMISSIONS ====================

  Future<bool> requestPermissions() async {
    await initialize();

    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final result = await android.requestNotificationsPermission();

      return result ??
          await android.areNotificationsEnabled() ??
          false;
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      return await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ??
          false;
    }

    return false;
  }

  /// Call from an "Enable reminders" button after explaining
  /// why precise alarm timing is needed.
  ///
  /// The returned value describes notification permission,
  /// not whether exact-alarm access was granted.
  Future<bool> requestReminderPermissions() async {
    final notificationsAllowed = await requestPermissions();

    if (!notificationsAllowed) return false;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final exactAllowed =
          await android.canScheduleExactNotifications() ?? false;

      if (!exactAllowed) {
        await android.requestExactAlarmsPermission();
      }
    }

    return notificationsAllowed;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final exactAllowed =
        await android?.canScheduleExactNotifications() ?? false;

    return exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // ==================== NOTIFICATION DETAILS ====================

  String _channelForTitle(String title) {
    final text = title.toLowerCase();

    if (text.contains('overdue')) return 'overdue_channel';
    if (text.contains('auto-completed')) return 'autocomplete_channel';
    if (text.contains('deadline extended')) return 'extension_channel';

    if (text.contains('daily summary') ||
        text.contains('daily task summary')) {
      return 'daily_summary_channel';
    }

    return 'task_channel';
  }

  String _channelName(String id) {
    switch (id) {
      case 'daily_summary_channel':
        return 'Daily Summary';
      case 'overdue_channel':
        return 'Overdue Reminders';
      case 'autocomplete_channel':
        return 'Auto-Complete';
      case 'extension_channel':
        return 'Deadline Extensions';
      default:
        return 'Task Reminders';
    }
  }

  NotificationDetails _details({
    required String title,
    required String body,
    required Color color,
  }) {
    final channelId = _channelForTitle(title);
    final quietChannel = channelId == 'daily_summary_channel' ||
        channelId == 'autocomplete_channel';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        icon: '@mipmap/launcher_icon',
        color: color,
        importance: quietChannel
            ? Importance.defaultImportance
            : Importance.high,
        priority: quietChannel ? Priority.defaultPriority : Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ==================== SCHEDULING ====================

  /// Registers a ONE-TIME notification with the operating system.
  ///
  /// scheduledTime must represent the correct actual instant.
  Future<void> scheduleTaskNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Color color = Colors.blue,
    String? payload,
  }) async {
    await initialize();

    if (!scheduledTime.isAfter(DateTime.now())) {
      debugPrint('Skipped past notification: $title');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(scheduledTime, _dhaka);
    final mode = await _scheduleMode();
    final id = _normalizeId(notificationId);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _details(title: title, body: body, color: color),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,

        // Deliberately omitted:
        // matchDateTimeComponents
        // This notification must not repeat every day.
      );

      debugPrint(
        'Scheduled #$id at $scheduledDate using $mode',
      );
    } catch (error, stackTrace) {
      // Propagate failure so callers do not falsely count it as scheduled.
      debugPrint('Notification scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> showImmediateNotification({
    required int notificationId,
    required String title,
    required String body,
    Color color = Colors.blue,
  }) async {
    await initialize();

    await _notifications.show(
      _normalizeId(notificationId),
      title,
      body,
      _details(title: title, body: body, color: color),
      payload: 'immediate_notification:$notificationId',
    );
  }

  // ==================== CANCELLATION ====================

  Future<void> cancelNotification(int id) async {
    await initialize();
    await _notifications.cancel(_normalizeId(id));
  }

  /// Explicit global cleanup only, such as logout.
  /// Do not call when refreshing calendar events.
  Future<void> cancelAllNotifications() async {
    await initialize();
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    await initialize();
    return _notifications.pendingNotificationRequests();
  }

  Future<bool> isNotificationScheduled(int notificationId) async {
    final pending = await getPendingNotifications();
    final id = _normalizeId(notificationId);

    return pending.any((notification) => notification.id == id);
  }

  // ==================== CALENDAR EVENTS ====================

  DateTime _eventReminderTime(CalendarEventModel event) {
    if (event.isAllDay) {
      return tz.TZDateTime(
        _dhaka,
        event.date.year,
        event.date.month,
        event.date.day,
        9,
      );
    }

    // Must already contain the event's correct date and time.
    return event.date;
  }

  /// Supply the COMPLETE current event list, not a filtered subset.
  /// Only calendar-owned pending notifications are replaced.
  Future<void> scheduleAllEvents(
      List<CalendarEventModel> events,
      ) async {
    await initialize();

    final pending = await getPendingNotifications();

    for (final notification in pending) {
      if (notification.payload?.startsWith(_calendarPrefix) ?? false) {
        await cancelNotification(notification.id);
      }
    }

    for (final event in events) {
      await scheduleEventNotification(event);
    }
  }

  Future<void> scheduleEventNotification(
      CalendarEventModel event,
      ) async {
    await initialize();

    final eventId = event.id.toString();
    final id = _calendarNotificationId(eventId);

    // Remove a previous reminder if the event time changed.
    await cancelNotification(id);

    final scheduledTime = _eventReminderTime(event);

    if (!scheduledTime.isAfter(DateTime.now())) return;

    await scheduleTaskNotification(
      notificationId: id,
      title: '${_getCategoryEmoji(event.category)} ${event.title}',
      body: _buildEventNotificationBody(event),
      scheduledTime: scheduledTime,
      color: event.category.color,
      payload: '$_calendarPrefix$eventId',
    );
  }

  Future<void> cancelEventNotification(String eventId) async {
    await cancelNotification(_calendarNotificationId(eventId));
  }

  String _buildEventNotificationBody(CalendarEventModel event) {
    final buffer = StringBuffer();

    if (event.isAllDay) {
      buffer.writeln('📆 All Day Event');
    } else {
      buffer.writeln('⏰ ${event.formattedTimeRange}');
    }

    if (event.location?.isNotEmpty ?? false) {
      buffer.writeln('📍 ${event.location}');
    }

    if (event.description?.isNotEmpty ?? false) {
      buffer.writeln('📝 ${event.description}');
    }

    buffer.writeln('🏷 ${event.categoryLabel}');

    return buffer.toString();
  }

  String _getCategoryEmoji(EventCategory category) {
    switch (category) {
      case EventCategory.holiday:
        return '🏖️';
      case EventCategory.birthday:
        return '🎂';
      case EventCategory.exam:
        return '📚';
      case EventCategory.meeting:
        return '👥';
      case EventCategory.appointment:
        return '📋';
      case EventCategory.celebration:
        return '🎉';
      case EventCategory.travel:
        return '✈️';
      case EventCategory.custom:
        return '📌';
    }
  }
}