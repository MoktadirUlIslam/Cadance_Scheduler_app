// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/data_provider.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _auth.currentUser != null;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Check if user is already signed in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _user = UserModel.fromFirebaseUser(currentUser);
      _isInitialized = true;
      notifyListeners();
      // Refresh data provider after auth initialization
      _refreshDataProvider();
    }

    // Listen for auth state changes
    _firebaseService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = UserModel.fromFirebaseUser(firebaseUser);
        // Refresh data provider when user logs in
        await _refreshDataProvider();
      } else {
        _user = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  // Helper method to refresh data provider
  Future<void> _refreshDataProvider() async {
    try {
      final dataProvider = DataProvider();
      await dataProvider.refreshUserData();
    } catch (e) {
      print('Error refreshing data provider: $e');
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
      _isLoading = false;

      // Refresh data provider after signup
      await _refreshDataProvider();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
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
      _isLoading = false;

      // Refresh data provider after signin
      await _refreshDataProvider();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
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
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _user = null;
    notifyListeners();

    // Clear data provider cache on signout
    try {
      final dataProvider = DataProvider();
      // You might want to add a clearCache method in DataProvider
    } catch (e) {
      print('Error clearing data provider: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}