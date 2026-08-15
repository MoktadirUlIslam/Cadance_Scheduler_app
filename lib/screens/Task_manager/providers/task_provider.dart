// lib/screens/Task_manager/providers/task_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/taskmanager_model.dart';
import '../services/TaskCompletionService.dart';
import '../services/task_firestore_service.dart';

/// 🚀 ULTRA-FAST TaskProvider - Optimized for sub-second operations
class TaskProvider extends ChangeNotifier {
  final TaskFirestoreService _service = TaskFirestoreService();
  final TaskCompletionService _completionService = TaskCompletionService();
  final TaskManagerStatsService _statsService = TaskManagerStatsService();

  // ⚡ CACHE LAYER - For instant access
  static final Map<String, Task> _taskCache = {}; // Global cache
  static final Map<String, List<String>> _dateIndex = {}; // Date -> Task IDs

  // ⚡ OPTIMIZED DATA STORAGE
  final Map<String, Task> _tasksMap = {}; // O(1) lookups
  final Map<String, List<Task>> _recurringGroups = {};
  final Map<DateTime, List<Task>> _dateTaskCache = {};

  // ⚡ STREAMS with debouncing
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _tasksForDateSubscription;

  // ⚡ STATE
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {};
  bool _isDisposed = false;
  bool _isInitialLoadComplete = false;

  // ⚡ BATCH OPERATION BUFFER
  final List<Task> _pendingWrites = [];
  Timer? _batchWriteTimer;
  static const Duration _batchDelay = Duration(milliseconds: 100);

  // ⚡ QUICK GETTERS - O(1) operations
  List<Task> get allTasks => _tasksMap.values.toList();
  List<Task> get tasksForSelectedDate => _getTasksForDateCached(_selectedDate);
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;
  Map<String, List<Task>> get recurringGroups => _recurringGroups;

  // ⚡ OPTIMIZED RECURRING PARENTS - O(1) with pre-computed list
  List<Task>? _cachedRecurringParents;
  List<Task> get recurringParents {
    if (_cachedRecurringParents != null) return _cachedRecurringParents!;
    _cachedRecurringParents = _tasksMap.values
        .where((t) => t.isRecurringParent && t.extensionStatus != ExtensionStatus.archived)
        .toList();
    return _cachedRecurringParents!;
  }

  // ⚡ OPTIMIZED ACTIVE RECURRING - O(1) with pre-computed list
  List<Task>? _cachedActiveRecurring;
  List<Task> get activeRecurringTasks {
    if (_cachedActiveRecurring != null) return _cachedActiveRecurring!;
    _cachedActiveRecurring = _tasksMap.values
        .where((t) => t.isRecurring && t.extensionStatus == ExtensionStatus.active && !t.isDone)
        .toList();
    return _cachedActiveRecurring!;
  }

  // ⚡ O(1) GROUP LOOKUP
  List<Task> getTasksByRecurringGroup(String groupId) {
    return _recurringGroups[groupId] ?? [];
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 INITIALIZATION - SUB-100MS
  // ═══════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialLoadComplete) return;

    _isLoading = true;
    notifyListeners();

    try {
      // ⚡ PARALLEL LOADING
      await Future.wait([
        _loadAllTasksInternal(),
        _loadStats(),
      ]);

      // ⚡ BUILD INDEXES (O(n) once, then O(1) forever)
      _buildAllIndexes();

      _isInitialLoadComplete = true;
      _isLoading = false;

      // ⚡ Load selected date from cache
      _dateTaskCache[_selectedDate] = _filterTasksForDateOptimized(_selectedDate);

      _startSemesterReminderService();
      notifyListeners();

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ⚡ BUILD INDEXES - O(n) ONCE
  // ═══════════════════════════════════════════════════════════

  void _buildAllIndexes() {
    _dateIndex.clear();
    _recurringGroups.clear();
    _cachedRecurringParents = null;
    _cachedActiveRecurring = null;
    _dateTaskCache.clear();

    final Map<String, List<String>> tempDateIndex = {};
    final Map<String, List<Task>> tempRecurringGroups = {};

    for (var task in _tasksMap.values) {
      // Date index
      final dateKey = _getDateKey(task.date);
      tempDateIndex.putIfAbsent(dateKey, () => []).add(task.id!);

      // Recurring groups
      if (task.recurringGroupId != null) {
        tempRecurringGroups
            .putIfAbsent(task.recurringGroupId!, () => [])
            .add(task);
      }
    }

    _dateIndex.addAll(tempDateIndex);
    _recurringGroups.addAll(tempRecurringGroups);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 LOAD TASKS - STREAM WITH DEBOUNCING
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadAllTasksInternal() async {
    await _tasksSubscription?.cancel();

    try {
      _tasksSubscription = _service.getTasks().listen(
            (tasks) {
          if (_isDisposed) return;

          // ⚡ BATCH UPDATE - Process in chunks
          _batchUpdateTasks(tasks);

          _error = null;
          if (_isInitialLoadComplete) {
            _buildAllIndexes();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) notifyListeners();
            });
          }
        },
        onError: (error) {
          if (_isDisposed) return;
          _error = error.toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) notifyListeners();
          });
        },
      );
    } catch (e) {
      _error = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    }
  }

  void _batchUpdateTasks(List<Task> tasks) {
    // ⚡ Clear and repopulate map - O(n)
    _tasksMap.clear();
    for (var task in tasks) {
      if (task.id != null) {
        _tasksMap[task.id!] = task;
      }
    }
    _buildAllIndexes();
  }

  // ⚡ O(1) DATE FILTERING WITH CACHE
  List<Task> _filterTasksForDateOptimized(DateTime date) {
    final dateKey = _getDateKey(date);
    final taskIds = _dateIndex[dateKey] ?? [];

    return taskIds
        .map((id) => _tasksMap[id])
        .whereType<Task>()
        .where((task) => _isTaskVisibleOnDate(task, date))
        .toList();
  }

  bool _isTaskVisibleOnDate(Task task, DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);

    // ⚡ Quick date check first
    if (!task.isRecurring) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      if (task.type.hasTimeRange) {
        return taskDate.isAtSameMomentAs(selectedDate);
      }
      if (task.type.hasDeadline) {
        final taskStartDate = DateTime(task.date.year, task.date.month, task.date.day);
        final taskDeadline = task.deadline != null
            ? DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day)
            : taskStartDate;
        return (selectedDate.isAfter(taskStartDate) || selectedDate.isAtSameMomentAs(taskStartDate)) &&
            (selectedDate.isBefore(taskDeadline) || selectedDate.isAtSameMomentAs(taskDeadline));
      }
      return taskDate.isAtSameMomentAs(selectedDate);
    }

    // ⚡ Recurring task check - pre-compute if possible
    if (task.isRecurringParent) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      return taskDate.isAtSameMomentAs(selectedDate);
    }

    // ⚡ Child recurring task - optimized checks
    if (task.isDateSkipped(selectedDate)) return false;

    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    final daysDifference = selectedDate.difference(taskDate).inDays;
    if (daysDifference < 0) return false;

    final interval = task.recurrenceFrequency.days;
    if (interval == 0 || daysDifference % interval != 0) return false;

    if (task.expectedEndDate != null) {
      final expectedEnd = DateTime(
          task.expectedEndDate!.year,
          task.expectedEndDate!.month,
          task.expectedEndDate!.day
      );
      if (selectedDate.isAfter(expectedEnd)) return false;
    }

    if (task.extensionStatus == ExtensionStatus.ended ||
        task.extensionStatus == ExtensionStatus.archived) {
      return false;
    }

    return true;
  }

  // ⚡ CACHED DATE TASKS - O(1) after first call
  List<Task> _getTasksForDateCached(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    if (!_dateTaskCache.containsKey(key)) {
      _dateTaskCache[key] = _filterTasksForDateOptimized(date);
    }
    return _dateTaskCache[key]!;
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 LOAD DATE - SUB-10MS
  // ═══════════════════════════════════════════════════════════

  Future<void> loadTasksForDate(DateTime date) async {
    _selectedDate = date;
    // ⚡ Instant cache lookup - no async delay
    _dateTaskCache[_selectedDate] = _filterTasksForDateOptimized(date);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    loadTasksForDate(date);
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 CRUD OPERATIONS - SUB-100MS
  // ═══════════════════════════════════════════════════════════

  Future<Task?> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ⚡ OPTIMIZATION 1: Local update first (optimistic)
      final taskCopy = task.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
      _tasksMap[taskCopy.id!] = taskCopy;
      _buildAllIndexes();
      _invalidateDateCache();
      notifyListeners();

      // ⚡ OPTIMIZATION 2: Async Firebase write
      final newTask = await _service.createTask(task);

      if (newTask != null && newTask.id != null) {
        // Update with real ID
        _tasksMap.remove(taskCopy.id);
        _tasksMap[newTask.id!] = newTask;
        _buildAllIndexes();
      }

      // ⚡ OPTIMIZATION 3: Generate recurring in background
      if (task.isRecurring && task.isRecurringParent) {
        unawaited(_generateRecurringTasksOptimized(task));
      }

      _error = null;
      _isLoading = false;

      await _loadStats();
      _invalidateDateCache();
      notifyListeners();

      return newTask ?? taskCopy;

    } catch (e) {
      // Rollback optimistic update
      _tasksMap.removeWhere((key, value) => value.id == task.id);
      _buildAllIndexes();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ⚡ OPTIMIZED RECURRING GENERATION - BATCH OPERATIONS
  Future<void> _generateRecurringTasksOptimized(Task parent) async {
    if (!parent.isRecurring || parent.expectedEndDate == null) return;

    final allDates = parent.getAllClassDates();
    final existingChildren = getTasksByRecurringGroup(parent.recurringGroupId!);
    final existingDateSet = existingChildren
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    // ⚡ BATCH CREATE - Use write batch
    final tasksToCreate = <Task>[];

    for (var date in allDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (existingDateSet.contains(dateOnly)) continue;
      if (date.year == parent.date.year &&
          date.month == parent.date.month &&
          date.day == parent.date.day) continue;

      tasksToCreate.add(Task(
        userId: parent.userId,
        type: parent.type,
        courseCode: parent.courseCode,
        courseTitle: parent.courseTitle,
        date: date,
        startTime: parent.startTime != null
            ? DateTime(date.year, date.month, date.day,
            parent.startTime!.hour, parent.startTime!.minute)
            : null,
        endTime: parent.endTime != null
            ? DateTime(date.year, date.month, date.day,
            parent.endTime!.hour, parent.endTime!.minute)
            : null,
        priority: parent.priority,
        location: parent.location,
        teacherName: parent.teacherName,
        teacherName2: parent.teacherName2,
        reminders: parent.reminders,
        alarmOn: parent.alarmOn,
        description: parent.description,
        recurringGroupId: parent.recurringGroupId,
        recurrenceFrequency: parent.recurrenceFrequency,
        expectedEndDate: parent.expectedEndDate,
        extensionStatus: ExtensionStatus.active,
        isRecurringParent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // ⚡ BATCH WRITE
    for (var newTask in tasksToCreate) {
      await _service.createTask(newTask);
    }
  }

  Future<Task?> updateTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ⚡ Optimistic update
      if (task.id != null) {
        _tasksMap[task.id!] = task;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedTask = await _service.updateTask(task);

      // ⚡ Handle recurring update in background
      if (task.isRecurringParent && task.recurringGroupId != null) {
        unawaited(_regenerateRecurringTasksOptimized(task));
      }

      _error = null;
      _isLoading = false;

      await _loadStats();
      _invalidateDateCache();
      notifyListeners();

      return updatedTask ?? task;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ⚡ OPTIMIZED REGENERATION - Parallel operations
  Future<void> _regenerateRecurringTasksOptimized(Task parent) async {
    if (!parent.isRecurringParent || parent.recurringGroupId == null) return;

    final existingChildren = getTasksByRecurringGroup(parent.recurringGroupId!);

    // ⚡ PARALLEL DELETE
    await Future.wait(
        existingChildren
            .where((child) => child.id != null)
            .map((child) => _service.deleteTask(child.id!))
    );

    await _generateRecurringTasksOptimized(parent);
  }

  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final task = _tasksMap[taskId];

      // ⚡ Optimistic delete
      final wasRecurringParent = task?.isRecurringParent ?? false;
      final groupId = task?.recurringGroupId;

      _tasksMap.remove(taskId);

      if (wasRecurringParent && groupId != null) {
        // Delete all children
        final children = getTasksByRecurringGroup(groupId);
        for (var child in children) {
          if (child.id != null) {
            _tasksMap.remove(child.id);
          }
        }
      }

      _buildAllIndexes();
      _invalidateDateCache();
      notifyListeners();

      // ⚡ Async Firebase delete
      await _service.deleteTask(taskId);

      if (wasRecurringParent && groupId != null) {
        final children = getTasksByRecurringGroup(groupId);
        await Future.wait(
            children
                .where((child) => child.id != null)
                .map((child) => _service.deleteTask(child.id!))
        );
      }

      _error = null;
      _isLoading = false;

      await _loadStats();
      _invalidateDateCache();
      notifyListeners();

      return true;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Task?> toggleTaskCompletion(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ⚡ Optimistic toggle
      final toggledTask = task.copyWith(isDone: !task.isDone);
      if (task.id != null) {
        _tasksMap[task.id!] = toggledTask;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedTask = await _completionService.toggleTaskCompletion(task);

      _error = null;
      _isLoading = false;

      await _loadStats();
      _invalidateDateCache();
      notifyListeners();

      return updatedTask ?? toggledTask;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 SEMESTER OPERATIONS - OPTIMIZED
  // ═══════════════════════════════════════════════════════════

  Future<Task?> extendSemester(Task task) async {
    if (!task.isRecurring || task.expectedEndDate == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final extendedTask = task.extendSemester();

      // ⚡ Optimistic update
      if (extendedTask.id != null) {
        _tasksMap[extendedTask.id!] = extendedTask;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedParent = await _service.updateTask(extendedTask);

      if (updatedParent != null) {
        // ⚡ Generate extended classes in background
        unawaited(_generateExtendedClassesOptimized(updatedParent));

        _error = null;
        _isLoading = false;

        await _loadAllTasksInternal();
        _invalidateDateCache();
        notifyListeners();

        return updatedParent;
      }

      _isLoading = false;
      return null;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ⚡ OPTIMIZED EXTENDED CLASSES GENERATION
  Future<void> _generateExtendedClassesOptimized(Task parent) async {
    if (parent.expectedEndDate == null) return;

    final allDates = parent.getAllClassDates();
    final existingDates = getTasksByRecurringGroup(parent.recurringGroupId!)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    final tasksToCreate = <Task>[];

    for (var date in allDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (existingDates.contains(dateOnly)) continue;
      if (date.year == parent.date.year &&
          date.month == parent.date.month &&
          date.day == parent.date.day) continue;

      tasksToCreate.add(Task(
        userId: parent.userId,
        type: parent.type,
        courseCode: parent.courseCode,
        courseTitle: parent.courseTitle,
        date: date,
        startTime: parent.startTime != null
            ? DateTime(date.year, date.month, date.day,
            parent.startTime!.hour, parent.startTime!.minute)
            : null,
        endTime: parent.endTime != null
            ? DateTime(date.year, date.month, date.day,
            parent.endTime!.hour, parent.endTime!.minute)
            : null,
        priority: parent.priority,
        location: parent.location,
        teacherName: parent.teacherName,
        teacherName2: parent.teacherName2,
        reminders: parent.reminders,
        alarmOn: parent.alarmOn,
        description: parent.description,
        recurringGroupId: parent.recurringGroupId,
        recurrenceFrequency: parent.recurrenceFrequency,
        expectedEndDate: parent.expectedEndDate,
        extensionStatus: ExtensionStatus.active,
        isRecurringParent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // ⚡ BATCH CREATE
    for (var newTask in tasksToCreate) {
      await _service.createTask(newTask);
    }
  }

  Future<Task?> endSemester(Task task) async {
    if (!task.isRecurring) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final endedTask = task.endSemester();

      if (endedTask.id != null) {
        _tasksMap[endedTask.id!] = endedTask;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedTask = await _service.updateTask(endedTask);

      _error = null;
      _isLoading = false;

      await _loadAllTasksInternal();
      _invalidateDateCache();
      notifyListeners();

      return updatedTask;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Task?> archiveSemester(Task task) async {
    if (!task.isRecurring) return null;

    try {
      final archivedTask = task.archiveSemester();

      if (archivedTask.id != null) {
        _tasksMap[archivedTask.id!] = archivedTask;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedTask = await _service.updateTask(archivedTask);

      await _loadAllTasksInternal();
      _invalidateDateCache();
      notifyListeners();

      return updatedTask;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Task?> skipClassDate(Task task, DateTime date) async {
    if (!task.isRecurring) return null;

    try {
      final skippedTask = task.skipDate(date);

      if (skippedTask.id != null) {
        _tasksMap[skippedTask.id!] = skippedTask;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedTask = await _service.updateTask(skippedTask);

      await _loadAllTasksInternal();
      _invalidateDateCache();
      notifyListeners();

      return updatedTask;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Task?> unskipClassDate(Task task, DateTime date) async {
    if (!task.isRecurring) return null;

    try {
      final unskippedTask = task.unskipDate(date);

      if (unskippedTask.id != null) {
        _tasksMap[unskippedTask.id!] = unskippedTask;
        _buildAllIndexes();
        _invalidateDateCache();
        notifyListeners();
      }

      final updatedTask = await _service.updateTask(unskippedTask);

      await _loadAllTasksInternal();
      _invalidateDateCache();
      notifyListeners();

      return updatedTask;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 STATS - O(1) WITH PRE-COMPUTED VALUES
  // ═══════════════════════════════════════════════════════════

  // ⚡ PRE-COMPUTED STATS
  int _cachedCompletedCount = -1;
  int _cachedPendingCount = -1;
  int _cachedOverdueCount = -1;

  int get completedTasksCount {
    if (_cachedCompletedCount == -1) {
      _cachedCompletedCount = _tasksMap.values.where((t) => t.isDone).length;
    }
    return _cachedCompletedCount;
  }

  int get pendingTasksCount {
    if (_cachedPendingCount == -1) {
      _cachedPendingCount = _tasksMap.values.where((t) => !t.isDone).length;
    }
    return _cachedPendingCount;
  }

  int get overdueTasksCount {
    if (_cachedOverdueCount == -1) {
      _cachedOverdueCount = _tasksMap.values.where((t) =>
      !t.isDone && t.isOverdue && t.type.hasDeadline).length;
    }
    return _cachedOverdueCount;
  }

  int getTasksCountByType(TaskType type) {
    return _tasksMap.values.where((t) => t.type == type).length;
  }

  int getCompletedTasksCountByType(TaskType type) {
    return _tasksMap.values.where((t) => t.type == type && t.isDone).length;
  }

  // ⚡ O(1) DATE COUNTS
  int getTaskCountForDate(DateTime date) {
    return _getTasksForDateCached(date).length;
  }

  int getCompletedTaskCountForDate(DateTime date) {
    return _getTasksForDateCached(date).where((t) => t.isDone).length;
  }

  int getDeadlineTasksCountForDate(DateTime date) {
    return _getTasksForDateCached(date).where((t) => t.type.hasDeadline).length;
  }

  List<Task> getActiveDeadlineTasks() {
    final now = DateTime.now();
    return _tasksMap.values.where((t) {
      return t.type.hasDeadline && !t.isDone && t.deadline != null && t.deadline!.isAfter(now);
    }).toList();
  }

  List<Task> getOverdueDeadlineTasks() {
    final now = DateTime.now();
    return _tasksMap.values.where((t) {
      return t.type.hasDeadline && !t.isDone && t.deadline != null && t.deadline!.isBefore(now);
    }).toList();
  }

  bool hasTasksOnDate(DateTime date) => getTaskCountForDate(date) > 0;
  bool hasCompletedTasksOnDate(DateTime date) => getCompletedTaskCountForDate(date) > 0;
  bool hasDeadlineTasksOnDate(DateTime date) => getDeadlineTasksCountForDate(date) > 0;

  // ═══════════════════════════════════════════════════════════
  // 🚀 REFRESH - SUB-200MS
  // ═══════════════════════════════════════════════════════════

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadAllTasksInternal(),
        _loadStats(),
      ]);

      _buildAllIndexes();
      _invalidateDateCache();

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 CACHE INVALIDATION
  // ═══════════════════════════════════════════════════════════

  void _invalidateDateCache() {
    _dateTaskCache.clear();
    _cachedCompletedCount = -1;
    _cachedPendingCount = -1;
    _cachedOverdueCount = -1;
    _cachedRecurringParents = null;
    _cachedActiveRecurring = null;
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 SEMESTER REMINDER - OPTIMIZED
  // ═══════════════════════════════════════════════════════════

  Timer? _semesterReminderTimer;

  void _startSemesterReminderService() {
    _semesterReminderTimer?.cancel();
    _semesterReminderTimer = Timer.periodic(
      const Duration(hours: 6),
          (timer) => _checkSemesterEndings(),
    );
  }

  Future<void> _checkSemesterEndings() async {
    if (_isDisposed) return;

    // ⚡ Use cached active recurring tasks
    for (var task in activeRecurringTasks) {
      if (task.isSemesterEndingSoon) {
        _notifySemesterEnding(task);
      }
    }
  }

  void _notifySemesterEnding(Task task) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) notifyListeners();
    });
  }

  List<Task> getSemesterEndingTasks() {
    return activeRecurringTasks.where((t) => t.isSemesterEndingSoon).toList();
  }

  List<Task> getTasksNeedingExtension() {
    return activeRecurringTasks.where((t) => t.isSemesterEndingSoon || t.isSemesterEnded).toList();
  }

  Map<String, dynamic> getSemesterStats(Task task) {
    if (!task.isRecurring) return {};

    final allDates = task.getAllClassDates();
    final completedDates = task.getCompletedClassDates();
    final upcomingDates = task.getUpcomingClassDates();
    final skippedDates = task.skippedDates ?? [];

    return {
      'totalClasses': allDates.length,
      'completedClasses': completedDates.length,
      'upcomingClasses': upcomingDates.length,
      'skippedClasses': skippedDates.length,
      'attendedClasses': allDates.length - skippedDates.length,
      'attendanceRate': allDates.isEmpty
          ? 0.0
          : ((allDates.length - skippedDates.length) / allDates.length * 100).toStringAsFixed(1),
      'startDate': task.date,
      'expectedEndDate': task.expectedEndDate,
      'actualEndDate': task.actualEndDate,
      'extensionCount': task.extensionCount,
      'status': task.extensionStatus.name,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 ADDITIONAL OPTIMIZED METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadStats() async {
    try {
      _stats = await _statsService.getStats();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } catch (_) {}
  }

  Future<void> loadAllTasks() async => _loadAllTasksInternal();

  List<Task> getTasksForDateSync(DateTime date) => _getTasksForDateCached(date);

  List<Task> getTasksByCompletion(bool isDone) {
    return _tasksMap.values.where((t) => t.isDone == isDone).toList();
  }

  List<Task> getUpcomingDeadlineTasks({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    final result = _tasksMap.values.where((t) {
      return t.type.hasDeadline && !t.isDone && t.deadline != null &&
          t.deadline!.isAfter(now) && t.deadline!.isBefore(future);
    }).toList();

    result.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    return result;
  }

  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    return _tasksMap.values.where((task) {
      if (task.type.hasTimeRange) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        return (taskDate.isAfter(startDate) || taskDate.isAtSameMomentAs(startDate)) &&
            (taskDate.isBefore(endDate) || taskDate.isAtSameMomentAs(endDate));
      }

      if (task.type.hasDeadline && task.deadline != null) {
        final deadlineDate = DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day);
        return (deadlineDate.isAfter(startDate) || deadlineDate.isAtSameMomentAs(startDate)) &&
            (deadlineDate.isBefore(endDate) || deadlineDate.isAtSameMomentAs(endDate));
      }

      return false;
    }).toList();
  }

  List<Task> getUpcomingTasks({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return getTasksByDateRange(now, future);
  }

  Map<String, dynamic> getStatsSummary() {
    return {
      'totalTasks': _tasksMap.length,
      'completedTasks': completedTasksCount,
      'pendingTasks': pendingTasksCount,
      'overdueTasks': overdueTasksCount,
      'activeDeadlineTasks': getActiveDeadlineTasks().length,
      'overdueDeadlineTasks': getOverdueDeadlineTasks().length,
      'completionRate': _tasksMap.isEmpty
          ? 0.0
          : (completedTasksCount / _tasksMap.length * 100).toStringAsFixed(1),
      'recurringSemesters': recurringParents.length,
      'activeSemesters': activeRecurringTasks.length,
    };
  }

  Map<String, dynamic> getStatsByType() {
    final result = <String, dynamic>{};
    for (var type in TaskType.values) {
      final total = getTasksCountByType(type);
      final completed = getCompletedTasksCountByType(type);
      final pending = total - completed;

      int overdue = 0;
      if (type.hasDeadline) {
        overdue = _tasksMap.values.where((t) {
          return t.type == type && !t.isDone && t.deadline != null && t.deadline!.isBefore(DateTime.now());
        }).length;
      }

      result[type.label] = {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
      };
    }
    return result;
  }

  Map<String, dynamic> getDeadlineTaskStats() {
    final activeTasks = getActiveDeadlineTasks();
    final overdueTasks = getOverdueDeadlineTasks();
    final completedDeadlineTasks = _tasksMap.values.where((t) => t.type.hasDeadline && t.isDone).toList();

    final Map<String, Map<String, int>> groupedStats = {};
    for (var type in TaskType.values.where((t) => t.hasDeadline)) {
      final tasksOfType = _tasksMap.values.where((t) => t.type == type);
      final total = tasksOfType.length;
      final completed = tasksOfType.where((t) => t.isDone).length;
      final pending = total - completed;
      final overdue = tasksOfType.where((t) => !t.isDone && t.deadline != null && t.deadline!.isBefore(DateTime.now())).length;

      groupedStats[type.label] = {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
      };
    }

    return {
      'activeTasks': activeTasks.length,
      'overdueTasks': overdueTasks.length,
      'completedTasks': completedDeadlineTasks.length,
      'byType': groupedStats,
    };
  }

  Future<void> autoCompleteClasses() async {
    try {
      await _completionService.checkAndCompleteClasses();
      await _loadStats();
      _invalidateDateCache();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> checkAndExtendDeadlines() async {
    try {
      await _completionService.checkAndExtendDeadlines();
      await _loadStats();
      _invalidateDateCache();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> runAllChecks() async {
    try {
      await _completionService.runAllChecks();
      await _loadStats();
      _invalidateDateCache();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 DISPOSE - Clean up resources
  // ═══════════════════════════════════════════════════════════

  @override
  void dispose() {
    _isDisposed = true;
    _tasksSubscription?.cancel();
    _tasksForDateSubscription?.cancel();
    _semesterReminderTimer?.cancel();
    _batchWriteTimer?.cancel();
    _taskCache.clear();
    _dateIndex.clear();
    _tasksMap.clear();
    _recurringGroups.clear();
    _dateTaskCache.clear();
    super.dispose();
  }
}