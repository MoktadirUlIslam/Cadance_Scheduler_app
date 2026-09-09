// lib/providers/user_auth_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/data_provider.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserAuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DataProvider? _dataProvider;

  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;
  bool _isCheckingSession = false;
  bool _authChecked = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _auth.currentUser != null;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get authChecked => _authChecked;

  UserAuthProvider() {
    // ✅ Set persistence for web only on initialization
    _setPersistenceIfWeb();
    _initAuthListener();
    _checkCurrentUser();
  }

  // ────────────────────────────────────────────────
  // ✅ FIX: setPersistence() throws UnimplementedError
  // on Android/iOS — it's web-only. Guard with kIsWeb.
  // Mobile persists sessions locally by default, so
  // there's nothing to set there.
  // ────────────────────────────────────────────────
  Future<void> _setPersistenceIfWeb() async {
    if (!kIsWeb) return;
    try {
      await _auth.setPersistence(Persistence.LOCAL);
      print('✅ Auth persistence set to LOCAL for web');
    } catch (e) {
      print('⚠️ Error setting persistence: $e');
    }
  }

  void initialize(DataProvider dataProvider) {
    _dataProvider = dataProvider;
    if (_user != null && _dataProvider != null) {
      _refreshDataProvider();
    }
    notifyListeners();
  }

  // ────────────────────────────────────────────────
  // Check current user (session restore on app start)
  // ────────────────────────────────────────────────
  Future<void> _checkCurrentUser() async {
    if (_isCheckingSession) return;

    _isLoading = true;
    _isCheckingSession = true;
    _authChecked = false;
    notifyListeners();

    try {
      // ✅ Only relevant on web
      await _setPersistenceIfWeb();

      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        try {
          // Force token refresh to check validity
          await currentUser.getIdToken(true);
          _user = UserModel.fromFirebaseUser(currentUser);
          print('✅ Auth session restored for: ${_user?.email}');

          if (_dataProvider != null) {
            await _refreshDataProvider();
          } else {
            print('⚠️ DataProvider not yet initialized, will refresh later');
          }
        } catch (e) {
          print('❌ Invalid token: $e');
          await _firebaseService.signOut();
          _user = null;
        }
      } else {
        print('ℹ️ No existing auth session found');
        _user = null;
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      _user = null;
    } finally {
      _isLoading = false;
      _isCheckingSession = false;
      _isInitialized = true;
      _authChecked = true;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────────
  // Auth state listener
  // ────────────────────────────────────────────────
  void _initAuthListener() {
    _firebaseService.authStateChanges.listen((User? firebaseUser) async {
      if (_isCheckingSession) return;

      try {
        if (firebaseUser != null) {
          try {
            // ✅ Only relevant on web
            await _setPersistenceIfWeb();
            await firebaseUser.getIdToken(true);
            _user = UserModel.fromFirebaseUser(firebaseUser);
            print('✅ Auth state changed: User logged in (${_user?.email})');

            if (_dataProvider != null) {
              await _refreshDataProvider();
            } else {
              print('⚠️ DataProvider not yet initialized, will refresh later');
            }
          } catch (e) {
            print('❌ Invalid user in auth state change: $e');
            await _firebaseService.signOut();
            _user = null;
          }
        } else {
          _user = null;
          print('ℹ️ Auth state changed: User logged out');
          await _clearDataProvider();
        }
      } catch (e) {
        print('❌ Error in auth state listener: $e');
        _user = null;
      } finally {
        _isInitialized = true;
        _isLoading = false;
        _authChecked = true;
        notifyListeners();
      }
    });
  }

  Future<void> _refreshDataProvider() async {
    if (_dataProvider == null) {
      print('⚠️ DataProvider not initialized, cannot refresh');
      return;
    }

    try {
      await _dataProvider!.refreshUserData();
      print('✅ DataProvider refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing data provider: $e');
    }
  }

  Future<void> _clearDataProvider() async {
    if (_dataProvider == null) return;
    try {
      print('✅ DataProvider cleared');
    } catch (e) {
      print('❌ Error clearing data provider: $e');
    }
  }

  // ────────────────────────────────────────────────
  // EMAIL CHECK METHODS
  // ────────────────────────────────────────────────

  Future<bool> checkEmailExists(String email) async {
    try {
      final userDoc = await _firebaseService.getUserByEmail(email);
      return userDoc != null;
    } catch (e) {
      print('❌ Error checking email existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithCheck(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final emailExists = await checkEmailExists(email);

      if (!emailExists) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'error': 'Email not found. Please check your email address.',
        };
      }

      await _firebaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      print('✅ Password reset email sent to: $email');
      return {
        'success': true,
        'message': 'Password reset link sent to your email.',
      };

    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('❌ Password reset failed: $_error');
      return {
        'success': false,
        'error': _error,
      };
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      print('✅ Password reset email sent to: $email');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('❌ Password reset failed: $_error');
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // Sign Up
  // ────────────────────────────────────────────────
  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ Only relevant on web
      await _setPersistenceIfWeb();

      final userModel = await _firebaseService.signUpWithEmail(
        username: username,
        email: email,
        password: password,
      );
      _user = userModel;

      _isLoading = false;
      if (_dataProvider != null) {
        await _refreshDataProvider();
      }
      _authChecked = true;
      notifyListeners();
      print('✅ User signed up successfully: ${userModel.email}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      _authChecked = true;
      notifyListeners();
      print('❌ Sign up failed: $_error');
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // Sign In
  // ────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ Only relevant on web
      await _setPersistenceIfWeb();

      final userModel = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );
      _user = userModel;

      _isLoading = false;
      if (_dataProvider != null) {
        await _refreshDataProvider();
      }
      _authChecked = true;
      notifyListeners();
      print('✅ User signed in successfully: ${userModel.email}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      _authChecked = true;
      notifyListeners();
      print('❌ Sign in failed: $_error');
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // SIGN OUT
  // ────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _user = null;
      _authChecked = true;
      await _clearDataProvider();
      notifyListeners();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────
  // SESSION VALIDATION
  // ────────────────────────────────────────────────
  Future<bool> checkSessionValidity() async {
    try {
      // ✅ Only relevant on web
      await _setPersistenceIfWeb();

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.getIdToken(true);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Session validation failed: $e');
      return false;
    }
  }

  Future<void> refreshUserData() async {
    await _refreshDataProvider();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.getIdToken(true);
        return UserModel.fromFirebaseUser(firebaseUser);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}