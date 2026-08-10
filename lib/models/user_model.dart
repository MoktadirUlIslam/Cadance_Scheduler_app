// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String username;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user, {String? username}) {
    return UserModel(
      uid: user.uid,
      username: username ?? user.displayName ?? 'User',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
  }
}