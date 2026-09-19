import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_animations.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Routes the user based on authentication status (FR1.2).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final Widget page;

        if (snapshot.connectionState == ConnectionState.waiting) {
          page = const Scaffold(
            key: ValueKey('loading'),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          page = const HomeScreen(key: ValueKey('home'));
        } else {
          page = const LoginScreen(key: ValueKey('login'));
        }

        // Smooth fade between loading / login / home (login & logout).
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          layoutBuilder: AppAnim.topLayout,
          child: page,
        );
      },
    );
  }
}