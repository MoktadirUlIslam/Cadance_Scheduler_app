// lib/providers/user_auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/data_provider.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

// ✅ Renamed to UserAuthProvider to avoid conflict with firebase_auth
class UserAuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DataProvider? _dataProvider;

  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;
  bool _isCheckingSession = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _auth.currentUser != null;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  UserAuthProvider() {
    _initAuthListener();
  }

  void initialize(DataProvider dataProvider) {
    _dataProvider = dataProvider;
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    if (_isCheckingSession || _dataProvider == null) return;

    _isLoading = true;
    _isCheckingSession = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        try {
          await currentUser.getIdToken(true);
          _user = UserModel.fromFirebaseUser(currentUser);
          print('✅ Auth session restored for: ${_user?.email}');
          await _refreshDataProvider();
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
      notifyListeners();
    }
  }

  void _initAuthListener() {
    _firebaseService.authStateChanges.listen((User? firebaseUser) async {
      if (_isCheckingSession) return;

      try {
        if (firebaseUser != null) {
          try {
            await firebaseUser.getIdToken(true);
            _user = UserModel.fromFirebaseUser(firebaseUser);
            print('✅ Auth state changed: User logged in');
            await _refreshDataProvider();
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
      // Add clear method if needed
      print('✅ DataProvider cleared');
    } catch (e) {
      print('❌ Error clearing data provider: $e');
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userModel = await _firebaseService.signUpWithEmail(
        username: username,
        email: email,
        password: password,
      );
      _user = userModel;
      await _auth.setPersistence(Persistence.LOCAL);
      _isLoading = false;
      await _refreshDataProvider();
      notifyListeners();
      print('✅ User signed up successfully: ${userModel.email}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('❌ Sign up failed: $_error');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userModel = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );
      _user = userModel;
      await _auth.setPersistence(Persistence.LOCAL);
      _isLoading = false;
      await _refreshDataProvider();
      notifyListeners();
      print('✅ User signed in successfully: ${userModel.email}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('❌ Sign in failed: $_error');
      return false;
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

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _user = null;
      await _clearDataProvider();
      notifyListeners();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  Future<bool> checkSessionValidity() async {
    try {
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