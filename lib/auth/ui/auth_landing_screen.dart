import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localangel/presentation/pages/welcome_page.dart';
import 'package:localangel/presentation/pages/location_permission_screen.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo and header section
              const SizedBox(height: 16),
              ClipOval(
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
              const SizedBox(height: 16),
              const Text(
                'ברוכים הבאים',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text('התחברו כדי להמשיך', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(height: 24),
              // Terms step wrapped in Card for readability on blue background - takes remaining space
              Flexible(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: TermsStep(
                        accepted: _agree,
                        onToggle: (v) => setState(() => _agree = v),
                        onContinue: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LocationPermissionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
