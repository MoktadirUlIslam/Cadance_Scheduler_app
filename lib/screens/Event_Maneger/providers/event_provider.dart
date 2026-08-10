// lib/providers/event_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/calendar_models.dart';

class EventProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== STATE ====================
  Map<DateTime, List<CalendarEventModel>> _events = {};
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // ==================== GETTERS ====================
  Map<DateTime, List<CalendarEventModel>> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // ==================== FIRESTORE REFERENCE ====================
  CollectionReference<Map<String, dynamic>> get _eventsRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('calendar_events');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _events.clear();
    super.dispose();
  }

  // ==================== LOAD EVENTS ====================
  Future<void> loadEvents() async {
    final user = _auth.currentUser;
    if (user == null) {
      _events.clear();
      _isInitialized = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _eventsRef.get();
      _events.clear();

      for (var doc in snapshot.docs) {
        final event = CalendarEventModel.fromMap(doc.data(), id: doc.id);
        _addEventToMap(event);
      }

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // ==================== GET EVENTS ====================
  List<CalendarEventModel> getEventsForDay(DateTime day) {
    final dateKey = _getDateKey(day);
    return _events[dateKey] ?? [];
  }

  List<CalendarEventModel> getAllEvents() {
    return _events.values.expand((list) => list).toList();
  }

  List<CalendarEventModel> getUpcomingEvents({int limit = 10}) {
    final allEvents = getAllEvents();
    allEvents.sort((a, b) => a.date.compareTo(b.date));
    return allEvents
        .where((e) => e.isUpcoming)
        .take(limit)
        .toList();
  }

  List<CalendarEventModel> getPastEvents({int limit = 20}) {
    final allEvents = getAllEvents();
    allEvents.sort((a, b) => b.date.compareTo(a.date));
    return allEvents
        .where((e) => e.isPast)
        .take(limit)
        .toList();
  }

  List<CalendarEventModel> getEventsByCategory(EventCategory category) {
    return getAllEvents().where((e) => e.category == category).toList();
  }

  List<CalendarEventModel> getTodayEvents() {
    return getEventsForDay(DateTime.now());
  }

  List<CalendarEventModel> getEventsForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    return _events[dateKey] ?? [];
  }

  // ==================== ADD EVENT (WITH TRANSACTION) ====================
  Future<void> addEvent(CalendarEventModel event) async {
    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      final docRef = _eventsRef.doc(event.id.isEmpty ? null : event.id);
      final newEvent = event.id.isEmpty
          ? event.copyWith(id: docRef.id)
          : event;

      // FIXED: Use transaction to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          transaction.set(docRef, newEvent.toMap());
        } else {
          throw Exception('Event with ID ${newEvent.id} already exists');
        }
      });

      _addEventToMap(newEvent);

      if (newEvent.isRecurring) {
        await _createRecurringEvents(newEvent);
      }
    } catch (e) {
      _error = e.toString();
      throw Exception('Failed to add event: $e');
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // ==================== UPDATE EVENT (WITH TRANSACTION) ====================
  Future<void> updateEvent(CalendarEventModel event) async {
    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      final docRef = _eventsRef.doc(event.id);

      // FIXED: Use transaction
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          transaction.update(docRef, event.toMap());
        } else {
          throw Exception('Event with ID ${event.id} not found');
        }
      });

      if (event.isRecurring) {
        await _deleteRecurringOccurrences(event.id);
        await _createRecurringEvents(event);
      }

      _removeEventFromMap(event);
      _addEventToMap(event);
    } catch (e) {
      _error = e.toString();
      throw Exception('Failed to update event: $e');
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // ==================== DELETE EVENT ====================
  Future<void> deleteEvent(CalendarEventModel event) async {
    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      if (event.isRecurring) {
        await _deleteRecurringOccurrences(event.id);
      }

      await _eventsRef.doc(event.id).delete();
      _removeEventFromMap(event);
    } catch (e) {
      _error = e.toString();
      throw Exception('Failed to delete event: $e');
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // ==================== RECURRING EVENTS ====================
  Future<void> _createRecurringEvents(CalendarEventModel event) async {
    if (!event.isRecurring) return;

    int occurrences;
    switch (event.recurrenceType) {
      case RecurrenceType.yearly:
        occurrences = 50;
        break;
      case RecurrenceType.monthly:
        occurrences = 120;
        break;
      case RecurrenceType.weekly:
        occurrences = 520;
        break;
      case RecurrenceType.daily:
        occurrences = 3650;
        break;
      default:
        return;
    }

    final now = DateTime.now();

    for (int i = 1; i <= occurrences; i++) {
      DateTime? nextDate;

      switch (event.recurrenceType) {
        case RecurrenceType.daily:
          nextDate = event.date.add(Duration(days: i));
          break;
        case RecurrenceType.weekly:
          nextDate = event.date.add(Duration(days: 7 * i));
          break;
        case RecurrenceType.monthly:
          final targetMonth = event.date.month + i;
          final targetYear = event.date.year + ((targetMonth - 1) ~/ 12);
          final adjustedMonth = ((targetMonth - 1) % 12) + 1;
          final maxDay = _daysInMonth(targetYear, adjustedMonth);
          nextDate = DateTime(
            targetYear,
            adjustedMonth,
            event.date.day.clamp(1, maxDay),
          );
          break;
        case RecurrenceType.yearly:
          nextDate = DateTime(
            event.date.year + i,
            event.date.month,
            event.date.day.clamp(1, _daysInMonth(event.date.year + i, event.date.month)),
          );
          break;
        default:
          continue;
      }

      if (nextDate.isBefore(now) && event.recurrenceType != RecurrenceType.yearly) {
        continue;
      }

      final recurringEvent = event.copyWith(
        id: '${event.id}_${i}_${nextDate.year}_${nextDate.month}_${nextDate.day}',
        date: nextDate,
        recurrenceType: RecurrenceType.none,
        parentEventId: event.id,
        notificationTime: event.hasReminder
            ? _calculateNotificationTime(
          nextDate,
          event.startTime,
          event.isAllDay,
          event.reminderMinutesBefore,
        )
            : null,
      );

      if (_eventExists(recurringEvent.id)) continue;

      try {
        await _eventsRef.doc(recurringEvent.id).set(recurringEvent.toMap());
        _addEventToMap(recurringEvent);
      } catch (e) {
        // Log but continue creating other recurring events
        print('Failed to create recurring event: $e');
      }
    }
  }

  Future<void> _deleteRecurringOccurrences(String parentId) async {
    try {
      final snapshot = await _eventsRef
          .where('parentEventId', isEqualTo: parentId)
          .get();

      for (var doc in snapshot.docs) {
        final event = CalendarEventModel.fromMap(doc.data(), id: doc.id);
        await _eventsRef.doc(doc.id).delete();
        _removeEventFromMap(event);
      }
    } catch (_) {
      // Silently handle deletion errors
    }
  }

  // ==================== HELPERS ====================
  void _addEventToMap(CalendarEventModel event) {
    final dateKey = _getDateKey(event.date);
    if (_events.containsKey(dateKey)) {
      _events[dateKey]!.removeWhere((e) => e.id == event.id);
      _events[dateKey]!.add(event);
      _events[dateKey]!.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        final aTime = a.startTime!.hour * 60 + a.startTime!.minute;
        final bTime = b.startTime!.hour * 60 + b.startTime!.minute;
        return aTime.compareTo(bTime);
      });
    } else {
      _events[dateKey] = [event];
    }
  }

  void _removeEventFromMap(CalendarEventModel event) {
    final keysToRemove = <DateTime>[];
    for (var entry in _events.entries) {
      final index = entry.value.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        entry.value.removeAt(index);
        if (entry.value.isEmpty) {
          keysToRemove.add(entry.key);
        }
      }
    }
    for (var key in keysToRemove) {
      _events.remove(key);
    }
  }

  bool _eventExists(String id) {
    for (var events in _events.values) {
      for (var event in events) {
        if (event.id == id) {
          return true;
        }
      }
    }
    return false;
  }

  DateTime _getDateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

  DateTime? _calculateNotificationTime(
      DateTime date,
      TimeOfDay? startTime,
      bool isAllDay,
      int minutesBefore,
      ) {
    if (isAllDay) {
      return DateTime(date.year, date.month, date.day, 9, 0);
    } else if (startTime != null) {
      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      return eventDateTime.subtract(Duration(minutes: minutesBefore));
    }
    return null;
  }

  // ==================== REFRESH ====================
  Future<void> refreshEvents() async {
    await loadEvents();
  }
}