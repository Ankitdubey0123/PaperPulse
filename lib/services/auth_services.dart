import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import for debugPrint

import '../model/auth_model.dart'; // Assuming AppUser is defined here

/// A service class to handle all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Private constructor for a singleton pattern (optional, but good practice for services)
  // Changed to const for better performance since it's a stateless service wrapper
  AuthService();

  /// Stream to listen to the user's authentication state changes.
  /// This is the stream that checks for persisted logins on startup.
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map((User? user) {
      if (user == null) {
        return null;
      } else {
        return AppUser.fromFirebaseUser(user);
      }
    });
  }

  /// Signs in a user with email and password.
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firebase automatically persists the session here.
      return AppUser.fromFirebaseUser(result.user!);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  /// Registers a new user with email and password, and updates their display name.
  Future<AppUser?> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user?.updateDisplayName(name);

      return AppUser.fromFirebaseUser(result.user!);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      // Signing out explicitly removes the persisted session.
      return await _auth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }
}