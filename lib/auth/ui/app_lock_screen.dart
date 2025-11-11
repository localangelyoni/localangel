import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('נעלת אפליקציה')),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final controller = ref.read(authControllerStateProvider.notifier);
            await controller.unlockWithBiometrics();
          },
          child: const Text('פתח באמצעות זיהוי ביומטרי'),
        ),
      ),
    );
  }
}





