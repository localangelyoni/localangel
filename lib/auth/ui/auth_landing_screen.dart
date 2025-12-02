import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localangel/auth/ui/login_signup_page.dart';

class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen> {
  bool _agree = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C3AED),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  height: 80,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.volunteer_activism,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ברוכים הבאים',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'התחברו כדי להמשיך',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 48),
                // Terms checkbox
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agree,
                          onChanged: (v) => setState(() => _agree = v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _agree = !_agree),
                            child: const Text(
                              'אני מסכים/ה לתנאי השימוש ומדיניות הפרטיות',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _agree
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginSignupPage(),
                              ),
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'התחברות / הרשמה',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
