// lib/models/profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String? mobile;
  final int? age;
  final String? gender;
  final String? occupation;
  final String? address;
  final DateTime? updatedAt;

  // Main constructor
  const ProfileModel({
    this.mobile,
    this.age,
    this.gender,
    this.occupation,
    this.address,
    this.updatedAt,
  });

  // Factory constructor to create from Firestore data
  factory ProfileModel.fromMap(Map<String, dynamic> data) {
    return ProfileModel(
      mobile: data['mobile'] as String?,
      age: data['age'] as int?,
      gender: data['gender'] as String?,
      occupation: data['occupation'] as String?,
      address: data['address'] as String?,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mobile': mobile ?? 'Not set',
      'age': age,
      'gender': gender ?? 'Not set',
      'occupation': occupation ?? 'Not set',
      'address': address ?? 'Not set',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method
  ProfileModel copyWith({
    String? mobile,
    int? age,
    String? gender,
    String? occupation,
    String? address,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      mobile: mobile ?? this.mobile,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Empty factory method
  static ProfileModel empty() {
    return const ProfileModel(
      mobile: 'Not set',
      age: null,
      gender: 'Not set',
      occupation: 'Not set',
      address: 'Not set',
    );
  }
}