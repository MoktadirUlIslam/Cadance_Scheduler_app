import 'package:flutter/material.dart';
import '../../../../models/taskmanager_model.dart';
import '../../../../utilites/app_colors.dart';
import '../../../../widgets/PopupForm.dart';
import 'TaskTypeSelector.dart';
import 'task_form_pickers.dart';
import 'task_form_controls.dart';

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

  // Recurring fields
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
      _recurrenceFrequency = task.recurrenceFrequency;
      _recurringStartDate = task.recurringStartDate;
      _recurringEndDate = task.recurringEndDate;
      _isRecurring = task.isRecurring;
      _examSubtype = task.type == TaskType.exam
          ? _getExamSubtypeFromTask(task)
          : ExamSubtype.classTest;
      _classSubtype = task.type == TaskType.classes
          ? _getClassSubtypeFromTask(task)
          : ClassSubtype.regular;
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
    fields.add(FormFieldConfig(
      key: 'taskType',
      type: FormFieldType.custom,
      customWidget: TaskTypeSelector(
        selectedType: _taskType,
        isDarkMode: widget.isDarkMode,
        onChanged: _updateTaskType,
      ),
    ));

    // Title field for Assignment and Others
    if (_taskType.hasTitle) {
      fields.add(FormFieldConfig(
        key: 'title',
        type: FormFieldType.text,
        hint: _taskType == TaskType.assignment ? 'Assignment Topic' : 'Task Title',
        prefixIcon: Icons.title,
        initialValue: _titleController.text,
        validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
        keyboardType: TextInputType.text,
      ));
    }

    // Course details for most types
    if (_taskType.hasCourseDetails) {
      fields.add(FormFieldConfig(
        key: 'courseCode',
        type: FormFieldType.text,
        hint: 'Course Code (e.g., CSE-301)',
        prefixIcon: Icons.code,
        initialValue: _courseCodeController.text,
        keyboardType: TextInputType.text,
      ));
      fields.add(FormFieldConfig(
        key: 'courseTitle',
        type: FormFieldType.text,
        hint: 'Course Title',
        prefixIcon: Icons.book,
        initialValue: _courseTitleController.text,
        keyboardType: TextInputType.text,
      ));
    }

    // ========== CLASS TYPE SPECIFIC FIELDS ==========
    if (_taskType == TaskType.classes) {
      fields.add(FormFieldConfig(
        key: 'classSubtype',
        type: FormFieldType.custom,
        customWidget: ClassSubtypeSelector(
          selectedSubtype: _classSubtype,
          isDarkMode: widget.isDarkMode,
          onChanged: (subtype) => setState(() => _classSubtype = subtype),
        ),
      ));

      fields.add(FormFieldConfig(
        key: 'date',
        type: FormFieldType.custom,
        customWidget: DatePickerWithRecurring(
          date: _date,
          isRecurring: _isRecurring,
          recurrenceFrequency: _recurrenceFrequency,
          recurringEndDate: _recurringEndDate,
          isDarkMode: widget.isDarkMode,
          onDateChanged: _updateDate,
          onRecurringToggled: _toggleRecurring,
          onFrequencyChanged: (freq) => setState(() => _recurrenceFrequency = freq),
          onEndDateChanged: (endDate) => setState(() => _recurringEndDate = endDate),
        ),
      ));

      fields.add(FormFieldConfig(
        key: 'timeRange',
        type: FormFieldType.custom,
        customWidget: TimeRangePicker(
          startTime: _startTime,
          endTime: _endTime,
          isDarkMode: widget.isDarkMode,
          onStartTimeChanged: (time) => setState(() => _startTime = time),
          onEndTimeChanged: (time) => setState(() => _endTime = time),
        ),
      ));

      fields.add(FormFieldConfig(
        key: 'location',
        type: FormFieldType.text,
        hint: 'Room No',
        prefixIcon: Icons.location_on,
        initialValue: _locationController.text,
        keyboardType: TextInputType.text,
      ));
      fields.add(FormFieldConfig(
        key: 'teacherName',
        type: FormFieldType.text,
        hint: 'Teacher Name',
        prefixIcon: Icons.person,
        initialValue: _teacherNameController.text,
        keyboardType: TextInputType.text,
      ));
    }

    // ========== EXAM TYPE SPECIFIC FIELDS ==========
    if (_taskType == TaskType.exam) {
      fields.add(FormFieldConfig(
        key: 'examSubtype',
        type: FormFieldType.custom,
        customWidget: ExamSubtypeSelector(
          selectedSubtype: _examSubtype,
          isDarkMode: widget.isDarkMode,
          onChanged: (subtype) {
            setState(() {
              _examSubtype = subtype;
              _examTypeController.clear();
            });
          },
        ),
      ));

      // Add exam-specific fields based on subtype
      _addExamSubtypeFields(fields);
    }

    // ========== ASSIGNMENT ==========
    if (_taskType == TaskType.assignment) {
      fields.add(FormFieldConfig(
        key: 'deadlineWithTime',
        type: FormFieldType.custom,
        customWidget: DeadlineWithTimePicker(
          deadline: _deadline,
          submissionTime: _submissionTime,
          isDarkMode: widget.isDarkMode,
          onDeadlineChanged: (date) => setState(() => _deadline = date),
          onTimeChanged: (time) => setState(() => _submissionTime = time),
        ),
      ));
      fields.add(FormFieldConfig(
        key: 'teacherName',
        type: FormFieldType.text,
        hint: 'Teacher Name',
        prefixIcon: Icons.person,
        initialValue: _teacherNameController.text,
        keyboardType: TextInputType.text,
      ));
    }

    // ========== LAB REPORT ==========
    if (_taskType == TaskType.labReport) {
      fields.add(FormFieldConfig(
        key: 'experimentNo',
        type: FormFieldType.text,
        hint: 'Experiment No',
        prefixIcon: Icons.numbers,
        initialValue: _experimentNoController.text,
        keyboardType: TextInputType.text,
      ));
      fields.add(FormFieldConfig(
        key: 'experimentTitle',
        type: FormFieldType.text,
        hint: 'Experiment Title',
        prefixIcon: Icons.science,
        initialValue: _experimentTitleController.text,
        keyboardType: TextInputType.text,
      ));
      fields.add(FormFieldConfig(
        key: 'deadline',
        type: FormFieldType.custom,
        customWidget: DeadlinePicker(
          deadline: _deadline,
          taskType: _taskType,
          isDarkMode: widget.isDarkMode,
          onChanged: (date) => setState(() => _deadline = date),
        ),
      ));
      fields.add(FormFieldConfig(
        key: 'teacherName',
        type: FormFieldType.text,
        hint: 'Teacher Name',
        prefixIcon: Icons.person,
        initialValue: _teacherNameController.text,
        keyboardType: TextInputType.text,
      ));
      fields.add(FormFieldConfig(
        key: 'teacherName2',
        type: FormFieldType.text,
        hint: 'Second Teacher (Optional)',
        prefixIcon: Icons.person_outline,
        initialValue: _teacherName2Controller.text,
        keyboardType: TextInputType.text,
      ));
    }

    // ========== OTHERS ==========
    if (_taskType == TaskType.others) {
      fields.add(FormFieldConfig(
        key: 'deadline',
        type: FormFieldType.custom,
        customWidget: DeadlinePicker(
          deadline: _deadline,
          taskType: _taskType,
          isDarkMode: widget.isDarkMode,
          onChanged: (date) => setState(() => _deadline = date),
        ),
      ));
    }

    // ========== COMMON FIELDS ==========
    fields.add(FormFieldConfig(
      key: 'priority',
      type: FormFieldType.custom,
      customWidget: PrioritySelector(
        selectedPriority: _priority,
        isDarkMode: widget.isDarkMode,
        onChanged: (priority) => setState(() => _priority = priority),
      ),
    ));

    fields.add(FormFieldConfig(
      key: 'reminders',
      type: FormFieldType.custom,
      customWidget: ReminderSelector(
        selectedReminders: _selectedReminders,
        isDarkMode: widget.isDarkMode,
        onChanged: (reminders) => setState(() => _selectedReminders = reminders),
      ),
    ));

    fields.add(FormFieldConfig(
      key: 'alarm',
      type: FormFieldType.custom,
      customWidget: AlarmToggle(
        alarmOn: _alarmOn,
        isDarkMode: widget.isDarkMode,
        onChanged: (value) => setState(() => _alarmOn = value),
      ),
    ));

    fields.add(FormFieldConfig(
      key: 'description',
      type: FormFieldType.text,
      hint: 'Description (Optional)',
      prefixIcon: Icons.description,
      initialValue: _descriptionController.text,
      keyboardType: TextInputType.multiline,
    ));

    return fields;
  }

  void _addExamSubtypeFields(List<FormFieldConfig> fields) {
    if (_examSubtype == ExamSubtype.classTest) {
      fields.add(FormFieldConfig(
        key: 'classTestNo',
        type: FormFieldType.text,
        hint: 'Test No (e.g., 1, 2, 3)',
        prefixIcon: Icons.numbers,
        initialValue: _classTestNoController.text,
        keyboardType: TextInputType.text,
      ));
      fields.add(FormFieldConfig(
        key: 'testTopic',
        type: FormFieldType.text,
        hint: 'Test Topic',
        prefixIcon: Icons.topic,
        initialValue: _testTopicController.text,
        keyboardType: TextInputType.text,
      ));
    }

    // Common exam fields
    fields.add(FormFieldConfig(
      key: 'date',
      type: FormFieldType.custom,
      customWidget: DatePicker(
        date: _date,
        isDarkMode: widget.isDarkMode,
        onChanged: (date) => setState(() => _date = date),
      ),
    ));

    fields.add(FormFieldConfig(
      key: 'timeRange',
      type: FormFieldType.custom,
      customWidget: TimeRangePicker(
        startTime: _startTime,
        endTime: _endTime,
        isDarkMode: widget.isDarkMode,
        onStartTimeChanged: (time) => setState(() => _startTime = time),
        onEndTimeChanged: (time) => setState(() => _endTime = time),
      ),
    ));

    fields.add(FormFieldConfig(
      key: 'location',
      type: FormFieldType.text,
      hint: 'Room No',
      prefixIcon: Icons.location_on,
      initialValue: _locationController.text,
      keyboardType: TextInputType.text,
    ));

    fields.add(FormFieldConfig(
      key: 'teacherName',
      type: FormFieldType.text,
      hint: _examSubtype == ExamSubtype.classTest ? 'Teacher Name' : 'Teacher Name (Optional)',
      prefixIcon: _examSubtype == ExamSubtype.classTest ? Icons.person : Icons.person_outline,
      initialValue: _teacherNameController.text,
      keyboardType: TextInputType.text,
    ));
  }

  void _updateTaskType(TaskType type) {
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
  }

  void _updateDate(DateTime date) {
    setState(() {
      _date = date;
      if (_isRecurring && _recurringEndDate == null) {
        _recurringEndDate = _date.add(const Duration(days: 120));
      }
    });
  }

  void _toggleRecurring(bool value) {
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
  }

  void _submitForm() {
    final title = _titleController.text.trim();
    final courseCode = _courseCodeController.text.trim();
    final courseTitle = _courseTitleController.text.trim();
    final location = _locationController.text.trim();
    final teacherName = _teacherNameController.text.trim();
    final teacherName2 = _teacherName2Controller.text.trim();
    final description = _descriptionController.text.trim();
    final classTestNo = _classTestNoController.text.trim();
    final testTopic = _testTopicController.text.trim();
    final experimentNo = _experimentNoController.text.trim();
    final experimentTitle = _experimentTitleController.text.trim();

    if (_selectedReminders.isEmpty) {
      _selectedReminders = [ReminderOption.oneDay, ReminderOption.twoHours];
    }

    DateTime effectiveDate;
    if ((_taskType == TaskType.assignment || _taskType == TaskType.labReport || _taskType == TaskType.others) && _deadline != null) {
      effectiveDate = DateTime(_deadline!.year, _deadline!.month, _deadline!.day);
      if (_taskType == TaskType.assignment && !_selectedReminders.contains(ReminderOption.twoDays)) {
        _selectedReminders.add(ReminderOption.twoDays);
      }
    } else if (_taskType.hasDeadline && !_taskType.hasTimeRange) {
      effectiveDate = DateTime.now();
    } else {
      effectiveDate = _date;
    }

    String? finalExamType;
    if (_taskType == TaskType.exam) {
      finalExamType = _examSubtype.label;
    }

    String? classTypeLabel;
    if (_taskType == TaskType.classes) {
      classTypeLabel = _classSubtype.label;
    }

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
      recurringGroupId: recurringGroupId,
      recurrenceFrequency: recurrenceFreq,
      recurringStartDate: recurringStartDate,
      recurringEndDate: recurringEndDate,
      recurringInstanceIndex: recurringInstanceIndex,
      isRecurringParent: isRecurringParent,
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