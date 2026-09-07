// lib/screens/TaskManager/widgets/TaskTypeSelector.dart
import 'package:flutter/material.dart';
import '../../../../models/taskmanager_model.dart';
import '../../../../utilites/app_colors.dart';


// ==================== TASK TYPE SELECTOR ====================
class TaskTypeSelector extends StatelessWidget {
  final TaskType selectedType;
  final bool isDarkMode;
  final Function(TaskType) onChanged;

  const TaskTypeSelector({
    super.key,
    required this.selectedType,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final taskTypes = TaskType.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Task Type'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: taskTypes.map((type) => _buildTypeChip(type)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }

  Widget _buildTypeChip(TaskType type) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? type.color : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? type.color : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 16, color: isSelected ? Colors.white : type.color),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : type.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CLASS SUBTYPE SELECTOR ====================
class ClassSubtypeSelector extends StatelessWidget {
  final ClassSubtype selectedSubtype;
  final bool isDarkMode;
  final Function(ClassSubtype) onChanged;

  const ClassSubtypeSelector({
    super.key,
    required this.selectedSubtype,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Class Type'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClassSubtype.values.map((subtype) {
              final isSelected = selectedSubtype == subtype;
              return GestureDetector(
                onTap: () => onChanged(subtype),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        subtype.icon,
                        size: 18,
                        color: isSelected ? AppColors.primaryLight : subtype.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subtype.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryLight : subtype.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }
}

// ==================== EXAM SUBTYPE SELECTOR ====================
class ExamSubtypeSelector extends StatelessWidget {
  final ExamSubtype selectedSubtype;
  final bool isDarkMode;
  final Function(ExamSubtype) onChanged;

  const ExamSubtypeSelector({
    super.key,
    required this.selectedSubtype,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Exam Type'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExamSubtype.values.map((subtype) {
              final isSelected = selectedSubtype == subtype;
              return GestureDetector(
                onTap: () => onChanged(subtype),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        subtype.icon,
                        size: 18,
                        color: isSelected ? AppColors.primaryLight : subtype.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subtype.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryLight : subtype.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }
}