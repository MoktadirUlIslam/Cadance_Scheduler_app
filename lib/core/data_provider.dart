// lib/core/data_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../models/profile_model.dart';
import '../models/timer_stats_model.dart';
import '../screens/Task_manager/services/task_firestore_service.dart';
import '../services/ActivityTrackerService.dart';

class DataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskManagerStatsService _taskStatsService = TaskManagerStatsService();
  final ActivityTrackerService _activityService = ActivityTrackerService();

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

  // ==================== TASK MANAGER STATS ====================
  Map<String, dynamic> _taskManagerStats = {};
  bool _isLoadingTaskStats = false;

  // ==================== PROFILE DATA ====================
  ProfileModel _profile = ProfileModel.empty();
  bool _isLoadingProfile = false;
  String? _profileError;

  // ==================== ACTIVITY STATS ====================
  Map<String, dynamic> _activityStats = {};
  bool _isLoadingActivity = false;
  String? _activityError;

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

  // ==================== GETTERS - TASK MANAGER STATS ====================
  Map<String, dynamic> get taskManagerStats => _taskManagerStats;
  bool get isLoadingTaskStats => _isLoadingTaskStats;

  // Task Manager Stats - Individual Getters
  int get totalTasksDone => _taskManagerStats['totalTasksDone'] ?? 0;
  int get totalClassesDone => _taskManagerStats['totalClassesDone'] ?? 0;
  int get totalAssignmentsDone => _taskManagerStats['totalAssignmentsDone'] ?? 0;
  int get totalLabReportsDone => _taskManagerStats['totalLabReportsDone'] ?? 0;
  int get totalExamsDone => _taskManagerStats['totalExamsDone'] ?? 0;
  int get totalOthersDone => _taskManagerStats['totalOthersDone'] ?? 0;
  DateTime? get taskStatsLastUpdated => _taskManagerStats['lastUpdated'];

  // ==================== GETTERS - PROFILE ====================
  ProfileModel get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  // Profile getters for convenience
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

  // ==================== HELPER METHODS ====================

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 8) {
      return 'Good Dawn 🌅';
    } else if (hour >= 8 && hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 13) {
      return 'Good Noon 🌞';
    } else if (hour >= 13 && hour < 17) {
      return 'Good Afternoon 🌤️';
    } else if (hour >= 17 && hour < 20) {
      return 'Good Evening 🌇';
    } else if (hour >= 20 && hour < 23) {
      return 'Good Night 🌙';
    } else {
      return 'Good Late Night 🌃';
    }
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
      _loadTaskManagerStats(),
      _loadProfile(),
      _loadActivityStats(),
    ]);
  }

  Future<void> loadAllDataWithProgress({
    Function(int total, int loaded)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final totalTasks = 7;
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

      await _loadTaskManagerStats();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadProfile();
      loaded++;
      if (onProgress != null) onProgress(totalTasks, loaded);

      await _loadActivityStats();
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

  // ==================== TASK MANAGER STATS ====================

  Future<void> _loadTaskManagerStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoadingTaskStats = true;
    notifyListeners();

    try {
      _taskManagerStats = await _taskStatsService.getStats();

      _taskManagerStats['totalTasksDone'] = _taskManagerStats['totalTasksDone'] ?? 0;
      _taskManagerStats['totalClassesDone'] = _taskManagerStats['totalClassesDone'] ?? 0;
      _taskManagerStats['totalAssignmentsDone'] = _taskManagerStats['totalAssignmentsDone'] ?? 0;
      _taskManagerStats['totalLabReportsDone'] = _taskManagerStats['totalLabReportsDone'] ?? 0;
      _taskManagerStats['totalExamsDone'] = _taskManagerStats['totalExamsDone'] ?? 0;
      _taskManagerStats['totalOthersDone'] = _taskManagerStats['totalOthersDone'] ?? 0;
    } catch (_) {
      _taskManagerStats = {
        'totalTasksDone': 0,
        'totalClassesDone': 0,
        'totalAssignmentsDone': 0,
        'totalLabReportsDone': 0,
        'totalExamsDone': 0,
        'totalOthersDone': 0,
      };
    } finally {
      _isLoadingTaskStats = false;
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

  // ==================== TASK MANAGER STATS - PUBLIC METHODS ====================

  Future<void> refreshTaskManagerStats() async {
    await _loadTaskManagerStats();
  }

  Map<String, dynamic> getTaskManagerStatsSummary() {
    return {
      'totalTasksDone': totalTasksDone,
      'totalClassesDone': totalClassesDone,
      'totalAssignmentsDone': totalAssignmentsDone,
      'totalLabReportsDone': totalLabReportsDone,
      'totalExamsDone': totalExamsDone,
      'totalOthersDone': totalOthersDone,
      'lastUpdated': taskStatsLastUpdated,
    };
  }

  Map<String, Map<String, dynamic>> getTaskManagerStatsByType() {
    return {
      'Classes': {
        'total': totalClassesDone,
        'icon': '🏫',
        'color': '#4CAF50',
      },
      'Assignments': {
        'total': totalAssignmentsDone,
        'icon': '📝',
        'color': '#9C27B0',
      },
      'Lab Reports': {
        'total': totalLabReportsDone,
        'icon': '🔬',
        'color': '#2196F3',
      },
      'Exams': {
        'total': totalExamsDone,
        'icon': '📚',
        'color': '#FF9800',
      },
      'Others': {
        'total': totalOthersDone,
        'icon': '📌',
        'color': '#757575',
      },
    };
  }

  double getTaskManagerCompletionRate() {
    final total = totalTasksDone;
    if (total == 0) return 0.0;

    final completed = totalClassesDone + totalAssignmentsDone +
        totalLabReportsDone + totalExamsDone + totalOthersDone;

    if (completed == 0) return 0.0;
    return (completed / total) * 100;
  }

  Future<bool> taskManagerStatsExist() async {
    try {
      return await _taskStatsService.statsExist();
    } catch (_) {
      return false;
    }
  }

  Future<void> initializeTaskManagerStats() async {
    try {
      await _taskStatsService.initializeStats();
      await _loadTaskManagerStats();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> resetTaskManagerStats() async {
    try {
      await _taskStatsService.resetStats();
      await _loadTaskManagerStats();
    } catch (_) {
      // Silent fail
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

  Stream<DocumentSnapshot> getTaskManagerStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('taskManagerStats')
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
    _taskManagerStats = {};
    _profile = ProfileModel.empty();
    _activityStats = {};
    _isLoading = false;
    _isLoadingSessions = false;
    _isLoadingDailyStats = false;
    _isLoadingTaskStats = false;
    _isLoadingProfile = false;
    _isLoadingActivity = false;
    _error = null;
    _profileError = null;
    _activityError = null;
    notifyListeners();
  }
}