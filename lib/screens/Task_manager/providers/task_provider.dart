// lib/screens/Task_manager/providers/task_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../models/taskmanager_model.dart';
import '../services/TaskCompletionService.dart';
import '../services/task_firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskFirestoreService _service = TaskFirestoreService();
  final TaskCompletionService _completionService = TaskCompletionService();
  final TaskManagerStatsService _statsService = TaskManagerStatsService();

  // Stream subscriptions
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _tasksForDateSubscription;

  List<Task> _allTasks = [];
  List<Task> _tasksForSelectedDate = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {};
  bool _isDisposed = false;

  // NEW: Recurring class tracking
  Map<String, List<Task>> _recurringGroups = {};
  Timer? _semesterReminderTimer;

  // Getters
  List<Task> get allTasks => _allTasks;
  List<Task> get tasksForSelectedDate => _tasksForSelectedDate;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;
  Map<String, List<Task>> get recurringGroups => _recurringGroups;

  // Get recurring parent tasks
  List<Task> get recurringParents {
    return _allTasks.where((task) =>
    task.isRecurringParent &&
        task.extensionStatus != ExtensionStatus.archived
    ).toList();
  }

  // NEW: Get active recurring tasks
  List<Task> get activeRecurringTasks {
    return _allTasks.where((task) =>
    task.isRecurring &&
        task.extensionStatus == ExtensionStatus.active &&
        !task.isDone
    ).toList();
  }

  // NEW: Get tasks by recurring group
  List<Task> getTasksByRecurringGroup(String groupId) {
    return _allTasks.where((task) =>
    task.recurringGroupId == groupId
    ).toList();
  }

  // Initialize and load tasks
  Future<void> initialize() async {
    await _loadAllTasksInternal();
    await _loadTasksForDateInternal(_selectedDate);
    await _loadStats();
    await _groupRecurringTasks();
    _startSemesterReminderService();
  }

  // NEW: Group recurring tasks
  Future<void> _groupRecurringTasks() async {
    _recurringGroups.clear();

    // Get all recurring parents
    final parents = _allTasks.where((task) => task.isRecurringParent).toList();

    for (var parent in parents) {
      if (parent.recurringGroupId != null) {
        // Get all tasks in this group (including the parent)
        final allGroupTasks = _allTasks.where((task) =>
        task.recurringGroupId == parent.recurringGroupId
        ).toList();

        _recurringGroups[parent.recurringGroupId!] = allGroupTasks;
      }
    }
    notifyListeners();
  }

  // NEW: Start semester reminder service
  void _startSemesterReminderService() {
    _semesterReminderTimer?.cancel();
    _semesterReminderTimer = Timer.periodic(
      const Duration(hours: 6), // Check every 6 hours
          (timer) => _checkSemesterEndings(),
    );
  }

  // NEW: Check if any semesters are ending soon
  Future<void> _checkSemesterEndings() async {
    if (_isDisposed) return;

    for (var task in activeRecurringTasks) {
      if (task.isSemesterEndingSoon) {
        // Notify listeners to show reminder
        _notifySemesterEnding(task);
      }
    }
  }

  // NEW: Notify about semester ending
  void _notifySemesterEnding(Task task) {
    // This will be handled by the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  // NEW: Get semester ending tasks
  List<Task> getSemesterEndingTasks() {
    return activeRecurringTasks.where((task) =>
    task.isSemesterEndingSoon
    ).toList();
  }

  // NEW: Get tasks with upcoming extensions
  List<Task> getTasksNeedingExtension() {
    return activeRecurringTasks.where((task) =>
    task.isSemesterEndingSoon || task.isSemesterEnded
    ).toList();
  }

  // NEW: Extend semester for a recurring task
  Future<Task?> extendSemester(Task task) async {
    if (!task.isRecurring || task.expectedEndDate == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // Extend the parent task
      final extendedTask = task.extendSemester();
      final updatedParent = await _service.updateTask(extendedTask);

      if (updatedParent != null) {
        // Generate new classes for the extended period
        final newClasses = _generateExtendedClasses(updatedParent);

        // Save all new classes
        for (var newTask in newClasses) {
          await _service.createTask(newTask);
        }

        _error = null;
        _isLoading = false;

        // Refresh data
        await _loadAllTasksInternal();
        await _loadTasksForDateInternal(_selectedDate);
        await _groupRecurringTasks();
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

  // NEW: Generate extended classes
  List<Task> _generateExtendedClasses(Task parent) {
    List<Task> newClasses = [];

    if (parent.expectedEndDate == null) return newClasses;

    final allDates = parent.getAllClassDates();
    final existingDates = getTasksByRecurringGroup(parent.recurringGroupId!)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    for (var date in allDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Skip if date already exists (including parent)
      if (existingDates.contains(dateOnly)) continue;

      // Skip the parent date
      if (date.year == parent.date.year &&
          date.month == parent.date.month &&
          date.day == parent.date.day) {
        continue;
      }

      // Create new task for this date
      final newTask = Task(
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
      );
      newClasses.add(newTask);
    }

    return newClasses;
  }

  // NEW: End semester for a recurring task
  Future<Task?> endSemester(Task task) async {
    if (!task.isRecurring) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final endedTask = task.endSemester();
      final updatedTask = await _service.updateTask(endedTask);

      _error = null;
      _isLoading = false;

      await _loadAllTasksInternal();
      await _loadTasksForDateInternal(_selectedDate);
      await _groupRecurringTasks();
      notifyListeners();

      return updatedTask;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // NEW: Archive old semesters
  Future<Task?> archiveSemester(Task task) async {
    if (!task.isRecurring) return null;

    try {
      final archivedTask = task.archiveSemester();
      final updatedTask = await _service.updateTask(archivedTask);

      await _loadAllTasksInternal();
      await _groupRecurringTasks();
      notifyListeners();

      return updatedTask;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // NEW: Skip a class date (holiday)
  Future<Task?> skipClassDate(Task task, DateTime date) async {
    if (!task.isRecurring) return null;

    try {
      final skippedTask = task.skipDate(date);
      final updatedTask = await _service.updateTask(skippedTask);

      await _loadAllTasksInternal();
      await _loadTasksForDateInternal(_selectedDate);
      await _groupRecurringTasks();
      notifyListeners();

      return updatedTask;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // NEW: Unskip a class date
  Future<Task?> unskipClassDate(Task task, DateTime date) async {
    if (!task.isRecurring) return null;

    try {
      final unskippedTask = task.unskipDate(date);
      final updatedTask = await _service.updateTask(unskippedTask);

      await _loadAllTasksInternal();
      await _loadTasksForDateInternal(_selectedDate);
      await _groupRecurringTasks();
      notifyListeners();

      return updatedTask;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // NEW: Get semester stats for a recurring task
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

  // ─── INTERNAL LOAD METHODS ───

  Future<void> _loadAllTasksInternal() async {
    await _tasksSubscription?.cancel();

    try {
      _tasksSubscription = _service.getTasks().listen(
            (tasks) {
          if (_isDisposed) return;
          _allTasks = tasks;
          _error = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              _groupRecurringTasks();
              notifyListeners();
            }
          });
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

  Future<void> _loadTasksForDateInternal(DateTime date) async {
    await _tasksForDateSubscription?.cancel();

    try {
      _tasksForDateSubscription = _service.getTasksForDate(date).listen(
            (tasks) {
          if (_isDisposed) return;
          _tasksForSelectedDate = _filterTasksForDate(tasks, date);
          _error = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) notifyListeners();
          });
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

  List<Task> _filterTasksForDate(List<Task> tasks, DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);

    return tasks.where((task) {
      // For recurring parent tasks - show them on their start date
      if (task.isRecurringParent) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        return taskDate.isAtSameMomentAs(selectedDate);
      }

      // For recurring child tasks, check if this date is in the recurring schedule
      if (task.isRecurring) {
        // Check if the date is skipped
        if (task.isDateSkipped(selectedDate)) return false;

        // Check if the date matches the recurrence pattern
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        final daysDifference = selectedDate.difference(taskDate).inDays;

        if (daysDifference < 0) return false;

        final interval = task.recurrenceFrequency.days;
        if (interval == 0) return false;

        // Check if this date is in the recurring schedule
        if (daysDifference % interval != 0) return false;

        // Check if within expected end date
        if (task.expectedEndDate != null) {
          final expectedEnd = DateTime(
              task.expectedEndDate!.year,
              task.expectedEndDate!.month,
              task.expectedEndDate!.day
          );
          if (selectedDate.isAfter(expectedEnd)) return false;
        }

        // Check if semester is ended or archived
        if (task.extensionStatus == ExtensionStatus.ended ||
            task.extensionStatus == ExtensionStatus.archived) {
          return false;
        }

        return true;
      }

      // For regular tasks (non-recurring)
      if (task.type.hasTimeRange) {
        return task.date.year == date.year &&
            task.date.month == date.month &&
            task.date.day == date.day;
      }

      if (task.type.hasDeadline) {
        final taskStartDate = DateTime(task.date.year, task.date.month, task.date.day);
        final taskDeadline = task.deadline != null
            ? DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day)
            : taskStartDate;

        return (selectedDate.isAfter(taskStartDate) || selectedDate.isAtSameMomentAs(taskStartDate)) &&
            (selectedDate.isBefore(taskDeadline) || selectedDate.isAtSameMomentAs(taskDeadline));
      }

      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  Future<void> _loadStats() async {
    try {
      _stats = await _statsService.getStats();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } catch (_) {
      // Silent fail
    }
  }

  // ─── PUBLIC METHODS ───

  Future<void> loadAllTasks() async {
    await _loadAllTasksInternal();
  }

  Future<void> loadTasksForDate(DateTime date) async {
    _selectedDate = date;
    await _loadTasksForDateInternal(date);
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    loadTasksForDate(date);
  }

  // ─── CRUD OPERATIONS ───

  Future<Task?> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newTask = await _service.createTask(task);
      _error = null;
      _isLoading = false;

      // If task is recurring, generate all child tasks
      if (task.isRecurring && task.isRecurringParent) {
        await _generateRecurringTasks(task);
      }

      await _loadStats();
      await _loadTasksForDateInternal(_selectedDate);
      await _groupRecurringTasks();
      notifyListeners();
      return newTask;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // NEW: Generate all recurring tasks
  Future<void> _generateRecurringTasks(Task parent) async {
    if (!parent.isRecurring || parent.expectedEndDate == null) return;

    final allDates = parent.getAllClassDates();

    // Get existing child tasks
    final existingChildren = getTasksByRecurringGroup(parent.recurringGroupId!);
    final existingDateSet = existingChildren
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    for (var date in allDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Skip if date already exists (including parent)
      if (existingDateSet.contains(dateOnly)) continue;

      // Skip the parent date (already created)
      if (date.year == parent.date.year &&
          date.month == parent.date.month &&
          date.day == parent.date.day) {
        continue;
      }

      final childTask = Task(
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
      );

      await _service.createTask(childTask);
    }
  }

  Future<Task?> updateTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedTask = await _service.updateTask(task);
      _error = null;
      _isLoading = false;

      // If updating a recurring parent, regenerate children
      if (task.isRecurringParent && task.recurringGroupId != null) {
        // Delete existing children
        final existingChildren = getTasksByRecurringGroup(task.recurringGroupId!);
        for (var child in existingChildren) {
          if (child.id != null) {
            await _service.deleteTask(child.id!);
          }
        }
        // Regenerate
        await _generateRecurringTasks(task);
      }

      await _loadStats();
      await _loadTasksForDateInternal(_selectedDate);
      await _groupRecurringTasks();
      notifyListeners();
      return updatedTask;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Find the task
      final task = _allTasks.firstWhere((t) => t.id == taskId);

      // If it's a recurring parent, delete all children
      if (task.isRecurringParent && task.recurringGroupId != null) {
        final children = getTasksByRecurringGroup(task.recurringGroupId!);
        for (var child in children) {
          if (child.id != null) {
            await _service.deleteTask(child.id!);
          }
        }
      }

      await _service.deleteTask(taskId);
      _error = null;
      _isLoading = false;
      await _loadStats();
      await _loadTasksForDateInternal(_selectedDate);
      await _groupRecurringTasks();
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
      final updatedTask = await _completionService.toggleTaskCompletion(task);
      _error = null;
      _isLoading = false;

      if (updatedTask != null) {
        // If it's a recurring task, update the parent's stats
        if (task.isRecurring && task.recurringGroupId != null) {
          final parent = _allTasks.firstWhere(
                (t) => t.recurringGroupId == task.recurringGroupId && t.isRecurringParent,
            orElse: () => task,
          );
          // Update parent completion stats (if needed)
        }

        await _loadTasksForDateInternal(_selectedDate);
        await _loadStats();
        await _groupRecurringTasks();
        notifyListeners();
      }

      return updatedTask;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── DISPOSE ───

  @override
  void dispose() {
    _isDisposed = true;
    _tasksSubscription?.cancel();
    _tasksForDateSubscription?.cancel();
    _semesterReminderTimer?.cancel();
    super.dispose();
  }

  // ─── OTHER METHODS ───

  Future<void> autoCompleteClasses() async {
    try {
      await _completionService.checkAndCompleteClasses();
      await _loadTasksForDateInternal(_selectedDate);
      await _loadStats();
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> checkAndExtendDeadlines() async {
    try {
      await _completionService.checkAndExtendDeadlines();
      await _loadTasksForDateInternal(_selectedDate);
      await _loadStats();
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> runAllChecks() async {
    try {
      await _completionService.runAllChecks();
      await _loadTasksForDateInternal(_selectedDate);
      await _loadStats();
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  List<Task> getTasksForDateSync(DateTime date) {
    return _filterTasksForDate(_allTasks, date);
  }

  List<Task> getTasksByCompletion(bool isDone) {
    return _allTasks.where((task) => task.isDone == isDone).toList();
  }

  int get completedTasksCount {
    return _allTasks.where((task) => task.isDone).length;
  }

  int get pendingTasksCount {
    return _allTasks.where((task) => !task.isDone).length;
  }

  // In task_provider.dart

  int get overdueTasksCount {
    return _allTasks.where((task) =>
    !task.isDone &&
        task.isOverdue &&
        task.type.hasDeadline  // ✅ Only tasks with deadlines
    ).length;
  }

  int getTasksCountByType(TaskType type) {
    return _allTasks.where((task) => task.type == type).length;
  }

  int getCompletedTasksCountByType(TaskType type) {
    return _allTasks.where((task) => task.type == type && task.isDone).length;
  }

  int getTaskCountForDate(DateTime date) {
    return getTasksForDateSync(date).length;
  }

  int getCompletedTaskCountForDate(DateTime date) {
    return getTasksForDateSync(date).where((task) => task.isDone).length;
  }

  int getDeadlineTasksCountForDate(DateTime date) {
    return getTasksForDateSync(date)
        .where((task) => task.type.hasDeadline)
        .length;
  }

  List<Task> getActiveDeadlineTasks() {
    final now = DateTime.now();
    return _allTasks.where((task) {
      return task.type.hasDeadline &&
          !task.isDone &&
          task.deadline != null &&
          task.deadline!.isAfter(now);
    }).toList();
  }

  // In task_provider.dart

  List<Task> getOverdueDeadlineTasks() {
    final now = DateTime.now();
    return _allTasks.where((task) {
      // ✅ Only tasks with deadlines
      return task.type.hasDeadline &&
          !task.isDone &&
          task.deadline != null &&
          task.deadline!.isBefore(now);
    }).toList();
  }

  bool hasTasksOnDate(DateTime date) {
    return getTaskCountForDate(date) > 0;
  }

  bool hasCompletedTasksOnDate(DateTime date) {
    return getCompletedTaskCountForDate(date) > 0;
  }

  bool hasDeadlineTasksOnDate(DateTime date) {
    return getDeadlineTasksCountForDate(date) > 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadAllTasksInternal();
      await _loadTasksForDateInternal(_selectedDate);
      await _loadStats();
      await _groupRecurringTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getStatsSummary() {
    return {
      'totalTasks': _allTasks.length,
      'completedTasks': completedTasksCount,
      'pendingTasks': pendingTasksCount,
      'overdueTasks': overdueTasksCount,
      'activeDeadlineTasks': getActiveDeadlineTasks().length,
      'overdueDeadlineTasks': getOverdueDeadlineTasks().length,
      'completionRate': _allTasks.isEmpty
          ? 0.0
          : (completedTasksCount / _allTasks.length * 100).toStringAsFixed(1),
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
        overdue = _allTasks.where((task) {
          return task.type == type &&
              !task.isDone &&
              task.deadline != null &&
              task.deadline!.isBefore(DateTime.now());
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
    final completedDeadlineTasks = _allTasks.where((task) =>
    task.type.hasDeadline && task.isDone
    ).toList();

    final Map<String, Map<String, int>> groupedStats = {};
    for (var type in TaskType.values.where((t) => t.hasDeadline)) {
      final tasksOfType = _allTasks.where((task) => task.type == type);
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

  List<Task> getUpcomingDeadlineTasks({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return _allTasks.where((task) {
      return task.type.hasDeadline &&
          !task.isDone &&
          task.deadline != null &&
          task.deadline!.isAfter(now) &&
          task.deadline!.isBefore(future);
    }).toList()..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }

  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    return _allTasks.where((task) {
      if (task.type.hasTimeRange) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        return (taskDate.isAfter(startDate) || taskDate.isAtSameMomentAs(startDate)) &&
            (taskDate.isBefore(endDate) || taskDate.isAtSameMomentAs(endDate));
      }

      if (task.type.hasDeadline && task.deadline != null) {
        final deadlineDate = DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day);
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
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
}