import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../widgets/app_animations.dart';
import 'assignments_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isOpeningNotification = false;

  @override
  void initState() {
    super.initState();

    // Listen for notification taps while the app is running.
    NotificationService.pendingNotification.addListener(
      _handleNotification,
    );
  }

  @override
  void dispose() {
    NotificationService.pendingNotification.removeListener(
      _handleNotification,
    );

    super.dispose();
  }

  // ============================================================
  // HANDLE NOTIFICATION NAVIGATION
  // ============================================================

  void _handleNotification() {
    final notification =
        NotificationService.pendingNotification.value;

    // No pending notification.
    if (notification == null) {
      return;
    }

    // Prevent duplicate navigation.
    if (_isOpeningNotification) {
      return;
    }

    final type = notification['type'];

    print('========== AUTH GATE NOTIFICATION ==========');
    print('Notification data: $notification');
    print('Notification type: $type');
    print('============================================');

    // Currently we only navigate assignment notifications.
    if (type != 'assignment') {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      // User must be logged in before opening assignments.
      if (user == null) {
        print(
          'User is not logged in. '
              'Keeping notification pending.',
        );
        return;
      }

      if (_isOpeningNotification) {
        return;
      }

      _isOpeningNotification = true;

      print('➡️ Opening AssignmentsScreen from notification');

      Navigator.of(context)
          .push(
        AppRoute.push(
          const AssignmentsScreen(),
        ),
      )
          .then((_) {
        if (!mounted) {
          return;
        }

        _isOpeningNotification = false;
      });

      // Notification has now been consumed.
      NotificationService.pendingNotification.value = null;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final Widget page;

        // --------------------------------------------------------
        // Firebase authentication is loading
        // --------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          page = const Scaffold(
            key: ValueKey('loading'),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --------------------------------------------------------
        // User is logged in
        // --------------------------------------------------------

        else if (snapshot.hasData) {
          page = const HomeScreen(
            key: ValueKey('home'),
          );

          // This is important for terminated-app notifications.
          //
          // checkInitialMessage() runs BEFORE runApp().
          // Therefore AuthGate may receive the pending notification
          // after the notification service has already stored it.
          //
          // We check it after the HomeScreen is ready.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNotification();
          });
        }

        // --------------------------------------------------------
        // User is logged out
        // --------------------------------------------------------

        else {
          page = const LoginScreen(
            key: ValueKey('login'),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          layoutBuilder: AppAnim.topLayout,
          child: page,
        );
      },
    );
  }
}