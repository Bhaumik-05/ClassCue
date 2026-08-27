import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class CustomSnackbar {
  // ============================================================
  // GLOBAL SCAFFOLD MESSENGER KEY
  // ============================================================

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
  GlobalKey<ScaffoldMessengerState>();

  // ============================================================
  // SUCCESS
  // ============================================================

  static void success({
    required String title,
    required String message,
  }) {
    _showSnackbar(
      title: title,
      message: message,
      contentType: ContentType.success,
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  static void error({
    required String title,
    required String message,
  }) {
    _showSnackbar(
      title: title,
      message: message,
      contentType: ContentType.failure,
    );
  }

  // ============================================================
  // WARNING
  // ============================================================

  static void warning({
    required String title,
    required String message,
  }) {
    _showSnackbar(
      title: title,
      message: message,
      contentType: ContentType.warning,
    );
  }

  // ============================================================
  // COMMON SNACKBAR
  // ============================================================

  static void _showSnackbar({
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    final messenger = messengerKey.currentState;

    if (messenger == null) {
      return;
    }

    // Remove currently visible snackbar
    messenger.hideCurrentSnackBar();

    // Create Awesome Snackbar Content
    final content = AwesomeSnackbarContent(
      title: title,
      message: message,
      contentType: contentType,
      inMaterialBanner: false,
    );

    // Show Snackbar
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,

        backgroundColor: Colors.transparent,

        padding: EdgeInsets.zero,

        duration: const Duration(seconds: 4),

        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          20,
        ),

        content: content,
      ),
    );
  }
}