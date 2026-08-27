import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // SIGN UP
  // =========================

  Future<UserCredential> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
    }

    return credential;
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