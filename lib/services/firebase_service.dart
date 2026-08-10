// lib/services/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/timer_stats_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ────────────────────────────────────────────────
  // AUTH PROPERTIES
  // ────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ────────────────────────────────────────────────
  // AUTH METHODS
  // ────────────────────────────────────────────────

  Future<UserModel> signUpWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user!;
      await user.updateDisplayName(username);
      await user.sendEmailVerification();

      await _storeUserData(
        userId: user.uid,
        username: username.trim(),
        email: email.trim(),
      );

      return UserModel.fromFirebaseUser(user, username: username);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return UserModel.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }

  // ────────────────────────────────────────────────
  // USER DATA METHODS
  // ────────────────────────────────────────────────

  Future<void> _storeUserData({
    required String userId,
    required String username,
    required String email,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ────────────────────────────────────────────────
  // TIMER STATS - DATA OPERATIONS
  // ────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _timerStatsRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('timerStats');
  }

  Future<void> initializeTimerStats() async {
    try {
      final statsRef = _timerStatsRef;
      final doc = await statsRef.get();

      if (!doc.exists) {
        final now = DateTime.now();
        await statsRef.set({
          'grandTotalFocusMinutes': 0,
          'grandTotalTaskCount': 0,
          'streak': 0,
          'appStartTime': Timestamp.fromDate(now),
          'history': [],
        });
      }
    } catch (e) {
      throw Exception('Failed to initialize timer stats: $e');
    }
  }

  Future<TimerStatsModel> getTimerStats() async {
    try {
      final doc = await _timerStatsRef.get();
      if (doc.exists && doc.data() != null) {
        return TimerStatsModel.fromMap(doc.data()!);
      }
      return TimerStatsModel();
    } catch (e) {
      throw Exception('Failed to get timer stats: $e');
    }
  }

  Future<void> saveTimerStats(TimerStatsModel stats) async {
    try {
      await _timerStatsRef.set({
        'grandTotalFocusMinutes': stats.grandTotalFocusMinutes,
        'grandTotalTaskCount': stats.grandTotalTaskCount,
        'streak': stats.streak,
        'appStartTime': stats.appStartTime != null
            ? Timestamp.fromDate(stats.appStartTime!)
            : Timestamp.fromDate(DateTime.now()),
        'history': stats.history.map((h) => h.toMap()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save timer stats: $e');
    }
  }

  Future<void> updateTimerStats({
    int? grandTotalFocusMinutes,
    int? grandTotalTaskCount,
    int? streak,
    DateTime? appStartTime,
    List<DailyStats>? history,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (grandTotalFocusMinutes != null) {
        updates['grandTotalFocusMinutes'] = grandTotalFocusMinutes;
      }
      if (grandTotalTaskCount != null) {
        updates['grandTotalTaskCount'] = grandTotalTaskCount;
      }
      if (streak != null) {
        updates['streak'] = streak;
      }
      if (appStartTime != null) {
        updates['appStartTime'] = Timestamp.fromDate(appStartTime);
      }
      if (history != null) {
        updates['history'] = history.map((h) => h.toMap()).toList();
      }

      if (updates.isNotEmpty) {
        await _timerStatsRef.update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update timer stats: $e');
    }
  }

  Future<void> deleteTimerStats() async {
    try {
      await _timerStatsRef.delete();
    } catch (e) {
      throw Exception('Failed to delete timer stats: $e');
    }
  }

  Future<bool> timerStatsExist() async {
    try {
      final doc = await _timerStatsRef.get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // AUTH ERROR HANDLER
  // ────────────────────────────────────────────────

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email. Please use a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}