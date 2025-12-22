import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localangel/presentation/pages/camera_permission_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isChecking = false;
  bool _isGranted = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() => _isChecking = true);
    try {
      final permission = await Geolocator.checkPermission();
      final isGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
      final isPermanentlyDenied = permission == LocationPermission.deniedForever;

      if (mounted) {
        setState(() {
          _isGranted = isGranted;
          _isPermanentlyDenied = isPermanentlyDenied;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (mounted) {
        await _checkPermissionStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
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
                                Icons.location_on_outlined,
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
                            'גישה למיקום',
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
                              'אנחנו זקוקים לגישה למיקום שלך כדי לחבר אותך עם אנשים בקרבתך ולאפשר לשומרים למצוא אותך כשצריך עזרה.',
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
                                      'הרשאת מיקום מאושרת',
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
                                      'הרשאת מיקום נדחתה',
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
                            if (_isGranted)
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CameraPermissionScreen(),
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
                              )
                            else if (_isPermanentlyDenied)
                              Column(
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
                                          builder: (_) => const CameraPermissionScreen(),
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
                              )
                            else
                              FilledButton(
                                onPressed: _requestPermission,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'אשר גישה למיקום',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
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
