// lib/services/activity_tracker_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityTrackerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get reference to user's activity document
  DocumentReference<Map<String, dynamic>> get _activityRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activity')
        .doc('tracking');
  }

  /// Record activity for today with count
  Future<void> recordActivity() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final todayKey = _formatDateKey(now);
      final timestamp = Timestamp.now();

      final doc = await _activityRef.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        List<String> activeDays = List<String>.from(data['activeDays'] ?? []);
        Map<String, dynamic> dailyDetails = Map<String, dynamic>.from(data['dailyDetails'] ?? {});
        Map<String, dynamic> monthlyDetails = Map<String, dynamic>.from(data['monthlyDetails'] ?? {});

        if (!dailyDetails.containsKey(todayKey)) {
          dailyDetails[todayKey] = {
            'count': 1,
            'firstActivity': timestamp,
            'lastActivity': timestamp,
            'activities': [
              {
                'timestamp': timestamp,
                'type': 'app_usage',
              }
            ]
          };
        } else {
          final dayData = dailyDetails[todayKey];
          dayData['count'] = (dayData['count'] ?? 0) + 1;
          dayData['lastActivity'] = timestamp;
          dayData['activities'].add({
            'timestamp': timestamp,
            'type': 'app_usage',
          });
        }

        if (!activeDays.contains(todayKey)) {
          activeDays.add(todayKey);
          activeDays.sort((a, b) => b.compareTo(a));
        }

        final monthKey = _formatMonthKey(now);
        if (!monthlyDetails.containsKey(monthKey)) {
          monthlyDetails[monthKey] = {
            'totalDays': 1,
            'totalActivities': 1,
            'days': [todayKey],
          };
        } else {
          final monthData = monthlyDetails[monthKey];
          if (!monthData['days'].contains(todayKey)) {
            monthData['days'].add(todayKey);
            monthData['totalDays'] = (monthData['totalDays'] ?? 0) + 1;
          }
          monthData['totalActivities'] = (monthData['totalActivities'] ?? 0) + 1;
        }

        final stats = _calculateActivityStats(activeDays);

        await _activityRef.update({
          'activeDays': activeDays,
          'totalActiveDays': stats['totalActiveDays'],
          'currentStreak': stats['currentStreak'],
          'maxStreak': stats['maxStreak'],
          'dailyDetails': dailyDetails,
          'monthlyDetails': monthlyDetails,
          'totalActivities': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        final activeDays = [todayKey];
        final stats = _calculateActivityStats(activeDays);

        final dailyDetails = {
          todayKey: {
            'count': 1,
            'firstActivity': timestamp,
            'lastActivity': timestamp,
            'activities': [
              {
                'timestamp': timestamp,
                'type': 'app_usage',
              }
            ]
          }
        };

        final monthKey = _formatMonthKey(now);
        final monthlyDetails = {
          monthKey: {
            'totalDays': 1,
            'totalActivities': 1,
            'days': [todayKey],
          }
        };

        await _activityRef.set({
          'activeDays': activeDays,
          'totalActiveDays': stats['totalActiveDays'],
          'currentStreak': stats['currentStreak'],
          'maxStreak': stats['maxStreak'],
          'dailyDetails': dailyDetails,
          'monthlyDetails': monthlyDetails,
          'totalActivities': 1,
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Silent fail
    }
  }

  /// Get activity stats
  Future<Map<String, dynamic>> getActivityStats() async {
    try {
      final doc = await _activityRef.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'activeDays': List<String>.from(data['activeDays'] ?? []),
          'totalActiveDays': data['totalActiveDays'] ?? 0,
          'currentStreak': data['currentStreak'] ?? 0,
          'maxStreak': data['maxStreak'] ?? 0,
          'totalActivities': data['totalActivities'] ?? 0,
          'dailyDetails': Map<String, dynamic>.from(data['dailyDetails'] ?? {}),
          'monthlyDetails': Map<String, dynamic>.from(data['monthlyDetails'] ?? {}),
          'lastUpdated': data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
              : null,
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
        };
      }

      return {
        'activeDays': <String>[],
        'totalActiveDays': 0,
        'currentStreak': 0,
        'maxStreak': 0,
        'totalActivities': 0,
        'dailyDetails': {},
        'monthlyDetails': {},
        'lastUpdated': null,
        'createdAt': null,
      };
    } catch (_) {
      return {
        'activeDays': <String>[],
        'totalActiveDays': 0,
        'currentStreak': 0,
        'maxStreak': 0,
        'totalActivities': 0,
        'dailyDetails': {},
        'monthlyDetails': {},
        'lastUpdated': null,
        'createdAt': null,
      };
    }
  }

  /// Get today's activity count
  Future<int> getTodayActivityCount() async {
    try {
      final stats = await getActivityStats();
      final todayKey = _formatDateKey(DateTime.now());
      final dailyDetails = Map<String, dynamic>.from(stats['dailyDetails'] ?? {});

      if (dailyDetails.containsKey(todayKey)) {
        return dailyDetails[todayKey]['count'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get daily activity details for a specific date
  Future<Map<String, dynamic>?> getDailyActivityDetails(DateTime date) async {
    try {
      final stats = await getActivityStats();
      final dateKey = _formatDateKey(date);
      final dailyDetails = Map<String, dynamic>.from(stats['dailyDetails'] ?? {});

      return dailyDetails[dateKey];
    } catch (_) {
      return null;
    }
  }

  /// Get monthly activity data for chart (enhanced with counts)
  Future<List<Map<String, dynamic>>> getMonthlyActivity() async {
    try {
      final stats = await getActivityStats();
      final monthlyDetails = Map<String, dynamic>.from(stats['monthlyDetails'] ?? {});

      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 0; i < 12; i++) {
        final month = now.month - i;
        final year = now.year - ((month <= 0) ? 1 : 0);
        final adjustedMonth = ((month - 1) % 12) + 1;
        final key = '$year-${adjustedMonth.toString().padLeft(2, '0')}';

        final monthData = monthlyDetails[key];
        final totalDays = monthData != null ? (monthData['totalDays'] ?? 0) : 0;
        final totalActivities = monthData != null ? (monthData['totalActivities'] ?? 0) : 0;

        final isCurrent = (year == now.year && adjustedMonth == now.month);
        final monthName = _getMonthAbbreviation(adjustedMonth);

        result.add({
          'month': monthName,
          'count': totalDays,
          'totalActivities': totalActivities,
          'isCurrent': isCurrent,
          'date': DateTime(year, adjustedMonth),
          'key': key,
          'days': monthData != null ? List<String>.from(monthData['days'] ?? []) : [],
        });
      }

      result.sort((a, b) => b['date'].compareTo(a['date']));
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Get activity summary for a month
  Future<Map<String, dynamic>> getMonthActivitySummary(DateTime date) async {
    try {
      final monthKey = _formatMonthKey(date);
      final stats = await getActivityStats();
      final monthlyDetails = Map<String, dynamic>.from(stats['monthlyDetails'] ?? {});

      if (monthlyDetails.containsKey(monthKey)) {
        return monthlyDetails[monthKey];
      }

      return {
        'totalDays': 0,
        'totalActivities': 0,
        'days': [],
      };
    } catch (_) {
      return {
        'totalDays': 0,
        'totalActivities': 0,
        'days': [],
      };
    }
  }

  /// Calculate activity stats from active days list
  Map<String, dynamic> _calculateActivityStats(List<String> activeDays) {
    if (activeDays.isEmpty) {
      return {
        'totalActiveDays': 0,
        'currentStreak': 0,
        'maxStreak': 0,
      };
    }

    final sorted = List<String>.from(activeDays)..sort((a, b) => b.compareTo(a));
    final totalActiveDays = sorted.length;

    int currentStreak = 0;
    int maxStreak = 0;
    int tempStreak = 0;

    if (sorted.isNotEmpty) {
      final today = _formatDateKey(DateTime.now());
      final yesterday = _formatDateKey(DateTime.now().subtract(const Duration(days: 1)));

      bool hasRecentActivity = sorted.contains(today) || sorted.contains(yesterday);

      if (hasRecentActivity) {
        DateTime? previousDate;
        for (var day in sorted) {
          final currentDate = _parseDateKey(day);
          if (previousDate == null) {
            tempStreak = 1;
          } else {
            final difference = previousDate.difference(currentDate).inDays;
            if (difference == 1) {
              tempStreak++;
            } else {
              break;
            }
          }
          previousDate = currentDate;
          if (tempStreak > maxStreak) {
            maxStreak = tempStreak;
          }
        }
        currentStreak = tempStreak;
      }

      tempStreak = 0;
      DateTime? prevDate;
      for (var day in sorted) {
        final currentDate = _parseDateKey(day);
        if (prevDate == null) {
          tempStreak = 1;
        } else {
          final difference = prevDate.difference(currentDate).inDays;
          if (difference == 1) {
            tempStreak++;
          } else {
            tempStreak = 1;
          }
        }
        prevDate = currentDate;
        if (tempStreak > maxStreak) {
          maxStreak = tempStreak;
        }
      }
    }

    return {
      'totalActiveDays': totalActiveDays,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
    };
  }

  /// Format date to YYYY-MM-DD string key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format month to YYYY-MM string key
  String _formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Parse date from YYYY-MM-DD string
  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Get month abbreviation
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  /// Delete activity data (for testing or account deletion)
  Future<void> deleteActivityData() async {
    try {
      await _activityRef.delete();
    } catch (_) {
      // Silent fail
    }
  }

  /// Reset activity data
  Future<void> resetActivityData() async {
    try {
      await _activityRef.delete();
    } catch (_) {
      // Silent fail
    }
  }

  /// Initialize activity tracking for new user
  Future<void> initializeActivityTracking() async {
    try {
      final doc = await _activityRef.get();
      if (!doc.exists) {
        final today = _formatDateKey(DateTime.now());
        final now = DateTime.now();
        final monthKey = _formatMonthKey(now);
        final timestamp = Timestamp.now();

        await _activityRef.set({
          'activeDays': [today],
          'totalActiveDays': 1,
          'currentStreak': 1,
          'maxStreak': 1,
          'totalActivities': 1,
          'dailyDetails': {
            today: {
              'count': 1,
              'firstActivity': timestamp,
              'lastActivity': timestamp,
              'activities': [
                {
                  'timestamp': timestamp,
                  'type': 'app_usage',
                }
              ]
            }
          },
          'monthlyDetails': {
            monthKey: {
              'totalDays': 1,
              'totalActivities': 1,
              'days': [today],
            }
          },
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Silent fail
    }
  }
}