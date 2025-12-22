import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:localangel/auth/ui/login_signup_page.dart';

class CameraPermissionScreen extends StatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  State<CameraPermissionScreen> createState() => _CameraPermissionScreenState();
}

class _CameraPermissionScreenState extends State<CameraPermissionScreen> {
  bool _isChecking = false;
  bool _isGranted = false;
  bool _isPermanentlyDenied = false;
  bool _hasRequestedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionStatus();
    });
  }

  Future<void> _checkPermissionStatus() async {
    setState(() => _isChecking = true);
    try {
      final status = await Permission.camera.status;
      final isGranted = status.isGranted;
      // Check if permanently denied OR if denied and we've already requested once
      final isPermanentlyDenied = status.isPermanentlyDenied || (status.isDenied && _hasRequestedOnce);

      if (mounted) {
        setState(() {
          _isGranted = isGranted;
          _isPermanentlyDenied = isPermanentlyDenied;
          _isChecking = false;
        });
        // Debug: Print status to help diagnose
        debugPrint(
          'Camera permission status: granted=$isGranted, permanentlyDenied=$isPermanentlyDenied, hasRequested=$_hasRequestedOnce',
        );
      }
    } catch (e) {
      // If permission_handler isn't properly linked, assume denied
      debugPrint('Error checking camera permission: $e');
      if (mounted) {
        setState(() {
          _isGranted = false;
          _isPermanentlyDenied = true; // Show red button if we can't check
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    _hasRequestedOnce = true; // Mark that we've tried requesting
    try {
      final status = await Permission.camera.request();

      // After requesting, check if it's now permanently denied
      if (mounted) {
        await _checkPermissionStatus();
        // If still denied after request, show red button
        if (!_isGranted && status.isDenied) {
          // Give it a moment and check again to see if it's permanently denied
          await Future.delayed(const Duration(milliseconds: 300));
          await _checkPermissionStatus();
        }
      }
    } catch (e) {
      // Handle platform channel errors - might need app rebuild
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isPermanentlyDenied = true; // Show red button on error
          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('שגיאה בבקשת הרשאה. אנא הפעל מחדש את האפליקציה.'),
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
    // Re-check permission after returning from settings
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _checkPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF9F5FF), Color(0xFFF5EEFF)],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'חזרה',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon
                          Center(
                            child: Container(
                              height: 96,
                              width: 96,
                              decoration: BoxDecoration(
                                color: _isGranted
                                    ? Colors.green.shade50
                                    : _isPermanentlyDenied
                                    ? Colors.red.shade50
                                    : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: _isGranted
                                    ? Colors.green.shade700
                                    : _isPermanentlyDenied
                                    ? Colors.red.shade700
                                    : const Color(0xFF7C3AED),
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          Text(
                            'גישה למצלמה',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'אנחנו זקוקים לגישה למצלמה שלך כדי לאפשר לך להעלות תמונות פרופיל, תמונות הוכחה לסיוע, ותמונות אחרות בקהילה.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Status indicator
                          if (_isChecking)
                            const Center(
                              child: CircularProgressIndicator(),
                            )
                          else if (_isGranted)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'הרשאת מצלמה מאושרת',
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_isPermanentlyDenied)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'הרשאת מצלמה נדחתה',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          // Action buttons
                          if (!_isChecking)
                            Builder(
                              builder: (context) {
                                if (_isGranted) {
                                  return FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const LoginSignupPage(),
                                        ),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'המשך',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                } else if (_isPermanentlyDenied) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      FilledButton(
                                        onPressed: _openSettings,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red.shade700,
                                          minimumSize: const Size.fromHeight(56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          'פתח הגדרות',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const LoginSignupPage(),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          side: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        child: const Text(
                                          'דלג',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return FilledButton(
                                    onPressed: _requestPermission,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED),
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'אשר גישה למצלמה',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
