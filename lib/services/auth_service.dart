import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // =========================
  // GOOGLE SIGN IN
  // =========================

  Future<UserCredential> signInWithGoogle() async {
    // 1. Trigger Google account picker
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google sign-in cancelled.');
    }

    // 2. Get auth tokens
    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Sign in to Firebase
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Firebase user was not created.');
    }

    // 4. Get FCM token
    final fcmToken = await _messaging.getToken();

    // 5. Create user doc only if new
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        fcmToken: fcmToken,
        createdAt: now,
        updatedAt: now,
      );
      await docRef.set(userModel.toMap());
    } else {
      await docRef.update({
        'fcm_token': fcmToken,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

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
      await user.reload();

      final updatedUser = _auth.currentUser;

      if (updatedUser == null) {
        throw Exception('Unable to retrieve created user.');
      }

      // =========================
      // 3. GET FCM TOKEN
      // =========================

      final fcmToken = await _messaging.getToken();

      print('FCM Token for new user: $fcmToken');

      // =========================
      // 4. CREATE USER MODEL
      // =========================

      final now = DateTime.now();

      final userModel = UserModel(
        uid: updatedUser.uid,
        name: name,
        email: updatedUser.email ?? email,
        fcmToken: fcmToken,
        createdAt: now,
        updatedAt: now,
      );

      // =========================
      // 5. SAVE USER TO FIRESTORE
      // =========================

      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .set(userModel.toMap());

      // =========================
      // 6. RETURN SUCCESS
      // =========================

      return credential;
    }

    // =========================
    // FIREBASE AUTH ERRORS
    // =========================

    on FirebaseAuthException {
      rethrow;
    }

    // =========================
    // FIRESTORE ERRORS
    // =========================

    on FirebaseException {
      rethrow;
    }

    // =========================
    // OTHER ERRORS
    // =========================

    catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update FCM token after login.
    await _updateFCMToken();

    return credential;
  }

  // =========================
  // UPDATE FCM TOKEN
  // =========================

  Future<void> _updateFCMToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      // Get the FCM token of the current device.
      final fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        print('FCM Token is null.');
        return;
      }

      print('Updating FCM Token in Firestore...');

      // Save the token to the logged-in user's document.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'fcm_token': fcmToken,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('FCM Token saved successfully.');
    } catch (e) {
      print('Failed to save FCM Token: $e');
    }
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

  // =========================
  // RESET PASSWORD
  // =========================

  Future<void> resetPassword({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }
}