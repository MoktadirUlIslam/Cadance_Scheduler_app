// lib/screens/TaskManager/services/task_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';
import 'TaskManagerStatsService.dart';

class TaskFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskManagerStatsService get _statsService => TaskManagerStatsService();

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

      // If task is already marked as done, update stats
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

        // Get tasks that match the date directly
        final dateMatchedTasks = allTasks.where((task) {
          final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
          return (taskDate.isAfter(startOfDay) || taskDate.isAtSameMomentAs(startOfDay)) &&
              (taskDate.isBefore(endOfDay) || taskDate.isAtSameMomentAs(endOfDay));
        }).toList();

        // Filter deadline-based tasks
        final deadlineTasks = allTasks.where((task) {
          if (!task.type.hasDeadline || task.deadline == null) return false;

          final targetDate = DateTime(date.year, date.month, date.day);

          // For assignments: show ONLY on the deadline date
          if (task.type == TaskType.assignment) {
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );
            return taskDeadline.isAtSameMomentAs(targetDate);
          }

          // For other deadline-based tasks (Lab Report, Others): show from start to deadline
          final taskStartDate = DateTime(task.date.year, task.date.month, task.date.day);
          final taskDeadline = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );

          final isOnOrAfterStart = targetDate.isAfter(taskStartDate) ||
              targetDate.isAtSameMomentAs(taskStartDate);
          final isOnOrBeforeDeadline = targetDate.isBefore(taskDeadline) ||
              targetDate.isAtSameMomentAs(taskDeadline);

          return isOnOrAfterStart && isOnOrBeforeDeadline;
        }).toList();

        // Combine both lists, remove duplicates by ID
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

        // Sort tasks
        allMatchedTasks.sort((a, b) {
          // First sort by completion status (pending first)
          if (a.isDone != b.isDone) {
            return a.isDone ? 1 : -1;
          }
          // Then sort by start time or deadline
          if (a.startTime != null && b.startTime != null) {
            return a.startTime!.compareTo(b.startTime!);
          }
          if (a.startTime != null) return -1;
          if (b.startTime != null) return 1;

          // If no start time, sort by deadline
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

  // Get tasks for a date range
  Stream<List<Task>> getTasksForDateRange(DateTime start, DateTime end) {
    try {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

      print('📅 Querying tasks for date range: ${DateFormat('yyyy-MM-dd').format(startOfDay)} to ${DateFormat('yyyy-MM-dd').format(endOfDay)}');

      return _tasksCollection
          .get()
          .asStream()
          .map((snapshot) {
        final allTasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        // Filter tasks that fall within the date range
        final filteredTasks = allTasks.where((task) {
          // For scheduled tasks (Classes, Exam)
          if (task.type.hasTimeRange) {
            final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
            return (taskDate.isAfter(startOfDay) || taskDate.isAtSameMomentAs(startOfDay)) &&
                (taskDate.isBefore(endOfDay) || taskDate.isAtSameMomentAs(endOfDay));
          }

          // For deadline-based tasks
          if (task.type.hasDeadline && task.deadline != null) {
            // For assignments: check if deadline is within range
            if (task.type == TaskType.assignment) {
              final taskDeadline = DateTime(
                task.deadline!.year,
                task.deadline!.month,
                task.deadline!.day,
              );
              return (taskDeadline.isAfter(startOfDay) || taskDeadline.isAtSameMomentAs(startOfDay)) &&
                  (taskDeadline.isBefore(endOfDay) || taskDeadline.isAtSameMomentAs(endOfDay));
            }

            // For other deadline-based tasks
            final taskStartDate = DateTime(task.date.year, task.date.month, task.date.day);
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );

            // Check if date range overlaps with task's active period
            final rangeStart = startOfDay;
            final rangeEnd = endOfDay;

            // Task is active if range overlaps with [taskStartDate, taskDeadline]
            final startsBeforeEnd = taskStartDate.isBefore(rangeEnd) ||
                taskStartDate.isAtSameMomentAs(rangeEnd);
            final endsAfterStart = taskDeadline.isAfter(rangeStart) ||
                taskDeadline.isAtSameMomentAs(rangeStart);

            return startsBeforeEnd && endsAfterStart;
          }

          return false;
        }).toList();

        // Sort tasks by date
        filteredTasks.sort((a, b) => a.date.compareTo(b.date));

        print('📊 Got ${filteredTasks.length} tasks for date range');
        return filteredTasks;
      }).handleError((error) {
        print('❌ Error in getTasksForDateRange stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks for date range: $e');
      return Stream.error('Failed to get tasks: $e');
    }
  }

  // Get tasks by completion status
  Stream<List<Task>> getTasksByCompletion(bool isDone) {
    try {
      return _tasksCollection
          .where('isDone', isEqualTo: isDone)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        print('📊 Got ${snapshot.docs.length} ${isDone ? 'completed' : 'pending'} tasks');
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        print('❌ Error in getTasksByCompletion stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks by completion: $e');
      return Stream.error('Failed to get tasks: $e');
    }
  }

  // Get overdue tasks
  Stream<List<Task>> getOverdueTasks() {
    try {
      final now = DateTime.now();
      return _tasksCollection
          .where('isDone', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        // Filter overdue tasks
        final overdueTasks = tasks.where((task) {
          if (task.isDone) return false;

          if (task.type.hasTimeRange) {
            // For scheduled tasks
            return task.date.isBefore(now);
          } else if (task.type.hasDeadline && task.deadline != null) {
            // For deadline-based tasks
            return task.deadline!.isBefore(now);
          }

          return false;
        }).toList();

        print('📊 Got ${overdueTasks.length} overdue tasks');
        return overdueTasks;
      }).handleError((error) {
        print('❌ Error in getOverdueTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting overdue tasks: $e');
      return Stream.error('Failed to get overdue tasks: $e');
    }
  }

  // Get tasks by type
  Stream<List<Task>> getTasksByType(TaskType type) {
    try {
      return _tasksCollection
          .where('type', isEqualTo: type.name)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        print('📊 Got ${snapshot.docs.length} ${type.label} tasks');
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        print('❌ Error in getTasksByType stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks by type: $e');
      return Stream.error('Failed to get tasks by type: $e');
    }
  }

  // Get active deadline-based tasks
  Stream<List<Task>> getActiveDeadlineTasks() {
    try {
      final now = DateTime.now();

      return _tasksCollection
          .where('deadline', isGreaterThan: Timestamp.fromDate(now))
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        // Filter only deadline-based types and not completed
        final activeTasks = tasks.where((task) {
          return task.type.hasDeadline && !task.isDone;
        }).toList();

        // Sort by deadline (earliest first)
        activeTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

        print('📊 Got ${activeTasks.length} active deadline tasks');
        return activeTasks;
      }).handleError((error) {
        print('❌ Error in getActiveDeadlineTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting active deadline tasks: $e');
      return Stream.error('Failed to get active deadline tasks: $e');
    }
  }

  // Get upcoming deadline tasks
  Stream<List<Task>> getUpcomingDeadlineTasks({int days = 7}) {
    try {
      final now = DateTime.now();
      final future = now.add(Duration(days: days));

      return _tasksCollection
          .where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('deadline', isLessThanOrEqualTo: Timestamp.fromDate(future))
          .where('isDone', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        // Filter only deadline-based types
        final upcomingTasks = tasks.where((task) {
          return task.type.hasDeadline;
        }).toList();

        // Sort by deadline (earliest first)
        upcomingTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

        print('📊 Got ${upcomingTasks.length} upcoming deadline tasks (next $days days)');
        return upcomingTasks;
      }).handleError((error) {
        print('❌ Error in getUpcomingDeadlineTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting upcoming deadline tasks: $e');
      return Stream.error('Failed to get upcoming deadline tasks: $e');
    }
  }

  // Get tasks with deadline in range
  Stream<List<Task>> getTasksWithDeadline(DateTime start, DateTime end) {
    try {
      return _tasksCollection
          .where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('deadline', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        // Filter only deadline-based types
        final filteredTasks = tasks.where((task) {
          return task.type.hasDeadline;
        }).toList();

        // Sort by deadline
        filteredTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

        print('📊 Got ${filteredTasks.length} tasks with deadline in range');
        return filteredTasks;
      }).handleError((error) {
        print('❌ Error in getTasksWithDeadline stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks with deadline: $e');
      return Stream.error('Failed to get tasks with deadline: $e');
    }
  }

  // Get tasks by course code
  Stream<List<Task>> getTasksByCourse(String courseCode) {
    try {
      return _tasksCollection
          .where('courseCode', isEqualTo: courseCode)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        print('❌ Error in getTasksByCourse stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks by course: $e');
      return Stream.error('Failed to get tasks by course: $e');
    }
  }

  // Get today's tasks count
  Future<int> getTodayTasksCount() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _tasksCollection.get();
      final allTasks = snapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data());
      }).toList();

      // Count tasks that are active today
      int count = 0;
      for (var task in allTasks) {
        if (task.type.hasTimeRange) {
          // Scheduled tasks: check if date matches today
          if (task.date.year == today.year &&
              task.date.month == today.month &&
              task.date.day == today.day) {
            count++;
          }
        } else if (task.type.hasDeadline && task.deadline != null) {
          // For assignments: check if deadline is today
          if (task.type == TaskType.assignment) {
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );
            if (taskDeadline.isAtSameMomentAs(today)) {
              count++;
            }
          } else {
            // For other deadline-based tasks: check if today is between start and deadline
            final taskStart = DateTime(task.date.year, task.date.month, task.date.day);
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );

            if ((today.isAfter(taskStart) || today.isAtSameMomentAs(taskStart)) &&
                (today.isBefore(taskDeadline) || today.isAtSameMomentAs(taskDeadline))) {
              count++;
            }
          }
        }
      }

      print('📊 Today\'s tasks count: $count');
      return count;
    } catch (e) {
      print('❌ Error getting today\'s tasks count: $e');
      return 0;
    }
  }

  // Get upcoming tasks (next 7 days)
  Stream<List<Task>> getUpcomingTasks() {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day + 7, 23, 59, 59);

      return _tasksCollection
          .get()
          .asStream()
          .map((snapshot) {
        final allTasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        // Filter tasks that fall within the next 7 days
        final upcomingTasks = allTasks.where((task) {
          if (task.type.hasTimeRange) {
            // Scheduled tasks
            final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
            return (taskDate.isAfter(startOfDay) || taskDate.isAtSameMomentAs(startOfDay)) &&
                (taskDate.isBefore(endOfDay) || taskDate.isAtSameMomentAs(endOfDay));
          } else if (task.type.hasDeadline && task.deadline != null) {
            // For assignments: check if deadline is within range
            if (task.type == TaskType.assignment) {
              final taskDeadline = DateTime(
                task.deadline!.year,
                task.deadline!.month,
                task.deadline!.day,
              );
              return (taskDeadline.isAfter(startOfDay) || taskDeadline.isAtSameMomentAs(startOfDay)) &&
                  (taskDeadline.isBefore(endOfDay) || taskDeadline.isAtSameMomentAs(endOfDay));
            }

            // For other deadline-based tasks
            final taskStart = DateTime(task.date.year, task.date.month, task.date.day);
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );

            // Check if task's active period overlaps with next 7 days
            return (taskStart.isBefore(endOfDay) || taskStart.isAtSameMomentAs(endOfDay)) &&
                (taskDeadline.isAfter(startOfDay) || taskDeadline.isAtSameMomentAs(startOfDay));
          }
          return false;
        }).toList();

        // Sort by date
        upcomingTasks.sort((a, b) => a.date.compareTo(b.date));

        print('📊 Got ${upcomingTasks.length} upcoming tasks (next 7 days)');
        return upcomingTasks;
      }).handleError((error) {
        print('❌ Error in getUpcomingTasks stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting upcoming tasks: $e');
      return Stream.error('Failed to get upcoming tasks: $e');
    }
  }

  // Update a task with stats management
  Future<Task> updateTask(Task task) async {
    try {
      if (task.id == null) throw Exception('Task ID is required for update');

      // Get old task to check if isDone changed
      final oldTask = await getTask(task.id!);

      final updatedTask = task.copyWith(
        updatedAt: DateTime.now(),
      );

      await _tasksCollection.doc(task.id).update(updatedTask.toMap());
      print('✅ Task updated: ${updatedTask.displayTitle}');

      // Update stats if isDone status changed
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

  // Bulk update tasks
  Future<void> updateTasks(List<Task> tasks) async {
    try {
      if (tasks.isEmpty) return;

      final batch = _firestore.batch();

      for (var task in tasks) {
        if (task.id == null) continue;
        final docRef = _tasksCollection.doc(task.id);
        batch.update(docRef, task.toMap());
      }

      await batch.commit();
      print('✅ Bulk updated ${tasks.length} tasks');
    } catch (e) {
      print('❌ Error bulk updating tasks: $e');
      throw Exception('Failed to bulk update tasks: $e');
    }
  }

  // Delete a task with stats management
  Future<void> deleteTask(String taskId) async {
    try {
      // Get task before deletion to update stats
      final task = await getTask(taskId);

      await _tasksCollection.doc(taskId).delete();
      print('✅ Task deleted: $taskId');

      // If task was completed, decrement stats
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

      // Count overdue tasks properly
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

  // Get tasks by priority
  Stream<List<Task>> getTasksByPriority(Priority priority) {
    try {
      return _tasksCollection
          .where('priority', isEqualTo: priority.name)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        print('❌ Error in getTasksByPriority stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting tasks by priority: $e');
      return Stream.error('Failed to get tasks by priority: $e');
    }
  }

  // ==================== STATS MANAGEMENT METHODS ====================

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

  /// Increment stats for a task type
  Future<void> incrementTaskStats(TaskType type) async {
    try {
      await _statsService.incrementTaskStats(type);
      print('✅ Stats incremented for ${type.label}');
    } catch (e) {
      print('❌ Error incrementing stats: $e');
    }
  }

  /// Decrement stats for a task type
  Future<void> decrementTaskStats(TaskType type) async {
    try {
      await _statsService.decrementTaskStats(type);
      print('✅ Stats decremented for ${type.label}');
    } catch (e) {
      print('❌ Error decrementing stats: $e');
    }
  }

  /// Get stats summary as a formatted map
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

  /// Reset all stats (use with caution)
  Future<void> resetStats() async {
    try {
      await _statsService.resetStats();
      print('✅ Stats reset');
    } catch (e) {
      print('❌ Error resetting stats: $e');
      throw Exception('Failed to reset stats: $e');
    }
  }

  /// Get stats by task type
  Future<Map<String, Map<String, int>>> getStatsByType() async {
    try {
      final result = <String, Map<String, int>>{};

      for (var type in TaskType.values) {
        final tasks = await _tasksCollection
            .where('type', isEqualTo: type.name)
            .get();

        final taskList = tasks.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();

        // Count overdue for deadline-based types
        int overdue = 0;
        if (type.hasDeadline) {
          final now = DateTime.now();
          overdue = taskList.where((t) =>
          !t.isDone && t.deadline != null && t.deadline!.isBefore(now)
          ).length;
        }

        result[type.label] = {
          'total': taskList.length,
          'completed': taskList.where((t) => t.isDone).length,
          'pending': taskList.where((t) => !t.isDone).length,
          'overdue': overdue,
        };
      }

      return result;
    } catch (e) {
      print('❌ Error getting stats by type: $e');
      return {};
    }
  }

  /// Get completion rate by date range
  Future<double> getCompletionRate(DateTime start, DateTime end) async {
    try {
      final snapshot = await _tasksCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();

      if (tasks.isEmpty) return 0.0;

      final completed = tasks.where((t) => t.isDone).length;
      return (completed / tasks.length) * 100;
    } catch (e) {
      print('❌ Error getting completion rate: $e');
      return 0.0;
    }
  }

  /// Get weekly stats
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - 7);
      final weekEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _tasksCollection.get();
      final allTasks = snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();

      // Filter tasks in date range
      final tasks = allTasks.where((task) {
        if (task.type.hasTimeRange) {
          return task.date.isAfter(weekStart) && task.date.isBefore(weekEnd);
        } else if (task.type.hasDeadline && task.deadline != null) {
          // For assignments: check if deadline is in range
          if (task.type == TaskType.assignment) {
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );
            return (taskDeadline.isAfter(weekStart) || taskDeadline.isAtSameMomentAs(weekStart)) &&
                (taskDeadline.isBefore(weekEnd) || taskDeadline.isAtSameMomentAs(weekEnd));
          }

          // For other deadline-based tasks
          final taskStart = task.date;
          final taskDeadline = task.deadline!;
          return (taskStart.isBefore(weekEnd) || taskStart.isAtSameMomentAs(weekEnd)) &&
              (taskDeadline.isAfter(weekStart) || taskDeadline.isAtSameMomentAs(weekStart));
        }
        return false;
      }).toList();

      final dailyStats = <String, int>{};
      for (var i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final key = DateFormat('yyyy-MM-dd').format(date);
        final dayTasks = tasks.where((t) {
          if (t.type.hasTimeRange) {
            return t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day;
          } else if (t.type.hasDeadline && t.deadline != null) {
            // For assignments: check if deadline matches the date
            if (t.type == TaskType.assignment) {
              final taskDeadline = DateTime(
                t.deadline!.year,
                t.deadline!.month,
                t.deadline!.day,
              );
              return taskDeadline.year == date.year &&
                  taskDeadline.month == date.month &&
                  taskDeadline.day == date.day;
            }

            // For other deadline-based tasks
            final taskStart = DateTime(t.date.year, t.date.month, t.date.day);
            final taskDeadline = DateTime(
              t.deadline!.year,
              t.deadline!.month,
              t.deadline!.day,
            );
            return (date.isAfter(taskStart) || date.isAtSameMomentAs(taskStart)) &&
                (date.isBefore(taskDeadline) || date.isAtSameMomentAs(taskDeadline));
          }
          return false;
        }).toList();
        dailyStats[key] = dayTasks.where((t) => t.isDone).length;
      }

      return {
        'totalTasks': tasks.length,
        'completedTasks': tasks.where((t) => t.isDone).length,
        'dailyStats': dailyStats,
        'completionRate': tasks.isEmpty ? 0.0 : (tasks.where((t) => t.isDone).length / tasks.length) * 100,
      };
    } catch (e) {
      print('❌ Error getting weekly stats: $e');
      return {};
    }
  }

  /// Get monthly stats
  Future<Map<String, dynamic>> getMonthlyStats() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _tasksCollection.get();
      final allTasks = snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();

      // Filter tasks in month range
      final tasks = allTasks.where((task) {
        if (task.type.hasTimeRange) {
          return task.date.isAfter(monthStart) && task.date.isBefore(monthEnd);
        } else if (task.type.hasDeadline && task.deadline != null) {
          // For assignments: check if deadline is in range
          if (task.type == TaskType.assignment) {
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );
            return (taskDeadline.isAfter(monthStart) || taskDeadline.isAtSameMomentAs(monthStart)) &&
                (taskDeadline.isBefore(monthEnd) || taskDeadline.isAtSameMomentAs(monthEnd));
          }

          // For other deadline-based tasks
          final taskStart = task.date;
          final taskDeadline = task.deadline!;
          return (taskStart.isBefore(monthEnd) || taskStart.isAtSameMomentAs(monthEnd)) &&
              (taskDeadline.isAfter(monthStart) || taskDeadline.isAtSameMomentAs(monthStart));
        }
        return false;
      }).toList();

      return {
        'totalTasks': tasks.length,
        'completedTasks': tasks.where((t) => t.isDone).length,
        'completionRate': tasks.isEmpty ? 0.0 : (tasks.where((t) => t.isDone).length / tasks.length) * 100,
        'tasksByType': await getStatsByType(),
      };
    } catch (e) {
      print('❌ Error getting monthly stats: $e');
      return {};
    }
  }

  // ==================== ADDITIONAL HELPER METHODS ====================

  /// Get tasks that are active on a specific date (including deadline-based tasks)
  Stream<List<Task>> getActiveTasksForDate(DateTime date) {
    try {
      final targetDate = DateTime(date.year, date.month, date.day);

      return _tasksCollection.get().asStream().map((snapshot) {
        final allTasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        final activeTasks = allTasks.where((task) {
          if (task.isDone) return false;

          if (task.type.hasTimeRange) {
            // Scheduled tasks: check if date matches
            return task.date.year == targetDate.year &&
                task.date.month == targetDate.month &&
                task.date.day == targetDate.day;
          } else if (task.type.hasDeadline && task.deadline != null) {
            // For assignments: check if deadline matches
            if (task.type == TaskType.assignment) {
              final taskDeadline = DateTime(
                task.deadline!.year,
                task.deadline!.month,
                task.deadline!.day,
              );
              return taskDeadline.year == targetDate.year &&
                  taskDeadline.month == targetDate.month &&
                  taskDeadline.day == targetDate.day;
            }

            // For other deadline-based tasks
            final taskStart = DateTime(task.date.year, task.date.month, task.date.day);
            final taskDeadline = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );

            return (targetDate.isAfter(taskStart) || targetDate.isAtSameMomentAs(taskStart)) &&
                (targetDate.isBefore(taskDeadline) || targetDate.isAtSameMomentAs(taskDeadline));
          }
          return false;
        }).toList();

        return activeTasks;
      }).handleError((error) {
        print('❌ Error in getActiveTasksForDate stream: $error');
        return <Task>[];
      });
    } catch (e) {
      print('❌ Error getting active tasks for date: $e');
      return Stream.error('Failed to get active tasks: $e');
    }
  }

  /// Get task completion stats by date
  Future<Map<String, dynamic>> getTaskCompletionStats(DateTime date) async {
    try {
      final tasks = await getTasksForDate(date).first;
      final completed = tasks.where((t) => t.isDone).length;

      return {
        'total': tasks.length,
        'completed': completed,
        'pending': tasks.length - completed,
        'completionRate': tasks.isEmpty ? 0.0 : (completed / tasks.length * 100),
      };
    } catch (e) {
      print('❌ Error getting task completion stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'completionRate': 0.0,
      };
    }
  }

  /// NEW: Check if stats exist
  Future<bool> statsExist() async {
    try {
      return await _statsService.statsExist();
    } catch (e) {
      print('❌ Error checking stats existence: $e');
      return false;
    }
  }

  /// NEW: Get stats with timestamp
  Future<Map<String, dynamic>> getStatsWithTimestamp() async {
    try {
      return await _statsService.getStatsWithTimestamp();
    } catch (e) {
      print('❌ Error getting stats with timestamp: $e');
      return {};
    }
  }

  /// NEW: Get stats for date range
  Future<Map<String, dynamic>> getStatsForDateRange(DateTime start, DateTime end) async {
    try {
      return await _statsService.getStatsForDateRange(start, end);
    } catch (e) {
      print('❌ Error getting stats for date range: $e');
      return {};
    }
  }

  /// NEW: Get completion rate
  Future<double> getCompletionRateStats() async {
    try {
      return await _statsService.getCompletionRate();
    } catch (e) {
      print('❌ Error getting completion rate: $e');
      return 0.0;
    }
  }
}