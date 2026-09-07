// lib/core/data_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../models/profile_model.dart';
import '../models/timer_stats_model.dart';
import '../models/taskmanager_model.dart';
import '../screens/Task_manager/services/task_notification_helper.dart';
import '../services/ActivityTrackerService.dart';

// ==================== DATA PROVIDER ====================

class DataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityTrackerService _activityService = ActivityTrackerService();
  final TaskNotificationHelper _notificationHelper = TaskNotificationHelper();

  // ==================== USER DATA ====================
  String? _username;
  String? _email;
  String? _userId;
  String? _userPhotoUrl;
  DateTime? _userCreatedAt;
  bool _isLoading = false;
  String? _error;

  // ==================== TIMER STATS ====================
  int _grandTotalFocusMinutes = 0;
  int _grandTotalTaskCount = 0;
  int _streak = 0;
  int _longestStreak = 0;
  List<DailyStats> _history = [];
  DateTime? _appStartTime;
  DateTime? _lastActivityDate;

  // ==================== SESSION HISTORY ====================
  List<Map<String, dynamic>> _sessionHistory = [];
  bool _isLoadingSessions = false;

  // ==================== DAILY STATS ====================
  Map<String, Map<String, dynamic>> _dailyStats = {};
  bool _isLoadingDailyStats = false;

  // ==================== PROFILE DATA ====================
  ProfileModel _profile = ProfileModel.empty();
  bool _isLoadingProfile = false;
  String? _profileError;

  // ==================== ACTIVITY STATS ====================
  Map<String, dynamic> _activityStats = {};
  bool _isLoadingActivity = false;
  String? _activityError;

  // ==================== TASK DATA ====================
  List<Task> _tasks = [];
  bool _isLoadingTasks = false;
  String? _taskError;
  FilterType _currentTaskFilter = FilterType.all;

  // ==================== TASK STATS ====================
  TaskStats? _taskStats;
  bool _isLoadingTaskStats = false;
  String? _taskStatsError;

  // ==================== GETTERS - USER DATA ====================
  String? get username => _username;
  String? get email => _email;
  String? get userId => _userId;
  String? get userPhotoUrl => _userPhotoUrl;
  DateTime? get userCreatedAt => _userCreatedAt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== GETTERS - TIMER STATS ====================
  int get grandTotalFocusMinutes => _grandTotalFocusMinutes;
  int get grandTotalTaskCount => _grandTotalTaskCount;
  int get streak => _streak;
  int get longestStreak => _longestStreak;
  List<DailyStats> get history => _history;
  DateTime? get appStartTime => _appStartTime;
  DateTime? get lastActivityDate => _lastActivityDate;

  // ==================== GETTERS - SESSIONS ====================
  List<Map<String, dynamic>> get sessionHistory => _sessionHistory;
  bool get isLoadingSessions => _isLoadingSessions;

  // ==================== GETTERS - DAILY STATS ====================
  Map<String, Map<String, dynamic>> get dailyStats => _dailyStats;
  bool get isLoadingDailyStats => _isLoadingDailyStats;

  // ==================== GETTERS - PROFILE ====================
  ProfileModel get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  String get userMobile => _profile.mobile ?? 'Not set';
  int? get userAge => _profile.age;
  String get userGender => _profile.gender ?? 'Not set';
  String get userOccupation => _profile.occupation ?? 'Not set';
  String get userAddress => _profile.address ?? 'Not set';

  // ==================== GETTERS - ACTIVITY ====================
  Map<String, dynamic> get activityStats => _activityStats;
  bool get isLoadingActivity => _isLoadingActivity;
  String? get activityError => _activityError;
  int get totalActiveDays => _activityStats['totalActiveDays'] ?? 0;
  int get currentStreak => _activityStats['currentStreak'] ?? 0;
  int get maxStreak => _activityStats['maxStreak'] ?? 0;
  List<String> get activeDays => List<String>.from(_activityStats['activeDays'] ?? []);

  // ==================== GETTERS - TASKS ====================
  List<Task> get tasks => _tasks;
  bool get isLoadingTasks => _isLoadingTasks;
  String? get taskError => _taskError;
  FilterType get currentTaskFilter => _currentTaskFilter;

  List<Task> get filteredTasks {
    return _applyTaskFilter(_tasks, _currentTaskFilter);
  }

  // ==================== GETTERS - TASK STATS ====================
  TaskStats? get taskStats => _taskStats;
  bool get isLoadingTaskStats => _isLoadingTaskStats;
  String? get taskStatsError => _taskStatsError;

  int get totalTasksDone => _taskStats?.totalCompleted ?? 0;
  int get totalClassesDone => _taskStats?.totalClasses ?? 0;
  int get totalAssignmentsDone => _taskStats?.totalAssignments ?? 0;
  int get totalLabReportsDone => _taskStats?.totalLabReports ?? 0;
  int get totalExamsDone => _taskStats?.totalExams ?? 0;
  int get totalOthersDone => _taskStats?.totalOthers ?? 0;
  int get totalPendingTasks => _taskStats?.totalPending ?? 0;
  int get totalOverdueTasks => _taskStats?.totalOverdue ?? 0;
  int get completedTodayCount => _taskStats?.completedToday ?? 0;
  int get currentStreakDays => _taskStats?.currentStreak ?? 0;
  int get longestStreakDays => _taskStats?.longestStreak ?? 0;

  // ==================== HELPER METHODS ====================

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 8) return 'Good Dawn 🌅';
    if (hour >= 8 && hour < 12) return 'Good Morning ☀️';
    if (hour >= 12 && hour < 13) return 'Good Noon 🌞';
    if (hour >= 13 && hour < 17) return 'Good Afternoon 🌤️';
    if (hour >= 17 && hour < 20) return 'Good Evening 🌇';
    if (hour >= 20 && hour < 23) return 'Good Night 🌙';
    return 'Good Late Night 🌃';
  }

  int get todayFocusMinutes {
    final today = DateTime.now();
    return _history
        .where((stat) => _isSameDay(stat.date, today))
        .fold(0, (sum, stat) => sum + stat.totalFocusMinutes);
  }

  int get todayTaskCount {
    final today = DateTime.now();
    return _history
        .where((stat) => _isSameDay(stat.date, today))
        .fold(0, (sum, stat) => sum + stat.totalTaskCount);
  }

  int get weekFocusMinutes {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _history
        .where((stat) => stat.date.isAfter(weekAgo) && stat.date.isBefore(now))
        .fold(0, (sum, stat) => sum + stat.totalFocusMinutes);
  }

  int get weekTaskCount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _history
        .where((stat) => stat.date.isAfter(weekAgo) && stat.date.isBefore(now))
        .fold(0, (sum, stat) => sum + stat.totalTaskCount);
  }

  // ==================== TASK HELPER METHODS ====================

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      final compareDate = DateTime(date.year, date.month, date.day);
      return taskDate.isAtSameMomentAs(compareDate);
    }).toList();
  }

  List<Task> getTasksForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _tasks.where((task) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      return taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          taskDate.isBefore(endOfWeek);
    }).toList();
  }

  List<Task> getTasksForMonth(int year, int month) {
    return _tasks.where((task) {
      return task.date.year == year && task.date.month == month;
    }).toList();
  }

  List<Task> getUpcomingTasks() {
    final now = DateTime.now();
    return _tasks.where((task) {
      if (task.isDone) return false;
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      return taskDate.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();
  }

  List<Task> getOverdueTasks() {
    return _tasks.where((task) => task.isOverdue && !task.isDone).toList();
  }

  List<Task> getCompletedTasks() {
    return _tasks.where((task) => task.isDone).toList();
  }

  List<Task> getTasksByType(TaskType type) {
    return _tasks.where((task) => task.type == type).toList();
  }

  List<Task> getTasksByPriority(Priority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.displayTitle.toLowerCase().contains(lowercaseQuery) ||
          (task.courseCode?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (task.courseTitle?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (task.teacherName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (task.location?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, int> getTaskCountByStatus() {
    final completed = _tasks.where((t) => t.isDone).length;
    final pending = _tasks.where((t) => !t.isDone).length;
    final overdue = _tasks.where((t) => t.isOverdue && !t.isDone).length;
    return {
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
      'total': _tasks.length,
    };
  }

  Map<DateTime, List<Task>> getTasksGroupedByDate() {
    final Map<DateTime, List<Task>> grouped = {};
    for (final task in _tasks) {
      final date = DateTime(task.date.year, task.date.month, task.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(task);
    }
    return grouped;
  }

  bool hasTasksOnDate(DateTime date) {
    return getTasksForDate(date).isNotEmpty;
  }

  /// ✅ Get all tasks in a recurring group
  List<Task> getTasksByRecurringGroup(String recurringGroupId) {
    return _tasks.where((t) => t.recurringGroupId == recurringGroupId).toList();
  }

  /// ✅ Get the parent task of a recurring group
  Task? getRecurringParent(String recurringGroupId) {
    try {
      return _tasks.firstWhere((t) =>
      t.recurringGroupId == recurringGroupId && t.isRecurringParent
      );
    } catch (_) {
      return null;
    }
  }

  /// ✅ Get all recurring class instances for a date
  List<Task> getRecurringInstancesForDate(DateTime date, String recurringGroupId) {
    return _tasks.where((t) =>
    t.recurringGroupId == recurringGroupId &&
        t.date.year == date.year &&
        t.date.month == date.month &&
        t.date.day == date.day
    ).toList();
  }

  // ==================== CONSTRUCTOR ====================

  DataProvider() {
    _loadAllData();
  }

  // ==================== LOAD ALL DATA ====================

  Future<void> _loadAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await Future.wait([
      _loadUserData(),
      _loadTimerStats(),
      _loadSessionHistory(),
      _loadDailyStats(),
      _loadProfile(),
      _loadActivityStats(),
      _loadTasks(),
      _loadTaskStats(),
    ]);
  }

  Future<void> loadAllDataWithProgress({
    Function(int total, int loaded)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final totalTasks = 8;
    int loaded = 0;

    try {
      await _loadUserData();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadTimerStats();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadSessionHistory();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadDailyStats();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadProfile();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadActivityStats();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadTasks();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadTaskStats();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== USER DATA ====================

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _username = null;
      _email = null;
      _userId = null;
      _userPhotoUrl = null;
      _userCreatedAt = null;
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        _username = data['username'] ?? user.displayName ?? 'User';
        _email = data['email'] ?? user.email ?? '';
        _userId = user.uid;
        _userPhotoUrl = data['photoUrl'] ?? user.photoURL;
        _userCreatedAt = data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null;
        _lastActivityDate = data['lastActivityDate'] != null
            ? (data['lastActivityDate'] as Timestamp).toDate()
            : null;
        _streak = data['currentStreak'] ?? 0;
        _longestStreak = data['longestStreak'] ?? 0;
      } else {
        await _createUserDocument(user);
      }
    } catch (_) {
      _username = user.displayName ?? user.email?.split('@').first ?? 'User';
      _email = user.email ?? '';
      _userId = user.uid;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _createUserDocument(User user) async {
    final username = user.displayName ?? user.email?.split('@').first ?? 'User';
    final email = user.email ?? '';

    await _firestore.collection('users').doc(user.uid).set({
      'userId': user.uid,
      'username': username,
      'email': email,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityDate': null,
      'totalFocusMinutes': 0,
      'totalTasksCompleted': 0,
      'currentStreak': 0,
      'longestStreak': 0,
    });

    _username = username;
    _email = email;
    _userId = user.uid;
    _userPhotoUrl = user.photoURL;
    _userCreatedAt = DateTime.now();

    await _activityService.initializeActivityTracking();
  }

  // ==================== TIMER STATS ====================

  Future<void> _loadTimerStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('timerStats')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _grandTotalFocusMinutes = data['grandTotalFocusMinutes'] ?? 0;
        _grandTotalTaskCount = data['grandTotalTaskCount'] ?? 0;
        _streak = data['streak'] ?? 0;
        _appStartTime = data['appStartTime'] != null
            ? (data['appStartTime'] as Timestamp).toDate()
            : null;

        final historyList = data['history'] as List<dynamic>?;
        if (historyList != null) {
          _history = historyList
              .map((h) => DailyStats.fromMap(h as Map<String, dynamic>))
              .toList();
        } else {
          _history = [];
        }
      } else {
        await _initializeTimerStats();
      }
    } catch (_) {
      _grandTotalFocusMinutes = 0;
      _grandTotalTaskCount = 0;
      _streak = 0;
      _history = [];
    }
    notifyListeners();
  }

  Future<void> _initializeTimerStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final statsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('timerStats');

      await statsRef.set({
        'grandTotalFocusMinutes': 0,
        'grandTotalTaskCount': 0,
        'streak': 0,
        'appStartTime': Timestamp.fromDate(now),
        'history': [],
      });

      _grandTotalFocusMinutes = 0;
      _grandTotalTaskCount = 0;
      _streak = 0;
      _appStartTime = now;
      _history = [];
    } catch (_) {
      // Silent fail
    }
    notifyListeners();
  }

  // ==================== SESSION HISTORY ====================

  Future<void> _loadSessionHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoadingSessions = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('startedAt', descending: true)
          .limit(100)
          .get();

      _sessionHistory = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'taskName': data['taskName'] ?? '',
          'duration': data['duration'] ?? 0,
          'startedAt': data['startedAt'] != null
              ? (data['startedAt'] as Timestamp).toDate()
              : DateTime.now(),
          'endedAt': data['endedAt'] != null
              ? (data['endedAt'] as Timestamp).toDate()
              : null,
          'isCompleted': data['isCompleted'] ?? false,
        };
      }).toList();
    } catch (_) {
      // Silent fail
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  // ==================== DAILY STATS ====================

  Future<void> _loadDailyStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoadingDailyStats = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('dailyStats')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _dailyStats = Map<String, Map<String, dynamic>>.from(data);
      } else {
        _dailyStats = {};
      }
    } catch (_) {
      _dailyStats = {};
    } finally {
      _isLoadingDailyStats = false;
      notifyListeners();
    }
  }

  // ==================== PROFILE METHODS ====================

  DocumentReference<Map<String, dynamic>> _getProfileRef() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('Personal_details')
        .doc('profile');
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _profile = ProfileModel.empty();
      notifyListeners();
      return;
    }

    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      final doc = await _getProfileRef().get();

      if (doc.exists && doc.data() != null) {
        _profile = ProfileModel.fromMap(doc.data()!);
      } else {
        _profile = ProfileModel.empty();
        await _createDefaultProfile();
      }
    } catch (e) {
      _profileError = e.toString();
      _profile = ProfileModel.empty();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultProfile() async {
    try {
      await _getProfileRef().set(_profile.toMap());
    } catch (e) {
      _profileError = e.toString();
    }
  }

  Future<bool> updateProfile(ProfileModel updatedProfile) async {
    final user = _auth.currentUser;
    if (user == null) {
      _profileError = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = updatedProfile;
      await _getProfileRef().set(updatedProfile.toMap(), SetOptions(merge: true));
      _isLoadingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      _profileError = e.toString();
      _isLoadingProfile = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileFields({
    String? mobile,
    int? age,
    String? gender,
    String? occupation,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _profileError = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = _profile.copyWith(
        mobile: mobile,
        age: age,
        gender: gender,
        occupation: occupation,
        address: address,
      );

      final Map<String, dynamic> updateData = {};
      if (mobile != null) updateData['mobile'] = mobile;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (occupation != null) updateData['occupation'] = occupation;
      if (address != null) updateData['address'] = address;
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _getProfileRef().update(updateData);

      _isLoadingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      _profileError = e.toString();
      _isLoadingProfile = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  Stream<DocumentSnapshot> getProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _getProfileRef().snapshots();
  }

  // ==================== ACTIVITY METHODS ====================

  Future<void> _loadActivityStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      _activityStats = {};
      notifyListeners();
      return;
    }

    _isLoadingActivity = true;
    _activityError = null;
    notifyListeners();

    try {
      _activityStats = await _activityService.getActivityStats();
    } catch (e) {
      _activityError = e.toString();
      _activityStats = {
        'activeDays': <String>[],
        'totalActiveDays': 0,
        'currentStreak': 0,
        'maxStreak': 0,
      };
    } finally {
      _isLoadingActivity = false;
      notifyListeners();
    }
  }

  Future<void> recordActivity() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _activityService.recordActivity();
      await _loadActivityStats();
    } catch (e) {
      _activityError = e.toString();
    }
  }

  Future<Map<String, dynamic>> getActivityStats() async {
    try {
      return await _activityService.getActivityStats();
    } catch (_) {
      return {
        'activeDays': <String>[],
        'totalActiveDays': 0,
        'currentStreak': 0,
        'maxStreak': 0,
        'lastUpdated': null,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyActivity() async {
    try {
      final result = await _activityService.getMonthlyActivity();
      return result.map((item) {
        return {
          ...item,
          'totalActivities': item['totalActivities'] ?? 0,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> refreshActivityStats() async {
    await _loadActivityStats();
  }

  Future<int> getTodayActivityCount() async {
    try {
      return await _activityService.getTodayActivityCount();
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>?> getDailyActivityDetails(DateTime date) async {
    try {
      return await _activityService.getDailyActivityDetails(date);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getMonthActivitySummary(DateTime date) async {
    try {
      return await _activityService.getMonthActivitySummary(date);
    } catch (_) {
      return {
        'totalDays': 0,
        'totalActivities': 0,
        'days': [],
      };
    }
  }

  Future<void> initializeActivityTracking() async {
    try {
      await _activityService.initializeActivityTracking();
      await _loadActivityStats();
    } catch (_) {
      // Silent fail
    }
  }

  // ==================== TASK STATS METHODS ====================

  DocumentReference<Map<String, dynamic>> _getTaskStatsRef() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('taskStats');
  }

  Future<void> _loadTaskStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      _taskStats = null;
      notifyListeners();
      return;
    }

    _isLoadingTaskStats = true;
    _taskStatsError = null;
    notifyListeners();

    try {
      final doc = await _getTaskStatsRef().get();

      if (doc.exists && doc.data() != null) {
        _taskStats = TaskStats.fromMap(doc.data()!);
      } else {
        _taskStats = TaskStats(lastUpdated: DateTime.now());
        await _saveTaskStats(_taskStats!);
      }
    } catch (e) {
      _taskStatsError = e.toString();
      _taskStats = TaskStats(lastUpdated: DateTime.now());
    } finally {
      _isLoadingTaskStats = false;
      notifyListeners();
    }
  }

  TaskStats _calculateTaskStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int totalClasses = 0;
    int totalAssignments = 0;
    int totalLabReports = 0;
    int totalExams = 0;
    int totalOthers = 0;
    int totalCompleted = 0;
    int totalPending = 0;
    int totalOverdue = 0;
    int completedToday = 0;

    for (final task in _tasks) {
      switch (task.type) {
        case TaskType.classes:
          totalClasses++;
          break;
        case TaskType.assignment:
          totalAssignments++;
          break;
        case TaskType.labReport:
          totalLabReports++;
          break;
        case TaskType.exam:
          totalExams++;
          break;
        case TaskType.others:
          totalOthers++;
          break;
      }

      if (task.isDone) {
        totalCompleted++;
        if (task.completedAt != null) {
          final completedDate = DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          );
          if (completedDate.isAtSameMomentAs(today)) {
            completedToday++;
          }
        }
      } else {
        totalPending++;
        if (task.isOverdue) {
          totalOverdue++;
        }
      }
    }

    return TaskStats(
      totalTasks: _tasks.length,
      totalClasses: totalClasses,
      totalAssignments: totalAssignments,
      totalLabReports: totalLabReports,
      totalExams: totalExams,
      totalOthers: totalOthers,
      totalCompleted: totalCompleted,
      totalPending: totalPending,
      totalOverdue: totalOverdue,
      completedToday: completedToday,
      currentStreak: _taskStats?.currentStreak ?? 0,
      longestStreak: _taskStats?.longestStreak ?? 0,
      lastUpdated: now,
    );
  }

  Future<void> _saveTaskStats(TaskStats stats) async {
    try {
      await _getTaskStatsRef().set(stats.toMap(), SetOptions(merge: true));
      _taskStats = stats;
      notifyListeners();
    } catch (e) {
      _taskStatsError = e.toString();
      debugPrint('❌ DataProvider: Error saving task stats: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStats() async {
    try {
      _isLoadingTaskStats = true;
      notifyListeners();

      final newStats = _calculateTaskStats();
      await _saveTaskStats(newStats);

      _isLoadingTaskStats = false;
      notifyListeners();

      debugPrint('✅ DataProvider: Task stats updated: ${newStats.totalCompleted} completed');
    } catch (e) {
      _isLoadingTaskStats = false;
      _taskStatsError = e.toString();
      notifyListeners();
      debugPrint('❌ DataProvider: Error updating task stats: $e');
      rethrow;
    }
  }

  Stream<TaskStats> watchTaskStats() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.error('User not authenticated');
      }

      return _getTaskStatsRef().snapshots().map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _taskStats = TaskStats.fromMap(snapshot.data()!);
        } else {
          _taskStats = TaskStats(lastUpdated: DateTime.now());
        }
        notifyListeners();
        return _taskStats!;
      }).handleError((error) {
        _taskStatsError = error.toString();
        notifyListeners();
        debugPrint('❌ DataProvider: Task stats stream error: $error');
        return TaskStats(lastUpdated: DateTime.now());
      });
    } catch (e) {
      return Stream.error(e.toString());
    }
  }

  // ==================== TASK DATA FETCHING METHODS ====================

  CollectionReference<Map<String, dynamic>> _getTasksCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
  }

  Future<void> _initNotificationHelper() async {
    try {
      await _notificationHelper.initialize();
    } catch (e) {
      debugPrint('❌ Error initializing notification helper: $e');
    }
  }

  Future<void> _scheduleAllTaskNotifications() async {
    try {
      if (_tasks.isEmpty) return;
      await _initNotificationHelper();
      await _notificationHelper.scheduleAllTaskNotifications(_tasks);
      debugPrint('📬 Scheduled notifications for ${_tasks.length} tasks');
    } catch (e) {
      debugPrint('❌ Error scheduling all task notifications: $e');
    }
  }

  /// ✅ Load all tasks for current user
  Future<void> _loadTasks() async {
    final user = _auth.currentUser;
    if (user == null) {
      _tasks = [];
      notifyListeners();
      return;
    }

    _isLoadingTasks = true;
    _taskError = null;
    notifyListeners();

    try {
      final querySnapshot = await _getTasksCollection()
          .orderBy('date', descending: true)
          .get();

      _tasks = querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data());
      }).toList();

      _isLoadingTasks = false;
      notifyListeners();
      debugPrint('✅ DataProvider: Loaded ${_tasks.length} tasks from Firestore');

      _scheduleAllTaskNotifications();
      await updateTaskStats();

    } catch (e) {
      _isLoadingTasks = false;
      _taskError = 'Failed to load tasks: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ DataProvider: Error loading tasks: $e');
    }
  }

  /// ✅ Watch tasks with real-time updates (Stream)
  Stream<List<Task>> watchTasks() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.error('User not authenticated');
      }

      return _getTasksCollection()
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        _tasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();
        _isLoadingTasks = false;
        notifyListeners();
        debugPrint('🔄 DataProvider: Real-time update - ${_tasks.length} tasks');

        updateTaskStats();

        return _tasks;
      }).handleError((error) {
        _taskError = error.toString();
        notifyListeners();
        debugPrint('❌ DataProvider: Stream error: $error');
      });
    } catch (e) {
      return Stream.error(e.toString());
    }
  }

  /// ✅ Watch tasks with filter applied
  Stream<List<Task>> watchTasksWithFilter(FilterType filter) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.error('User not authenticated');
      }

      return _getTasksCollection()
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        final allTasks = snapshot.docs.map((doc) {
          return Task.fromMap(doc.id, doc.data());
        }).toList();

        _tasks = allTasks;
        _currentTaskFilter = filter;
        notifyListeners();

        updateTaskStats();

        return _applyTaskFilter(allTasks, filter);
      }).handleError((error) {
        _taskError = error.toString();
        notifyListeners();
        debugPrint('❌ DataProvider: Stream with filter error: $error');
      });
    } catch (e) {
      return Stream.error(e.toString());
    }
  }

  List<Task> _applyTaskFilter(List<Task> tasks, FilterType filter) {
    switch (filter) {
      case FilterType.all:
        return tasks;
      case FilterType.exam:
        return tasks.where((t) => t.type == TaskType.exam).toList();
      case FilterType.assignment:
        return tasks.where((t) => t.type == TaskType.assignment).toList();
      case FilterType.labReport:
        return tasks.where((t) => t.type == TaskType.labReport).toList();
      case FilterType.classes:
        return tasks.where((t) => t.type == TaskType.classes).toList();
      case FilterType.highPriority:
        return tasks.where((t) => t.priority == Priority.high).toList();
      case FilterType.mediumPriority:
        return tasks.where((t) => t.priority == Priority.medium).toList();
      case FilterType.lowPriority:
        return tasks.where((t) => t.priority == Priority.low).toList();
    }
  }

  Future<void> refreshTasks() async {
    await _loadTasks();
  }

  Future<void> refreshTaskStats() async {
    await _loadTaskStats();
    await updateTaskStats();
  }

  void setTaskFilter(FilterType filter) {
    _currentTaskFilter = filter;
    notifyListeners();
  }

  void clearTaskError() {
    _taskError = null;
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    try {
      await _initNotificationHelper();
      await _notificationHelper.clearAllNotifications();
      debugPrint('✅ Cleared all notifications');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  // ==================== HELPERS ====================

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ==================== STREAMS ====================

  Stream<DocumentSnapshot> getUserDataStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Stream<DocumentSnapshot> getTimerStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('timerStats')
        .snapshots();
  }

  Stream<QuerySnapshot> getSessionHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getDailyStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('dailyStats')
        .snapshots();
  }

  Stream<DocumentSnapshot> getActivityStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activity')
        .doc('tracking')
        .snapshots();
  }

  Stream<QuerySnapshot> getTasksStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _getTasksCollection()
        .orderBy('date', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getTaskStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _getTaskStatsRef().snapshots();
  }

  // ==================== REFRESH METHODS ====================

  Future<void> refreshAllData() async => await _loadAllData();
  Future<void> refreshUserData() async => await _loadUserData();
  Future<void> refreshTimerStats() async => await _loadTimerStats();
  Future<void> refreshSessionHistory() async => await _loadSessionHistory();
  Future<void> refreshDailyStats() async => await _loadDailyStats();

  // ==================== USER PROFILE ====================

  Future<bool> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await user.updateDisplayName(newUsername);
      _username = newUsername;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== CLEANUP ====================

  void reset() {
    _username = null;
    _email = null;
    _userId = null;
    _userPhotoUrl = null;
    _userCreatedAt = null;
    _grandTotalFocusMinutes = 0;
    _grandTotalTaskCount = 0;
    _streak = 0;
    _longestStreak = 0;
    _history = [];
    _appStartTime = null;
    _lastActivityDate = null;
    _sessionHistory.clear();
    _dailyStats.clear();
    _profile = ProfileModel.empty();
    _activityStats = {};
    _tasks.clear();
    _taskStats = null;
    _isLoading = false;
    _isLoadingSessions = false;
    _isLoadingDailyStats = false;
    _isLoadingProfile = false;
    _isLoadingActivity = false;
    _isLoadingTasks = false;
    _isLoadingTaskStats = false;
    _error = null;
    _profileError = null;
    _activityError = null;
    _taskError = null;
    _taskStatsError = null;
    _currentTaskFilter = FilterType.all;

    _notificationHelper.clearAllNotifications();

    notifyListeners();
  }

  @override
  void dispose() {
    _notificationHelper.clearAllNotifications();
    super.dispose();
  }
}