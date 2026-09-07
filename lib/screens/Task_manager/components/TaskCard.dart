// lib/screens/TaskManager/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../models/taskmanager_model.dart';
import '../../../utilites/app_colors.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Task) onToggleComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDarkMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  bool _isDeadlineApproaching(Task task) {
    if (task.isDone) return false;
    if (task.type != TaskType.assignment) return false;
    if (task.submissionTime == null) return false;
    final now = DateTime.now();
    final daysUntilDeadline = task.submissionTime!.difference(now).inDays;
    return daysUntilDeadline >= 0 && daysUntilDeadline <= 2;
  }

  @override
  Widget build(BuildContext context) {
    final bool canSwipeToComplete = !task.isDone;

    return Dismissible(
      key: Key('task_${task.id ?? DateTime.now().millisecondsSinceEpoch}'),
      direction: canSwipeToComplete ? DismissDirection.startToEnd : DismissDirection.none,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          onToggleComplete(task);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getCompletionMessage()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              _getSwipeIcon(),
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _getSwipeActionLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDarkMode ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 3,
                      height: 28,
                      decoration: BoxDecoration(
                        color: task.isDone ? Colors.green : task.priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Title
                    Expanded(
                      child: Text(
                        task.displayTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: task.isDone
                              ? (isDarkMode ? Colors.grey : Colors.grey.shade600)
                              : (isDarkMode ? Colors.white : AppColors.ink),
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: task.typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTypeLabel(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: task.isDone ? Colors.grey : task.typeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Course details
                if (_shouldShowCourseDetails())
                  Text(
                    _getCourseDetails(),
                    style: TextStyle(
                      fontSize: 11,
                      color: task.isDone
                          ? (isDarkMode ? Colors.grey : Colors.grey.shade600)
                          : (isDarkMode ? Colors.white60 : AppColors.inkSoft),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 6),

                // Info chips - horizontal scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildInfoChips(),
                  ),
                ),

                const SizedBox(height: 6),

                // Bottom row: Status + Actions
                Row(
                  children: [
                    // Status label - SINGLE SOURCE OF TRUTH
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 10,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _getStatusLabel(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (task.alarmOn) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.notifications_active, size: 12, color: AppColors.primaryLight),
                    ],

                    if (task.reminders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.alarm, size: 12, color: Colors.orange),
                    ],

                    const Spacer(),

                    if (task.isDone)
                    // Completed badge - SIMPLIFIED (no auto prefix here)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: task.autoCompleted
                              ? Colors.purple.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              task.autoCompleted ? Icons.auto_awesome : Icons.verified,
                              size: 10,
                              color: task.autoCompleted ? Colors.purple : Colors.green,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _getCompletionLabel(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: task.autoCompleted ? Colors.purple : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Action buttons
                      IconButton(
                        onPressed: () => onToggleComplete(task),
                        icon: Icon(
                          _getCompleteIcon(),
                          size: 18,
                          color: Colors.green,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 14,
                        tooltip: _getCompleteTooltip(),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 14,
                        tooltip: 'Edit task',
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 14,
                        tooltip: 'Delete task',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  bool _shouldShowCourseDetails() {
    return task.courseCode != null &&
        task.courseCode!.isNotEmpty &&
        task.type != TaskType.others;
  }

  String _getCourseDetails() {
    if (task.courseCode != null && task.courseCode!.isNotEmpty) {
      return '${task.courseCode} • ${task.courseTitle ?? ''}';
    }
    return task.courseTitle ?? '';
  }

  String _getTypeLabel() {
    if (task.type == TaskType.classes) {
      if (task.classType != null && task.classType!.isNotEmpty) {
        return task.classType!;
      }
      return 'Class';
    }
    if (task.type == TaskType.exam) {
      if (task.examType != null && task.examType!.isNotEmpty) {
        return task.examType!;
      }
      return 'Exam';
    }
    return task.type.label;
  }

  String _getCompletionLabel() {
    // Don't add "Auto-" here - the status indicator already shows auto
    switch (task.type) {
      case TaskType.assignment:
        return 'Submitted';
      case TaskType.labReport:
        return 'Submitted';
      case TaskType.classes:
        return 'Completed';
      case TaskType.exam:
        return 'Taken';
      case TaskType.others:
        return 'Done';
      default:
        return 'Completed';
    }
  }

  String _getCompletionMessage() {
    final source = task.autoCompleted ? 'auto-' : '';
    switch (task.type) {
      case TaskType.assignment:
        return '✅ "${task.displayTitle}" ${source}submitted!';
      case TaskType.labReport:
        return '✅ "${task.displayTitle}" ${source}submitted!';
      case TaskType.classes:
        return '✅ "${task.displayTitle}" ${source}completed!';
      case TaskType.exam:
        return '✅ "${task.displayTitle}" ${source}taken!';
      case TaskType.others:
        return '✅ "${task.displayTitle}" ${source}done!';
      default:
        return '✅ "${task.displayTitle}" ${source}completed!';
    }
  }

  String _getSwipeActionLabel() {
    switch (task.type) {
      case TaskType.assignment:
      case TaskType.labReport:
        return 'SUBMIT';
      case TaskType.exam:
        return 'TAKE';
      case TaskType.classes:
        return 'COMPLETE';
      case TaskType.others:
        return 'DONE';
      default:
        return 'DONE';
    }
  }

  IconData _getSwipeIcon() {
    switch (task.type) {
      case TaskType.assignment:
      case TaskType.labReport:
        return Icons.check_circle;
      case TaskType.exam:
        return Icons.assignment_turned_in;
      case TaskType.classes:
        return Icons.done_all;
      case TaskType.others:
        return Icons.check_circle;
      default:
        return Icons.done_all;
    }
  }

  IconData _getCompleteIcon() {
    switch (task.type) {
      case TaskType.assignment:
      case TaskType.labReport:
        return Icons.check_circle_outline;
      case TaskType.classes:
        return Icons.done_all;
      case TaskType.exam:
        return Icons.assignment_turned_in;
      case TaskType.others:
        return Icons.check_circle_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getCompleteTooltip() {
    switch (task.type) {
      case TaskType.assignment:
      case TaskType.labReport:
        return 'Submit assignment';
      case TaskType.exam:
        return 'Mark as taken';
      case TaskType.classes:
        return 'Mark as completed';
      case TaskType.others:
        return 'Mark as done';
      default:
        return 'Mark as complete';
    }
  }

  String _getStatusLabel() {
    if (task.isDone) {
      // Only show "Auto-" prefix in the status indicator
      final baseLabel = _getCompletionLabel();
      return task.autoCompleted ? 'Auto-$baseLabel' : baseLabel;
    }
    if (task.isOverdue) return 'Overdue';
    if (_isDeadlineApproaching(task)) return 'Due Soon';
    return 'Pending';
  }

  Color _getStatusColor() {
    if (task.isDone) {
      return task.autoCompleted ? Colors.purple : Colors.green;
    }
    if (task.isOverdue) return Colors.red;
    if (_isDeadlineApproaching(task)) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon() {
    if (task.isDone) {
      return task.autoCompleted ? Icons.auto_awesome : Icons.check_circle;
    }
    if (task.isOverdue) return Icons.warning;
    if (_isDeadlineApproaching(task)) return Icons.timer;
    return Icons.hourglass_empty;
  }

  List<Widget> _buildInfoChips() {
    final chips = <Widget>[];

    // Date
    chips.add(_buildInfoChip(
      Icons.calendar_today,
      DateFormat('MMM d').format(task.date),
    ));

    // Time range
    if (task.startTime != null && task.endTime != null) {
      chips.add(_buildInfoChip(
        Icons.access_time,
        _formatTimeCompact(task.startTime!, task.endTime!),
      ));
    }

    // Location
    if (task.location != null && task.location!.isNotEmpty) {
      chips.add(_buildInfoChip(
        Icons.location_on,
        _truncateText(task.location!, 12),
      ));
    }

    // Teacher
    if (task.teacherName != null && task.teacherName!.isNotEmpty) {
      chips.add(_buildInfoChip(
        Icons.person,
        _truncateText(task.teacherName!, 10),
      ));
    }

    // Deadline - only if not done
    if (task.effectiveDeadline != null && !task.isDone) {
      chips.add(_buildInfoChip(
        Icons.event,
        DateFormat('MMM d, h:mm a').format(task.effectiveDeadline!),
        isOverdue: task.isOverdue && !task.isDone,
      ));
    }

    // Recurring
    if (task.isRecurring) {
      chips.add(_buildInfoChip(
        Icons.repeat,
        task.recurrenceFrequency.label,
      ));
    }

    // Extension
    if (task.totalExtensions > 0) {
      chips.add(_buildInfoChip(
        Icons.timer_outlined,
        '+${task.totalExtensions}',
        isExtension: true,
      ));
    }

    return chips;
  }

  Widget _buildInfoChip(
      IconData icon,
      String label, {
        bool isOverdue = false,
        bool isExtension = false,
      }) {
    Color? textColor;
    Color? bgColor;
    Color? borderColor;

    if (isOverdue) {
      textColor = Colors.red;
      bgColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red.withOpacity(0.3);
    } else if (isExtension) {
      textColor = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange.withOpacity(0.2);
    } else {
      textColor = isDarkMode ? Colors.white60 : AppColors.inkSoft;
      bgColor = isDarkMode ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04);
      borderColor = isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borderColor,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 9,
              color: textColor,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: textColor,
                fontWeight: isOverdue || isExtension ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    return text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;
  }

  String _formatTimeCompact(DateTime start, DateTime end) {
    final format = (DateTime t) {
      final hour = t.hour;
      final minute = t.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $ampm';
    };
    return '${format(start)}-${format(end)}';
  }
}