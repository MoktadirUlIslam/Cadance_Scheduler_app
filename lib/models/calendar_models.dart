// lib/models/calendar_models.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pomodoro/utilites/app_colors.dart';

// ==================== ENUMS ====================

enum EventCategory {
  holiday,
  birthday,
  exam,
  meeting,
  appointment,
  celebration,
  travel,
  custom;

  String get label {
    switch (this) {
      case EventCategory.holiday:
        return 'Holiday';
      case EventCategory.birthday:
        return 'Birthday';
      case EventCategory.exam:
        return 'Exam';
      case EventCategory.meeting:
        return 'Meeting';
      case EventCategory.appointment:
        return 'Appointment';
      case EventCategory.celebration:
        return 'Celebration';
      case EventCategory.travel:
        return 'Travel';
      case EventCategory.custom:
        return 'Event';
    }
  }

  String get emoji {
    switch (this) {
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

  IconData get icon {
    switch (this) {
      case EventCategory.holiday:
        return Icons.beach_access_rounded;
      case EventCategory.birthday:
        return Icons.cake_rounded;
      case EventCategory.exam:
        return Icons.school_rounded;
      case EventCategory.meeting:
        return Icons.meeting_room_rounded;
      case EventCategory.appointment:
        return Icons.calendar_today_rounded;
      case EventCategory.celebration:
        return Icons.celebration_rounded;
      case EventCategory.travel:
        return Icons.flight_rounded;
      case EventCategory.custom:
        return Icons.event_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EventCategory.holiday:
        return Colors.blue;
      case EventCategory.birthday:
        return Colors.pink;
      case EventCategory.exam:
        return Colors.deepPurple;
      case EventCategory.meeting:
        return Colors.orange;
      case EventCategory.appointment:
        return Colors.teal;
      case EventCategory.celebration:
        return Colors.amber;
      case EventCategory.travel:
        return Colors.green;
      case EventCategory.custom:
        return AppColors.primaryLight;
    }
  }
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case RecurrenceType.none:
        return 'Never';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Repeats every day forever';
      case RecurrenceType.weekly:
        return 'Repeats every week forever';
      case RecurrenceType.monthly:
        return 'Repeats every month forever';
      case RecurrenceType.yearly:
        return 'Repeats every year forever (great for birthdays & holidays)';
    }
  }
}

// ==================== CALENDAR EVENT MODEL ====================

class CalendarEventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final EventCategory category;
  final bool isAllDay;
  final bool hasReminder;
  final int reminderMinutesBefore;
  final List<int> allReminderMinutes;
  final RecurrenceType recurrenceType;
  final DateTime? notificationTime;
  final String? parentEventId; // For tracking recurring event parent

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    this.isAllDay = false,
    this.hasReminder = false,
    this.reminderMinutesBefore = 30,
    this.allReminderMinutes = const [],
    this.recurrenceType = RecurrenceType.none,
    this.notificationTime,
    this.parentEventId,
  });

  // ==================== FACTORY METHODS ====================

  factory CalendarEventModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CalendarEventModel(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      location: map['location'],
      date: (map['date'] as Timestamp).toDate(),
      startTime: _timeFromMap(map['startTime']),
      endTime: _timeFromMap(map['endTime']),
      category: _categoryFromString(map['category'] ?? 'custom'),
      isAllDay: map['isAllDay'] ?? false,
      hasReminder: map['hasReminder'] ?? false,
      reminderMinutesBefore: map['reminderMinutesBefore'] ?? 30,
      allReminderMinutes: List<int>.from(map['allReminderMinutes'] ?? []),
      recurrenceType: _recurrenceTypeFromString(map['recurrenceType'] ?? 'none'),
      notificationTime: map['notificationTime'] != null
          ? (map['notificationTime'] as Timestamp).toDate()
          : null,
      parentEventId: map['parentEventId'],
    );
  }

  // Helper to parse time from Firestore
  static TimeOfDay? _timeFromMap(dynamic timeData) {
    if (timeData == null) return null;

    // If it's already a TimeOfDay
    if (timeData is TimeOfDay) return timeData;

    // If it's a Map with hour and minute
    if (timeData is Map<String, dynamic>) {
      final hour = timeData['hour'] ?? 0;
      final minute = timeData['minute'] ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    // If it's a string in format "HH:MM"
    if (timeData is String) {
      final parts = timeData.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return null;
  }

  static EventCategory _categoryFromString(String value) {
    try {
      return EventCategory.values.firstWhere(
            (e) => e.name == value,
        orElse: () => EventCategory.custom,
      );
    } catch (e) {
      return EventCategory.custom;
    }
  }

  static RecurrenceType _recurrenceTypeFromString(String value) {
    try {
      return RecurrenceType.values.firstWhere(
            (e) => e.name == value,
        orElse: () => RecurrenceType.none,
      );
    } catch (e) {
      return RecurrenceType.none;
    }
  }

  // ==================== TO MAP ====================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'startTime': _timeToMap(startTime),
      'endTime': _timeToMap(endTime),
      'category': category.name,
      'isAllDay': isAllDay,
      'hasReminder': hasReminder,
      'reminderMinutesBefore': reminderMinutesBefore,
      'allReminderMinutes': allReminderMinutes,
      'recurrenceType': recurrenceType.name,
      'notificationTime': notificationTime != null
          ? Timestamp.fromDate(notificationTime!)
          : null,
      'parentEventId': parentEventId,
    };
  }

  static Map<String, int>? _timeToMap(TimeOfDay? time) {
    if (time == null) return null;
    return {
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  // ==================== COPY WITH ====================

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    EventCategory? category,
    bool? isAllDay,
    bool? hasReminder,
    int? reminderMinutesBefore,
    List<int>? allReminderMinutes,
    RecurrenceType? recurrenceType,
    DateTime? notificationTime,
    String? parentEventId,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      isAllDay: isAllDay ?? this.isAllDay,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      allReminderMinutes: allReminderMinutes ?? this.allReminderMinutes,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      notificationTime: notificationTime ?? this.notificationTime,
      parentEventId: parentEventId ?? this.parentEventId,
    );
  }

  // ==================== COMPUTED PROPERTIES ====================

  Color get eventColor => category.color;
  IconData get eventIcon => category.icon;
  String get categoryLabel => category.label;
  String get eventEmoji => category.emoji;

  bool get isRecurring => recurrenceType != RecurrenceType.none;

  bool get isYearlyRecurring =>
      recurrenceType == RecurrenceType.yearly;

  bool get isPast {
    final now = DateTime.now();
    final eventDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (eventDate.isBefore(today)) return true;
    if (eventDate.isAfter(today)) return false;

    // Same day - check time
    if (!isAllDay && startTime != null) {
      final nowTime = now.hour * 60 + now.minute;
      final eventTime = startTime!.hour * 60 + startTime!.minute;
      return nowTime > eventTime;
    }

    return false;
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final eventDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (eventDate.isAfter(today)) return true;
    if (eventDate.isBefore(today)) return false;

    // Same day - check time
    if (!isAllDay && startTime != null) {
      final nowTime = now.hour * 60 + now.minute;
      final eventTime = startTime!.hour * 60 + startTime!.minute;
      return nowTime < eventTime;
    }

    return false;
  }

  bool get isTodayOrUpcoming => isToday || isUpcoming;

  String get formattedTimeRange {
    if (isAllDay) {
      return 'All Day';
    }

    if (startTime != null && endTime != null) {
      final startStr = _formatTimeOfDay(startTime!);
      final endStr = _formatTimeOfDay(endTime!);
      return '$startStr - $endStr';
    } else if (startTime != null) {
      return _formatTimeOfDay(startTime!);
    }

    return 'No time set';
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String get formattedShortDate {
    return DateFormat('MMM d').format(date);
  }

  String get recurrenceDescription {
    if (!isRecurring) return 'Does not repeat';
    return '${recurrenceType.label} (forever)';
  }

  // ==================== RECURRENCE HELPERS ====================

  /// Get the next occurrence date after a given date
  DateTime? getNextOccurrence(DateTime afterDate) {
    if (!isRecurring) return null;

    switch (recurrenceType) {
      case RecurrenceType.daily:
        return _getNextDaily(afterDate);
      case RecurrenceType.weekly:
        return _getNextWeekly(afterDate);
      case RecurrenceType.monthly:
        return _getNextMonthly(afterDate);
      case RecurrenceType.yearly:
        return _getNextYearly(afterDate);
      default:
        return null;
    }
  }

  DateTime? _getNextDaily(DateTime afterDate) {
    var next = DateTime(date.year, date.month, date.day);
    while (next.isBefore(afterDate) || next == afterDate) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime? _getNextWeekly(DateTime afterDate) {
    var next = DateTime(date.year, date.month, date.day);
    while (next.isBefore(afterDate) || next == afterDate) {
      next = next.add(const Duration(days: 7));
    }
    return next;
  }

  DateTime? _getNextMonthly(DateTime afterDate) {
    var next = DateTime(date.year, date.month, date.day);
    while (next.isBefore(afterDate) || next == afterDate) {
      next = DateTime(
        next.year,
        next.month + 1,
        date.day.clamp(1, _daysInMonth(next.year, next.month + 1)),
      );
    }
    return next;
  }

  DateTime? _getNextYearly(DateTime afterDate) {
    var next = DateTime(date.year, date.month, date.day);
    while (next.isBefore(afterDate) || next == afterDate) {
      next = DateTime(
        next.year + 1,
        date.month,
        date.day.clamp(1, _daysInMonth(next.year + 1, date.month)),
      );
    }
    return next;
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      return _isLeapYear(year) ? 29 : 28;
    }
    const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }

  bool _isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  // ==================== NOTIFICATION HELPERS ====================

  /// Get the notification time for the first reminder
  DateTime? get firstNotificationTime {
    if (!hasReminder || reminderMinutesBefore <= 0) return null;

    // Calculate notification time based on event time
    if (isAllDay) {
      // For all-day events, notify at 9 AM on the event day
      return DateTime(date.year, date.month, date.day, 9, 0);
    } else if (startTime != null) {
      // For timed events, notify X minutes before start time
      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime!.hour,
        startTime!.minute,
      );
      return eventDateTime.subtract(Duration(minutes: reminderMinutesBefore));
    }

    return null;
  }

  /// Get all notification times for all reminders
  List<DateTime> get allNotificationTimes {
    if (!hasReminder || allReminderMinutes.isEmpty) return [];

    final List<DateTime> times = [];
    final eventDateTime = isAllDay
        ? DateTime(date.year, date.month, date.day, 9, 0)
        : startTime != null
        ? DateTime(date.year, date.month, date.day, startTime!.hour, startTime!.minute)
        : DateTime(date.year, date.month, date.day);

    for (int minutes in allReminderMinutes) {
      times.add(eventDateTime.subtract(Duration(minutes: minutes)));
    }

    times.sort();
    return times;
  }

  // ==================== FORMATTING HELPERS ====================

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }

  // ==================== EQUALITY ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ==================== TO STRING ====================

  @override
  String toString() {
    return 'CalendarEventModel(id: $id, title: $title, date: $formattedDate, recurrence: ${recurrenceType.label})';
  }
}

// ==================== EXTENSIONS ====================

extension DateTimeExtension on DateTime {
  DateTime get dateOnly {
    return DateTime(year, month, day);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}