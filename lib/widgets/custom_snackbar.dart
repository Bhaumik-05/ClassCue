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
      type: _SnackbarType.success,
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
      type: _SnackbarType.error,
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
      type: _SnackbarType.warning,
    );
  }

  // ============================================================
  // COMMON SNACKBAR
  // ============================================================

  static void _showSnackbar({
    required String title,
    required String message,
    required _SnackbarType type,
  }) {
    final messenger = messengerKey.currentState;

    if (messenger == null) {
      return;
    }

    final context = messenger.context;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // ------------------------------------------------------------
    // THEME COLORS
    // ------------------------------------------------------------

    late Color backgroundColor;
    late Color iconBackgroundColor;
    late Color iconColor;
    late Color titleColor;
    late Color messageColor;
    late IconData icon;

    switch (type) {
      case _SnackbarType.success:
        backgroundColor = scheme.primaryContainer;
        iconBackgroundColor = scheme.primary;
        iconColor = scheme.onPrimary;
        titleColor = scheme.onPrimaryContainer;
        messageColor = scheme.onPrimaryContainer;
        icon = Icons.check_rounded;
        break;

      case _SnackbarType.error:
        backgroundColor = scheme.errorContainer;
        iconBackgroundColor = scheme.error;
        iconColor = scheme.onError;
        titleColor = scheme.onErrorContainer;
        messageColor = scheme.onErrorContainer;
        icon = Icons.error_outline_rounded;
        break;

      case _SnackbarType.warning:
        backgroundColor = scheme.tertiaryContainer;
        iconBackgroundColor = scheme.tertiary;
        iconColor = scheme.onTertiary;
        titleColor = scheme.onTertiaryContainer;
        messageColor = scheme.onTertiaryContainer;
        icon = Icons.warning_amber_rounded;
        break;
    }

    // Remove currently visible snackbar
    messenger.hideCurrentSnackBar();

    // ------------------------------------------------------------
    // CUSTOM CONTENT
    // ------------------------------------------------------------

    final content = Container(
      constraints: const BoxConstraints(
        minHeight: 64,
        maxHeight: 90,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconBackgroundColor.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // ICON
          // ------------------------------------------------------

          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          // ------------------------------------------------------
          // TEXT
          // ------------------------------------------------------

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: messageColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ------------------------------------------------------
          // CLOSE BUTTON
          // ------------------------------------------------------

          IconButton(
            onPressed: () {
              messenger.hideCurrentSnackBar();
            },
            icon: Icon(
              Icons.close_rounded,
              color: messageColor,
              size: 19,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
        ],
      ),
    );

    // ------------------------------------------------------------
    // SHOW SNACKBAR
    // ------------------------------------------------------------

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,

        duration: const Duration(seconds: 3),

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

// ============================================================
// SNACKBAR TYPE
// ============================================================

enum _SnackbarType {
  success,
  error,
  warning,
}