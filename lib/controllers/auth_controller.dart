import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';

class AuthController {
  final AuthService _authService = AuthService();

  String? errorMessage;

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      errorMessage = null;

      // ========================================================
      // NAME VALIDATION
      // ========================================================

      if (name.trim().isEmpty) {
        errorMessage = 'Please enter your name.';

        CustomSnackbar.error(
          title: 'Missing Name',
          message: errorMessage!,
        );

        return false;
      }

      // ========================================================
      // EMAIL VALIDATION
      // ========================================================

      final emailRegex = RegExp(
        r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$',
      );

      if (!emailRegex.hasMatch(email)) {
        errorMessage = 'Please enter a valid email address.';

        CustomSnackbar.error(
          title: 'Invalid Email',
          message: errorMessage!,
        );

        return false;
      }

      // ========================================================
      // PASSWORD VALIDATION
      // ========================================================

      if (password.length < 8) {
        errorMessage =
        'Password must be at least 8 characters long.';

        CustomSnackbar.error(
          title: 'Weak Password',
          message: errorMessage!,
        );

        return false;
      }

      // At least one letter
      if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
        errorMessage =
        'Password must contain at least one letter.';

        CustomSnackbar.error(
          title: 'Weak Password',
          message: errorMessage!,
        );

        return false;
      }

      // At least one number
      if (!RegExp(r'[0-9]').hasMatch(password)) {
        errorMessage =
        'Password must contain at least one number.';

        CustomSnackbar.error(
          title: 'Weak Password',
          message: errorMessage!,
        );

        return false;
      }

      // ========================================================
      // CREATE ACCOUNT
      // ========================================================

      await _authService.signup(
        name: name,
        email: email,
        password: password,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      CustomSnackbar.success(
        title: 'Account Created!',
        message: 'Welcome to ClassCue.',
      );

      return true;
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
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

      CustomSnackbar.error(
        title: 'Signup Failed',
        message: errorMessage!,
      );

      return false;
    }

    // ==========================================================
    // FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      print('FIRESTORE ERROR CODE: ${e.code}');
      print('FIRESTORE ERROR MESSAGE: ${e.message}');

      if (e.code == 'permission-denied') {
        errorMessage =
        'Unable to save your account. Please try again.';
      } else if (e.code == 'unavailable') {
        errorMessage =
        'Database is currently unavailable. Please try again.';
      } else {
        errorMessage =
        'Something went wrong with the database.';
      }

      CustomSnackbar.error(
        title: 'Database Error',
        message: errorMessage!,
      );

      return false;
    }

    // ==========================================================
    // UNKNOWN ERROR
    // ==========================================================

    catch (e) {
      print('UNKNOWN SIGNUP ERROR: $e');

      errorMessage =
      'Something went wrong during signup.';

      CustomSnackbar.error(
        title: 'Signup Failed',
        message: errorMessage!,
      );

      return false;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      errorMessage = null;

      // ========================================================
      // EMAIL VALIDATION
      // ========================================================

      final emailRegex = RegExp(
        r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$',
      );

      if (!emailRegex.hasMatch(email)) {
        errorMessage =
        'Please enter a valid email address.';

        CustomSnackbar.error(
          title: 'Invalid Email',
          message: errorMessage!,
        );

        return false;
      }

      // ========================================================
      // PASSWORD VALIDATION
      // ========================================================

      if (password.isEmpty) {
        errorMessage =
        'Please enter your password.';

        CustomSnackbar.error(
          title: 'Missing Password',
          message: errorMessage!,
        );

        return false;
      }

      // ========================================================
      // LOGIN
      // ========================================================

      await _authService.login(
        email: email,
        password: password,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      CustomSnackbar.success(
        title: 'Welcome Back!',
        message: 'You have successfully logged in.',
      );

      return true;
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      print('LOGIN ERROR CODE: ${e.code}');
      print('LOGIN ERROR MESSAGE: ${e.message}');

      switch (e.code) {
        case 'invalid-credential':
          errorMessage =
          'Invalid email or password.';
          break;

        case 'user-not-found':
          errorMessage =
          'No account found with this email.';
          break;

        case 'wrong-password':
          errorMessage =
          'Incorrect password.';
          break;

        case 'invalid-email':
          errorMessage =
          'Invalid email address.';
          break;

        case 'user-disabled':
          errorMessage =
          'This account has been disabled.';
          break;

        case 'too-many-requests':
          errorMessage =
          'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          errorMessage =
          'Network error. Check your internet connection.';
          break;

        default:
          errorMessage =
              e.message ??
                  'Login failed. Please check your credentials.';
      }

      CustomSnackbar.error(
        title: 'Login Failed',
        message: errorMessage!,
      );

      return false;
    }

    // ==========================================================
    // UNKNOWN ERROR
    // ==========================================================

    catch (e) {
      print('UNKNOWN LOGIN ERROR: $e');

      errorMessage =
      'Something went wrong. Please try again.';

      CustomSnackbar.error(
        title: 'Login Failed',
        message: errorMessage!,
      );

      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _authService.logout();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _authService.currentUser;
  }

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<User?> get authStateChanges {
    return _authService.authStateChanges;
  }
}