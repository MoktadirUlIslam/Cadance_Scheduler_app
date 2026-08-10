import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileModel _profile = ProfileModel.empty();
  bool _isLoading = false;
  String? _error;

  // Getters
  ProfileModel get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get the profile document reference
  DocumentReference<Map<String, dynamic>> get _profileRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('Personal_details')
        .doc('profile');
  }

  // Load profile from Firebase
  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _profile = ProfileModel.empty();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _profileRef.get();

      if (doc.exists && doc.data() != null) {
        _profile = ProfileModel.fromMap(doc.data()!);
      } else {
        _profile = ProfileModel.empty();
        await _createDefaultProfile();
      }
    } catch (e) {
      _error = e.toString();
      _profile = ProfileModel.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create default profile
  Future<void> _createDefaultProfile() async {
    try {
      await _profileRef.set(_profile.toMap());
    } catch (e) {
      _error = e.toString();
    }
  }

  // Save/Update profile
  Future<bool> saveProfile(ProfileModel updatedProfile) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = updatedProfile;
      await _profileRef.set(updatedProfile.toMap(), SetOptions(merge: true));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update specific fields
  Future<bool> updateProfileFields({
    String? mobile,
    int? age,
    String? gender,
    String? occupation,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
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

      await _profileRef.update(updateData);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset profile to default
  Future<void> resetProfile() async {
    _profile = ProfileModel.empty();
    await _createDefaultProfile();
    notifyListeners();
  }

  // Stream for real-time updates
  Stream<DocumentSnapshot> get profileStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _profileRef.snapshots();
  }

  // Listen to profile changes in real-time
  void listenToProfileChanges() {
    final user = _auth.currentUser;
    if (user == null) return;

    _profileRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _profile = ProfileModel.fromMap(snapshot.data()!);
        notifyListeners();
      }
    }, onError: (_) {
      // Silent error handling
    });
  }

  // Clear/Reset provider state
  void reset() {
    _profile = ProfileModel.empty();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}