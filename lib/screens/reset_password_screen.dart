import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../widgets/custom_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {

  // ============================================================
  // CONTROLLER
  // ============================================================

  final AuthController _authController = AuthController();

  final TextEditingController _emailController =
  TextEditingController();

  bool _isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // ==========================================================
    // EMPTY EMAIL
    // ==========================================================

    if (email.isEmpty) {
      CustomSnackbar.error(
        title: 'Invalid email',
        message: 'Please enter your email address.',
      );

      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _isLoading = true;
    });

    // ==========================================================
    // CALL CONTROLLER
    // ==========================================================

    final success =
    await _authController.resetPassword(
      email: email,
    );

    if (!mounted) return;

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    setState(() {
      _isLoading = false;
    });

    // ==========================================================
    // ERROR
    // ==========================================================

    if (!success) {
      CustomSnackbar.error(
        title: 'Reset failed',
        message:
        _authController.errorMessage ??
            'Unable to send reset email.',
      );

      return;
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    CustomSnackbar.success(
      title: 'Email sent',
      message:
      'Password reset link has been sent to your email.',
    );

    // ==========================================================
    // GO BACK TO SIGN IN
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [

            const SizedBox(height: 24),

            // ==================================================
            // ICON
            // ==================================================

            Center(
              child: Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 40,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              'Forgot your password?',
              textAlign: TextAlign.center,
              style:
              theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              textAlign: TextAlign.center,
              style:
              theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // EMAIL FIELD
            // ==================================================

            TextField(
              controller: _emailController,
              keyboardType:
              TextInputType.emailAddress,
              textInputAction:
              TextInputAction.done,
              enabled: !_isLoading,

              onSubmitted: (_) {
                if (!_isLoading) {
                  _resetPassword();
                }
              },

              decoration:
              const InputDecoration(
                labelText: 'Email',
                hintText:
                'Enter your email address',
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                ),
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SEND RESET LINK BUTTON
            // ==================================================

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                _isLoading
                    ? null
                    : _resetPassword,

                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Send reset link',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // BACK TO SIGN IN
            // ==================================================

            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.pop(context);
              },
              child: const Text(
                'Back to sign in',
              ),
            ),
          ],
        ),
      ),
    );
  }
}