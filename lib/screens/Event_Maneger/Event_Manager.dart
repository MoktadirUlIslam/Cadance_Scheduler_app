// lib/screens/Event_Maneger/event_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pomodoro/screens/Event_Maneger/providers/event_provider.dart';
import 'package:pomodoro/screens/Event_Maneger/services/event_form_helper.dart';
import 'package:pomodoro/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/section_header.dart';
import 'package:pomodoro/widgets/drawer_widget.dart';
import '../../models/calendar_models.dart';
import 'components/event_card.dart';
import 'components/event_widgets.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with SingleTickerProviderStateMixin {
  // ==================== KEYS ====================
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ==================== ANIMATION ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ==================== STATE ====================
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showAllEvents = false;
  EventCategory? _filterCategory;
  bool _showHelpTip = true;

  // FIXED: Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreEvents = true;
  List<CalendarEventModel> _displayEvents = [];

  // ==================== GETTERS ====================
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
    await context.read<EventProvider>().loadEvents();

    // Load initial events
    _loadEvents();

    final events = context.read<EventProvider>().getAllEvents();
    await NotificationService().scheduleAllEvents(events);
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==================== PAGINATION ====================

  void _loadEvents({bool resetPagination = true}) {
    if (resetPagination) {
      _currentPage = 0;
      _hasMoreEvents = true;
    }

    final eventProvider = context.read<EventProvider>();
    final allEvents = _getFilteredEvents(eventProvider.getAllEvents());
    allEvents.sort((a, b) => a.date.compareTo(b.date));

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, allEvents.length);

    if (resetPagination) {
      _displayEvents = allEvents.sublist(0, end);
    } else {
      if (end <= allEvents.length) {
        _displayEvents.addAll(allEvents.sublist(start, end));
      }
    }

    _hasMoreEvents = end < allEvents.length;
    _isLoadingMore = false;
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreEvents) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    _loadEvents(resetPagination: false);

    setState(() {});
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _isDarkMode ? AppColors.darkBg : AppColors.bg,
      drawer: const CustomDrawer(),
      body: CustomScrollView(
        slivers: [
          // Category Filter Chips
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),

          // Calendar Widget
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: EventCalendarWidget(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                calendarFormat: _calendarFormat,
                isDarkMode: _isDarkMode,
                fadeAnimation: _fadeAnimation,
                eventProvider: eventProvider,
                onDaySelected: _handleDaySelected,
                onPageChanged: _handlePageChanged,
                onFormatChanged: _handleFormatChanged,
                onDayLongPress: _handleDayLongPress,
              ),
            ),
          ),

          // Help instruction
          if (_showHelpTip)
            SliverToBoxAdapter(
              child: _buildHelpInstruction(),
            ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: _buildSectionHeader(eventProvider),
            ),
          ),

          // Events List with pagination
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildEventItems(),
              ),
            ),
          ),

          // Load more indicator
          if (_hasMoreEvents && !_showAllEvents)
            SliverToBoxAdapter(
              child: _buildLoadMoreButton(),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildEventItems() {
    if (_displayEvents.isEmpty) {
      return [_buildEmptyState()];
    }

    final items = <Widget>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Group events by date
    final grouped = <DateTime, List<CalendarEventModel>>{};
    for (var event in _displayEvents) {
      final key = DateTime(event.date.year, event.date.month, event.date.day);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    // Sort dates
    final sortedDates = grouped.keys.toList()..sort();

    for (var date in sortedDates) {
      final events = grouped[date]!;

      // Add date divider
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == tomorrow) {
        label = 'Tomorrow';
      } else {
        label = _formatDate(date);
      }

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white70 : AppColors.inkSoft,
            ),
          ),
        ),
      );

      // Add events for this date
      for (var event in events) {
        items.add(
          EventCard(
            event: event,
            isDarkMode: _isDarkMode,
            index: events.indexOf(event),
            onTap: () => _showEventDetails(event),
            onEdit: () => _showEditEventForm(event),
            onDelete: () => _handleDeleteEvent(event),
          ),
        );
      }
    }

    return items;
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(strokeWidth: 2)
            : TextButton(
          onPressed: _loadMoreEvents,
          child: Text(
            'Load More Events',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ─── HELP INSTRUCTION ───
  Widget _buildHelpInstruction() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 8, 18, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [
              AppColors.primaryLight.withOpacity(0.15),
              AppColors.primaryLight.withOpacity(0.05),
            ]
                : [
              AppColors.primaryLight.withOpacity(0.08),
              AppColors.primaryLight.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isDarkMode
                ? AppColors.primaryLight.withOpacity(0.2)
                : AppColors.primaryLight.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How to add an event?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Long press on any date in the calendar to create a new event.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.5)
                          : AppColors.inkSoft,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showHelpTip = false;
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.4)
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORY FILTER ───
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _buildFilterChip(null, 'All'),
          ...EventCategory.values.map((category) => _buildFilterChip(category, category.label)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(EventCategory? category, String label) {
    final isSelected = _filterCategory == category;
    final color = category?.color ?? AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterCategory = isSelected ? null : category;
            _loadEvents(); // Reload with filter
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : (_isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : (_isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category != null) ...[
                Icon(category.icon, size: 16, color: isSelected ? Colors.white : color),
                const SizedBox(width: 6),
              ] else ...[
                Icon(Icons.all_inclusive, size: 16, color: isSelected ? Colors.white : AppColors.primaryLight),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (_isDarkMode ? Colors.white70 : AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ───
  Widget _buildSectionHeader(EventProvider eventProvider) {
    String title;
    String? action;

    if (_showAllEvents) {
      final total = _getFilteredEvents(eventProvider.getAllEvents()).length;
      title = _filterCategory != null
          ? '${_filterCategory!.label} Events ($total)'
          : 'All Events ($total)';
    } else if (_selectedDay != null) {
      final dateEvents = _getFilteredEvents(eventProvider.getEventsForDay(_selectedDay!));
      final today = DateTime.now();
      final isToday = _selectedDay!.year == today.year &&
          _selectedDay!.month == today.month &&
          _selectedDay!.day == today.day;

      title = isToday
          ? "Today's Events (${dateEvents.length})"
          : 'Events for ${_formatDate(_selectedDay!)} (${dateEvents.length})';
      action = 'Show All';
    } else {
      final upcoming = _getFilteredEvents(eventProvider.getUpcomingEvents());
      title = 'Upcoming Events (${upcoming.length})';
    }

    return SectionHeader(
      title: title,
      action: action,
      onAction: action != null ? _handleShowAll : null,
      isDarkMode: _isDarkMode,
    );
  }

  // ─── EVENT HANDLERS ───

  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _showAllEvents = false;
      _loadEvents(); // Reload for selected day
    });
  }

  void _handlePageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _handleFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _handleShowAll() {
    setState(() {
      _showAllEvents = true;
      _selectedDay = null;
      _loadEvents(); // Reload all events
    });
  }

  void _handleDayLongPress(DateTime day) {
    _showAddEventForm(selectedDate: day);
  }

  Future<void> _handleDeleteEvent(CalendarEventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
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
      await context.read<EventProvider>().deleteEvent(event);
      await _rescheduleNotifications();

      // Reload events after deletion
      _loadEvents();

      if (mounted) {
        setState(() {});
        _showSnackBar('Event "${event.title}" deleted', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to delete event', Colors.red);
      }
    }
  }

  // ─── FORM HELPERS ───

  void _showAddEventForm({DateTime? selectedDate}) {
    EventFormHelper.showAddEventForm(
      context: context,
      selectedDate: selectedDate ?? _selectedDay ?? DateTime.now(),
      onEventAdded: (event) async {
        try {
          await context.read<EventProvider>().addEvent(event);
          await _rescheduleNotifications();

          _loadEvents(); // Reload after adding

          if (mounted) {
            setState(() {
              _selectedDay = event.date;
              _showAllEvents = false;
            });
            _showSnackBar('Event "${event.title}" added! 🎉', AppColors.primaryLight);
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar('Failed to add event', Colors.red);
          }
        }
      },
    );
  }

  void _showEditEventForm(CalendarEventModel event) {
    EventFormHelper.showEditEventForm(
      context: context,
      event: event,
      onEventUpdated: (updatedEvent) async {
        try {
          await context.read<EventProvider>().updateEvent(updatedEvent);
          await _rescheduleNotifications();

          _loadEvents(); // Reload after update

          if (mounted) {
            setState(() {});
            _showSnackBar('Event "${updatedEvent.title}" updated!', AppColors.accentLight);
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar('Failed to update event', Colors.red);
          }
        }
      },
    );
  }

  void _showEventDetails(CalendarEventModel event) {
    EventFormHelper.showEventDetails(
      context: context,
      event: event,
      isDarkMode: _isDarkMode,
      onEdit: () {
        Navigator.pop(context);
        _showEditEventForm(event);
      },
      onDelete: () {
        Navigator.pop(context);
        _handleDeleteEvent(event);
      },
    );
  }

  // ─── HELPERS ───

  List<CalendarEventModel> _getFilteredEvents(List<CalendarEventModel> events) {
    if (_filterCategory == null) return events;
    return events.where((e) => e.category == _filterCategory).toList();
  }

  Future<void> _rescheduleNotifications() async {
    final events = context.read<EventProvider>().getAllEvents();
    await NotificationService().scheduleAllEvents(events);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── EMPTY STATE ───
  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
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
                Icons.event_busy_rounded,
                size: 64,
                color: _isDarkMode ? Colors.white.withOpacity(0.2) : AppColors.ink.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No events found',
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
                'Long press on any date in the calendar\nto add your first event',
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
      ),
    );
  }
}