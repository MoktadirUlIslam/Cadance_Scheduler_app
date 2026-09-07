// lib/screens/TaskManager/widgets/task_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/taskmanager_model.dart';
import '../../../utilites/app_colors.dart';
import '../../../widgets/PopupForm.dart';

class TaskForm extends StatefulWidget {
  final Task? initialTask;
  final DateTime selectedDate;
  final Function(Task) onSubmit;
  final bool isDarkMode;

  const TaskForm({
    super.key,
    this.initialTask,
    required this.selectedDate,
    required this.onSubmit,
    required this.isDarkMode,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  // Form fields
  late TaskType _taskType;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Priority _priority;
  late List<ReminderOption> _selectedReminders;
  late bool _alarmOn;
  late DateTime? _deadline;
  late TimeOfDay? _submissionTime;

  // ✅ Recurring fields
  late RecurrenceFrequency _recurrenceFrequency;
  late DateTime? _recurringStartDate;
  late DateTime? _recurringEndDate;
  late bool _isRecurring;

  // Exam subtype
  late ExamSubtype _examSubtype;

  // Class subtype
  late ClassSubtype _classSubtype;

  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _teacherName2Controller = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _examTypeController = TextEditingController();
  final TextEditingController _classTestNoController = TextEditingController();
  final TextEditingController _testTopicController = TextEditingController();
  final TextEditingController _experimentNoController = TextEditingController();
  final TextEditingController _experimentTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initializeControllers();
  }

  void _initializeFields() {
    if (widget.initialTask != null) {
      final task = widget.initialTask!;
      _taskType = task.type;
      _date = task.date;
      _startTime = TimeOfDay.fromDateTime(task.startTime ?? DateTime.now());
      _endTime = TimeOfDay.fromDateTime(task.endTime ?? DateTime.now().add(const Duration(hours: 1)));
      _priority = task.priority;
      _selectedReminders = List.from(task.reminders);
      _alarmOn = task.alarmOn;
      _deadline = task.deadline;
      _submissionTime = task.submissionTime != null
          ? TimeOfDay.fromDateTime(task.submissionTime!)
          : null;

      // ✅ Recurring fields
      _recurrenceFrequency = task.recurrenceFrequency;
      _recurringStartDate = task.recurringStartDate;
      _recurringEndDate = task.recurringEndDate;
      _isRecurring = task.isRecurring;

      if (task.type == TaskType.exam) {
        _examSubtype = _getExamSubtypeFromTask(task);
      } else {
        _examSubtype = ExamSubtype.classTest;
      }

      if (task.type == TaskType.classes) {
        _classSubtype = _getClassSubtypeFromTask(task);
      } else {
        _classSubtype = ClassSubtype.regular;
      }
    } else {
      _taskType = TaskType.classes;
      _date = widget.selectedDate;

      final now = TimeOfDay.now();
      _startTime = now;
      _endTime = TimeOfDay(hour: now.hour + 1, minute: now.minute);
      _priority = Priority.medium;
      _selectedReminders = [];
      _alarmOn = true;
      _deadline = DateTime.now().add(const Duration(days: 7));
      _submissionTime = TimeOfDay(hour: 23, minute: 59);

      // ✅ Recurring fields defaults
      _recurrenceFrequency = RecurrenceFrequency.weekly;
      _recurringStartDate = _date;
      _recurringEndDate = _date.add(const Duration(days: 120));
      _isRecurring = false;
      _examSubtype = ExamSubtype.classTest;
      _classSubtype = ClassSubtype.regular;
    }
  }

  ExamSubtype _getExamSubtypeFromTask(Task task) {
    final examType = task.examType?.toLowerCase() ?? '';
    if (examType.contains('mid') || examType.contains('midterm')) {
      return ExamSubtype.midterm;
    } else if (examType.contains('final')) {
      return ExamSubtype.finalExam;
    }
    return ExamSubtype.classTest;
  }

  ClassSubtype _getClassSubtypeFromTask(Task task) {
    final classType = task.classType?.toLowerCase() ?? '';
    if (classType.contains('sessional')) {
      return ClassSubtype.sessional;
    }
    return ClassSubtype.regular;
  }

  void _initializeControllers() {
    if (widget.initialTask != null) {
      final task = widget.initialTask!;
      _titleController.text = task.title ?? '';
      _courseCodeController.text = task.courseCode ?? '';
      _courseTitleController.text = task.courseTitle ?? '';
      _locationController.text = task.location ?? '';
      _teacherNameController.text = task.teacherName ?? '';
      _teacherName2Controller.text = task.teacherName2 ?? '';
      _descriptionController.text = task.description ?? '';
      _examTypeController.text = task.examType ?? '';
      _classTestNoController.text = task.classTestNo ?? '';
      _testTopicController.text = task.testTopic ?? '';
      _experimentNoController.text = task.experimentNo ?? '';
      _experimentTitleController.text = task.experimentTitle ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _locationController.dispose();
    _teacherNameController.dispose();
    _teacherName2Controller.dispose();
    _descriptionController.dispose();
    _examTypeController.dispose();
    _classTestNoController.dispose();
    _testTopicController.dispose();
    _experimentNoController.dispose();
    _experimentTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalPopupForm(
      title: widget.initialTask != null ? 'Edit Task' : 'New Task',
      subtitle: widget.initialTask != null
          ? 'Update your task details'
          : 'Create a new task for your schedule',
      icon: widget.initialTask != null ? Icons.edit_note : Icons.add_task,
      accentColor: AppColors.primaryLight,
      fields: _buildFormFields(),
      primaryButtonText: widget.initialTask != null ? 'Update Task' : 'Create Task',
      secondaryButtonText: 'Cancel',
      onSubmit: (data) {
        _updateControllersFromData(data);
        _submitForm();
      },
    );
  }

  void _updateControllersFromData(Map<String, dynamic> data) {
    if (data.containsKey('title')) _titleController.text = data['title'] ?? '';
    if (data.containsKey('courseCode')) _courseCodeController.text = data['courseCode'] ?? '';
    if (data.containsKey('courseTitle')) _courseTitleController.text = data['courseTitle'] ?? '';
    if (data.containsKey('location')) _locationController.text = data['location'] ?? '';
    if (data.containsKey('teacherName')) _teacherNameController.text = data['teacherName'] ?? '';
    if (data.containsKey('teacherName2')) _teacherName2Controller.text = data['teacherName2'] ?? '';
    if (data.containsKey('description')) _descriptionController.text = data['description'] ?? '';
    if (data.containsKey('examType')) _examTypeController.text = data['examType'] ?? '';
    if (data.containsKey('classTestNo')) _classTestNoController.text = data['classTestNo'] ?? '';
    if (data.containsKey('testTopic')) _testTopicController.text = data['testTopic'] ?? '';
    if (data.containsKey('experimentNo')) _experimentNoController.text = data['experimentNo'] ?? '';
    if (data.containsKey('experimentTitle')) _experimentTitleController.text = data['experimentTitle'] ?? '';
  }

  List<FormFieldConfig> _buildFormFields() {
    final fields = <FormFieldConfig>[];

    // Task Type Selector
    fields.add(
      FormFieldConfig(
        key: 'taskType',
        type: FormFieldType.custom,
        customWidget: _buildTaskTypeSelector(),
      ),
    );

    // Title field for Assignment and Others
    if (_taskType.hasTitle) {
      fields.add(
        FormFieldConfig(
          key: 'title',
          type: FormFieldType.text,
          hint: _taskType == TaskType.assignment ? 'Assignment Topic' : 'Task Title',
          prefixIcon: Icons.title,
          initialValue: _titleController.text,
          validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
          keyboardType: TextInputType.text,
        ),
      );
    }

    // Course details for most types (except Others)
    if (_taskType.hasCourseDetails) {
      fields.add(
        FormFieldConfig(
          key: 'courseCode',
          type: FormFieldType.text,
          hint: 'Course Code (e.g., CSE-301)',
          prefixIcon: Icons.code,
          initialValue: _courseCodeController.text,
          keyboardType: TextInputType.text,
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'courseTitle',
          type: FormFieldType.text,
          hint: 'Course Title',
          prefixIcon: Icons.book,
          initialValue: _courseTitleController.text,
          keyboardType: TextInputType.text,
        ),
      );
    }

    // ========== CLASS TYPE SPECIFIC FIELDS ==========
    if (_taskType == TaskType.classes) {
      fields.add(
        FormFieldConfig(
          key: 'classSubtype',
          type: FormFieldType.custom,
          customWidget: _buildClassSubtypeSelector(),
        ),
      );

      // ✅ Always show recurring options for both Regular and Sessional classes
      fields.add(
        FormFieldConfig(
          key: 'date',
          type: FormFieldType.custom,
          customWidget: _buildDatePickerWithRecurring(),
        ),
      );

      fields.add(
        FormFieldConfig(
          key: 'timeRange',
          type: FormFieldType.custom,
          customWidget: _buildTimeRangePicker(),
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'location',
          type: FormFieldType.text,
          hint: 'Room No',
          prefixIcon: Icons.location_on,
          initialValue: _locationController.text,
          keyboardType: TextInputType.text,
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'teacherName',
          type: FormFieldType.text,
          hint: 'Teacher Name',
          prefixIcon: Icons.person,
          initialValue: _teacherNameController.text,
          keyboardType: TextInputType.text,
        ),
      );
    }

    // ========== EXAM TYPE SPECIFIC FIELDS ==========
    if (_taskType == TaskType.exam) {
      fields.add(
        FormFieldConfig(
          key: 'examSubtype',
          type: FormFieldType.custom,
          customWidget: _buildExamSubtypeSelector(),
        ),
      );

      if (_examSubtype == ExamSubtype.classTest) {
        fields.add(
          FormFieldConfig(
            key: 'classTestNo',
            type: FormFieldType.text,
            hint: 'Test No (e.g., 1, 2, 3)',
            prefixIcon: Icons.numbers,
            initialValue: _classTestNoController.text,
            keyboardType: TextInputType.text,
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'testTopic',
            type: FormFieldType.text,
            hint: 'Test Topic',
            prefixIcon: Icons.topic,
            initialValue: _testTopicController.text,
            keyboardType: TextInputType.text,
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'date',
            type: FormFieldType.custom,
            customWidget: _buildDatePicker(),
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'timeRange',
            type: FormFieldType.custom,
            customWidget: _buildTimeRangePicker(),
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'location',
            type: FormFieldType.text,
            hint: 'Room No',
            prefixIcon: Icons.location_on,
            initialValue: _locationController.text,
            keyboardType: TextInputType.text,
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'teacherName',
            type: FormFieldType.text,
            hint: 'Teacher Name',
            prefixIcon: Icons.person,
            initialValue: _teacherNameController.text,
            keyboardType: TextInputType.text,
          ),
        );
      }

      if (_examSubtype == ExamSubtype.midterm) {
        fields.add(
          FormFieldConfig(
            key: 'date',
            type: FormFieldType.custom,
            customWidget: _buildDatePicker(),
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'timeRange',
            type: FormFieldType.custom,
            customWidget: _buildTimeRangePicker(),
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'location',
            type: FormFieldType.text,
            hint: 'Room No',
            prefixIcon: Icons.location_on,
            initialValue: _locationController.text,
            keyboardType: TextInputType.text,
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'teacherName',
            type: FormFieldType.text,
            hint: 'Teacher Name (Optional)',
            prefixIcon: Icons.person_outline,
            initialValue: _teacherNameController.text,
            keyboardType: TextInputType.text,
          ),
        );
      }

      if (_examSubtype == ExamSubtype.finalExam) {
        fields.add(
          FormFieldConfig(
            key: 'date',
            type: FormFieldType.custom,
            customWidget: _buildDatePicker(),
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'timeRange',
            type: FormFieldType.custom,
            customWidget: _buildTimeRangePicker(),
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'location',
            type: FormFieldType.text,
            hint: 'Room No',
            prefixIcon: Icons.location_on,
            initialValue: _locationController.text,
            keyboardType: TextInputType.text,
          ),
        );
        fields.add(
          FormFieldConfig(
            key: 'teacherName',
            type: FormFieldType.text,
            hint: 'Teacher Name (Optional)',
            prefixIcon: Icons.person_outline,
            initialValue: _teacherNameController.text,
            keyboardType: TextInputType.text,
          ),
        );
      }
    }

    // ========== ASSIGNMENT ==========
    if (_taskType == TaskType.assignment) {
      fields.add(
        FormFieldConfig(
          key: 'deadlineWithTime',
          type: FormFieldType.custom,
          customWidget: _buildDeadlineWithTimePicker(),
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'teacherName',
          type: FormFieldType.text,
          hint: 'Teacher Name',
          prefixIcon: Icons.person,
          initialValue: _teacherNameController.text,
          keyboardType: TextInputType.text,
        ),
      );
    }

    // ========== LAB REPORT ==========
    if (_taskType == TaskType.labReport) {
      fields.add(
        FormFieldConfig(
          key: 'experimentNo',
          type: FormFieldType.text,
          hint: 'Experiment No',
          prefixIcon: Icons.numbers,
          initialValue: _experimentNoController.text,
          keyboardType: TextInputType.text,
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'experimentTitle',
          type: FormFieldType.text,
          hint: 'Experiment Title',
          prefixIcon: Icons.science,
          initialValue: _experimentTitleController.text,
          keyboardType: TextInputType.text,
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'deadline',
          type: FormFieldType.custom,
          customWidget: _buildDeadlinePicker(),
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'teacherName',
          type: FormFieldType.text,
          hint: 'Teacher Name',
          prefixIcon: Icons.person,
          initialValue: _teacherNameController.text,
          keyboardType: TextInputType.text,
        ),
      );
      fields.add(
        FormFieldConfig(
          key: 'teacherName2',
          type: FormFieldType.text,
          hint: 'Second Teacher (Optional)',
          prefixIcon: Icons.person_outline,
          initialValue: _teacherName2Controller.text,
          keyboardType: TextInputType.text,
        ),
      );
    }

    // ========== OTHERS ==========
    if (_taskType == TaskType.others) {
      fields.add(
        FormFieldConfig(
          key: 'deadline',
          type: FormFieldType.custom,
          customWidget: _buildDeadlinePicker(),
        ),
      );
    }

    // ========== COMMON FIELDS ==========
    fields.add(
      FormFieldConfig(
        key: 'priority',
        type: FormFieldType.custom,
        customWidget: _buildPrioritySelector(),
      ),
    );

    fields.add(
      FormFieldConfig(
        key: 'reminders',
        type: FormFieldType.custom,
        customWidget: _buildReminderSelector(),
      ),
    );

    fields.add(
      FormFieldConfig(
        key: 'alarm',
        type: FormFieldType.custom,
        customWidget: _buildAlarmToggle(),
      ),
    );

    fields.add(
      FormFieldConfig(
        key: 'description',
        type: FormFieldType.text,
        hint: 'Description (Optional)',
        prefixIcon: Icons.description,
        initialValue: _descriptionController.text,
        keyboardType: TextInputType.multiline,
      ),
    );

    return fields;
  }

  // ==================== CLASS SUBTYPE SELECTOR ====================

  Widget _buildClassSubtypeSelector() {
    final isDarkMode = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Class Type', isDarkMode),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClassSubtype.values.map((subtype) {
              final isSelected = _classSubtype == subtype;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _classSubtype = subtype;
                    // ✅ When switching to Regular, keep recurring if already enabled
                    if (subtype == ClassSubtype.regular && !_isRecurring) {
                      // Don't auto-enable recurring for regular
                    }
                  });
                },
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

  // ==================== DEADLINE WITH TIME PICKER ====================

  Widget _buildDeadlineWithTimePicker() {
    final isDarkMode = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Submission Deadline', isDarkMode),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildSimpleDatePicker(),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildSimpleTimePicker(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Shows on schedule 2 days before deadline',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDatePicker() {
    final isDarkMode = widget.isDarkMode;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryLight,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _deadline = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _deadline != null
                    ? DateFormat('MMM d, yyyy').format(_deadline!)
                    : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  color: _deadline != null
                      ? (isDarkMode ? Colors.white : AppColors.ink)
                      : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTimePicker() {
    final isDarkMode = widget.isDarkMode;
    final time = _submissionTime ?? TimeOfDay(hour: 23, minute: 59);

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: AppColors.primaryLight, onPrimary: Colors.white),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _submissionTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatTimeOfDayWithAmPm(time),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  // ==================== EXAM SUBTYPE SELECTOR ====================

  Widget _buildExamSubtypeSelector() {
    final isDarkMode = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Exam Type', isDarkMode),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExamSubtype.values.map((subtype) {
              final isSelected = _examSubtype == subtype;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _examSubtype = subtype;
                    _examTypeController.clear();
                  });
                },
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

  // ==================== RECURRING UI ====================

  Widget _buildDatePickerWithRecurring() {
    final isDarkMode = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Class Date', isDarkMode),
        const SizedBox(height: 8),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildRecurringToggle(),
        if (_isRecurring) ...[
          const SizedBox(height: 12),
          _buildRecurrenceFrequencySelector(),
          const SizedBox(height: 12),
          _buildRecurringEndDatePicker(),
        ],
      ],
    );
  }

  Widget _buildLabel(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppColors.ink,
      ),
    );
  }

  Widget _buildDatePicker() {
    final isDarkMode = widget.isDarkMode;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryLight,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _date = picked;
            if (_isRecurring && _recurringEndDate == null) {
              _recurringEndDate = _date.add(const Duration(days: 120));
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_date),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringToggle() {
    final isDarkMode = widget.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRecurring
              ? AppColors.primaryLight
              : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
          width: _isRecurring ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isRecurring ? Icons.repeat : Icons.repeat_outlined,
            color: _isRecurring ? AppColors.primaryLight : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recurring Class',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.ink,
                  ),
                ),
                Text(
                  _isRecurring ? 'Repeats weekly/bi-weekly' : 'Enable recurring for this class',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
                if (value && _recurringEndDate == null) {
                  _recurringEndDate = _date.add(const Duration(days: 120));
                }
                if (!value) {
                  _recurrenceFrequency = RecurrenceFrequency.none;
                  _recurringEndDate = null;
                }
              });
            },
            activeColor: AppColors.primaryLight,
            activeTrackColor: AppColors.primaryLight.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceFrequencySelector() {
    final isDarkMode = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Repeat Every', isDarkMode),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFrequencyOption(
                RecurrenceFrequency.weekly,
                'Weekly (7 days)',
                Icons.repeat,
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFrequencyOption(
                RecurrenceFrequency.biWeekly,
                'Bi-Weekly (14 days)',
                Icons.repeat_on,
                isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyOption(RecurrenceFrequency frequency, String label, IconData icon, bool isDarkMode) {
    final isSelected = _recurrenceFrequency == frequency;

    return GestureDetector(
      onTap: () => setState(() => _recurrenceFrequency = frequency),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.1)
              : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryLight : (isDarkMode ? Colors.white54 : Colors.grey),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryLight
                    : (isDarkMode ? Colors.white70 : AppColors.ink),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringEndDatePicker() {
    final isDarkMode = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('End Date (Last Class)', isDarkMode),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _recurringEndDate ?? _date.add(const Duration(days: 120)),
              firstDate: _date,
              lastDate: DateTime(2030),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primaryLight,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _recurringEndDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recurringEndDate != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(_recurringEndDate!)
                            : 'Select end date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _recurringEndDate != null ? FontWeight.w600 : FontWeight.w400,
                          color: _recurringEndDate != null
                              ? (isDarkMode ? Colors.white : AppColors.ink)
                              : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
                        ),
                      ),
                      if (_recurringEndDate != null)
                        Text(
                          '${_calculateDaysBetween(_date, _recurringEndDate!)} classes',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calculateDaysBetween(DateTime start, DateTime end) {
    final interval = _recurrenceFrequency.days;
    if (interval == 0) return 1;
    final daysBetween = end.difference(start).inDays;
    return (daysBetween / interval).floor() + 1;
  }

  // ==================== TASK TYPE SELECTOR ====================

  Widget _buildTaskTypeSelector() {
    final isDarkMode = widget.isDarkMode;
    final taskTypes = TaskType.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Task Type', isDarkMode),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: taskTypes.map((type) => _buildTypeChip(
              type: type,
              label: type.label,
              isDarkMode: isDarkMode,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required TaskType type,
    required String label,
    required bool isDarkMode,
  }) {
    final isSelected = _taskType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _taskType = type;
          if (type != TaskType.classes) {
            _isRecurring = false;
            _recurrenceFrequency = RecurrenceFrequency.none;
            _recurringEndDate = null;
          }
          if (type == TaskType.exam) {
            _examSubtype = ExamSubtype.classTest;
          }
          if (type == TaskType.classes) {
            _classSubtype = ClassSubtype.regular;
          }
          if (_taskType.hasDeadline && !_taskType.hasTimeRange) {
            _date = DateTime.now();
            _deadline ??= DateTime.now().add(const Duration(days: 7));
          } else {
            _date = widget.selectedDate;
          }
        });
      },
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
              label,
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

  // ==================== OTHER UI WIDGETS ====================

  Widget _buildTimeRangePicker() {
    final isDarkMode = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Time Range', isDarkMode),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker('Start', _startTime, (time) => setState(() => _startTime = time)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimePicker('End', _endTime, (time) => setState(() => _endTime = time)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    final isDarkMode = widget.isDarkMode;
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: AppColors.primaryLight, onPrimary: Colors.white),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTimeOfDayWithAmPm(time),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white54 : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDayWithAmPm(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $ampm';
  }

  Widget _buildPrioritySelector() {
    final isDarkMode = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Priority', isDarkMode),
        const SizedBox(height: 8),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = _priority == priority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _priority = priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [priority.color, priority.color.withOpacity(0.7)])
                          : null,
                      color: isSelected ? null : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? priority.color : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : priority.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            priority.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : priority.color,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker() {
    final isDarkMode = widget.isDarkMode;

    String label = 'Deadline';
    String hint = 'Select deadline date';

    if (_taskType == TaskType.assignment) {
      label = 'Submission Deadline';
      hint = 'Select submission deadline';
    } else if (_taskType == TaskType.labReport) {
      label = 'Lab Report Deadline';
      hint = 'Select lab report submission date';
    } else if (_taskType == TaskType.others) {
      label = 'Task Deadline';
      hint = 'Select task deadline';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isDarkMode),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primaryLight,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _deadline = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _deadline != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(_deadline!)
                            : hint,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _deadline != null ? FontWeight.w600 : FontWeight.w400,
                          color: _deadline != null
                              ? (isDarkMode ? Colors.white : AppColors.ink)
                              : (isDarkMode ? Colors.white54 : AppColors.inkSoft),
                        ),
                      ),
                      if (_deadline != null)
                        Text(
                          _getDaysUntilDeadline(_deadline!),
                          style: TextStyle(fontSize: 11, color: _getDeadlineColor(_deadline!)),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white54 : AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDaysUntilDeadline(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return '⚠️ Deadline has passed!';
    if (difference == 0) return '⏰ Deadline is today!';
    if (difference == 1) return '⏰ 1 day remaining';
    return '$difference days remaining';
  }

  Color _getDeadlineColor(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return Colors.red;
    if (difference <= 2) return Colors.orange;
    return Colors.green;
  }

  Widget _buildReminderSelector() {
    final isDarkMode = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Reminders', isDarkMode),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ReminderOption.values.map((option) {
            final isSelected = _selectedReminders.contains(option);
            return FilterChip(
              label: Text(
                option.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedReminders.add(option);
                  } else {
                    _selectedReminders.remove(option);
                  }
                });
              },
              backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              selectedColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryLight : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedReminders.isEmpty
                      ? '⚠️ No reminders selected. Default: 1 day & 2 hours before'
                      : '${_selectedReminders.length} reminder(s) selected',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmToggle() {
    final isDarkMode = widget.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _alarmOn ? Icons.notifications_active : Icons.notifications_off,
                color: _alarmOn ? AppColors.primaryLight : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Alarm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Text(
                    _alarmOn ? 'Notifications will be sent' : 'Alarm is off',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _alarmOn,
            onChanged: (value) => setState(() => _alarmOn = value),
            activeColor: AppColors.primaryLight,
            activeTrackColor: AppColors.primaryLight.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ==================== SUBMIT ====================

  void _submitForm() {
    final title = _titleController.text.trim();
    final courseCode = _courseCodeController.text.trim();
    final courseTitle = _courseTitleController.text.trim();
    final location = _locationController.text.trim();
    final teacherName = _teacherNameController.text.trim();
    final teacherName2 = _teacherName2Controller.text.trim();
    final description = _descriptionController.text.trim();
    final examType = _examTypeController.text.trim();
    final classTestNo = _classTestNoController.text.trim();
    final testTopic = _testTopicController.text.trim();
    final experimentNo = _experimentNoController.text.trim();
    final experimentTitle = _experimentTitleController.text.trim();

    if (_selectedReminders.isEmpty) {
      _selectedReminders = [ReminderOption.oneDay, ReminderOption.twoHours];
    }

    // Determine effective date
    DateTime effectiveDate;
    if ((_taskType == TaskType.assignment || _taskType == TaskType.labReport || _taskType == TaskType.others) && _deadline != null) {
      effectiveDate = DateTime(
        _deadline!.year,
        _deadline!.month,
        _deadline!.day,
      );
      if (_taskType == TaskType.assignment && !_selectedReminders.contains(ReminderOption.twoDays)) {
        _selectedReminders.add(ReminderOption.twoDays);
      }
    } else if (_taskType.hasDeadline && !_taskType.hasTimeRange) {
      effectiveDate = DateTime.now();
    } else {
      effectiveDate = _date;
    }

    // ✅ Define variables before using them
    String? finalExamType;
    if (_taskType == TaskType.exam) {
      finalExamType = _examSubtype.label;
    }

    String? classTypeLabel;
    if (_taskType == TaskType.classes) {
      classTypeLabel = _classSubtype.label;
    }

    // ✅ RECURRING CLASS FIELDS - Available for both Regular and Sessional
    String? recurringGroupId;
    DateTime? recurringStartDate;
    DateTime? recurringEndDate;
    RecurrenceFrequency recurrenceFreq = RecurrenceFrequency.none;
    int recurringInstanceIndex = 0;
    bool isRecurringParent = false;

    if (_taskType == TaskType.classes && _isRecurring) {
      recurringGroupId = DateTime.now().millisecondsSinceEpoch.toString();
      recurringStartDate = _date;
      recurringEndDate = _recurringEndDate ?? _date.add(const Duration(days: 120));
      recurrenceFreq = _recurrenceFrequency;
      recurringInstanceIndex = 0;
      isRecurringParent = true;
    }

    // Build submission deadline with time for assignments
    DateTime? submissionDateTime;
    if (_taskType == TaskType.assignment && _deadline != null) {
      final time = _submissionTime ?? TimeOfDay(hour: 23, minute: 59);
      submissionDateTime = DateTime(
        _deadline!.year,
        _deadline!.month,
        _deadline!.day,
        time.hour,
        time.minute,
      );
    }

    final task = Task(
      id: widget.initialTask?.id,
      userId: '',
      type: _taskType,
      title: _taskType.hasTitle ? (title.isNotEmpty ? title : null) : null,
      courseCode: _taskType.hasCourseDetails ? (courseCode.isNotEmpty ? courseCode : null) : null,
      courseTitle: _taskType.hasCourseDetails ? (courseTitle.isNotEmpty ? courseTitle : null) : null,
      date: effectiveDate,
      startTime: (_taskType.hasTimeRange || _taskType == TaskType.exam)
          ? DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day, _startTime.hour, _startTime.minute)
          : null,
      endTime: (_taskType.hasTimeRange || _taskType == TaskType.exam)
          ? DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day, _endTime.hour, _endTime.minute)
          : null,
      priority: _priority,
      location: (_taskType.hasLocation || _taskType == TaskType.exam) ? (location.isNotEmpty ? location : null) : null,
      teacherName: _taskType.hasTeacher ? (teacherName.isNotEmpty ? teacherName : null) : null,
      teacherName2: _taskType == TaskType.labReport ? (teacherName2.isNotEmpty ? teacherName2 : null) : null,
      reminders: _selectedReminders,
      alarmOn: _alarmOn,
      deadline: _taskType.hasDeadline ? _deadline : null,
      submissionTime: _taskType == TaskType.assignment ? submissionDateTime : null,
      description: description.isNotEmpty ? description : null,
      examType: _taskType == TaskType.exam ? finalExamType : null,
      classTestNo: _taskType == TaskType.exam && _examSubtype == ExamSubtype.classTest
          ? (classTestNo.isNotEmpty ? classTestNo : null)
          : null,
      testTopic: _taskType == TaskType.exam && _examSubtype == ExamSubtype.classTest
          ? (testTopic.isNotEmpty ? testTopic : null)
          : null,
      experimentNo: _taskType == TaskType.labReport ? (experimentNo.isNotEmpty ? experimentNo : null) : null,
      experimentTitle: _taskType == TaskType.labReport ? (experimentTitle.isNotEmpty ? experimentTitle : null) : null,
      classType: classTypeLabel,
      // ✅ Recurring fields - Available for both Regular and Sessional
      recurringGroupId: recurringGroupId,
      recurrenceFrequency: recurrenceFreq,
      recurringStartDate: recurringStartDate,
      recurringEndDate: recurringEndDate,
      recurringInstanceIndex: recurringInstanceIndex,
      isRecurringParent: isRecurringParent,
      // ✅ Auto-completion fields (defaults)
      autoCompleted: false,
      autoCompletedAt: null,
      autoCompletionSource: null,
      extensionHistory: null,
      totalExtensions: 0,
      countedInStats: false,
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSubmit(task);
  }
}

// ==================== EXAM SUBTYPE ENUM ====================

enum ExamSubtype {
  classTest,
  midterm,
  finalExam,
}

extension ExamSubtypeExtension on ExamSubtype {
  String get label {
    switch (this) {
      case ExamSubtype.classTest:
        return 'Class Test';
      case ExamSubtype.midterm:
        return 'Midterm';
      case ExamSubtype.finalExam:
        return 'Final Exam';
    }
  }

  IconData get icon {
    switch (this) {
      case ExamSubtype.classTest:
        return Icons.school;
      case ExamSubtype.midterm:
        return Icons.quiz;
      case ExamSubtype.finalExam:
        return Icons.assignment_turned_in;
    }
  }

  Color get color {
    switch (this) {
      case ExamSubtype.classTest:
        return AppColors.warningLight;
      case ExamSubtype.midterm:
        return AppColors.accentLight;
      case ExamSubtype.finalExam:
        return Colors.red;
    }
  }
}