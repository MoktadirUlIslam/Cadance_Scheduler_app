// lib/screens/TaskManager/services/task_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';
import 'TaskManagerStatsService.dart';

class TaskFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ FIXED: Use lazy getter with proper initialization
  TaskManagerStatsService? _statsService;
  TaskManagerStatsService get statsService {
    _statsService ??= TaskManagerStatsService();
    return _statsService!;
  }

  // ✅ FIXED: Get current user with proper null safety
  User? get _currentUser => _auth.currentUser;

  // ✅ FIXED: Get tasks collection reference with proper error handling
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final user = _currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
  }

  // ✅ FIXED: Get stats collection reference
  CollectionReference<Map<String, dynamic>> get _statsCollection {
    final user = _currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats');
  }

  String get _userId {
    final user = _currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<Task> createTask(Task task) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _tasksCollection.doc();
      final now = DateTime.now();

      final newTask = task.copyWith(
        id: docRef.id,
        userId: user.uid,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(newTask.toMap());
      print('✅ Task created: ${newTask.displayTitle} with ID: ${newTask.id}');
      print('   📋 Type: ${newTask.type.label}');
      print('   📅 Date: ${DateFormat('yyyy-MM-dd').format(newTask.date)}');
      if (newTask.deadline != null) {
        print('   ⏰ Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(newTask.deadline!)}');
      }

      // Update stats if task is already done
      if (newTask.isDone) {
        await statsService.incrementTaskStats(newTask.type);
      }

      return newTask;
    } catch (e) {
      print('❌ Error creating task: $e');
      rethrow;
    }
  }

  // ============================================================
  // READ - Streams
  // ============================================================

  Stream<List<Task>> getTasks() {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getTasks');
        return Stream.value([]);
      }

      return _tasksCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        print('📊 Got ${snapshot.docs.length} tasks from Firestore');
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      })
          .handleError((error) {
        print('❌ Error in getTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks stream: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Task>> getTasksForDate(DateTime date) {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getTasksForDate');
        return Stream.value([]);
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      print('📅 Querying tasks for date: ${DateFormat('yyyy-MM-dd').format(startOfDay)}');

      return _tasksCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        print('📊 Got ${tasks.length} tasks for ${DateFormat('yyyy-MM-dd').format(date)}');

        // Sort tasks: pending first, then by start time or deadline
        tasks.sort((a, b) {
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

        return tasks;
      })
          .handleError((error) {
        print('❌ Error in getTasksForDate stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks for date: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Task>> getTasksByCompletion(bool isDone) {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getTasksByCompletion');
        return Stream.value([]);
      }

      return _tasksCollection
          .where('isDone', isEqualTo: isDone)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        print('📊 Got ${snapshot.docs.length} ${isDone ? 'completed' : 'pending'} tasks');
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      })
          .handleError((error) {
        print('❌ Error in getTasksByCompletion stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks by completion: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Task>> getOverdueTasks() {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getOverdueTasks');
        return Stream.value([]);
      }

      final now = DateTime.now();
      return _tasksCollection
          .where('isDone', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        final overdueTasks = tasks.where((task) {
          if (task.isDone) return false;
          if (task.type.hasTimeRange && task.endTime != null) {
            return task.endTime!.isBefore(now);
          }
          if (task.type.hasDeadline && task.deadline != null) {
            return task.deadline!.isBefore(now);
          }
          return false;
        }).toList();

        print('📊 Got ${overdueTasks.length} overdue tasks');
        return overdueTasks;
      })
          .handleError((error) {
        print('❌ Error in getOverdueTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting overdue tasks: $e');
      return Stream.value([]);
    }
  }

  // ============================================================
  // READ - Single
  // ============================================================

  Future<Task?> getTask(String taskId) async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getTask');
        return null;
      }

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

  // ============================================================
  // UPDATE
  // ============================================================

  Future<Task> updateTask(Task task) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (task.id == null) {
        throw Exception('Task ID is required for update');
      }

      // Get old task before updating
      final oldTask = await getTask(task.id!);

      final updatedTask = task.copyWith(
        updatedAt: DateTime.now(),
      );

      await _tasksCollection.doc(task.id).update(updatedTask.toMap());
      print('✅ Task updated: ${updatedTask.displayTitle}');

      // Update stats if completion status changed
      if (oldTask != null && oldTask.isDone != updatedTask.isDone) {
        if (updatedTask.isDone) {
          await statsService.incrementTaskStats(updatedTask.type);
          print('📊 Stats incremented for ${updatedTask.type.label}');
        } else {
          await statsService.decrementTaskStats(updatedTask.type);
          print('📊 Stats decremented for ${updatedTask.type.label}');
        }
      }

      return updatedTask;
    } catch (e) {
      print('❌ Error updating task: $e');
      rethrow;
    }
  }

  Future<void> updateTasks(List<Task> tasks) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (tasks.isEmpty) return;

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var task in tasks) {
        if (task.id == null) continue;
        final updatedTask = task.copyWith(updatedAt: now);
        final docRef = _tasksCollection.doc(task.id);
        batch.update(docRef, updatedTask.toMap());
      }

      await batch.commit();
      print('✅ Bulk updated ${tasks.length} tasks');
    } catch (e) {
      print('❌ Error bulk updating tasks: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteTask(String taskId) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get task before deleting for stats update
      final task = await getTask(taskId);

      await _tasksCollection.doc(taskId).delete();
      print('✅ Task deleted: $taskId');

      // Decrement stats if task was completed
      if (task != null && task.isDone) {
        await statsService.decrementTaskStats(task.type);
        print('📊 Stats decremented for deleted ${task.type.label}');
      }
    } catch (e) {
      print('❌ Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> deleteTasks(List<String> taskIds) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (taskIds.isEmpty) return;

      final batch = _firestore.batch();

      for (var taskId in taskIds) {
        final docRef = _tasksCollection.doc(taskId);
        batch.delete(docRef);
      }

      await batch.commit();
      print('✅ Bulk deleted ${taskIds.length} tasks');
    } catch (e) {
      print('❌ Error bulk deleting tasks: $e');
      rethrow;
    }
  }

  // ============================================================
  // STATS - Delegated to TaskManagerStatsService
  // ============================================================

  /// Get task counts by status
  Future<Map<String, int>> getTaskCounts() async {
    try {
      final user = _currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for getTaskCounts');
        return {
          'total': 0,
          'completed': 0,
          'pending': 0,
          'overdue': 0,
        };
      }

      final snapshot = await _tasksCollection.get();
      final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();

      final now = DateTime.now();
      int overdueCount = 0;
      for (var task in tasks) {
        if (!task.isDone) {
          if (task.type.hasTimeRange && task.endTime != null && task.endTime!.isBefore(now)) {
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

  /// Get stats
  Future<Map<String, dynamic>> getStats() async {
    return await statsService.getStats();
  }

  /// Initialize stats
  Future<void> initializeStats() async {
    await statsService.initializeStats();
  }

  /// Get stats summary
  Future<Map<String, dynamic>> getStatsSummary() async {
    final stats = await statsService.getStats();
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
  }

  /// Check if stats exist
  Future<bool> statsExist() async {
    return await statsService.statsExist();
  }

  /// Reset stats
  Future<void> resetStats() async {
    await statsService.resetStats();
  }

  /// Get stats with timestamp
  Future<Map<String, dynamic>> getStatsWithTimestamp() async {
    return await statsService.getStatsWithTimestamp();
  }

  /// Get stats for date range
  Future<Map<String, dynamic>> getStatsForDateRange(DateTime start, DateTime end) async {
    return await statsService.getStatsForDateRange(start, end);
  }

  /// Get completion rate
  Future<double> getCompletionRateStats() async {
    return await statsService.getCompletionRate();
  }

  /// Get stats by type
  Future<Map<String, Map<String, int>>> getStatsByType() async {
    return await statsService.getStatsByType();
  }
}