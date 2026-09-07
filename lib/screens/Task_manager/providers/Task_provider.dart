// lib/providers/task_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../models/taskmanager_model.dart';
import '../../../services/firebase_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  CollectionReference<Map<String, dynamic>> _getTasksCollection() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  Future<List<Task>> submitTask(Task task) async {
    if (task.type == TaskType.classes && task.isRecurring) {
      return await createRecurringClass(task);
    } else {
      final created = await createTask(task);
      return [created];
    }
  }

  /// ✅ UPDATED: now also converts raw Enum values to their `.name`
  /// string, since Firestore's native plugin cannot serialize a Dart
  /// enum instance directly — it will fail with an opaque native
  /// error (often surfacing as "Unexpected null value" or a codec
  /// error) rather than a clear Dart exception.
  dynamic _deepClean(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }
    if (value is Enum) {
      return value.name;
    }
    if (value is Map) {
      final cleaned = <String, dynamic>{};
      value.forEach((k, v) {
        final cv = _deepClean(v);
        if (cv != null) cleaned[k.toString()] = cv;
      });
      return cleaned;
    }
    if (value is List) {
      return value
          .map((v) => _deepClean(v))
          .where((v) => v != null)
          .toList();
    }
    return value;
  }

  /// ✅ NEW: Walks the fully-cleaned map and throws a precise exception
  /// naming the exact key/path if anything unsupported remains —
  /// instead of letting Firestore's native plugin throw its vague
  /// "Unexpected null value" with no indication of which field it was.
  void _validateForFirestore(dynamic value, String path) {
    if (value == null) {
      throw Exception('Invalid value at "$path": still null after cleaning');
    }
    if (value is String || value is num || value is bool || value is Timestamp) {
      return; // supported primitives
    }
    if (value is Map) {
      value.forEach((k, v) => _validateForFirestore(v, '$path.$k'));
      return;
    }
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _validateForFirestore(value[i], '$path[$i]');
      }
      return;
    }
    // Anything else (raw enum, custom object, etc.) is unsupported.
    throw Exception(
      'Invalid value at "$path": ${value.runtimeType} (${value.toString()}) — '
          'not a String/num/bool/Timestamp/Map/List. This is almost certainly '
          'the source of "Unexpected null value" or a native codec crash.',
    );
  }

  /// ✅ Clean null values and ensure required fields have defaults
  Map<String, dynamic> _prepareTaskMap(Task task) {
    final map = task.toMap();

    final requiredFields = {
      'recurrenceFrequency': RecurrenceFrequency.none.name,
      'recurringInstanceIndex': 0,
      'isRecurringParent': false,
      'autoCompleted': false,
      'totalExtensions': 0,
      'countedInStats': false,
      'isDone': false,
      'alarmOn': false,
      'reminders': <String>[],
    };

    requiredFields.forEach((key, defaultValue) {
      if (!map.containsKey(key) || map[key] == null) {
        map[key] = defaultValue;
      }
    });

    final cleaned = _deepClean(map) as Map<String, dynamic>;

    // ✅ Validate before it ever reaches Firestore. If this throws,
    // the exception message tells you EXACTLY which field is bad —
    // check your debug console for "Invalid value at ...".
    try {
      _validateForFirestore(cleaned, 'root');
    } catch (e) {
      debugPrint('🚨 $e');
      debugPrint('🚨 Full map at failure: $cleaned');
      rethrow;
    }

    return cleaned;
  }

  Future<Task> createTask(Task task) async {
    if (task.type == TaskType.classes && task.isRecurring) {
      final created = await createRecurringClass(task);
      if (created.isEmpty) {
        throw Exception('Failed to create any recurring class instances');
      }
      return created.firstWhere(
            (t) => t.isRecurringParent,
        orElse: () => created.first,
      );
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final taskToCreate = task.userId.isEmpty
          ? task.copyWith(userId: user.uid)
          : task;

      final Map<String, dynamic> taskMap = _prepareTaskMap(taskToCreate);

      final docRef = await _getTasksCollection().add(taskMap);

      final createdTask = taskToCreate.copyWith(id: docRef.id);

      _tasks.insert(0, createdTask);
      _isLoading = false;
      notifyListeners();

      return createdTask;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create task: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Task>> createRecurringClass(Task parentTask) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final instances = _generateRecurringInstances(parentTask);
      final List<Task> createdInstances = [];
      final List<String> failedDates = [];

      for (final instance in instances) {
        try {
          final taskToCreate = instance.userId.isEmpty
              ? instance.copyWith(userId: user.uid)
              : instance;

          final Map<String, dynamic> taskMap = _prepareTaskMap(taskToCreate);

          final docRef = await _getTasksCollection().add(taskMap);
          final created = taskToCreate.copyWith(id: docRef.id);
          createdInstances.add(created);
          _tasks.insert(0, created);
        } catch (e) {
          failedDates.add('${instance.date} — $e');
        }
      }

      _isLoading = false;
      notifyListeners();

      if (failedDates.isNotEmpty) {
        _error = 'Stored ${createdInstances.length}/${instances.length} classes. '
            'Failures:\n${failedDates.join("\n")}';
        debugPrint('⚠️ $_error');
      }

      if (createdInstances.isEmpty) {
        throw Exception('Failed to create any recurring class instances');
      }

      return createdInstances;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create recurring class: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  List<Task> _generateRecurringInstances(Task parentTask) {
    if (!parentTask.isRecurring || parentTask.recurringStartDate == null) {
      return [parentTask];
    }

    final List<Task> instances = [];
    final interval = parentTask.recurrenceFrequency.days;
    if (interval == 0) return [parentTask];

    DateTime currentDate = DateTime(
      parentTask.recurringStartDate!.year,
      parentTask.recurringStartDate!.month,
      parentTask.recurringStartDate!.day,
    );
    final rawEndDate = parentTask.recurringEndDate ?? currentDate.add(const Duration(days: 120));
    final endDate = DateTime(rawEndDate.year, rawEndDate.month, rawEndDate.day);

    int index = 0;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final instance = parentTask.copyWith(
        id: null,
        date: currentDate,
        recurringGroupId: parentTask.recurringGroupId,
        startTime: parentTask.startTime != null
            ? DateTime(currentDate.year, currentDate.month, currentDate.day,
            parentTask.startTime!.hour, parentTask.startTime!.minute)
            : null,
        endTime: parentTask.endTime != null
            ? DateTime(currentDate.year, currentDate.month, currentDate.day,
            parentTask.endTime!.hour, parentTask.endTime!.minute)
            : null,
        recurringInstanceIndex: index,
        isRecurringParent: index == 0,
        isDone: false,
        completedAt: null,
        autoCompleted: false,
        autoCompletedAt: null,
        autoCompletionSource: null,
        countedInStats: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      instances.add(instance);
      currentDate = currentDate.add(Duration(days: interval));
      index++;
    }

    return instances;
  }

  Future<Task> updateTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      if (task.id == null || task.id!.isEmpty) {
        throw Exception('Task ID is required for update');
      }
      final Map<String, dynamic> taskMap = _prepareTaskMap(task);
      await _getTasksCollection().doc(task.id!).update(taskMap);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      } else {
        _tasks.insert(0, task);
      }
      _isLoading = false;
      notifyListeners();
      return task;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update task: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Task>> updateRecurringClass(Task updatedParent) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      if (updatedParent.recurringGroupId == null) {
        throw Exception('Recurring group ID is required');
      }
      final instancesToUpdate = _tasks
          .where((t) => t.recurringGroupId == updatedParent.recurringGroupId)
          .toList();
      if (instancesToUpdate.isEmpty) {
        throw Exception('No recurring instances found');
      }
      final List<Task> updatedInstances = [];
      for (final instance in instancesToUpdate) {
        final updatedInstance = instance.copyWith(
          courseCode: updatedParent.courseCode,
          courseTitle: updatedParent.courseTitle,
          startTime: updatedParent.startTime != null
              ? DateTime(instance.date.year, instance.date.month, instance.date.day,
              updatedParent.startTime!.hour, updatedParent.startTime!.minute)
              : null,
          endTime: updatedParent.endTime != null
              ? DateTime(instance.date.year, instance.date.month, instance.date.day,
              updatedParent.endTime!.hour, updatedParent.endTime!.minute)
              : null,
          location: updatedParent.location,
          teacherName: updatedParent.teacherName,
          teacherName2: updatedParent.teacherName2,
          priority: updatedParent.priority,
          reminders: updatedParent.reminders,
          alarmOn: updatedParent.alarmOn,
          classType: updatedParent.classType,
          updatedAt: DateTime.now(),
        );
        final Map<String, dynamic> taskMap = _prepareTaskMap(updatedInstance);
        await _getTasksCollection().doc(instance.id!).update(taskMap);
        final index = _tasks.indexWhere((t) => t.id == instance.id);
        if (index != -1) {
          _tasks[index] = updatedInstance;
          updatedInstances.add(updatedInstance);
        }
      }
      _isLoading = false;
      notifyListeners();
      return updatedInstances;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update recurring class: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<Task> toggleTaskDone(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      if (task.id == null || task.id!.isEmpty) {
        throw Exception('Task ID is required');
      }
      final updatedTask = task.toggleDone();
      final Map<String, dynamic> updateData = {
        'isDone': updatedTask.isDone,
        'updatedAt': Timestamp.fromDate(updatedTask.updatedAt),
      };
      if (updatedTask.completedAt != null) {
        updateData['completedAt'] = Timestamp.fromDate(updatedTask.completedAt!);
      } else {
        updateData['completedAt'] = null;
      }
      await _getTasksCollection().doc(task.id!).update(updateData);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      } else {
        _tasks.insert(0, updatedTask);
      }
      _isLoading = false;
      notifyListeners();
      return updatedTask;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to toggle task: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await _getTasksCollection().doc(taskId).delete();
      _tasks.removeWhere((t) => t.id == taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete task: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecurringClass(String recurringGroupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final instancesToDelete =
      _tasks.where((t) => t.recurringGroupId == recurringGroupId).toList();
      if (instancesToDelete.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      final batch = _firestore.batch();
      for (final instance in instancesToDelete) {
        if (instance.id != null) {
          batch.delete(_getTasksCollection().doc(instance.id!));
        }
      }
      await batch.commit();
      _tasks.removeWhere((t) => t.recurringGroupId == recurringGroupId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete recurring class: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final batch = _firestore.batch();
      for (final taskId in taskIds) {
        batch.delete(_getTasksCollection().doc(taskId));
      }
      await batch.commit();
      _tasks.removeWhere((t) => taskIds.contains(t.id));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete multiple tasks: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> archiveCompletedTasks() async {
    final completedTasks = _tasks.where((t) => t.isDone).toList();
    if (completedTasks.isEmpty) return;
    final taskIds = completedTasks.map((t) => t.id!).toList();
    await deleteMultipleTasks(taskIds);
  }

  Future<void> markTasksDone(List<String> taskIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();
      for (final taskId in taskIds) {
        Task? task;
        try {
          task = _tasks.firstWhere((t) => t.id == taskId);
        } catch (_) {
          continue;
        }
        final updatedTask = task.toggleDone();
        final docRef = _getTasksCollection().doc(taskId);
        batch.update(docRef, {
          'isDone': true,
          'completedAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) _tasks[index] = updatedTask;
      }
      await batch.commit();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to mark tasks as done: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markTasksPending(List<String> taskIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final batch = _firestore.batch();
      for (final taskId in taskIds) {
        Task? task;
        try {
          task = _tasks.firstWhere((t) => t.id == taskId);
        } catch (_) {
          continue;
        }
        final updatedTask = task.toggleDone();
        final docRef = _getTasksCollection().doc(taskId);
        batch.update(docRef, {
          'isDone': false,
          'completedAt': null,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) _tasks[index] = updatedTask;
      }
      await batch.commit();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to mark tasks as pending: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Task> getTasksByRecurringGroup(String recurringGroupId) {
    return _tasks.where((t) => t.recurringGroupId == recurringGroupId).toList();
  }

  Task? getRecurringParent(String recurringGroupId) {
    try {
      return _tasks.firstWhere(
              (t) => t.recurringGroupId == recurringGroupId && t.isRecurringParent);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _tasks.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}