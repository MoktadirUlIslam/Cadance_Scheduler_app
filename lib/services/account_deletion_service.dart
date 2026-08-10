// lib/screens/Profile/services/account_deletion_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete all user data from Firestore
  Future<void> deleteAllUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user stats subcollection
      final statsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .get();

      for (var doc in statsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete sessions subcollection
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();

      for (var doc in sessionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete personal details subcollection
      final detailsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('Personal_details')
          .get();

      for (var doc in detailsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ All user data deleted successfully');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Delete user authentication account
  Future<void> deleteAuthAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await user.delete();
      print('✅ Auth account deleted successfully');
    } catch (e) {
      print('❌ Error deleting auth account: $e');
      throw Exception('Failed to delete auth account: $e');
    }
  }

  /// Delete all data and auth account
  Future<void> deleteAccount() async {
    try {
      // First delete all user data
      await deleteAllUserData();

      // Then delete auth account
      await deleteAuthAccount();

      // Sign out
      await _auth.signOut();

      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Error deleting account: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
}