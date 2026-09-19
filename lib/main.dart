import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_project/firebase_options.dart';

import 'package:flutter_project/screens/splash_screen.dart';

import 'widgets/custom_snackbar.dart';

import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // INITIALIZE FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // REGISTER BACKGROUND FCM HANDLER
  // ============================================================

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // ============================================================
  // INITIALIZE NOTIFICATIONS
  // ============================================================

  final notificationService = NotificationService();
  await notificationService.initialize();

  // ============================================================
  // RUN APP
  // ============================================================

  runApp(const MyApp());
}

// ================================================================
// MY APP
// ================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'ClassCue',

      // ========================================================
      // DARK MODE
      // ========================================================

      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      // ========================================================
      // CUSTOM SNACKBAR GLOBAL KEY
      // ========================================================

      scaffoldMessengerKey: CustomSnackbar.messengerKey,

      // ========================================================
      // AUTH / SPLASH SCREEN
      // ========================================================

      home: const SplashScreen(),
    );
  }
}