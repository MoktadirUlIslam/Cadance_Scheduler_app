// lib/screens/TaskManager/services/task_manager_stats_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';

class TaskManagerStatsService {
  static TaskManagerStatsService? _instance;

  factory TaskManagerStatsService() {
    _instance ??= TaskManagerStatsService._internal();
    return _instance!;
  }

  TaskManagerStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ FIXED: Get current user
  User? get _currentUser => _auth.currentUser;

  // ✅ FIXED: Get stats document reference with proper error handling
  DocumentReference<Map<String, dynamic>> get _statsRef {
    final user = _currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('taskManagerStats');
  }

  /// Initialize stats for new user
  Future<void> initializeStats() async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _statsRef.get();
      if (!doc.exists) {
        await _statsRef.set({
          'totalTasksDone': 0,
          'totalClassesDone': 0,
          'totalAssignmentsDone': 0,
          'totalLabReportsDone': 0,
          'totalExamsDone': 0,
          'totalOthersDone': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Task Manager stats initialized for user: ${user.uid}');
      } else {
        print('ℹ️ Stats already exist for user: ${user.uid}');
      }
    } catch (e) {
      print('❌ Error initializing task manager stats: $e');
      rethrow;
    }
  }

  /// Get current stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getStats');
        return _getDefaultStats();
      }

      final doc = await _statsRef.get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }

      // Initialize stats if they don't exist
      await initializeStats();
      final newDoc = await _statsRef.get();
      return newDoc.data() ?? _getDefaultStats();
    } catch (e) {
      print('❌ Error getting stats: $e');
      return _getDefaultStats();
    }
  }

  Map<String, dynamic> _getDefaultStats() {
    return {
      'totalTasksDone': 0,
      'totalClassesDone': 0,
      'totalAssignmentsDone': 0,
      'totalLabReportsDone': 0,
      'totalExamsDone': 0,
      'totalOthersDone': 0,
      'lastUpdated': null,
    };
  }

  /// Increment stats when a task is marked as done
  Future<void> incrementTaskStats(TaskType type) async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for incrementTaskStats');
        return;
      }

      final String fieldName = _getFieldNameForType(type);

      await _statsRef.update({
        'totalTasksDone': FieldValue.increment(1),
        fieldName: FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Stats incremented for ${type.label}: $fieldName');
    } catch (e) {
      print('❌ Error incrementing stats: $e');
    }
  }

  /// Decrement stats when a task is unmarked
  Future<void> decrementTaskStats(TaskType type) async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for decrementTaskStats');
        return;
      }

      final String fieldName = _getFieldNameForType(type);

      // Ensure we don't go below 0
      final currentStats = await getStats();
      final currentTotal = currentStats['totalTasksDone'] ?? 0;
      final currentField = currentStats[fieldName] ?? 0;

      if (currentTotal > 0 && currentField > 0) {
        await _statsRef.update({
          'totalTasksDone': FieldValue.increment(-1),
          fieldName: FieldValue.increment(-1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ Stats decremented for ${type.label}: $fieldName');
      } else {
        print('⚠️ Cannot decrement stats below 0 for ${type.label}');
      }
    } catch (e) {
      print('❌ Error decrementing stats: $e');
    }
  }

  /// Helper to get field name for task type
  String _getFieldNameForType(TaskType type) {
    switch (type) {
      case TaskType.classes:
        return 'totalClassesDone';
      case TaskType.assignment:
        return 'totalAssignmentsDone';
      case TaskType.labReport:
        return 'totalLabReportsDone';
      case TaskType.exam:
        return 'totalExamsDone';
      case TaskType.others:
        return 'totalOthersDone';
    }
  }

  /// Reset all stats (use with caution)
  Future<void> resetStats() async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _statsRef.set({
        'totalTasksDone': 0,
        'totalClassesDone': 0,
        'totalAssignmentsDone': 0,
        'totalLabReportsDone': 0,
        'totalExamsDone': 0,
        'totalOthersDone': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'resetAt': FieldValue.serverTimestamp(),
      });
      print('✅ Stats reset successfully for user: ${user.uid}');
    } catch (e) {
      print('❌ Error resetting stats: $e');
      rethrow;
    }
  }

  /// Check if stats exist
  Future<bool> statsExist() async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for statsExist');
        return false;
      }

      final doc = await _statsRef.get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking stats existence: $e');
      return false;
    }
  }

  /// Get stats with timestamp
  Future<Map<String, dynamic>> getStatsWithTimestamp() async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getStatsWithTimestamp');
        return {};
      }

      final doc = await _statsRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          ...data,
          'lastUpdated': data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
              : null,
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
        };
      }
      return {};
    } catch (e) {
      print('❌ Error getting stats with timestamp: $e');
      return {};
    }
  }

  /// Get stats for date range (if history is stored)
  Future<Map<String, dynamic>> getStatsForDateRange(DateTime start, DateTime end) async {
    try {
      // For now, just return current stats
      // You can extend this to store historical stats if needed
      return await getStats();
    } catch (e) {
      print('❌ Error getting stats for date range: $e');
      return {};
    }
  }

  /// Get completion rate as percentage
  Future<double> getCompletionRate() async {
    try {
      final stats = await getStats();

      final classesDone = stats['totalClassesDone'] ?? 0;
      final assignmentsDone = stats['totalAssignmentsDone'] ?? 0;
      final labReportsDone = stats['totalLabReportsDone'] ?? 0;
      final examsDone = stats['totalExamsDone'] ?? 0;
      final othersDone = stats['totalOthersDone'] ?? 0;

      final totalDone = classesDone + assignmentsDone + labReportsDone + examsDone + othersDone;
      final total = stats['totalTasksDone'] ?? 0;

      if (total == 0) return 0.0;
      return (totalDone / total) * 100;
    } catch (e) {
      print('❌ Error getting completion rate: $e');
      return 0.0;
    }
  }

  /// Get stats summary as a formatted map
  Future<Map<String, dynamic>> getStatsSummary() async {
    try {
      final stats = await getStats();

      return {
        'totalTasksDone': stats['totalTasksDone'] ?? 0,
        'totalClassesDone': stats['totalClassesDone'] ?? 0,
        'totalAssignmentsDone': stats['totalAssignmentsDone'] ?? 0,
        'totalLabReportsDone': stats['totalLabReportsDone'] ?? 0,
        'totalExamsDone': stats['totalExamsDone'] ?? 0,
        'totalOthersDone': stats['totalOthersDone'] ?? 0,
        'completionRate': await getCompletionRate(),
        'lastUpdated': stats['lastUpdated'] != null
            ? (stats['lastUpdated'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      print('❌ Error getting stats summary: $e');
      return {};
    }
  }

  /// Get stats by task type with counts
  Future<Map<String, Map<String, int>>> getStatsByType() async {
    try {
      final stats = await getStats();

      return {
        'Classes': {
          'completed': stats['totalClassesDone'] ?? 0,
        },
        'Assignment': {
          'completed': stats['totalAssignmentsDone'] ?? 0,
        },
        'Lab Report': {
          'completed': stats['totalLabReportsDone'] ?? 0,
        },
        'Exam': {
          'completed': stats['totalExamsDone'] ?? 0,
        },
        'Others': {
          'completed': stats['totalOthersDone'] ?? 0,
        },
      };
    } catch (e) {
      print('❌ Error getting stats by type: $e');
      return {};
    }
  }

  /// Delete stats (use with caution - for testing or account deletion)
  Future<void> deleteStats() async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _statsRef.delete();
      print('✅ Stats deleted successfully for user: ${user.uid}');
    } catch (e) {
      print('❌ Error deleting stats: $e');
      rethrow;
    }
  }

  /// Update multiple stats at once
  Future<void> updateMultipleStats({
    int? totalTasksDone,
    int? totalClassesDone,
    int? totalAssignmentsDone,
    int? totalLabReportsDone,
    int? totalExamsDone,
    int? totalOthersDone,
  }) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> updates = {};

      if (totalTasksDone != null) updates['totalTasksDone'] = totalTasksDone;
      if (totalClassesDone != null) updates['totalClassesDone'] = totalClassesDone;
      if (totalAssignmentsDone != null) updates['totalAssignmentsDone'] = totalAssignmentsDone;
      if (totalLabReportsDone != null) updates['totalLabReportsDone'] = totalLabReportsDone;
      if (totalExamsDone != null) updates['totalExamsDone'] = totalExamsDone;
      if (totalOthersDone != null) updates['totalOthersDone'] = totalOthersDone;

      if (updates.isNotEmpty) {
        updates['lastUpdated'] = FieldValue.serverTimestamp();
        await _statsRef.update(updates);
        print('✅ Multiple stats updated: ${updates.keys.join(', ')}');
      }
    } catch (e) {
      print('❌ Error updating multiple stats: $e');
      rethrow;
    }
  }

  /// Recalculate all stats from tasks (for fixing inconsistencies)
  Future<void> recalculateStats(List<Task> tasks) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      int classesDone = 0;
      int assignmentsDone = 0;
      int labReportsDone = 0;
      int examsDone = 0;
      int othersDone = 0;

      for (var task in tasks) {
        if (task.isDone) {
          switch (task.type) {
            case TaskType.classes:
              classesDone++;
              break;
            case TaskType.assignment:
              assignmentsDone++;
              break;
            case TaskType.labReport:
              labReportsDone++;
              break;
            case TaskType.exam:
              examsDone++;
              break;
            case TaskType.others:
              othersDone++;
              break;
          }
        }
      }

      final totalDone = classesDone + assignmentsDone + labReportsDone + examsDone + othersDone;

      await _statsRef.set({
        'totalTasksDone': totalDone,
        'totalClassesDone': classesDone,
        'totalAssignmentsDone': assignmentsDone,
        'totalLabReportsDone': labReportsDone,
        'totalExamsDone': examsDone,
        'totalOthersDone': othersDone,
        'lastUpdated': FieldValue.serverTimestamp(),
        'recalculatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Stats recalculated: Total=$totalDone, Classes=$classesDone, Assignments=$assignmentsDone, Lab Reports=$labReportsDone, Exams=$examsDone, Others=$othersDone');
    } catch (e) {
      print('❌ Error recalculating stats: $e');
      rethrow;
    }
  }
}