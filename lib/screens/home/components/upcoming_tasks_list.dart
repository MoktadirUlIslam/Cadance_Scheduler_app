// lib/screens/home/components/today_tasks_and_events.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/data_provider.dart';
import '../../../models/calendar_models.dart';
import '../../../models/taskmanager_model.dart';
import '../../../utilites/app_colors.dart';
import '../../Event_Maneger/providers/event_provider.dart';
import '../../Task_manager/providers/Task_provider.dart';

class TodayTasksAndEvents extends StatefulWidget {
  final bool isDarkMode;
  final Animation<double> fadeAnimation;

  const TodayTasksAndEvents({
    super.key,
    required this.isDarkMode,
    required this.fadeAnimation,
  });

  @override
  State<TodayTasksAndEvents> createState() => _TodayTasksAndEventsState();
}

class _TodayTasksAndEventsState extends State<TodayTasksAndEvents> {
  int _selectedTab = 0; // 0 = Today, 1 = Upcoming

  @override
  void initState() {
    super.initState();
    // No need to load tasks here - DataProvider handles it
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final eventProvider = context.watch<EventProvider>();
    final taskProvider = context.watch<TaskProvider>();

    // ✅ Get today's tasks from DataProvider
    final today = DateTime.now();
    final todayTasks = dataProvider.getTasksForDate(today);

    // Filter pending tasks
    final pendingTasks = todayTasks.where((t) => !t.isDone).toList();
    final todayEvents = eventProvider.getTodayEvents();

    // ✅ Get upcoming events for next 3 days (today + next 3 days = 4 days total)
    final upcomingEvents = _getUpcomingEventsInRange(eventProvider, daysRange: 4);

    // ✅ Get upcoming tasks from DataProvider
    final allTasks = dataProvider.tasks;
    final upcomingTasks = _getUpcomingTasksInRange(allTasks, daysRange: 4);

    // Separate missed tasks from pending tasks for Today tab
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final missedTasks = pendingTasks.where((task) {
      return task.deadline != null &&
          task.deadline!.isBefore(todayDate) &&
          !task.isDone;
    }).toList();
    final activeTasks = pendingTasks.where((task) {
      return !missedTasks.contains(task);
    }).toList();

    final hasData = _selectedTab == 0
        ? pendingTasks.isNotEmpty || todayEvents.isNotEmpty
        : upcomingTasks.isNotEmpty || upcomingEvents.isNotEmpty;

    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDarkMode ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              missedTasks: missedTasks,
              dataProvider: dataProvider,
              eventProvider: eventProvider,
            ),
            const SizedBox(height: 8),
            _buildTabSelector(),
            const SizedBox(height: 10),
            dataProvider.isLoadingTasks
                ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
                : !hasData
                ? _buildEmptyState()
                : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedTab == 0
                      ? _buildTodayItems(activeTasks, missedTasks, todayEvents)
                      : _buildUpcomingItems(upcomingTasks, upcomingEvents),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required List<Task> missedTasks,
    required DataProvider dataProvider,
    required EventProvider eventProvider,
  }) {
    int totalItems = 0;
    String title = '';

    if (_selectedTab == 0) {
      final today = DateTime.now();
      final todayTasks = dataProvider.getTasksForDate(today);
      final pendingTasks = todayTasks.where((t) => !t.isDone).toList();
      final todayEvents = eventProvider.getTodayEvents();
      totalItems = pendingTasks.length + todayEvents.length;
      title = 'Today';
    } else {
      final allTasks = dataProvider.tasks;
      final upcomingTasks = _getUpcomingTasksInRange(allTasks, daysRange: 4);
      final upcomingEvents = _getUpcomingEventsInRange(eventProvider, daysRange: 4);
      totalItems = upcomingTasks.length + upcomingEvents.length;
      title = 'Upcoming 3 Days';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryLight.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _selectedTab == 0 ? Icons.today : Icons.upcoming,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title Overview',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
          ),
        ),
        const Spacer(),
        if (_selectedTab == 0 && missedTasks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 10,
                  color: Colors.red,
                ),
                const SizedBox(width: 2),
                Text(
                  '${missedTasks.length} missed',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$totalItems items',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _selectedTab == 0
                      ? [
                    BoxShadow(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.today,
                      size: 14,
                      color: _selectedTab == 0 ? Colors.white : (widget.isDarkMode ? Colors.white54 : AppColors.inkSoft),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 0 ? Colors.white : (widget.isDarkMode ? Colors.white70 : AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _selectedTab == 1
                      ? [
                    BoxShadow(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upcoming,
                      size: 14,
                      color: _selectedTab == 1 ? Colors.white : (widget.isDarkMode ? Colors.white54 : AppColors.inkSoft),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Upcoming 3 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 1 ? Colors.white : (widget.isDarkMode ? Colors.white70 : AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GET UPCOMING EVENTS IN RANGE ====================

  List<CalendarEventModel> _getUpcomingEventsInRange(EventProvider provider, {int daysRange = 4}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: daysRange - 1));

    // Get all events from provider - it's a Map<DateTime, List<CalendarEventModel>>
    final allEventsMap = provider.events;

    // Flatten the Map to a List of CalendarEventModel
    final List<CalendarEventModel> allEvents = [];
    for (final entry in allEventsMap.entries) {
      allEvents.addAll(entry.value);
    }

    // Filter events within the date range
    final List<CalendarEventModel> filteredEvents = [];

    for (final event in allEvents) {
      final eventDate = event.date;

      // Skip events that are already passed
      if (eventDate.isBefore(today)) continue;

      // Include events within the date range (today to endDate)
      if (eventDate.isAtSameMomentAs(today) ||
          eventDate.isAfter(today) && eventDate.isBefore(endDate) ||
          eventDate.isAtSameMomentAs(endDate)) {
        filteredEvents.add(event);
      }
    }

    // Sort by date
    filteredEvents.sort((a, b) => a.date.compareTo(b.date));

    return filteredEvents;
  }

  // ==================== GET UPCOMING TASKS IN RANGE ====================

  List<Task> _getUpcomingTasksInRange(List<Task> allTasks, {int daysRange = 4}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: daysRange - 1));

    return allTasks.where((task) {
      if (task.isDone) return false;

      // Skip tasks that are already passed
      if (task.type.hasTimeRange) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        if (taskDate.isBefore(today)) return false;

        // Include tasks within the date range
        if (taskDate.isAtSameMomentAs(today) ||
            taskDate.isAfter(today) && taskDate.isBefore(endDate) ||
            taskDate.isAtSameMomentAs(endDate)) {
          return true;
        }
      } else if (task.type.hasDeadline && task.deadline != null) {
        final deadlineDate = DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day);
        if (deadlineDate.isBefore(today)) return false;

        // Include tasks within the date range
        if (deadlineDate.isAtSameMomentAs(today) ||
            deadlineDate.isAfter(today) && deadlineDate.isBefore(endDate) ||
            deadlineDate.isAtSameMomentAs(endDate)) {
          return true;
        }
      }
      return false;
    }).toList()..sort((a, b) {
      // Sort by date
      DateTime dateA = a.type.hasTimeRange ? a.date : (a.deadline ?? a.date);
      DateTime dateB = b.type.hasTimeRange ? b.date : (b.deadline ?? b.date);
      return dateA.compareTo(dateB);
    });
  }

  List<Widget> _buildTodayItems(
      List<Task> activeTasks,
      List<Task> missedTasks,
      List<CalendarEventModel> events,
      ) {
    final items = <Widget>[];

    // ACTIVE TASKS SECTION
    if (activeTasks.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${activeTasks.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final task in activeTasks) {
        items.add(_CompactTaskItem(
          task: task,
          isDarkMode: widget.isDarkMode,
          showType: true,
        ));
      }
      items.add(const SizedBox(height: 8));
    }

    // MISSED TASKS SECTION
    if (missedTasks.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Missed Tasks',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${missedTasks.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final task in missedTasks) {
        items.add(_CompactTaskItem(
          task: task,
          isDarkMode: widget.isDarkMode,
          showType: true,
        ));
      }
      items.add(const SizedBox(height: 8));
    }

    // EVENTS SECTION
    if (events.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Events',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${events.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final event in events) {
        items.add(_CompactEventItem(
          event: event,
          isDarkMode: widget.isDarkMode,
          showDate: false,
        ));
      }
    }

    return items;
  }

  List<Widget> _buildUpcomingItems(List<Task> tasks, List<CalendarEventModel> events) {
    final items = <Widget>[];

    if (tasks.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final task in tasks.take(5)) {
        items.add(_CompactTaskItem(
          task: task,
          isDarkMode: widget.isDarkMode,
          showType: true,
        ));
      }
      if (tasks.length > 5) {
        items.add(_buildMoreIndicator('${tasks.length - 5} more tasks'));
      }
      items.add(const SizedBox(height: 8));
    }

    if (events.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Events',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${events.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final event in events.take(5)) {
        items.add(_CompactEventItem(
          event: event,
          isDarkMode: widget.isDarkMode,
          showDate: true,
        ));
      }
      if (events.length > 5) {
        items.add(_buildMoreIndicator('${events.length - 5} more events'));
      }
    }

    return items;
  }

  Widget _buildMoreIndicator(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '+$text',
        style: TextStyle(
          fontSize: 10,
          color: widget.isDarkMode
              ? AppColors.darkInkSoft.withOpacity(0.6)
              : AppColors.inkSoft.withOpacity(0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          _selectedTab == 0 ? 'No tasks or events for today' : 'No upcoming tasks or events in next 3 days',
          style: TextStyle(
            fontSize: 12,
            color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

// COMPACT TASK ITEM
class _CompactTaskItem extends StatelessWidget {
  final Task task;
  final bool isDarkMode;
  final bool showType;

  const _CompactTaskItem({
    required this.task,
    required this.isDarkMode,
    this.showType = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String displayText = '';
    Color displayColor = Colors.grey;
    Color displayBgColor = Colors.grey.withOpacity(0.1);

    if (task.startTime != null) {
      // ✅ Show time with AM/PM
      final t = task.startTime!;
      final hour = t.hour;
      final minute = t.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      displayText = '$hour12:$minute $ampm';
      displayColor = Colors.blue;
      displayBgColor = Colors.blue.withOpacity(0.1);
    } else if (task.deadline != null) {
      final daysUntil = task.deadline!.difference(today).inDays;
      final isOverdue = task.deadline!.isBefore(today) && !task.isDone;

      if (isOverdue) {
        displayText = 'Missed';
        displayColor = Colors.red;
        displayBgColor = Colors.red.withOpacity(0.15);
      } else if (daysUntil == 0) {
        displayText = 'Today';
        displayColor = Colors.orange;
        displayBgColor = Colors.orange.withOpacity(0.1);
      } else if (daysUntil == 1) {
        displayText = 'Tomorrow';
        displayColor = Colors.orange;
        displayBgColor = Colors.orange.withOpacity(0.1);
      } else if (daysUntil <= 3) {
        displayText = '${daysUntil}d left';
        displayColor = Colors.deepOrange;
        displayBgColor = Colors.deepOrange.withOpacity(0.1);
      } else {
        displayText = '${daysUntil}d left';
        displayColor = Colors.green;
        displayBgColor = Colors.green.withOpacity(0.1);
      }
    } else {
      displayText = task.type.label;
      displayColor = task.typeColor;
      displayBgColor = task.typeColor.withOpacity(0.1);
    }

    final isMissed = displayText == 'Missed';
    final isAutoCompleted = task.isDone && task.autoCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: (isDarkMode ? AppColors.darkCard : AppColors.card).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMissed
              ? Colors.red.withOpacity(0.3)
              : (isAutoCompleted
              ? Colors.purple.withOpacity(0.3)
              : (isDarkMode ? AppColors.darkBorder : AppColors.border).withOpacity(0.3)),
          width: isMissed ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isMissed
                  ? Colors.red
                  : (isAutoCompleted ? Colors.purple : task.priorityColor),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.displayTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isMissed
                              ? Colors.red
                              : (task.isDone
                              ? (isDarkMode ? Colors.grey : Colors.grey.shade600)
                              : (isDarkMode ? Colors.white : AppColors.ink)),
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAutoCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 8,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Auto',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (showType && task.type.label.isNotEmpty)
                  Text(
                    task.type.label,
                    style: TextStyle(
                      fontSize: 8,
                      color: isMissed
                          ? Colors.red.withOpacity(0.7)
                          : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: displayBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMissed)
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 10,
                    color: Colors.red,
                  ),
                if (isMissed) const SizedBox(width: 2),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: displayColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactEventItem extends StatelessWidget {
  final CalendarEventModel event;
  final bool isDarkMode;
  final bool showDate;

  const _CompactEventItem({
    required this.event,
    required this.isDarkMode,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.eventColor;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isPast = false;
    if (event.isAllDay) {
      isPast = event.date.isBefore(today);
    } else {
      if (event.endTime != null) {
        final endDateTime = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
          event.endTime!.hour,
          event.endTime!.minute,
        );
        isPast = endDateTime.isBefore(now);
      } else {
        isPast = event.date.isBefore(today);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: (isDarkMode ? AppColors.darkCard : AppColors.card).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPast
              ? Colors.grey.withOpacity(0.3)
              : (isDarkMode ? AppColors.darkBorder : AppColors.border).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            event.eventIcon,
            size: 12,
            color: isPast ? Colors.grey : color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPast
                    ? Colors.grey
                    : (isDarkMode ? Colors.white : AppColors.ink),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey.withOpacity(0.1)
                  : (showDate ? Colors.purple.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPast
                  ? 'Passed'
                  : (showDate ? _formatDate(event.date) : _formatTime(event.startTime)),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isPast ? Colors.grey : (showDate ? Colors.purple : Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic startTime) {
    if (startTime is DateTime) {
      // ✅ Show time with AM/PM
      final hour = startTime.hour;
      final minute = startTime.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $ampm';
    } else if (startTime is TimeOfDay) {
      final hour = startTime.hour;
      final minute = startTime.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $ampm';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntil = date.difference(today).inDays;

    if (daysUntil == 0) {
      return 'Today';
    } else if (daysUntil == 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }
}