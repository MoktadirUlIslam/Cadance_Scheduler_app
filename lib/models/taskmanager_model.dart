// lib/models/taskmanager_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utilites/app_colors.dart';

enum FilterType {
  all,
  exam,
  assignment,
  labReport,
  classTest,
  classes,
  highPriority,
  mediumPriority,
  lowPriority
}

enum TaskType {
  classes,
  assignment,
  labReport,
  exam,
  classTest,
  others,
}

enum Priority {
  high,
  medium,
  low,
}

enum ReminderOption {
  atTime,
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  oneDay,
  twoDays,
}

// NEW: Recurrence frequency enum
enum RecurrenceFrequency {
  none,
  weekly,
  biWeekly,
}

// NEW: Extension status enum
enum ExtensionStatus {
  active,        // Semester is active
  ended,         // Semester ended naturally
  extended,      // Semester was extended
  archived,      // Semester is archived
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.none:
        return 'No Repeat';
      case RecurrenceFrequency.weekly:
        return 'Weekly (Every 7 days)';
      case RecurrenceFrequency.biWeekly:
        return 'Bi-Weekly (Every 14 days)';
    }
  }

  int get days {
    switch (this) {
      case RecurrenceFrequency.none:
        return 0;
      case RecurrenceFrequency.weekly:
        return 7;
      case RecurrenceFrequency.biWeekly:
        return 14;
    }
  }

  IconData get icon {
    switch (this) {
      case RecurrenceFrequency.none:
        return Icons.close;
      case RecurrenceFrequency.weekly:
        return Icons.repeat;
      case RecurrenceFrequency.biWeekly:
        return Icons.repeat_on;
    }
  }
}

extension ReminderOptionExtension on ReminderOption {
  String get label {
    switch (this) {
      case ReminderOption.atTime:
        return 'At time of event';
      case ReminderOption.fiveMinutes:
        return '5 minutes before';
      case ReminderOption.tenMinutes:
        return '10 minutes before';
      case ReminderOption.fifteenMinutes:
        return '15 minutes before';
      case ReminderOption.thirtyMinutes:
        return '30 minutes before';
      case ReminderOption.oneHour:
        return '1 hour before';
      case ReminderOption.twoHours:
        return '2 hours before';
      case ReminderOption.oneDay:
        return '1 day before';
      case ReminderOption.twoDays:
        return '2 days before';
    }
  }

  Duration get duration {
    switch (this) {
      case ReminderOption.atTime:
        return Duration.zero;
      case ReminderOption.fiveMinutes:
        return const Duration(minutes: 5);
      case ReminderOption.tenMinutes:
        return const Duration(minutes: 10);
      case ReminderOption.fifteenMinutes:
        return const Duration(minutes: 15);
      case ReminderOption.thirtyMinutes:
        return const Duration(minutes: 30);
      case ReminderOption.oneHour:
        return const Duration(hours: 1);
      case ReminderOption.twoHours:
        return const Duration(hours: 2);
      case ReminderOption.oneDay:
        return const Duration(days: 1);
      case ReminderOption.twoDays:
        return const Duration(days: 2);
    }
  }
}

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  int get value {
    switch (this) {
      case Priority.high:
        return 3;
      case Priority.medium:
        return 2;
      case Priority.low:
        return 1;
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return AppColors.warningLight;
      case Priority.low:
        return AppColors.successLight;
    }
  }
}

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.classes:
        return 'Classes';
      case TaskType.assignment:
        return 'Assignment';
      case TaskType.labReport:
        return 'Lab Report';
      case TaskType.exam:
        return 'Exam';
      case TaskType.classTest:
        return 'Class Test';
      case TaskType.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.classes:
        return Icons.class_;
      case TaskType.assignment:
        return Icons.assignment;
      case TaskType.labReport:
        return Icons.science;
      case TaskType.exam:
        return Icons.quiz;
      case TaskType.classTest:
        return Icons.school;
      case TaskType.others:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case TaskType.classes:
        return AppColors.primaryLight;
      case TaskType.assignment:
        return AppColors.purple;
      case TaskType.labReport:
        return AppColors.successLight;
      case TaskType.exam:
        return AppColors.accentLight;
      case TaskType.classTest:
        return AppColors.warningLight;
      case TaskType.others:
        return Colors.grey;
    }
  }

  bool get hasTitle {
    return this == TaskType.assignment || this == TaskType.others;
  }

  bool get hasCourseDetails {
    return this != TaskType.others;
  }

  bool get hasTimeRange {
    return this == TaskType.classes;
  }

  bool get hasLocation {
    return this == TaskType.classes || this == TaskType.exam || this == TaskType.classTest;
  }

  bool get hasTeacher {
    return this == TaskType.classes || this == TaskType.assignment ||
        this == TaskType.labReport || this == TaskType.classTest;
  }

  bool get hasDeadline {
    return this == TaskType.assignment || this == TaskType.labReport || this == TaskType.others;
  }

  bool get hasAssignmentTopic {
    return this == TaskType.assignment;
  }

  bool get hasExperimentFields {
    return this == TaskType.labReport;
  }

  bool get hasExamType {
    return this == TaskType.exam;
  }

  bool get hasClassTestFields {
    return this == TaskType.classTest;
  }

  bool get hasManualCompletion {
    return this == TaskType.assignment ||
        this == TaskType.labReport ||
        this == TaskType.others;
  }

  bool get hasAutoCompletion {
    return this == TaskType.classes;
  }

  Duration get extensionDuration {
    switch (this) {
      case TaskType.assignment:
      case TaskType.labReport:
        return const Duration(days: 1);
      case TaskType.others:
        return const Duration(hours: 5);
      default:
        return Duration.zero;
    }
  }

  Duration get reminderInterval {
    switch (this) {
      case TaskType.assignment:
      case TaskType.labReport:
        return const Duration(hours: 1);
      case TaskType.others:
        return const Duration(minutes: 30);
      default:
        return const Duration(hours: 1);
    }
  }

  String get completionLabel {
    switch (this) {
      case TaskType.assignment:
        return 'Submitted';
      case TaskType.labReport:
        return 'Submitted';
      case TaskType.others:
        return 'Done';
      case TaskType.classes:
        return 'Completed';
      default:
        return 'Done';
    }
  }

  String get actionLabel {
    switch (this) {
      case TaskType.assignment:
        return 'Submit';
      case TaskType.labReport:
        return 'Submit';
      case TaskType.others:
        return 'Mark Done';
      default:
        return 'Complete';
    }
  }

  String get undoActionLabel {
    switch (this) {
      case TaskType.assignment:
        return 'Unsubmit';
      case TaskType.labReport:
        return 'Unsubmit';
      default:
        return 'Undo';
    }
  }
}

class Task {
  final String? id;
  final String userId;
  final TaskType type;
  final String? title;
  final String? courseCode;
  final String? courseTitle;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final Priority priority;
  final String? location;
  final String? teacherName;
  final String? teacherName2;
  final List<ReminderOption> reminders;
  final bool alarmOn;
  final DateTime? deadline;
  final String? description;
  final bool isDone;

  // Additional fields for specific task types
  final String? examType;
  final String? classTestNo;
  final String? testTopic;
  final String? experimentNo;
  final String? experimentTitle;

  // NEW: Recurring class fields
  final String? recurringGroupId;
  final RecurrenceFrequency recurrenceFrequency;
  final DateTime? expectedEndDate;
  final DateTime? actualEndDate;
  final ExtensionStatus extensionStatus;
  final int extensionCount;
  final List<DateTime>? skippedDates;
  final bool isRecurringParent;

  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    this.id,
    required this.userId,
    required this.type,
    this.title,
    this.courseCode,
    this.courseTitle,
    required this.date,
    this.startTime,
    this.endTime,
    required this.priority,
    this.location,
    this.teacherName,
    this.teacherName2,
    this.reminders = const [],
    this.alarmOn = false,
    this.deadline,
    this.description,
    this.examType,
    this.classTestNo,
    this.testTopic,
    this.experimentNo,
    this.experimentTitle,
    this.isDone = false,
    // NEW: Recurring fields with defaults
    this.recurringGroupId,
    this.recurrenceFrequency = RecurrenceFrequency.none,
    this.expectedEndDate,
    this.actualEndDate,
    this.extensionStatus = ExtensionStatus.active,
    this.extensionCount = 0,
    this.skippedDates,
    this.isRecurringParent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters
  bool get isAllDay => startTime == null && endTime == null;

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTimeRange {
    if (startTime == null || endTime == null) return 'All Day';
    final format = (time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return '${format(startTime!)} - ${format(endTime!)}';
  }

  String get displayTitle {
    if (type == TaskType.others || type == TaskType.assignment) {
      return title ?? 'Untitled';
    }
    return courseTitle ?? 'Untitled';
  }

  String get displaySubtitle {
    switch (type) {
      case TaskType.classes:
        return '${courseCode ?? ''} ${courseTitle ?? ''}'.trim();
      case TaskType.assignment:
        return title ?? 'Assignment';
      case TaskType.labReport:
        return experimentNo != null ? 'Experiment $experimentNo' : 'Lab Report';
      case TaskType.exam:
        return examType ?? 'Exam';
      case TaskType.classTest:
        return classTestNo != null ? 'Class Test $classTestNo' : 'Class Test';
      case TaskType.others:
        return 'Task';
    }
  }

  String get priorityLabel => priority.label;
  Color get priorityColor => priority.color;
  Color get typeColor => type.color;

  String get statusLabel {
    if (isDone) {
      return type.completionLabel + ' ✅';
    }
    if (isOverdue) {
      return 'Overdue ⚠️';
    }
    return 'Pending ⏳';
  }

  bool get isOverdue {
    if (isDone) return false;
    if (type == TaskType.classes && endTime != null) {
      return DateTime.now().isAfter(endTime!);
    }
    if (deadline != null) {
      return DateTime.now().isAfter(deadline!);
    }
    return false;
  }

  Duration get extensionDuration => type.extensionDuration;
  Duration get reminderInterval => type.reminderInterval;
  bool get canManuallyComplete => type.hasManualCompletion;
  bool get autoCompletes => type.hasAutoCompletion;
  Color get statusColor {
    if (isDone) return Colors.green;
    if (isOverdue) return Colors.red;
    return Colors.orange;
  }
  IconData get statusIcon {
    if (isDone) return Icons.check_circle;
    if (isOverdue) return Icons.warning;
    return Icons.hourglass_empty;
  }

  // NEW: Check if this is a recurring class
  bool get isRecurring => recurrenceFrequency != RecurrenceFrequency.none;

  // NEW: Check if semester is ending soon (within 1 day)
  bool get isSemesterEndingSoon {
    if (expectedEndDate == null) return false;
    if (extensionStatus == ExtensionStatus.ended || extensionStatus == ExtensionStatus.archived) return false;
    final daysUntilEnd = expectedEndDate!.difference(DateTime.now()).inDays;
    return daysUntilEnd <= 1 && daysUntilEnd >= 0;
  }

  // NEW: Check if semester has ended
  bool get isSemesterEnded {
    if (expectedEndDate == null) return false;
    if (extensionStatus == ExtensionStatus.ended || extensionStatus == ExtensionStatus.archived) return true;
    return DateTime.now().isAfter(expectedEndDate!) &&
        extensionStatus != ExtensionStatus.extended;
  }

// NEW: Get total expected classes (including the start date)
  int get totalExpectedClasses {
    if (!isRecurring || expectedEndDate == null) return 1;
    final daysBetween = expectedEndDate!.difference(date).inDays;
    final interval = recurrenceFrequency.days;
    if (interval == 0) return 1;
    // Add 1 to include the start date
    return (daysBetween / interval).floor() + 1;
  }

  // NEW: Get actual classes count (including extensions)
  int get actualTotalClasses {
    if (!isRecurring || actualEndDate == null) return totalExpectedClasses;
    final daysBetween = actualEndDate!.difference(date).inDays;
    final interval = recurrenceFrequency.days;
    if (interval == 0) return 1;
    return (daysBetween / interval).floor() + 1;
  }

  // NEW: Get skipped date count
  int get skippedCount => skippedDates?.length ?? 0;

  // NEW: Get completion rate
  double get completionRate {
    final total = actualTotalClasses;
    if (total == 0) return 0.0;
    return (skippedDates?.length ?? 0) / total;
  }

  // NEW: Check if a specific date is skipped
  bool isDateSkipped(DateTime date) {
    if (skippedDates == null) return false;
    return skippedDates!.any((d) =>
    d.year == date.year &&
        d.month == date.month &&
        d.day == date.day
    );
  }

  // NEW: Generate all class dates
  List<DateTime> getAllClassDates() {
    if (!isRecurring || expectedEndDate == null) {
      return [date];
    }

    List<DateTime> dates = [];
    DateTime current = date;
    final endDate = actualEndDate ?? expectedEndDate!;
    final interval = recurrenceFrequency.days;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dates.add(current);
      current = current.add(Duration(days: interval));
    }

    return dates;
  }

  // NEW: Get upcoming class dates (after today)
  List<DateTime> getUpcomingClassDates() {
    final allDates = getAllClassDates();
    final now = DateTime.now();
    return allDates.where((d) => d.isAfter(now)).toList();
  }

  // NEW: Get completed class dates
  List<DateTime> getCompletedClassDates() {
    final allDates = getAllClassDates();
    final now = DateTime.now();
    return allDates.where((d) => d.isBefore(now)).toList();
  }

  // NEW: Create a copy with extension
  Task extendSemester() {
    if (expectedEndDate == null) return this;
    final newEndDate = expectedEndDate!.add(Duration(days: 7));
    return copyWith(
      expectedEndDate: newEndDate,
      extensionStatus: ExtensionStatus.extended,
      extensionCount: extensionCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  // NEW: End semester
  Task endSemester() {
    return copyWith(
      actualEndDate: DateTime.now(),
      extensionStatus: ExtensionStatus.ended,
      updatedAt: DateTime.now(),
    );
  }

  // NEW: Archive semester
  Task archiveSemester() {
    return copyWith(
      extensionStatus: ExtensionStatus.archived,
      updatedAt: DateTime.now(),
    );
  }

  // NEW: Skip a specific date
  Task skipDate(DateTime date) {
    final updatedSkipped = List<DateTime>.from(skippedDates ?? []);
    updatedSkipped.add(date);
    return copyWith(
      skippedDates: updatedSkipped,
      updatedAt: DateTime.now(),
    );
  }

  // NEW: Unskip a specific date
  Task unskipDate(DateTime date) {
    final updatedSkipped = List<DateTime>.from(skippedDates ?? []);
    updatedSkipped.removeWhere((d) =>
    d.year == date.year &&
        d.month == date.month &&
        d.day == date.day
    );
    return copyWith(
      skippedDates: updatedSkipped,
      updatedAt: DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'date': Timestamp.fromDate(date),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'priority': priority.name,
      'location': location,
      'teacherName': teacherName,
      'teacherName2': teacherName2,
      'reminders': reminders.map((e) => e.name).toList(),
      'alarmOn': alarmOn,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'description': description,
      'examType': examType,
      'classTestNo': classTestNo,
      'testTopic': testTopic,
      'experimentNo': experimentNo,
      'experimentTitle': experimentTitle,
      'isDone': isDone,
      // NEW: Recurring fields
      'recurringGroupId': recurringGroupId,
      'recurrenceFrequency': recurrenceFrequency.name,
      'expectedEndDate': expectedEndDate != null ? Timestamp.fromDate(expectedEndDate!) : null,
      'actualEndDate': actualEndDate != null ? Timestamp.fromDate(actualEndDate!) : null,
      'extensionStatus': extensionStatus.name,
      'extensionCount': extensionCount,
      'skippedDates': skippedDates?.map((d) => Timestamp.fromDate(d)).toList(),
      'isRecurringParent': isRecurringParent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore
  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      userId: map['userId'] ?? '',
      type: TaskType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => TaskType.others,
      ),
      title: map['title']?.toString(),
      courseCode: map['courseCode']?.toString(),
      courseTitle: map['courseTitle']?.toString(),
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] != null ? (map['startTime'] as Timestamp).toDate() : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      priority: Priority.values.firstWhere(
            (e) => e.name == map['priority'],
        orElse: () => Priority.medium,
      ),
      location: map['location']?.toString(),
      teacherName: map['teacherName']?.toString(),
      teacherName2: map['teacherName2']?.toString(),
      reminders: (map['reminders'] as List<dynamic>?)?.map((e) => ReminderOption.values.firstWhere(
            (r) => r.name == e,
        orElse: () => ReminderOption.atTime,
      )).toList() ?? [],
      alarmOn: map['alarmOn'] ?? false,
      deadline: map['deadline'] != null ? (map['deadline'] as Timestamp).toDate() : null,
      description: map['description']?.toString(),
      examType: map['examType']?.toString(),
      classTestNo: map['classTestNo']?.toString(),
      testTopic: map['testTopic']?.toString(),
      experimentNo: map['experimentNo']?.toString(),
      experimentTitle: map['experimentTitle']?.toString(),
      isDone: map['isDone'] ?? false,
      // NEW: Recurring fields
      recurringGroupId: map['recurringGroupId']?.toString(),
      recurrenceFrequency: RecurrenceFrequency.values.firstWhere(
            (e) => e.name == map['recurrenceFrequency'],
        orElse: () => RecurrenceFrequency.none,
      ),
      expectedEndDate: map['expectedEndDate'] != null ? (map['expectedEndDate'] as Timestamp).toDate() : null,
      actualEndDate: map['actualEndDate'] != null ? (map['actualEndDate'] as Timestamp).toDate() : null,
      extensionStatus: ExtensionStatus.values.firstWhere(
            (e) => e.name == map['extensionStatus'],
        orElse: () => ExtensionStatus.active,
      ),
      extensionCount: map['extensionCount'] ?? 0,
      skippedDates: (map['skippedDates'] as List<dynamic>?)?.map((e) => (e as Timestamp).toDate()).toList(),
      isRecurringParent: map['isRecurringParent'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy with updated fields
  Task copyWith({
    String? id,
    String? userId,
    TaskType? type,
    String? title,
    String? courseCode,
    String? courseTitle,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    Priority? priority,
    String? location,
    String? teacherName,
    String? teacherName2,
    List<ReminderOption>? reminders,
    bool? alarmOn,
    DateTime? deadline,
    String? description,
    String? examType,
    String? classTestNo,
    String? testTopic,
    String? experimentNo,
    String? experimentTitle,
    bool? isDone,
    // NEW: Recurring fields
    String? recurringGroupId,
    RecurrenceFrequency? recurrenceFrequency,
    DateTime? expectedEndDate,
    DateTime? actualEndDate,
    ExtensionStatus? extensionStatus,
    int? extensionCount,
    List<DateTime>? skippedDates,
    bool? isRecurringParent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      teacherName: teacherName ?? this.teacherName,
      teacherName2: teacherName2 ?? this.teacherName2,
      reminders: reminders ?? this.reminders,
      alarmOn: alarmOn ?? this.alarmOn,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      examType: examType ?? this.examType,
      classTestNo: classTestNo ?? this.classTestNo,
      testTopic: testTopic ?? this.testTopic,
      experimentNo: experimentNo ?? this.experimentNo,
      experimentTitle: experimentTitle ?? this.experimentTitle,
      isDone: isDone ?? this.isDone,
      // NEW: Recurring fields
      recurringGroupId: recurringGroupId ?? this.recurringGroupId,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      extensionStatus: extensionStatus ?? this.extensionStatus,
      extensionCount: extensionCount ?? this.extensionCount,
      skippedDates: skippedDates ?? this.skippedDates,
      isRecurringParent: isRecurringParent ?? this.isRecurringParent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Task toggleDone() {
    return copyWith(
      isDone: !isDone,
      updatedAt: DateTime.now(),
    );
  }

  Task extendDeadline() {
    if (deadline == null) return this;
    return copyWith(
      deadline: deadline!.add(extensionDuration),
      updatedAt: DateTime.now(),
    );
  }

  bool get isDueSoon {
    if (isDone) return false;
    final now = DateTime.now();
    final targetDate = deadline ?? date;
    return targetDate.difference(now).inHours <= 24 && targetDate.isAfter(now);
  }

  String get timeRemaining {
    if (isDone) return 'Completed';
    final now = DateTime.now();
    final targetDate = deadline ?? date;

    if (now.isAfter(targetDate)) {
      return 'Overdue';
    }

    final difference = targetDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m remaining';
    } else {
      return 'Due very soon!';
    }
  }

  String get formattedDeadlineWithStatus {
    if (deadline == null) return 'No deadline';
    if (isDone) return '✅ Completed on ${DateFormat('MMM d').format(updatedAt)}';
    if (isOverdue) return '⚠️ Overdue: ${DateFormat('MMM d, h:mm a').format(deadline!)}';
    return '📅 Due: ${DateFormat('MMM d, h:mm a').format(deadline!)}';
  }

  bool get shouldCountInStats => isDone && type != TaskType.classes;
}