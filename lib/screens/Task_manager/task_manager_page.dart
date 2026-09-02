// lib/screens/TaskManager/task_manager_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro/screens/Task_manager/services/TaskCompletionService.dart';
import 'package:pomodoro/screens/Task_manager/services/TaskManagerStatsService.dart';
import 'package:pomodoro/screens/Task_manager/services/task_firestore_service.dart';
import 'package:provider/provider.dart';
import '../../models/taskmanager_model.dart';
import '../../utilites/app_colors.dart';
import '../../widgets/drawer_widget.dart';
import 'components/TaskCard.dart';
import 'components/task_form.dart';
import 'components/weekly_calendar.dart';
import 'providers/task_provider.dart';
import 'services/task_notification_helper.dart';

// FilterType enum - removed classTest
enum FilterType {
  all,
  exam,
  assignment,
  labReport,
  classes,
  highPriority,
  mediumPriority,
  lowPriority
}

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

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadInitialData();

    // Run completion checks every 5 minutes
    _completionTimer = Timer.periodic(
      const Duration(minutes: 5),
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

  Future<void> _loadInitialData() async {
    await context.read<TaskProvider>().initialize();
    await _scheduleNotifications();

    // Initialize stats
    try {
      final statsService = TaskManagerStatsService();
      await statsService.initializeStats();
    } catch (e) {
      print('❌ Stats initialization error: $e');
    }
  }

  Future<void> _scheduleNotifications() async {
    final tasks = context.read<TaskProvider>().allTasks;
    await TaskNotificationHelper().scheduleAllTaskNotifications(tasks);
  }

  Future<void> _runCompletionChecks() async {
    try {
      final service = TaskCompletionService();
      await service.runAllChecks();

      // Refresh tasks after checks
      final provider = context.read<TaskProvider>();
      await provider.loadTasksForDate(provider.selectedDate);
    } catch (e) {
      print('❌ Completion check error: $e');
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = context.watch<TaskProvider>();

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
                selectedDate: taskProvider.selectedDate,
                onDateSelected: (date) {
                  taskProvider.selectDate(date);
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
              child: _buildDateHeader(taskProvider),
            ),
          ),

          // Task list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            sliver: SliverToBoxAdapter(
              child: _buildTaskList(taskProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'type': FilterType.all, 'icon': Icons.all_inclusive},
      {'label': '🏫 Class', 'type': FilterType.classes, 'icon': Icons.class_},  // Shows as "Class"
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

  Widget _buildDateHeader(TaskProvider taskProvider) {
    final date = taskProvider.selectedDate;
    final tasks = _getFilteredTasks(taskProvider.tasksForSelectedDate);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    String title;
    if (isToday) {
      title = 'Today';
    } else if (date.day == today.day + 1 && date.month == today.month) {
      title = 'Tomorrow';
    } else {
      title = '${_monthName(date.month)} ${date.day}, ${date.year}';
    }

    // Count completed tasks
    final completedCount = tasks.where((t) => t.isDone).length;

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
              '${tasks.length} task${tasks.length != 1 ? 's' : ''} · ${completedCount} completed',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white54 : AppColors.inkSoft,
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
    final highCount = tasks.where((t) => t.priority == Priority.high).length;
    final mediumCount = tasks.where((t) => t.priority == Priority.medium).length;
    final lowCount = tasks.where((t) => t.priority == Priority.low).length;

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

  Widget _buildTaskList(TaskProvider taskProvider) {
    final allTasks = taskProvider.tasksForSelectedDate;
    final tasks = _getFilteredTasks(allTasks);

    if (taskProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          onDelete: () => _handleDeleteTask(task),
          onToggleComplete: _handleToggleComplete,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    final taskProvider = context.watch<TaskProvider>();
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
                  : 'Tap the + button to add your first task for ${_monthName(taskProvider.selectedDate.month)} ${taskProvider.selectedDate.day}, ${taskProvider.selectedDate.year}',
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
            selectedDate: context.read<TaskProvider>().selectedDate,
            isDarkMode: _isDarkMode,
            onSubmit: (task) async {
              final provider = context.read<TaskProvider>();
              final newTask = await provider.addTask(task);
              if (newTask != null) {
                await TaskNotificationHelper().scheduleTaskNotifications(newTask);
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Task "${task.displayTitle}" added! 🎉');
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
              final provider = context.read<TaskProvider>();
              final result = await provider.updateTask(updatedTask);
              if (result != null) {
                await TaskNotificationHelper().scheduleTaskNotifications(result);
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Task "${updatedTask.displayTitle}" updated! ✅');
                }
              }
            },
          ),
        );
      },
    );
  }

  // ==================== TASK COMPLETION HANDLER ====================

  Future<void> _handleToggleComplete(Task task) async {
    try {
      final provider = context.read<TaskProvider>();

      // Toggle completion status using provider
      final updatedTask = await provider.toggleTaskCompletion(task);

      if (updatedTask != null && mounted) {
        // Show success message
        final message = updatedTask.isDone
            ? (task.type == TaskType.assignment
            ? '✅ "${task.displayTitle}" submitted!'
            : '✅ "${task.displayTitle}" completed!')
            : '⏳ "${task.displayTitle}" marked as pending';

        _showSnackBar(message);

        // Schedule notifications for the updated task
        if (updatedTask.isDone) {
          await TaskNotificationHelper().cancelTaskNotifications(updatedTask.id!);
        } else {
          await TaskNotificationHelper().scheduleTaskNotifications(updatedTask);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error updating task status');
      }
      print('❌ Toggle completion error: $e');
    }
  }

  // ==================== ENHANCED TASK DETAILS POPUP ====================

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
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: task.isDone
                                        ? Colors.green.withOpacity(0.12)
                                        : task.typeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.isDone
                                        ? (task.type == TaskType.assignment ? 'Submitted' : 'Completed')
                                        : task.type.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: task.isDone ? Colors.green : task.typeColor,
                                    ),
                                  ),
                                ),
                                if (task.isOverdue && !task.isDone) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Overdue',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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

                          // Time (for Classes) - Updated with AM/PM
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

                          // Class Test details (when exam is Class Test)
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
                                    _handleDeleteTask(task);
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

  // Enhanced detail item builder with icon
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

  // Updated _formatTimeRange with AM/PM
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

  // Keep old method for backward compatibility (if needed)
  String _formatTimeRange(DateTime start, DateTime end) {
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  Future<void> _handleDeleteTask(Task task) async {
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

    final success = await context.read<TaskProvider>().deleteTask(task.id!);
    if (success && mounted) {
      await TaskNotificationHelper().cancelTaskNotifications(task.id!);
      _showSnackBar('Task "${task.displayTitle}" deleted');
    }
  }

  void _showAllTasksStats() {
    final tasks = context.read<TaskProvider>().allTasks;
    final high = tasks.where((t) => t.priority == Priority.high).length;
    final medium = tasks.where((t) => t.priority == Priority.medium).length;
    final low = tasks.where((t) => t.priority == Priority.low).length;

    // Count by type
    final classes = tasks.where((t) => t.type == TaskType.classes).length;
    final assignments = tasks.where((t) => t.type == TaskType.assignment).length;
    final labReports = tasks.where((t) => t.type == TaskType.labReport).length;
    final exams = tasks.where((t) => t.type == TaskType.exam).length;
    final others = tasks.where((t) => t.type == TaskType.others).length;

    // Count completed
    final completed = tasks.where((t) => t.isDone).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Tasks', tasks.length, Colors.grey),
            _buildStatRow('✅ Completed', completed, Colors.green),
            const Divider(),
            _buildStatRow('📚 Exam', exams, AppColors.accentLight),
            _buildStatRow('📝 Assignment', assignments, AppColors.purple),
            _buildStatRow('🔬 Lab Report', labReports, AppColors.successLight),
            _buildStatRow('🏫 Classes', classes, AppColors.primaryLight),
            _buildStatRow('📌 Others', others, Colors.grey),
            const Divider(),
            _buildStatRow('🔴 High Priority', high, Colors.red),
            _buildStatRow('🟡 Medium Priority', medium, AppColors.warningLight),
            _buildStatRow('🟢 Low Priority', low, AppColors.successLight),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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