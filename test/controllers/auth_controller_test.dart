import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/controllers/auth_controller.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthService service;
  late AuthController controller;

  setUp(() {
    service = FakeAuthService();
    controller = AuthController(authService: service);
  });

  Future<bool> signup({
    String name = 'Asha',
    String email = 'asha@example.com',
    String password = 'abc12345',
  }) =>
      controller.signup(name: name, email: email, password: password);

  group('signup validation (FR2.1)', () {
    test('valid details reach the service', () async {
      expect(await signup(), isTrue);
      expect(service.signupCalls, 1);
      expect(service.lastEmail, 'asha@example.com');
    });

    test('empty name', () async {
      expect(await signup(name: '  '), isFalse);
      expect(controller.errorMessage, 'Please enter your name.');
      expect(service.signupCalls, 0);
    });

    test('invalid emails', () async {
      for (final e in ['', 'abc', 'a@b', 'a@b.', '@b.com', 'a b@c.com']) {
        expect(await signup(email: e), isFalse, reason: e);
        expect(controller.errorMessage, 'Please enter a valid email address.');
      }
      expect(service.signupCalls, 0);
    });

    test('password too short', () async {
      expect(await signup(password: 'ab1'), isFalse);
      expect(controller.errorMessage,
          'Password must be at least 8 characters long.');
    });

    test('password without a letter', () async {
      expect(await signup(password: '12345678'), isFalse);
      expect(controller.errorMessage,
          'Password must contain at least one letter.');
    });

    test('password without a number', () async {
      expect(await signup(password: 'abcdefgh'), isFalse);
      expect(controller.errorMessage,
          'Password must contain at least one number.');
    });
  });

  group('signup error mapping', () {
    test('email already in use', () async {
      service.error = FirebaseAuthException(code: 'email-already-in-use');
      expect(await signup(), isFalse);
      expect(controller.errorMessage,
          'An account already exists with this email.');
    });

    test('network error', () async {
      service.error = FirebaseAuthException(code: 'network-request-failed');
      expect(await signup(), isFalse);
      expect(controller.errorMessage,
          'Network error. Check your internet connection.');
    });

    test('firestore permission denied', () async {
      service.error =
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      expect(await signup(), isFalse);
      expect(controller.errorMessage,
          'Unable to save your account. Please try again.');
    });

    test('unknown error', () async {
      service.error = Exception('???');
      expect(await signup(), isFalse);
      expect(controller.errorMessage, 'Something went wrong during signup.');
    });
  });

  group('login (FR2.2)', () {
    test('success', () async {
      expect(
          await controller.login(email: 'a@b.com', password: 'x'), isTrue);
      expect(service.loginCalls, 1);
    });

    test('invalid email is rejected before calling the service', () async {
      expect(await controller.login(email: 'nope', password: 'x'), isFalse);
      expect(controller.errorMessage, 'Please enter a valid email address.');
      expect(service.loginCalls, 0);
    });

    test('empty password', () async {
      expect(await controller.login(email: 'a@b.com', password: ''), isFalse);
      expect(controller.errorMessage, 'Please enter your password.');
      expect(service.loginCalls, 0);
    });

    final cases = {
      'invalid-credential': 'Invalid email or password.',
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect password.',
      'user-disabled': 'This account has been disabled.',
      'too-many-requests': 'Too many login attempts. Please try again later.',
      'network-request-failed':
      'Network error. Check your internet connection.',
    };

    cases.forEach((code, message) {
      test('maps $code', () async {
        service.error = FirebaseAuthException(code: code);
        expect(
            await controller.login(email: 'a@b.com', password: 'x'), isFalse);
        expect(controller.errorMessage, message);
      });
    });

    test('unknown auth code falls back', () async {
      service.error = FirebaseAuthException(code: 'weird');
      await controller.login(email: 'a@b.com', password: 'x');
      expect(controller.errorMessage,
          'Login failed. Please check your credentials.');
    });

    test('non-auth exception', () async {
      service.error = Exception('boom');
      expect(
          await controller.login(email: 'a@b.com', password: 'x'), isFalse);
      expect(controller.errorMessage, 'Something went wrong. Please try again.');
    });
  });

  group('resetPassword', () {
    test('invalid email', () async {
      expect(await controller.resetPassword(email: 'bad'), isFalse);
      expect(controller.errorMessage, 'Please enter a valid email address.');
      expect(service.resetCalls, 0);
    });

    test('success', () async {
      expect(await controller.resetPassword(email: 'a@b.com'), isTrue);
      expect(service.resetCalls, 1);
    });

    test('user not found', () async {
      service.error = FirebaseAuthException(code: 'user-not-found');
      expect(await controller.resetPassword(email: 'a@b.com'), isFalse);
      expect(controller.errorMessage, 'No account found with this email.');
    });
  });
}