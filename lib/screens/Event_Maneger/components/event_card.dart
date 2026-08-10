// lib/screens/Event_Maneger/components/event_card.dart

import 'package:flutter/material.dart';
import '../../../models/calendar_models.dart';

class EventCard extends StatefulWidget {
  final CalendarEventModel event;
  final bool isDarkMode;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventCard({
    Key? key,
    required this.event,
    required this.isDarkMode,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = (widget.index * 60).clamp(0, 300);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildCard(),
      ),
    );
  }

  // In event_card.dart - Updated _buildCard method
  Widget _buildCard() {
    final isDark = widget.isDarkMode;
    final event = widget.event;
    final color = event.eventColor;
    final isPast = event.isPast;
    final opacity = isPast ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Category indicator
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(event.eventIcon, size: 18, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Time
                            Icon(
                              event.isAllDay ? Icons.calendar_today : Icons.access_time,
                              size: 14,
                              color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.formattedTimeRange, // Make sure this returns a string
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.categoryLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // REMOVED: Reminders section - if it existed
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade500,
                      size: 20,
                    ),
                    color: isDark ? const Color(0xFF1A2E2E) : Colors.white,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: color),
                            const SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit();
                      if (value == 'delete') widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}