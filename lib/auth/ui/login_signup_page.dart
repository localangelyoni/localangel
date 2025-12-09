import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localangel/auth/providers.dart';
import 'package:localangel/auth/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LoginSignupPage extends ConsumerStatefulWidget {
  const LoginSignupPage({super.key});

  @override
  ConsumerState<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends ConsumerState<LoginSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final storage = ref.read(secureStorageProvider);
    final savedEmail = await storage.read(key: 'saved_email');
    final savedPassword = await storage.read(key: 'saved_password');
    final rememberMe = await storage.read(key: 'remember_me');

    if (mounted && rememberMe == 'true' && savedEmail != null && savedPassword != null) {
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(firebaseAuthRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLoginMode) {
        await authRepo.signInWithEmail(email: email, password: password);
      } else {
        await authRepo.signUpWithEmail(email: email, password: password);
      }

      if (_rememberMe) {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'saved_email', value: email);
        await storage.write(key: 'saved_password', value: password);
        await storage.write(key: 'remember_me', value: 'true');
      } else {
        final storage = ref.read(secureStorageProvider);
        await storage.delete(key: 'saved_email');
        await storage.delete(key: 'saved_password');
        await storage.delete(key: 'remember_me');
      }

      if (mounted) {
        // Invalidate the auth stream provider to force it to refresh with new user
        ref.invalidate(authUserStreamProvider);

        // Wait a moment for the provider to refresh
        await Future.delayed(const Duration(milliseconds: 100));

        // Pop back to root - Firebase stream provider will have refreshed
        // and _AuthGate will rebuild to show HomePage
        if (mounted && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'משתמש לא נמצא';
            break;
          case 'wrong-password':
            message = 'סיסמה שגויה';
            break;
          case 'email-already-in-use':
            message = 'כתובת אימייל כבר בשימוש';
            break;
          case 'weak-password':
            message = 'הסיסמה חלשה מדי';
            break;
          case 'invalid-email':
            message = 'כתובת אימייל לא תקינה';
            break;
          default:
            message = 'שגיאה בהתחברות: ${e.message ?? 'שגיאה לא ידועה'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(SocialProvider provider) async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(firebaseAuthRepositoryProvider);

      switch (provider) {
        case SocialProvider.google:
          await authRepo.signInWithGoogle();
          break;
        default:
          return; // Only Google is supported now
      }

      if (mounted) {
        // Invalidate the auth stream provider to force it to refresh with new user
        ref.invalidate(authUserStreamProvider);

        // Wait a moment for the provider to refresh
        await Future.delayed(const Duration(milliseconds: 100));

        // Pop back to root - Firebase stream provider will have refreshed
        // and _AuthGate will rebuild to show HomePage
        if (mounted && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'שגיאה בהתחברות';
        if (e.code == 'canceled') {
          message = 'ההתחברות בוטלה';
        } else if (e.message != null) {
          message = e.message!;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('נא להזין כתובת אימייל')));
      return;
    }

    try {
      final authRepo = ref.read(firebaseAuthRepositoryProvider);
      await authRepo.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('נשלח אימייל לאיפוס סיסמה')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C3AED),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  color: Colors.white,
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/logo.png',
                    height: 90,
                    width: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.volunteer_activism, size: 48, color: Color(0xFF7C3AED)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),

                              Text(
                                _isLoginMode ? 'התחברות' : 'הרשמה',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'אימייל',
                              border: UnderlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'נא להזין כתובת אימייל';
                              }
                              if (!value.contains('@')) {
                                return 'כתובת אימייל לא תקינה';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: _isLoginMode ? TextInputAction.done : TextInputAction.next,
                            autofillHints: _isLoginMode ? [AutofillHints.password] : [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'סיסמה',
                              border: const UnderlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'נא להזין סיסמה';
                              }
                              if (!_isLoginMode && value.length < 6) {
                                return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                              }
                              return null;
                            },
                          ),
                          if (!_isLoginMode) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: 'אימות סיסמה',
                                border: const UnderlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () {
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'נא לאמת את הסיסמה';
                                }
                                if (value != _passwordController.text) {
                                  return 'הסיסמאות לא תואמות';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                              ),
                              const Text('זכור אותי'),
                              const Spacer(),
                              if (_isLoginMode) TextButton(onPressed: _handlePasswordReset, child: const Text('שכחתי סיסמה')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _handleEmailLogin,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: const Color(0xFF1F1F23),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_isLoginMode ? 'התחברות עם אימייל' : 'הרשמה'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('או', style: TextStyle(color: Colors.grey.shade600)),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _SocialButton(
                            label: 'המשך עם Google',
                            icon: Icons.login,
                            iconColor: const Color(0xFF4285F4),
                            onPressed: _isLoading ? null : () => _handleSocialLogin(SocialProvider.google),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isLoginMode ? 'אין לך חשבון? ' : 'יש לך חשבון? '),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoginMode = !_isLoginMode;
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                child: Text(_isLoginMode ? 'הירשם' : 'התחבר'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, this.iconColor, this.onPressed});

  final String label;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
