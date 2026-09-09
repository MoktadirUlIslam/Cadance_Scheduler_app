// lib/screens/TaskManager/task_manager_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro/screens/Task_manager/providers/Task_provider.dart';
import 'package:provider/provider.dart';
import '../../core/data_provider.dart';
import '../../models/taskmanager_model.dart';
import '../../utilites/app_colors.dart';
import '../../widgets/drawer_widget.dart';
import 'components/TaskCard.dart';
import 'components/Task_form/task_form.dart';
import 'components/weekly_calendar.dart';
import 'services/task_completion_service.dart';
import 'services/task_notification_helper.dart';

class TaskManagerPage extends StatefulWidget {
  const TaskManagerPage({super.key});

  @override
  State<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  FilterType _selectedFilter = FilterType.all;
  bool _isDarkMode = false;
  Timer? _completionTimer;

  // Selected date for task filtering
  DateTime _selectedDate = DateTime.now();

  // Services
  late TaskCompletionService _completionService;
  late TaskNotificationHelper _notificationHelper;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initServices();

    // ✅ FIX: Load data after the first frame to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });

    // Run completion checks every 10 minutes
    _completionTimer = Timer.periodic(
      const Duration(minutes: 10),
          (timer) => _runCompletionChecks(),
    );
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  void _initServices() {
    _completionService = TaskCompletionService();
    _notificationHelper = TaskNotificationHelper();
  }

  Future<void> _loadInitialData() async {
    try {
      final dataProvider = context.read<DataProvider>();
      final taskProvider = context.read<TaskProvider>();

      // Load all data from DataProvider
      await dataProvider.loadAllDataWithProgress();

      // Initialize TaskCompletionService with both providers
      await _completionService.initialize(
        dataProvider: dataProvider,
        taskProvider: taskProvider,
        onTasksUpdated: (tasks) {
          // Update TaskProvider when tasks change
          taskProvider.setTasks(tasks);
          if (mounted) {
            setState(() {});
          }
        },
      );

      // Initialize NotificationHelper
      await _notificationHelper.initialize();

      // Schedule notifications for all tasks
      await _scheduleNotifications(dataProvider.tasks);

      debugPrint('✅ All data loaded successfully');
      debugPrint('📊 Tasks: ${dataProvider.tasks.length}');
      debugPrint('📊 Stats: ${dataProvider.taskStats?.totalCompleted ?? 0} completed');
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
    }
  }

  Future<void> _scheduleNotifications(List<Task> tasks) async {
    try {
      await _notificationHelper.scheduleAllTaskNotifications(tasks);
      debugPrint('📬 Scheduled notifications for ${tasks.length} tasks');
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
    }
  }

  Future<void> _runCompletionChecks() async {
    try {
      await _completionService.runAllChecks();

      // Refresh DataProvider after completion checks
      final dataProvider = context.read<DataProvider>();
      await dataProvider.refreshTasks();

      // Update TaskProvider with fresh data
      final taskProvider = context.read<TaskProvider>();
      taskProvider.setTasks(dataProvider.tasks);

      if (mounted) {
        setState(() {});
      }

      debugPrint('✅ Completion checks completed');
    } catch (e) {
      debugPrint('❌ Completion check error: $e');
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _animationController.dispose();
    _completionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dataProvider = context.watch<DataProvider>();
    final taskProvider = context.watch<TaskProvider>();

    // Get tasks for selected date from DataProvider
    final tasksForDate = dataProvider.getTasksForDate(_selectedDate);
    final filteredTasks = _getFilteredTasks(tasksForDate);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _isDarkMode ? AppColors.darkBg : AppColors.bg,
      drawer: const CustomDrawer(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 8,
          right: 8,
        ),
        child: FloatingActionButton(
          key: const Key('task_manager_fab'),
          onPressed: _showAddTaskForm,
          backgroundColor: AppColors.primaryLight,
          child: const Icon(Icons.add, color: Colors.white),
          heroTag: 'task_manager_fab',
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Weekly Calendar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: WeeklyCalendar(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                isDarkMode: _isDarkMode,
              ),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),

          // Date header with task count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: _buildDateHeader(filteredTasks),
            ),
          ),

          // Task list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            sliver: SliverToBoxAdapter(
              child: _buildTaskList(filteredTasks, dataProvider, taskProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'type': FilterType.all, 'icon': Icons.all_inclusive},
      {'label': '🏫 Class', 'type': FilterType.classes, 'icon': Icons.class_},
      {'label': '📚 Exam', 'type': FilterType.exam, 'icon': Icons.quiz},
      {'label': '📝 Assignment', 'type': FilterType.assignment, 'icon': Icons.assignment},
      {'label': '🔬 Lab', 'type': FilterType.labReport, 'icon': Icons.science},
      {'label': '🔴 High', 'type': FilterType.highPriority, 'icon': Icons.priority_high},
      {'label': '🟡 Medium', 'type': FilterType.mediumPriority, 'icon': Icons.remove},
      {'label': '🟢 Low', 'type': FilterType.lowPriority, 'icon': Icons.low_priority},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['type'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter['type'] as FilterType : FilterType.all;
                });
              },
              selectedColor: AppColors.primaryLight,
              backgroundColor: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (_isDarkMode ? Colors.white70 : AppColors.ink),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryLight : (_isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateHeader(List<Task> tasks) {
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    String title;
    if (isToday) {
      title = 'Today';
    } else if (_selectedDate.day == today.day + 1 && _selectedDate.month == today.month) {
      title = 'Tomorrow';
    } else {
      title = '${_monthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}';
    }

    // Count completed tasks
    final completedCount = tasks.where((t) => t.isDone).length;
    final autoCompletedCount = tasks.where((t) => t.isDone && t.autoCompleted).length;
    final overdueCount = tasks.where((t) => t.isOverdue && !t.isDone).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? Colors.white : AppColors.ink,
              ),
            ),
            Text(
              '${tasks.length} task${tasks.length != 1 ? 's' : ''} · $completedCount completed',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white54 : AppColors.inkSoft,
              ),
            ),
            if (overdueCount > 0)
              Text(
                '⚠️ $overdueCount overdue',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.withOpacity(0.7),
                ),
              ),
          ],
        ),
        if (tasks.isNotEmpty)
          _buildPrioritySummary(tasks),
      ],
    );
  }

  Widget _buildPrioritySummary(List<Task> tasks) {
    final highCount = tasks.where((t) => t.priority == Priority.high && !t.isDone).length;
    final mediumCount = tasks.where((t) => t.priority == Priority.medium && !t.isDone).length;
    final lowCount = tasks.where((t) => t.priority == Priority.low && !t.isDone).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highCount > 0)
            _buildPriorityDot(Colors.red, highCount),
          if (mediumCount > 0)
            _buildPriorityDot(AppColors.warningLight, mediumCount),
          if (lowCount > 0)
            _buildPriorityDot(AppColors.successLight, lowCount),
        ],
      ),
    );
  }

  Widget _buildPriorityDot(Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white70 : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    return tasks.where((task) {
      switch (_selectedFilter) {
        case FilterType.all:
          return true;
        case FilterType.classes:
          return task.type == TaskType.classes;
        case FilterType.exam:
          return task.type == TaskType.exam;
        case FilterType.assignment:
          return task.type == TaskType.assignment;
        case FilterType.labReport:
          return task.type == TaskType.labReport;
        case FilterType.highPriority:
          return task.priority == Priority.high;
        case FilterType.mediumPriority:
          return task.priority == Priority.medium;
        case FilterType.lowPriority:
          return task.priority == Priority.low;
      }
    }).toList();
  }

  Widget _buildTaskList(List<Task> tasks, DataProvider dataProvider, TaskProvider taskProvider) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: tasks.map((task) {
        return TaskCard(
          task: task,
          isDarkMode: _isDarkMode,
          onTap: () => _showTaskDetails(task),
          onEdit: () => _showEditTaskForm(task),
          onDelete: () => _handleDeleteTask(task, dataProvider, taskProvider),
          onToggleComplete: (t) => _handleToggleComplete(t, dataProvider, taskProvider),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _selectedFilter != FilterType.all;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? AppColors.primaryLight.withOpacity(0.1)
                  : AppColors.primaryLight.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilter ? Icons.filter_alt_off : Icons.assignment_outlined,
              size: 64,
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.ink.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilter ? 'No tasks match filter' : 'No tasks for this day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white70 : AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasFilter
                  ? 'Try changing the filter to see more tasks'
                  : 'Tap the + button to add your first task for ${_monthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TASK FORM METHODS ====================

  void _showAddTaskForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TaskForm(
            selectedDate: _selectedDate,
            isDarkMode: _isDarkMode,
            onSubmit: (task) async {
              final dataProvider = context.read<DataProvider>();
              final taskProvider = context.read<TaskProvider>();

              try {
                // ✅ Create task via TaskProvider (CRUD)
                final newTask = await taskProvider.createTask(task);

                // ✅ Refresh DataProvider to get the new task
                await dataProvider.refreshTasks();

                // ✅ Update TaskProvider with fresh data
                taskProvider.setTasks(dataProvider.tasks);

                // Schedule notifications
                await _notificationHelper.scheduleTaskNotifications(newTask);

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Task "${task.displayTitle}" added! 🎉');
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Task Created Successfully: ${e.toString()}');
                }
              }
            },
          ),
        );
      },
    );
  }

  void _showEditTaskForm(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TaskForm(
            initialTask: task,
            selectedDate: task.date,
            isDarkMode: _isDarkMode,
            onSubmit: (updatedTask) async {
              final dataProvider = context.read<DataProvider>();
              final taskProvider = context.read<TaskProvider>();

              try {
                // ✅ Update task via TaskProvider (CRUD)
                final result = await taskProvider.updateTask(updatedTask);

                // ✅ Refresh DataProvider
                await dataProvider.refreshTasks();

                // ✅ Update TaskProvider with fresh data
                taskProvider.setTasks(dataProvider.tasks);

                // Reschedule notifications
                await _notificationHelper.scheduleTaskNotifications(result);

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Task "${updatedTask.displayTitle}" updated! ✅');
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('❌ Error updating task: ${e.toString()}');
                }
                debugPrint('❌ Error updating task: $e');
              }
            },
          ),
        );
      },
    );
  }

  // ==================== TASK COMPLETION HANDLER ====================

  Future<void> _handleToggleComplete(Task task, DataProvider dataProvider, TaskProvider taskProvider) async {
    try {
      // ✅ Toggle the task completion status
      final updatedTask = await taskProvider.toggleTaskDone(task);

      // ✅ Refresh DataProvider
      await dataProvider.refreshTasks();

      // ✅ Update TaskProvider with fresh data
      taskProvider.setTasks(dataProvider.tasks);

      // ✅ CRITICAL FIX: Force a rebuild of the UI
      if (mounted) {
        setState(() {
          // This will rebuild the widget tree with the updated task list
          // and remove the dismissed widget from the tree
        });

        // Show success message
        final message = updatedTask.isDone
            ? (task.type == TaskType.assignment
            ? '✅ "${task.displayTitle}" submitted!'
            : '✅ "${task.displayTitle}" completed!')
            : '⏳ "${task.displayTitle}" marked as pending';

        _showSnackBar(message);

        // Cancel or reschedule notifications
        if (updatedTask.isDone) {
          await _notificationHelper.cancelTaskNotifications(updatedTask.id!);
        } else {
          await _notificationHelper.scheduleTaskNotifications(updatedTask);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error updating task status');
        // ✅ Also rebuild on error to remove the dismissed widget
        setState(() {});
      }
      debugPrint('❌ Toggle completion error: $e');
    }
  }

  // ==================== TASK DELETE HANDLER ====================

  Future<void> _handleDeleteTask(Task task, DataProvider dataProvider, TaskProvider taskProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.displayTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ✅ Delete via TaskProvider (CRUD)
      await taskProvider.deleteTask(task.id!);

      // ✅ Refresh DataProvider
      await dataProvider.refreshTasks();

      // ✅ Update TaskProvider with fresh data
      taskProvider.setTasks(dataProvider.tasks);

      // Cancel notifications
      await _notificationHelper.cancelTaskNotifications(task.id!);

      if (mounted) {
        setState(() {});
        _showSnackBar('Task "${task.displayTitle}" deleted');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error deleting task');
      }
      debugPrint('❌ Error deleting task: $e');
    }
  }

  // ==================== TASK DETAILS POPUP ====================

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: _isDarkMode ? AppColors.darkBg : AppColors.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Title and Status
                  Row(
                    children: [
                      // Type icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: task.typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          task.type.icon,
                          color: task.isDone ? Colors.green : task.typeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.displayTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _isDarkMode ? Colors.white : AppColors.ink,
                                decoration: task.isDone ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Scrollable details
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          // Date
                          _buildDetailItem(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: DateFormat('EEEE, MMMM d, yyyy').format(task.date),
                          ),
                          const SizedBox(height: 12),

                          // Course Code
                          if (task.courseCode != null && task.courseCode!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.code,
                              label: 'Course Code',
                              value: task.courseCode!,
                            ),
                          const SizedBox(height: 12),

                          // Course Title
                          if (task.courseTitle != null && task.courseTitle!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.book,
                              label: 'Course Title',
                              value: task.courseTitle!,
                            ),
                          const SizedBox(height: 12),

                          // Time (for Classes)
                          if (task.type == TaskType.classes && task.startTime != null && task.endTime != null)
                            _buildDetailItem(
                              icon: Icons.access_time,
                              label: 'Time',
                              value: _formatTimeRangeWithAmPm(task.startTime!, task.endTime!),
                            ),
                          const SizedBox(height: 12),

                          // Location
                          if (task.location != null && task.location!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.location_on,
                              label: 'Location',
                              value: task.location!,
                            ),
                          const SizedBox(height: 12),

                          // Teacher
                          if (task.teacherName != null && task.teacherName!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.person,
                              label: 'Teacher',
                              value: task.teacherName!,
                            ),
                          const SizedBox(height: 12),

                          // Deadline
                          if (task.deadline != null)
                            _buildDetailItem(
                              icon: Icons.event,
                              label: 'Deadline',
                              value: DateFormat('EEEE, MMMM d, yyyy h:mm a').format(task.deadline!),
                              valueColor: task.isOverdue && !task.isDone ? Colors.red : null,
                            ),
                          const SizedBox(height: 12),

                          // Extension count
                          if (task.totalExtensions > 0)
                            _buildDetailItem(
                              icon: Icons.timer_outlined,
                              label: 'Extensions',
                              value: '${task.totalExtensions} time${task.totalExtensions > 1 ? 's' : ''}',
                              valueColor: Colors.orange,
                            ),
                          const SizedBox(height: 12),

                          // Assignment Topic
                          if (task.type == TaskType.assignment && task.title != null && task.title!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.title,
                              label: 'Assignment Topic',
                              value: task.title!,
                            ),
                          const SizedBox(height: 12),

                          // Exam Type
                          if (task.type == TaskType.exam && task.examType != null && task.examType!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.quiz,
                              label: 'Exam Type',
                              value: task.examType!,
                            ),
                          const SizedBox(height: 12),

                          // Class Test details
                          if (task.type == TaskType.exam && task.examType == 'Class Test') ...[
                            if (task.classTestNo != null && task.classTestNo!.isNotEmpty)
                              _buildDetailItem(
                                icon: Icons.numbers,
                                label: 'Class Test',
                                value: 'Test ${task.classTestNo}',
                              ),
                            if (task.testTopic != null && task.testTopic!.isNotEmpty)
                              _buildDetailItem(
                                icon: Icons.topic,
                                label: 'Topic',
                                value: task.testTopic!,
                              ),
                          ],
                          const SizedBox(height: 12),

                          // Lab Report
                          if (task.type == TaskType.labReport) ...[
                            if (task.experimentNo != null && task.experimentNo!.isNotEmpty)
                              _buildDetailItem(
                                icon: Icons.numbers,
                                label: 'Experiment',
                                value: 'Exp ${task.experimentNo}',
                              ),
                            if (task.experimentTitle != null && task.experimentTitle!.isNotEmpty)
                              _buildDetailItem(
                                icon: Icons.science,
                                label: 'Title',
                                value: task.experimentTitle!,
                              ),
                          ],
                          const SizedBox(height: 12),

                          // Reminders
                          if (task.reminders.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.notifications,
                              label: 'Reminders',
                              value: task.reminders.map((r) => r.label).join(', '),
                            ),
                          const SizedBox(height: 12),

                          // Alarm
                          _buildDetailItem(
                            icon: Icons.alarm,
                            label: 'Alarm',
                            value: task.alarmOn ? 'Enabled' : 'Disabled',
                            valueColor: task.alarmOn ? AppColors.primaryLight : null,
                          ),
                          const SizedBox(height: 12),

                          // Description
                          if (task.description != null && task.description!.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.description,
                              label: 'Description',
                              value: task.description!,
                              isLong: true,
                            ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              // Only show Edit button for pending tasks
                              if (!task.isDone)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEditTaskForm(task);
                                    },
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryLight,
                                      side: const BorderSide(color: AppColors.primaryLight),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                              if (!task.isDone) const SizedBox(width: 12),

                              // Delete button (always shown)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    final dataProvider = context.read<DataProvider>();
                                    final taskProvider = context.read<TaskProvider>();
                                    _handleDeleteTask(task, dataProvider, taskProvider);
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== HELPER METHODS ====================

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isLong = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isDarkMode ? Colors.white.withOpacity(0.4) : Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? (_isDarkMode ? Colors.white : AppColors.ink),
                  height: 1.3,
                ),
                softWrap: isLong,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeRangeWithAmPm(DateTime start, DateTime end) {
    final format = (DateTime t) {
      final hour = t.hour;
      final minute = t.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $ampm';
    };
    return '${format(start)} - ${format(end)}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}