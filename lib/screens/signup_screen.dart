import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController _authController = AuthController();

  String _password = '';
  bool _agreed = false;
  bool _isLoading = false;

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  // ============================================================
  // PASSWORD STRENGTH
  // ============================================================

  int get _strength {
    var score = 0;

    if (_password.length >= 8) score++;

    if (RegExp(r'[A-Z]').hasMatch(_password)) score++;

    if (RegExp(r'[0-9]').hasMatch(_password)) score++;

    if (RegExp(r'[!@#$%^&*]').hasMatch(_password)) score++;

    return score;
  }

  static const _labels = [
    'Too weak',
    'Weak',
    'Fair',
    'Good',
    'Strong',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    final success = await _authController.signup(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      // AuthController already showed CustomSnackbar.
      return;
    }

    // AuthGate will automatically show HomeScreen.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final colors = [
      scheme.error,
      scheme.error,
      Colors.orange,
      Colors.amber,
      Colors.green,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),

        children: [
          // ====================================================
          // TITLE
          // ====================================================

          Text(
            'Get started free',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // NAME
          // ====================================================

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // EMAIL
          // ====================================================

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

          // ====================================================
          // PASSWORD
          // ====================================================

          TextField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (value) {
              setState(() {
                _password = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // PASSWORD STRENGTH
          // ====================================================

          Row(
            children: List.generate(
              4,
                  (index) {
                final active = index < _strength;

                return Expanded(
                  child: Container(
                    height: 6,

                    margin: EdgeInsets.only(
                      right: index < 3 ? 6 : 0,
                    ),

                    decoration: BoxDecoration(
                      color: active
                          ? colors[_strength]
                          : scheme.surfaceContainerHighest,

                      borderRadius:
                      BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Strength: ${_labels[_strength]}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // TERMS
          // ====================================================

          CheckboxListTile(
            value: _agreed,

            onChanged: (value) {
              setState(() {
                _agreed = value ?? false;
              });
            },

            controlAffinity:
            ListTileControlAffinity.leading,

            contentPadding: EdgeInsets.zero,

            title: const Text(
              'I agree to the Terms of Service and Privacy Policy',
            ),
          ),

          const SizedBox(height: 8),

          // ====================================================
          // CREATE ACCOUNT BUTTON
          // ====================================================

          SizedBox(
            height: 52,

            child: FilledButton(
              onPressed:
              _agreed && !_isLoading
                  ? _createAccount
                  : null,

              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(),
              )
                  : const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}