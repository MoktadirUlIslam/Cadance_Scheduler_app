// lib/screens/Event_Maneger/components/event_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/calendar_models.dart';
import '../providers/event_provider.dart'; // 👈 FIXED PATH (was ../providers/)
import 'event_card.dart';

// ==================== EVENT CALENDAR WIDGET ====================

/// Main calendar widget for events (not tasks)
class EventCalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;
  final EventProvider eventProvider;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onDayLongPress;

  const EventCalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.isDarkMode,
    required this.fadeAnimation,
    required this.eventProvider,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onFormatChanged,
    required this.onDayLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF0E241E).withOpacity(0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _EventCalendarHeader(
              focusedDay: focusedDay,
              isDarkMode: isDarkMode,
              onPreviousMonth: () {
                final prev = DateTime(focusedDay.year, focusedDay.month - 1, focusedDay.day);
                onPageChanged(prev);
              },
              onNextMonth: () {
                final next = DateTime(focusedDay.year, focusedDay.month + 1, focusedDay.day);
                onPageChanged(next);
              },
              onMonthChanged: (month) {
                onPageChanged(DateTime(focusedDay.year, month, focusedDay.day));
              },
              onYearChanged: (year) {
                onPageChanged(DateTime(year, focusedDay.month, focusedDay.day));
              },
            ),
            TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              calendarFormat: calendarFormat,
              onFormatChanged: onFormatChanged,
              eventLoader: (day) {
                return eventProvider.getEventsForDay(day);
              },
              onDayLongPressed: (day, _) => onDayLongPress(day),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronVisible: false,
                rightChevronVisible: false,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.accentLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.accentLight,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentLight.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.ink.withOpacity(0.5),
                ),
                defaultTextStyle: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.ink,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                markersMaxCount: 3,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();

                  final uniqueCategories = events
                      .whereType<CalendarEventModel>()
                      .map((e) => e.category)
                      .toSet()
                      .take(3);

                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: uniqueCategories.map((category) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: category?.color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.6)
                      : AppColors.ink.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.4)
                      : AppColors.ink.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EVENT CALENDAR HEADER ====================

class _EventCalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final bool isDarkMode;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;

  const _EventCalendarHeader({
    required this.focusedDay,
    required this.isDarkMode,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.chevron_left,
            isDarkMode: isDarkMode,
            onPressed: onPreviousMonth,
          ),
          _MonthYearSelector(
            focusedDay: focusedDay,
            isDarkMode: isDarkMode,
            onMonthChanged: onMonthChanged,
            onYearChanged: onYearChanged,
          ),
          _NavButton(
            icon: Icons.chevron_right,
            isDarkMode: isDarkMode,
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}

// ==================== MONTH/YEAR SELECTOR ====================

class _MonthYearSelector extends StatelessWidget {
  final DateTime focusedDay;
  final bool isDarkMode;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;

  const _MonthYearSelector({
    required this.focusedDay,
    required this.isDarkMode,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(26, (i) => currentYear - 5 + i);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DropdownContainer(
          isDarkMode: isDarkMode,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: focusedDay.month,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.ink.withOpacity(0.7),
                size: 20,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppColors.ink,
              ),
              dropdownColor: isDarkMode ? const Color(0xFF1A2E2E) : Colors.white,
              items: List.generate(12, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(
                    _months[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : AppColors.ink,
                    ),
                  ),
                );
              }),
              onChanged: (month) {
                if (month != null) onMonthChanged(month);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _DropdownContainer(
          isDarkMode: isDarkMode,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: focusedDay.year,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.ink.withOpacity(0.7),
                size: 20,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppColors.ink,
              ),
              dropdownColor: isDarkMode ? const Color(0xFF1A2E2E) : Colors.white,
              items: years.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : AppColors.ink,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (year) {
                if (year != null) onYearChanged(year);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== DROPDOWN CONTAINER ====================

class _DropdownContainer extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const _DropdownContainer({
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

// ==================== NAV BUTTON ====================

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.isDarkMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isDarkMode
              ? Colors.white.withOpacity(0.7)
              : AppColors.ink.withOpacity(0.7),
        ),
      ),
    );
  }
}

// ==================== EVENT SECTION HEADER ====================

class EventSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final bool isDarkMode;

  const EventSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== EVENT LIST (SINGLE DAY) ====================

class EventListForDay extends StatelessWidget {
  final List<CalendarEventModel> events;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;
  final Function(CalendarEventModel) onDeleteEvent;
  final Function(CalendarEventModel) onEditEvent;
  final VoidCallback? onAddEvent;

  const EventListForDay({
    super.key,
    required this.events,
    required this.isDarkMode,
    required this.fadeAnimation,
    required this.onDeleteEvent,
    required this.onEditEvent,
    this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    final sorted = List<CalendarEventModel>.from(events)
      ..sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        final aTime = a.startTime!.hour * 60 + a.startTime!.minute;
        final bTime = b.startTime!.hour * 60 + b.startTime!.minute;
        return aTime.compareTo(bTime);
      });

    final upcoming = sorted.where((e) => e.isUpcoming || e.isToday).toList();
    final past = sorted.where((e) => e.isPast && !e.isToday).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: fadeAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primaryLight.withOpacity(0.05)
                  : AppColors.primaryLight.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.primaryLight.withOpacity(0.1)
                    : AppColors.primaryLight.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18,
                    color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Long press a date to add an event',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 12),
          EventSectionHeader(
            title: 'Events',
            count: upcoming.length,
            color: AppColors.primaryLight,
            icon: Icons.event,
            isDarkMode: isDarkMode,
          ),
          ...upcoming.asMap().entries.map((entry) {
            return EventCard(
              event: entry.value,
              isDarkMode: isDarkMode,
              index: entry.key,
              onTap: () {},
              onEdit: () => onEditEvent(entry.value),
              onDelete: () => onDeleteEvent(entry.value),
            );
          }),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 16),
          EventSectionHeader(
            title: 'Past Events',
            count: past.length,
            color: Colors.grey,
            icon: Icons.history,
            isDarkMode: isDarkMode,
          ),
          ...past.asMap().entries.map((entry) {
            return EventCard(
              event: entry.value,
              isDarkMode: isDarkMode,
              index: entry.key,
              onTap: () {},
              onEdit: () => onEditEvent(entry.value),
              onDelete: () => onDeleteEvent(entry.value),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.primaryLight.withOpacity(0.1)
                    : AppColors.primaryLight.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 56,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No events for this day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press a date to add one',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ALL EVENTS LIST (GROUPED) ====================

class AllEventsList extends StatelessWidget {
  final Map<DateTime, List<CalendarEventModel>> events;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;
  final Function(CalendarEventModel) onDeleteEvent;
  final Function(CalendarEventModel) onEditEvent;
  final Function(DateTime) onDateSelected;

  const AllEventsList({
    super.key,
    required this.events,
    required this.isDarkMode,
    required this.fadeAnimation,
    required this.onDeleteEvent,
    required this.onEditEvent,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_note, size: 64,
                color: isDarkMode ? Colors.white.withOpacity(0.1) : AppColors.ink.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('No events yet',
                style: TextStyle(fontSize: 18,
                    color: isDarkMode ? Colors.white.withOpacity(0.4) : AppColors.ink.withOpacity(0.4))),
            const SizedBox(height: 8),
            Text('Long press a date to add one',
                style: TextStyle(fontSize: 14,
                    color: isDarkMode ? Colors.white.withOpacity(0.3) : AppColors.ink.withOpacity(0.3))),
          ],
        ),
      );
    }

    final sortedDates = events.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        children: sortedDates.map((date) {
          final dayEvents = events[date]!
            ..sort((a, b) {
              if (a.isAllDay && !b.isAllDay) return -1;
              if (!a.isAllDay && b.isAllDay) return 1;
              return 0;
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDateHeader(date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.inkSoft,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onDateSelected(date),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('View Day',
                          style: TextStyle(fontSize: 12,
                              color: AppColors.primaryLight, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              ...dayEvents.asMap().entries.map((entry) {
                return EventCard(
                  event: entry.value,
                  isDarkMode: isDarkMode,
                  index: entry.key,
                  onTap: () {},
                  onEdit: () => onEditEvent(entry.value),
                  onDelete: () => onDeleteEvent(entry.value),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateKey = DateTime(date.year, date.month, date.day);

    if (dateKey == today) return 'Today';
    if (dateKey == yesterday) return 'Yesterday';
    if (dateKey.isAfter(today.subtract(const Duration(days: 7)))) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}