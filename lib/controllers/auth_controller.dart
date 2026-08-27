import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  String? errorMessage;

  // =========================
  // SIGN UP
  // =========================

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      errorMessage = null;

      // =========================
      // EMAIL VALIDATION
      // =========================

      final emailRegex = RegExp(
        r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$',
      );

      if (!emailRegex.hasMatch(email)) {
        errorMessage = 'Please enter a valid email address.';
        return false;
      }

      // =========================
      // PASSWORD VALIDATION
      // =========================

      // Minimum 8 characters
      if (password.length < 8) {
        errorMessage =
        'Password must be at least 8 characters long.';
        return false;
      }

      // At least one letter
      if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
        errorMessage =
        'Password must contain at least one letter.';
        return false;
      }

      // At least one number
      if (!RegExp(r'[0-9]').hasMatch(password)) {
        errorMessage =
        'Password must contain at least one number.';
        return false;
      }

      // =========================
      // CREATE ACCOUNT
      // =========================

      await _authService.signup(
        name: name,
        email: email,
        password: password,
      );

      return true;

    } on FirebaseAuthException catch (e) {
      print('AUTH ERROR CODE: ${e.code}');
      print('AUTH ERROR MESSAGE: ${e.message}');

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
          'An account already exists with this email.';
          break;

        case 'invalid-email':
          errorMessage =
          'Invalid email address.';
          break;

        case 'weak-password':
          errorMessage =
          'Password is too weak.';
          break;

        case 'operation-not-allowed':
          errorMessage =
          'Email/password authentication is not enabled.';
          break;

        case 'network-request-failed':
          errorMessage =
          'Network error. Check your internet connection.';
          break;

        default:
          errorMessage =
              e.message ?? 'Authentication failed.';
      }

      return false;

    } on FirebaseException catch (e) {
      print('FIRESTORE ERROR CODE: ${e.code}');
      print('FIRESTORE ERROR MESSAGE: ${e.message}');

      errorMessage =
      'Firestore error: ${e.message ?? e.code}';

      return false;

    } catch (e) {
      print('UNKNOWN SIGNUP ERROR: $e');

      errorMessage = e.toString();

      return false;
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      errorMessage = null;

      await _authService.login(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      print('LOGIN ERROR CODE: ${e.code}');
      print('LOGIN ERROR MESSAGE: ${e.message}');

      errorMessage = e.message ?? 'Login failed.';

      return false;
    } catch (e) {
      print('UNKNOWN LOGIN ERROR: $e');

      errorMessage =
      'Something went wrong. Please try again.';

      return false;
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await _authService.logout();
  }

  // =========================
  // CURRENT USER
  // =========================

  User? get currentUser {
    return _authService.currentUser;
  }

  // =========================
  // AUTH STATE
  // =========================

  Stream<User?> get authStateChanges {
    return _authService.authStateChanges;
  }
}