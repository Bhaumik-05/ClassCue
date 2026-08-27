import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // SIGN UP
  // =========================

  Future<UserCredential> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // =========================
      // 1. CREATE FIREBASE AUTH USER
      // =========================

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Firebase user was not created.');
      }

      // =========================
      // 2. SAVE NAME IN FIREBASE AUTH
      // =========================

      await user.updateDisplayName(name);

      // Make sure updated user data is available
      await user.reload();

      // Get the refreshed user
      final updatedUser = _auth.currentUser;

      if (updatedUser == null) {
        throw Exception('Unable to retrieve created user.');
      }

      // =========================
      // 3. CREATE USER MODEL
      // =========================

      final now = DateTime.now();

      final userModel = UserModel(
        uid: updatedUser.uid,
        name: name,
        email: updatedUser.email ?? email,
        createdAt: now,
        updatedAt: now,
      );

      // =========================
      // 4. SAVE USER TO FIRESTORE
      // =========================

      await _firestore
          .collection('users')
          .doc(updatedUser.uid) // Firebase automatically generated UID
          .set(userModel.toMap());

      // =========================
      // 5. RETURN SUCCESS
      // =========================

      return credential;
    }

    // =========================
    // FIREBASE AUTH ERRORS
    // =========================

    on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'An account already exists with this email.',
          );

        case 'invalid-email':
          throw Exception(
            'The email address is invalid.',
          );

        case 'weak-password':
          throw Exception(
            'The password is too weak.',
          );

        case 'operation-not-allowed':
          throw Exception(
            'Email/password authentication is not enabled.',
          );

        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection.',
          );

        default:
          throw Exception(
            e.message ?? 'Authentication failed.',
          );
      }
    }

    // =========================
    // FIRESTORE ERRORS
    // =========================

    on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Firestore permission denied. Check your Firestore security rules.',
        );
      }

      if (e.code == 'unavailable') {
        throw Exception(
          'Firestore is currently unavailable. Please try again.',
        );
      }

      throw Exception(
        'Firestore error: ${e.message ?? e.code}',
      );
    }

    // =========================
    // OTHER ERRORS
    // =========================

    catch (e) {
      throw Exception(
        'Signup failed: $e',
      );
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // =========================
  // CURRENT USER
  // =========================

  User? get currentUser {
    return _auth.currentUser;
  }

  // =========================
  // AUTH STATE
  // =========================

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}