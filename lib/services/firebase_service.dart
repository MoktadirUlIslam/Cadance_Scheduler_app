// lib/services/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../models/timer_stats_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ────────────────────────────────────────────────
  // AUTH PROPERTIES
  // ────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges {
    // Ensure we're listening to auth state changes properly
    return _auth.authStateChanges();
  }

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

      // Update display name
      await user.updateDisplayName(username);

      // Send email verification (optional, but good practice)
      await user.sendEmailVerification();

      // Store user data in Firestore
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

      // On mobile, Firebase Auth automatically persists the session
      // On web, we need to explicitly set persistence
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }

      // Force token refresh to ensure valid session
      await result.user!.getIdToken(true);

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
    } catch (e) {
      // If signOut fails, try force sign out
      try {
        await _auth.signOut();
      } catch (_) {
        // Silently handle - user is already signed out
      }
    }
  }

  // ────────────────────────────────────────────────
  // SESSION MANAGEMENT
  // ────────────────────────────────────────────────

  /// Check if the current session is valid
  Future<bool> isSessionValid() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Force token refresh to check validity
      await user.getIdToken(true);
      return true;
    } catch (e) {
      print('❌ Session validation failed: $e');
      return false;
    }
  }

  /// Get the current user's ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      print('❌ Error getting ID token: $e');
      return null;
    }
  }

  /// Get current user with fresh data
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Force token refresh
      await user.getIdToken(true);
      return UserModel.fromFirebaseUser(user);
    } catch (e) {
      print('❌ Error getting current user model: $e');
      return null;
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
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update user's last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Error updating last login: $e');
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // ────────────────────────────────────────────────
  // ✅ NEW: GET USER BY EMAIL
  // ────────────────────────────────────────────────

  /// Check if a user exists with the given email
  Future<DocumentSnapshot?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user by email: $e');
      return null;
    }
  }

  /// Check if email exists in Firestore
  Future<bool> emailExists(String email) async {
    try {
      final userDoc = await getUserByEmail(email);
      return userDoc != null;
    } catch (e) {
      print('❌ Error checking email existence: $e');
      return false;
    }
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
          'lastUpdated': FieldValue.serverTimestamp(),
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
        'lastUpdated': FieldValue.serverTimestamp(),
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
      final Map<String, dynamic> updates = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

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

      await _timerStatsRef.update(updates);
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
      case 'requires-recent-login':
        return 'For security reasons, please sign in again to continue.';
      case 'user-token-expired':
        return 'Your session has expired. Please sign in again.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }


  /// Check if Firebase services are working
  Future<bool> checkFirebaseHealth() async {
    try {
      // Try to access Firestore
      await _firestore.collection('users').limit(1).get();
      return true;
    } catch (e) {
      print('❌ Firebase health check failed: $e');
      return false;
    }
  }
}