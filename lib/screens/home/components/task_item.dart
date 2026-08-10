import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';

class TaskItem extends StatefulWidget {
  final String title;
  final String meta;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;
  final bool isDone;

  const TaskItem({
    super.key,
    required this.title,
    required this.meta,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
    this.isDone = false,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _isDone = widget.isDone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isDone = !_isDone;
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _isDone ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: _isDone ? AppColors.primaryLight : AppColors.border,
                  width: 2,
                ),
              ),
              child: _isDone
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    decoration: _isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  widget.meta,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.tagColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.tagTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}