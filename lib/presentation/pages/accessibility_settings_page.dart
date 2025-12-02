import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/accessibility/accessibility_cubit.dart';

class AccessibilitySettingsPage extends ConsumerWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessibilityCubitProvider);
    final cubit = ref.read(accessibilityCubitProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'אפשרויות נגישות',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1F23),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'התאם את חווית השימוש באפליקציה לצרכים שלך.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF1F1F23),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Main settings card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'הגדרות תצוגה וקול',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F1F23),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _AccessibilityToggle(
                              title: 'מצב ניגודיות גבוהה',
                              value: state.highContrastMode,
                              onChanged: (value) =>
                                  cubit.updateHighContrastMode(value),
                            ),
                            const SizedBox(height: 16),
                            _AccessibilityToggle(
                              title: 'טקסט גדול',
                              value: state.largeText,
                              onChanged: (value) =>
                                  cubit.updateLargeText(value),
                            ),
                            const SizedBox(height: 16),
                            _AccessibilityToggle(
                              title: 'מצב פשוט',
                              value: state.simpleMode,
                              onChanged: (value) =>
                                  cubit.updateSimpleMode(value),
                            ),
                            const SizedBox(height: 16),
                            _AccessibilityToggle(
                              title: 'הפעל Voice Over',
                              value: state.voiceOverEnabled,
                              onChanged: (value) =>
                                  cubit.updateVoiceOverEnabled(value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reset button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => cubit.resetToDefaults(),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'איפוס לברירת המחדל',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilityToggle extends StatelessWidget {
  const _AccessibilityToggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF7C3AED),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF1F1F23),
            ),
          ),
        ),
      ],
    );
  }
}
