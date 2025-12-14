import 'package:firebase_auth/firebase_auth.dart';

/// Represents the application user model, simplified for internal use.
class AppUser {
  final String uid;
  final String email;
  final String? displayName;

  AppUser({required this.uid, required this.email, this.displayName});

  /// Factory constructor to create AppUser from the Firebase User object.
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? 'No Email',
      displayName: user.displayName,
    );
  }
}