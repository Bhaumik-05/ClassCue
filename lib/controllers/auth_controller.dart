import 'package:firebase_auth/firebase_auth.dart';
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

      await _authService.signup(
        name: name,
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;

        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;

        default:
          errorMessage = e.message ?? 'Account creation failed.';
      }

      return false;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
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
      errorMessage = e.message ?? 'Login failed.';
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
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