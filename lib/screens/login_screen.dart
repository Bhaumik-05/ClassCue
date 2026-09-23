import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import 'signup_screen.dart';
import 'reset_password_screen.dart';
import '../widgets/app_animations.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();

  bool _remember = true;
  bool _obscure = true;
  bool _isLoading = false;

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ============================================================
    // START LOADING
    // ============================================================

    setState(() {
      _isLoading = true;
    });

    // ============================================================
    // LOGIN THROUGH AUTH CONTROLLER
    // ============================================================

    final success = await _authController.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    // ============================================================
    // STOP LOADING
    // ============================================================

    setState(() {
      _isLoading = false;
    });

    // ============================================================
    // LOGIN FAILED
    // ============================================================

    if (!success) {
      return;
    }

    // ============================================================
    // LOGIN SUCCESS
    // ============================================================
    // AuthGate automatically shows HomeScreen.
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    await _authController.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
    // AuthGate automatically shows HomeScreen on success.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 24),

            // ==================================================
            // HEADER
            // ==================================================

            Center(
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 72,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Welcome back',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Sign in to continue to your account',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // EMAIL
            // ==================================================

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PASSWORD
            // ==================================================

            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                ),
              ),
            ),

            // ==================================================
            // REMEMBER + FORGOT PASSWORD
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      onChanged: (value) {
                        setState(() {
                          _remember = value ?? false;
                        });
                      },
                    ),
                    const Text('Remember me'),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      AppRoute.push(const ResetPasswordScreen()),
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ==================================================
            // LOGIN BUTTON
            // ==================================================

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(),
                )
                    : const Text('Sign in'),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // OR DIVIDER
            // ==================================================

            Row(
              children: [
                Expanded(child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'or',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // GOOGLE SIGN IN
            // ==================================================

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continue with Google'),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SIGN UP
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      AppRoute.push(const SignupScreen()),
                    );
                  },
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}