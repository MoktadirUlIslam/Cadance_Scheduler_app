// lib/screens/TaskManager/services/task_firestore_service.dart

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

  // Get reference to user's stats document
  DocumentReference<Map<String, dynamic>> get _statsRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('taskManagerStats');
  }

  /// Initialize stats for new user
  Future<void> initializeStats() async {
    try {
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
        });
        print('✅ Task Manager stats initialized');
      } else {
        print('ℹ️ Stats already exist');
      }
    } catch (e) {
      print('❌ Error initializing task manager stats: $e');
      throw Exception('Failed to initialize task manager stats: $e');
    }
  }

  /// Get current stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final doc = await _statsRef.get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      // Return default if no stats exist
      return {
        'totalTasksDone': 0,
        'totalClassesDone': 0,
        'totalAssignmentsDone': 0,
        'totalLabReportsDone': 0,
        'totalExamsDone': 0,
        'totalOthersDone': 0,
        'lastUpdated': null,
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
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
  }

  /// Increment stats when a task is marked as done
  Future<void> incrementTaskStats(TaskType type) async {
    try {
      final String fieldName;
      switch (type) {
        case TaskType.classes:
          fieldName = 'totalClassesDone';
          break;
        case TaskType.assignment:
          fieldName = 'totalAssignmentsDone';
          break;
        case TaskType.labReport:
          fieldName = 'totalLabReportsDone';
          break;
        case TaskType.exam:
          fieldName = 'totalExamsDone';
          break;
        case TaskType.classTest:
          fieldName = 'totalExamsDone';
          break;
        case TaskType.others:
          fieldName = 'totalOthersDone';
          break;
      }

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
      final String fieldName;
      switch (type) {
        case TaskType.classes:
          fieldName = 'totalClassesDone';
          break;
        case TaskType.assignment:
          fieldName = 'totalAssignmentsDone';
          break;
        case TaskType.labReport:
          fieldName = 'totalLabReportsDone';
          break;
        case TaskType.exam:
          fieldName = 'totalExamsDone';
          break;
        case TaskType.classTest:
          fieldName = 'totalExamsDone';
          break;
        case TaskType.others:
          fieldName = 'totalOthersDone';
          break;
      }

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

  /// Reset all stats (use with caution)
  Future<void> resetStats() async {
    try {
      await _statsRef.set({
        'totalTasksDone': 0,
        'totalClassesDone': 0,
        'totalAssignmentsDone': 0,
        'totalLabReportsDone': 0,
        'totalExamsDone': 0,
        'totalOthersDone': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Stats reset successfully');
    } catch (e) {
      print('❌ Error resetting stats: $e');
      throw Exception('Failed to reset stats: $e');
    }
  }

  /// Check if stats exist
  Future<bool> statsExist() async {
    try {
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
      final doc = await _statsRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          ...data,
          'lastUpdated': data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
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
      final total = stats['totalTasksDone'] ?? 0;

      final classesDone = stats['totalClassesDone'] ?? 0;
      final assignmentsDone = stats['totalAssignmentsDone'] ?? 0;
      final labReportsDone = stats['totalLabReportsDone'] ?? 0;
      final examsDone = stats['totalExamsDone'] ?? 0;
      final othersDone = stats['totalOthersDone'] ?? 0;

      final totalDone = classesDone + assignmentsDone + labReportsDone + examsDone + othersDone;

      if (totalDone == 0) return 0.0;
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
      final total = stats['totalTasksDone'] ?? 0;

      return {
        'totalTasksDone': total,
        'totalClassesDone': stats['totalClassesDone'] ?? 0,
        'totalAssignmentsDone': stats['totalAssignmentsDone'] ?? 0,
        'totalLabReportsDone': stats['totalLabReportsDone'] ?? 0,
        'totalExamsDone': stats['totalExamsDone'] ?? 0,
        'totalOthersDone': stats['totalOthersDone'] ?? 0,
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
          'total': stats['totalClassesDone'] ?? 0,
        },
        'Assignment': {
          'total': stats['totalAssignmentsDone'] ?? 0,
        },
        'Lab Report': {
          'total': stats['totalLabReportsDone'] ?? 0,
        },
        'Exam': {
          'total': stats['totalExamsDone'] ?? 0,
        },
        'Others': {
          'total': stats['totalOthersDone'] ?? 0,
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
      await _statsRef.delete();
      print('✅ Stats deleted successfully');
    } catch (e) {
      print('❌ Error deleting stats: $e');
      throw Exception('Failed to delete stats: $e');
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
      throw Exception('Failed to update multiple stats: $e');
    }
  }
}

// ✅ FIXED: TaskFirestoreService with proper initialization
class TaskFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Fixed: Use lazy getter
  TaskManagerStatsService get _statsService => TaskManagerStatsService();

  // ✅ Fixed: Use getter with proper null safety
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
  }

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      final docRef = _tasksCollection.doc();
      final newTask = task.copyWith(
        id: docRef.id,
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newTask.toMap());
      print('✅ Task created: ${newTask.displayTitle} with ID: ${newTask.id}');
      print('   Type: ${newTask.type.label}');
      print('   Date: ${DateFormat('yyyy-MM-dd').format(newTask.date)}');
      if (newTask.deadline != null) {
        print('   Deadline: ${DateFormat('yyyy-MM-dd').format(newTask.deadline!)}');
      }

      if (newTask.isDone) {
        await _statsService.incrementTaskStats(newTask.type);
      }

      return newTask;
    } catch (e) {
      print('❌ Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks for the user
  Stream<List<Task>> getTasks() {
    try {
      return _tasksCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        print('📊 Got ${snapshot.docs.length} tasks from Firestore');
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        print('❌ Error in getTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks: $e');
      return Stream.error('Failed to get tasks: $e');
    }
  }

  // Get tasks for a specific date
  Stream<List<Task>> getTasksForDate(DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('📅 Querying tasks for date: ${DateFormat('yyyy-MM-dd').format(startOfDay)}');

      return _tasksCollection.snapshots().map((snapshot) {
        final allTasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        final dateMatchedTasks = allTasks.where((task) {
          final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
          return (taskDate.isAfter(startOfDay) || taskDate.isAtSameMomentAs(startOfDay)) &&
              (taskDate.isBefore(endOfDay) || taskDate.isAtSameMomentAs(endOfDay));
        }).toList();

        final deadlineTasks = allTasks.where((task) {
          if (!task.type.hasDeadline || task.deadline == null) return false;

          final taskStartDate = DateTime(task.date.year, task.date.month, task.date.day);
          final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day
          );

          final isOnOrAfterStart = date.isAfter(taskStartDate) ||
              date.isAtSameMomentAs(taskStartDate);
          final isOnOrBeforeDeadline = date.isBefore(taskDeadline) ||
              date.isAtSameMomentAs(taskDeadline);

          return isOnOrAfterStart && isOnOrBeforeDeadline;
        }).toList();

        final Map<String, Task> taskMap = {};
        for (var task in dateMatchedTasks) {
          if (task.id != null) {
            taskMap[task.id!] = task;
          }
        }
        for (var task in deadlineTasks) {
          if (task.id != null) {
            taskMap[task.id!] = task;
          }
        }
        final allMatchedTasks = taskMap.values.toList();

        print('📊 Total ${allMatchedTasks.length} tasks for selected date (${dateMatchedTasks.length} date-matched, ${deadlineTasks.length} deadline-matched)');

        allMatchedTasks.sort((a, b) {
          if (a.isDone != b.isDone) {
            return a.isDone ? 1 : -1;
          }
          if (a.startTime != null && b.startTime != null) {
            return a.startTime!.compareTo(b.startTime!);
          }
          if (a.startTime != null) return -1;
          if (b.startTime != null) return 1;
          if (a.deadline != null && b.deadline != null) {
            return a.deadline!.compareTo(b.deadline!);
          }
          if (a.deadline != null) return -1;
          if (b.deadline != null) return 1;
          return 0;
        });

        return allMatchedTasks;
      }).handleError((error) {
        print('❌ Error in getTasksForDate stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks for date: $e');
      return Stream.error('Failed to get tasks: $e');
    }
  }

  // Update a task with stats management
  Future<Task> updateTask(Task task) async {
    try {
      if (task.id == null) throw Exception('Task ID is required for update');

      final oldTask = await getTask(task.id!);

      final updatedTask = task.copyWith(
        updatedAt: DateTime.now(),
      );

      await _tasksCollection.doc(task.id).update(updatedTask.toMap());
      print('✅ Task updated: ${updatedTask.displayTitle}');

      if (oldTask != null) {
        if (oldTask.isDone != updatedTask.isDone) {
          if (updatedTask.isDone) {
            await _statsService.incrementTaskStats(updatedTask.type);
            print('📊 Stats incremented for ${updatedTask.type.label}');
          } else {
            await _statsService.decrementTaskStats(updatedTask.type);
            print('📊 Stats decremented for ${updatedTask.type.label}');
          }
        }
      }

      return updatedTask;
    } catch (e) {
      print('❌ Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete a task with stats management
  Future<void> deleteTask(String taskId) async {
    try {
      final task = await getTask(taskId);

      await _tasksCollection.doc(taskId).delete();
      print('✅ Task deleted: $taskId');

      if (task != null && task.isDone) {
        await _statsService.decrementTaskStats(task.type);
        print('📊 Stats decremented for deleted ${task.type.label}');
      }
    } catch (e) {
      print('❌ Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get a single task by ID
  Future<Task?> getTask(String taskId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists && doc.data() != null) {
        return Task.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting task: $e');
      return null;
    }
  }

  // Get tasks count by status
  Future<Map<String, int>> getTaskCounts() async {
    try {
      final allTasks = await _tasksCollection.get();
      final tasks = allTasks.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();

      final now = DateTime.now();
      int overdueCount = 0;
      for (var task in tasks) {
        if (!task.isDone) {
          if (task.type.hasTimeRange && task.date.isBefore(now)) {
            overdueCount++;
          } else if (task.type.hasDeadline && task.deadline != null && task.deadline!.isBefore(now)) {
            overdueCount++;
          }
        }
      }

      return {
        'total': tasks.length,
        'completed': tasks.where((t) => t.isDone).length,
        'pending': tasks.where((t) => !t.isDone).length,
        'overdue': overdueCount,
      };
    } catch (e) {
      print('❌ Error getting task counts: $e');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'overdue': 0,
      };
    }
  }

  // Get stats summary as a formatted map
  Future<Map<String, dynamic>> getStatsSummary() async {
    try {
      final stats = await _statsService.getStats();
      final counts = await getTaskCounts();

      return {
        'totalTasks': counts['total'] ?? 0,
        'completedTasks': counts['completed'] ?? 0,
        'pendingTasks': counts['pending'] ?? 0,
        'overdueTasks': counts['overdue'] ?? 0,
        'totalClassesDone': stats['totalClassesDone'] ?? 0,
        'totalAssignmentsDone': stats['totalAssignmentsDone'] ?? 0,
        'totalLabReportsDone': stats['totalLabReportsDone'] ?? 0,
        'totalExamsDone': stats['totalExamsDone'] ?? 0,
        'totalOthersDone': stats['totalOthersDone'] ?? 0,
        'completionRate': counts['total'] != null && counts['total']! > 0
            ? ((counts['completed'] ?? 0) / (counts['total'] ?? 1) * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('❌ Error getting stats summary: $e');
      return {};
    }
  }

  /// Initialize stats for the user
  Future<void> initializeStats() async {
    try {
      await _statsService.initializeStats();
      print('✅ Stats initialized');
    } catch (e) {
      print('❌ Error initializing stats: $e');
      throw Exception('Failed to initialize stats: $e');
    }
  }

  /// Get current stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await _statsService.getStats();
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {};
    }
  }
}