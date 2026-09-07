// lib/models/taskmanager_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utilites/app_colors.dart';

enum FilterType {
  all,
  exam,
  assignment,
  labReport,
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

// ==================== EXAM SUBTYPE ====================
enum ExamSubtype {
  classTest('Class Test', 'Class Test', Icons.quiz_outlined),
  midterm('Midterm', 'Midterm Exam', Icons.assignment_outlined),
  finalExam('Final', 'Final Exam', Icons.school_outlined);

  final String label;
  final String shortLabel;
  final IconData icon;

  const ExamSubtype(this.label, this.shortLabel, this.icon);
}

// ADD THIS EXTENSION AFTER THE ExamSubtype enum
extension ExamSubtypeExtension on ExamSubtype {
  String get label {
    switch (this) {
      case ExamSubtype.classTest:
        return 'Class Test';
      case ExamSubtype.midterm:
        return 'Midterm';
      case ExamSubtype.finalExam:
        return 'Final';
    }
  }

  IconData get icon {
    switch (this) {
      case ExamSubtype.classTest:
        return Icons.quiz_outlined;
      case ExamSubtype.midterm:
        return Icons.assignment_outlined;
      case ExamSubtype.finalExam:
        return Icons.school_outlined;
    }
  }

  // ADD THIS COLOR GETTER
  Color get color {
    switch (this) {
      case ExamSubtype.classTest:
        return AppColors.accentLight;
      case ExamSubtype.midterm:
        return AppColors.warningLight;
      case ExamSubtype.finalExam:
        return AppColors.primaryLight;
    }
  }
}
// ==================== CLASS SUBTYPE ====================
enum ClassSubtype {
  regular('Regular', 'Regular Class', Icons.class_outlined),
  sessional('Sessional', 'Sessional Class', Icons.science_outlined);

  final String label;
  final String shortLabel;
  final IconData icon;

  const ClassSubtype(this.label, this.shortLabel, this.icon);
}

enum RecurrenceFrequency {
  none,
  weekly,
  biWeekly,
}

enum ExtensionStatus {
  active,
  ended,
  extended,
  archived,
}

// ==================== TASK STATS MODEL ====================
class TaskStats {
  final int totalTasks;
  final int totalClasses;
  final int totalAssignments;
  final int totalLabReports;
  final int totalExams;
  final int totalOthers;
  final int totalCompleted;
  final int totalPending;
  final int totalOverdue;
  final int completedToday;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastUpdated;

  TaskStats({
    this.totalTasks = 0,
    this.totalClasses = 0,
    this.totalAssignments = 0,
    this.totalLabReports = 0,
    this.totalExams = 0,
    this.totalOthers = 0,
    this.totalCompleted = 0,
    this.totalPending = 0,
    this.totalOverdue = 0,
    this.completedToday = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory TaskStats.fromMap(Map<String, dynamic> map) {
    return TaskStats(
      totalTasks: map['totalTasks'] ?? 0,
      totalClasses: map['totalClasses'] ?? 0,
      totalAssignments: map['totalAssignments'] ?? 0,
      totalLabReports: map['totalLabReports'] ?? 0,
      totalExams: map['totalExams'] ?? 0,
      totalOthers: map['totalOthers'] ?? 0,
      totalCompleted: map['totalCompleted'] ?? 0,
      totalPending: map['totalPending'] ?? 0,
      totalOverdue: map['totalOverdue'] ?? 0,
      completedToday: map['completedToday'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalTasks': totalTasks,
      'totalClasses': totalClasses,
      'totalAssignments': totalAssignments,
      'totalLabReports': totalLabReports,
      'totalExams': totalExams,
      'totalOthers': totalOthers,
      'totalCompleted': totalCompleted,
      'totalPending': totalPending,
      'totalOverdue': totalOverdue,
      'completedToday': completedToday,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  TaskStats copyWith({
    int? totalTasks,
    int? totalClasses,
    int? totalAssignments,
    int? totalLabReports,
    int? totalExams,
    int? totalOthers,
    int? totalCompleted,
    int? totalPending,
    int? totalOverdue,
    int? completedToday,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastUpdated,
  }) {
    return TaskStats(
      totalTasks: totalTasks ?? this.totalTasks,
      totalClasses: totalClasses ?? this.totalClasses,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      totalLabReports: totalLabReports ?? this.totalLabReports,
      totalExams: totalExams ?? this.totalExams,
      totalOthers: totalOthers ?? this.totalOthers,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      totalPending: totalPending ?? this.totalPending,
      totalOverdue: totalOverdue ?? this.totalOverdue,
      completedToday: completedToday ?? this.completedToday,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

extension ClassSubtypeExtension on ClassSubtype {
  String get label {
    switch (this) {
      case ClassSubtype.regular:
        return 'Regular Class';
      case ClassSubtype.sessional:
        return 'Sessional Class';
    }
  }

  IconData get icon {
    switch (this) {
      case ClassSubtype.regular:
        return Icons.class_;
      case ClassSubtype.sessional:
        return Icons.school;
    }
  }

  Color get color {
    switch (this) {
      case ClassSubtype.regular:
        return AppColors.primaryLight;
      case ClassSubtype.sessional:
        return AppColors.accentLight;
    }
  }
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.none:
        return 'No Repeat';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biWeekly:
        return 'Bi-Weekly';
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
        return 'Class';
      case TaskType.assignment:
        return 'Assignment';
      case TaskType.labReport:
        return 'Lab Report';
      case TaskType.exam:
        return 'Exam';
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
      case TaskType.others:
        return Colors.grey;
    }
  }

  bool get hasTitle => this == TaskType.assignment || this == TaskType.others;
  bool get hasCourseDetails => this != TaskType.others;
  bool get hasTimeRange => this == TaskType.classes;
  bool get hasLocation => this == TaskType.classes || this == TaskType.exam;
  bool get hasTeacher => this == TaskType.classes || this == TaskType.assignment || this == TaskType.labReport;
  bool get hasDeadline => this == TaskType.assignment || this == TaskType.labReport || this == TaskType.others;
  bool get hasAssignmentTopic => this == TaskType.assignment;
  bool get hasExperimentFields => this == TaskType.labReport;
  bool get hasExamType => this == TaskType.exam;
  bool get hasManualCompletion => this == TaskType.assignment || this == TaskType.labReport || this == TaskType.others;
  bool get hasAutoCompletion => this == TaskType.classes;

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
  final DateTime? submissionTime;
  final String? description;
  final bool isDone;
  final DateTime? completedAt;

  final String? examType;
  final String? classTestNo;
  final String? testTopic;
  final String? experimentNo;
  final String? experimentTitle;
  final String? classType;

  // Recurring class fields
  final String? recurringGroupId;
  final RecurrenceFrequency recurrenceFrequency;
  final DateTime? recurringStartDate;
  final DateTime? recurringEndDate;
  final int recurringInstanceIndex;
  final bool isRecurringParent;

  // Auto-completion tracking
  final bool autoCompleted;
  final DateTime? autoCompletedAt;
  final String? autoCompletionSource;

  // Extension history tracking
  final List<Map<String, dynamic>>? extensionHistory;
  final int totalExtensions;

  // Stats tracking
  final bool countedInStats;

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
    this.submissionTime,
    this.description,
    this.examType,
    this.classTestNo,
    this.testTopic,
    this.experimentNo,
    this.experimentTitle,
    this.classType,
    this.isDone = false,
    this.completedAt,
    this.recurringGroupId,
    this.recurrenceFrequency = RecurrenceFrequency.none,
    this.recurringStartDate,
    this.recurringEndDate,
    this.recurringInstanceIndex = 0,
    this.isRecurringParent = false,
    this.autoCompleted = false,
    this.autoCompletedAt,
    this.autoCompletionSource,
    this.extensionHistory,
    this.totalExtensions = 0,
    this.countedInStats = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters
  bool get isAllDay => startTime == null && endTime == null;
  bool get isRecurring => recurrenceFrequency != RecurrenceFrequency.none;

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
      case TaskType.others:
        return 'Task';
    }
  }

  String get classTypeLabel => classType ?? 'Regular Class';
  String get priorityLabel => priority.label;
  Color get priorityColor => priority.color;
  Color get typeColor => type.color;

  bool get isOverdue {
    if (isDone) return false;
    if (type == TaskType.classes && endTime != null) {
      return DateTime.now().isAfter(endTime!);
    }
    if (deadline != null) {
      final deadlineToCheck = submissionTime ?? deadline;
      return DateTime.now().isAfter(deadlineToCheck!);
    }
    return false;
  }

  DateTime? get effectiveDeadline {
    if (type == TaskType.assignment) {
      return submissionTime ?? deadline;
    }
    return deadline;
  }

  Duration get extensionDuration => type.extensionDuration;
  Duration get reminderInterval => type.reminderInterval;
  bool get canManuallyComplete => type.hasManualCompletion;
  bool get autoCompletes => type.hasAutoCompletion;

  DateTime? getNextRecurringDate() {
    if (!isRecurring || recurringStartDate == null) return null;
    final interval = recurrenceFrequency.days;
    if (interval == 0) return null;
    return date.add(Duration(days: interval));
  }

  DateTime? getPreviousRecurringDate() {
    if (!isRecurring || recurringStartDate == null) return null;
    final interval = recurrenceFrequency.days;
    if (interval == 0) return null;
    return date.subtract(Duration(days: interval));
  }

  bool get isLastRecurringInstance {
    if (!isRecurring || recurringEndDate == null) return false;
    final nextDate = getNextRecurringDate();
    if (nextDate == null) return true;
    return nextDate.isAfter(recurringEndDate!);
  }

  bool get isFirstRecurringInstance {
    if (!isRecurring || recurringStartDate == null) return false;
    final prevDate = getPreviousRecurringDate();
    if (prevDate == null) return true;
    return prevDate.isBefore(recurringStartDate!);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'priority': priority.name,
      'alarmOn': alarmOn,
      'reminders': reminders.map((e) => e.name).toList(),
      'isDone': isDone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'recurrenceFrequency': recurrenceFrequency.name,
      'recurringInstanceIndex': recurringInstanceIndex,
      'isRecurringParent': isRecurringParent,
      'autoCompleted': autoCompleted,
      'totalExtensions': totalExtensions,
      'countedInStats': countedInStats,
    };

    if (title != null) map['title'] = title;
    if (courseCode != null) map['courseCode'] = courseCode;
    if (courseTitle != null) map['courseTitle'] = courseTitle;
    if (startTime != null) map['startTime'] = Timestamp.fromDate(startTime!);
    if (endTime != null) map['endTime'] = Timestamp.fromDate(endTime!);
    if (location != null) map['location'] = location;
    if (teacherName != null) map['teacherName'] = teacherName;
    if (teacherName2 != null) map['teacherName2'] = teacherName2;
    if (deadline != null) map['deadline'] = Timestamp.fromDate(deadline!);
    if (submissionTime != null) map['submissionTime'] = Timestamp.fromDate(submissionTime!);
    if (description != null) map['description'] = description;
    if (examType != null) map['examType'] = examType;
    if (classTestNo != null) map['classTestNo'] = classTestNo;
    if (testTopic != null) map['testTopic'] = testTopic;
    if (experimentNo != null) map['experimentNo'] = experimentNo;
    if (experimentTitle != null) map['experimentTitle'] = experimentTitle;
    if (classType != null) map['classType'] = classType;
    if (completedAt != null) map['completedAt'] = Timestamp.fromDate(completedAt!);
    if (recurringGroupId != null) map['recurringGroupId'] = recurringGroupId;
    if (recurringStartDate != null) map['recurringStartDate'] = Timestamp.fromDate(recurringStartDate!);
    if (recurringEndDate != null) map['recurringEndDate'] = Timestamp.fromDate(recurringEndDate!);
    if (autoCompletedAt != null) map['autoCompletedAt'] = Timestamp.fromDate(autoCompletedAt!);
    if (autoCompletionSource != null) map['autoCompletionSource'] = autoCompletionSource;
    if (extensionHistory != null) map['extensionHistory'] = extensionHistory;

    return map;
  }

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
      submissionTime: map['submissionTime'] != null ? (map['submissionTime'] as Timestamp).toDate() : null,
      description: map['description']?.toString(),
      examType: map['examType']?.toString(),
      classTestNo: map['classTestNo']?.toString(),
      testTopic: map['testTopic']?.toString(),
      experimentNo: map['experimentNo']?.toString(),
      experimentTitle: map['experimentTitle']?.toString(),
      classType: map['classType']?.toString(),
      isDone: map['isDone'] ?? false,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      recurringGroupId: map['recurringGroupId']?.toString(),
      recurrenceFrequency: RecurrenceFrequency.values.firstWhere(
            (e) => e.name == map['recurrenceFrequency'],
        orElse: () => RecurrenceFrequency.none,
      ),
      recurringStartDate: map['recurringStartDate'] != null ? (map['recurringStartDate'] as Timestamp).toDate() : null,
      recurringEndDate: map['recurringEndDate'] != null ? (map['recurringEndDate'] as Timestamp).toDate() : null,
      recurringInstanceIndex: map['recurringInstanceIndex'] ?? 0,
      isRecurringParent: map['isRecurringParent'] ?? false,
      autoCompleted: map['autoCompleted'] ?? false,
      autoCompletedAt: map['autoCompletedAt'] != null ? (map['autoCompletedAt'] as Timestamp).toDate() : null,
      autoCompletionSource: map['autoCompletionSource']?.toString(),
      extensionHistory: map['extensionHistory'] != null
          ? List<Map<String, dynamic>>.from(map['extensionHistory'])
          : null,
      totalExtensions: map['totalExtensions'] ?? 0,
      countedInStats: map['countedInStats'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

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
    DateTime? submissionTime,
    String? description,
    String? examType,
    String? classTestNo,
    String? testTopic,
    String? experimentNo,
    String? experimentTitle,
    String? classType,
    bool? isDone,
    DateTime? completedAt,
    String? recurringGroupId,
    RecurrenceFrequency? recurrenceFrequency,
    DateTime? recurringStartDate,
    DateTime? recurringEndDate,
    int? recurringInstanceIndex,
    bool? isRecurringParent,
    bool? autoCompleted,
    DateTime? autoCompletedAt,
    String? autoCompletionSource,
    List<Map<String, dynamic>>? extensionHistory,
    int? totalExtensions,
    bool? countedInStats,
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
      submissionTime: submissionTime ?? this.submissionTime,
      description: description ?? this.description,
      examType: examType ?? this.examType,
      classTestNo: classTestNo ?? this.classTestNo,
      testTopic: testTopic ?? this.testTopic,
      experimentNo: experimentNo ?? this.experimentNo,
      experimentTitle: experimentTitle ?? this.experimentTitle,
      classType: classType ?? this.classType,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      recurringGroupId: recurringGroupId ?? this.recurringGroupId,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurringStartDate: recurringStartDate ?? this.recurringStartDate,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      recurringInstanceIndex: recurringInstanceIndex ?? this.recurringInstanceIndex,
      isRecurringParent: isRecurringParent ?? this.isRecurringParent,
      autoCompleted: autoCompleted ?? this.autoCompleted,
      autoCompletedAt: autoCompletedAt ?? this.autoCompletedAt,
      autoCompletionSource: autoCompletionSource ?? this.autoCompletionSource,
      extensionHistory: extensionHistory ?? this.extensionHistory,
      totalExtensions: totalExtensions ?? this.totalExtensions,
      countedInStats: countedInStats ?? this.countedInStats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Task toggleDone() {
    final now = DateTime.now();
    if (isDone) {
      return copyWith(
        isDone: false,
        completedAt: null,
        autoCompleted: false,
        autoCompletedAt: null,
        autoCompletionSource: null,
        countedInStats: false,
        updatedAt: now,
      );
    } else {
      return copyWith(
        isDone: true,
        completedAt: now,
        autoCompleted: false,
        autoCompletedAt: now,
        autoCompletionSource: 'manual',
        updatedAt: now,
      );
    }
  }

  Task markAutoCompleted() {
    final now = DateTime.now();
    return copyWith(
      isDone: true,
      completedAt: now,
      autoCompleted: true,
      autoCompletedAt: now,
      autoCompletionSource: 'system',
      updatedAt: now,
    );
  }

  Task extendDeadlineWithHistory() {
    if (deadline == null) return this;
    final now = DateTime.now();
    final newDeadline = deadline!.add(extensionDuration);
    final extensionEntry = {
      'oldDeadline': Timestamp.fromDate(deadline!),
      'newDeadline': Timestamp.fromDate(newDeadline),
      'extendedAt': Timestamp.fromDate(now),
      'extensionDuration': extensionDuration.inDays,
      'reason': 'Auto-extension after deadline passed',
    };
    final updatedHistory = List<Map<String, dynamic>>.from(extensionHistory ?? []);
    updatedHistory.add(extensionEntry);
    return copyWith(
      deadline: newDeadline,
      totalExtensions: totalExtensions + 1,
      extensionHistory: updatedHistory,
      updatedAt: now,
    );
  }

  bool get shouldCountInStats => isDone && !countedInStats && type != TaskType.classes;
}