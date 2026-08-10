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

  @override
  Widget build(BuildContext context) {
    final bool canSwipeToComplete = !task.isDone;

    return Dismissible(
      key: Key('task_${task.id}'),
      direction: canSwipeToComplete ? DismissDirection.startToEnd : DismissDirection.none,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          onToggleComplete(task);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                task.type == TaskType.assignment
                    ? '✅ "${task.displayTitle}" submitted!'
                    : '✅ "${task.displayTitle}" completed!',
              ),
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
              task.type == TaskType.assignment ? Icons.check_circle : Icons.done_all,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              task.type == TaskType.assignment ? 'SUBMIT' : 'DONE',
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
        margin: const EdgeInsets.only(bottom: 10),
        color: isDarkMode ? AppColors.darkCard : AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: task.isDone ? Colors.green : task.priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Text(
                        task.displayTitle,
                        style: TextStyle(
                          fontSize: 16,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: task.typeColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        task.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: task.isDone ? Colors.grey : task.typeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Course details (if available)
                if (task.courseCode != null && task.courseCode!.isNotEmpty)
                  Text(
                    '${task.courseCode} • ${task.courseTitle ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: task.isDone
                          ? (isDarkMode ? Colors.grey : Colors.grey.shade600)
                          : (isDarkMode ? Colors.white70 : AppColors.inkSoft),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 8),

                // Info row: Date, Time, Location
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip(Icons.calendar_today, DateFormat('MMM d').format(task.date)),
                    if (task.startTime != null && task.endTime != null)
                      _buildInfoChip(Icons.access_time, _formatTimeCompact(task.startTime!, task.endTime!)),
                    if (task.location != null && task.location!.isNotEmpty)
                      _buildInfoChip(Icons.location_on, task.location!),
                    if (task.teacherName != null && task.teacherName!.isNotEmpty)
                      _buildInfoChip(Icons.person, task.teacherName!),
                    if (task.deadline != null)
                      _buildInfoChip(
                        Icons.event,
                        'Due ${DateFormat('MMM d').format(task.deadline!)}',
                        isOverdue: task.isOverdue && !task.isDone,
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Bottom row: Priority/Status + Actions
                Row(
                  children: [
                    // Status label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.isDone
                            ? Colors.green.withOpacity(0.1)
                            : task.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: task.isDone
                              ? Colors.green.withOpacity(0.2)
                              : task.priorityColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        task.isDone ? 'Complete' : task.priority.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: task.isDone ? Colors.green : task.priorityColor,
                        ),
                      ),
                    ),

                    if (task.alarmOn) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.notifications_active, size: 14, color: AppColors.primaryLight),
                    ],

                    const Spacer(),

                    if (task.isDone)
                    // Submitted badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.type == TaskType.assignment ? 'Submitted' : 'Completed',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Action buttons for pending tasks
                      IconButton(
                        onPressed: () => onToggleComplete(task),
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: AppColors.primaryLight,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 14,
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isDarkMode ? Colors.white54 : AppColors.inkSoft,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 14,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 14,
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

  Widget _buildInfoChip(IconData icon, String label, {bool isOverdue = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.1)
            : (isDarkMode ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : (isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isOverdue ? Colors.red : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isOverdue ? Colors.red : (isDarkMode ? Colors.white70 : AppColors.inkSoft),
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // lib/screens/TaskManager/widgets/task_card.dart

// Replace the _formatTimeCompact method with this:

  String _formatTimeCompact(DateTime start, DateTime end) {
    final format = (DateTime t) {
      final hour = t.hour;
      final minute = t.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $ampm';
    };
    return '${format(start)} - ${format(end)}';
  }
}