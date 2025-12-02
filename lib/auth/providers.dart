import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'biometric_lock_service.dart';
import 'firebase_auth_repository.dart';
import 'secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
final biometricLockProvider = Provider<BiometricLockService>(
  (ref) => BiometricLockService(ref.read(secureStorageProvider)),
);
final firebaseAuthRepositoryProvider = Provider(
  (ref) => FirebaseAuthRepository(),
);

/// Stream provider that directly listens to Firebase Auth state changes
/// This is the single source of truth for authentication state
/// Starts with current user value immediately, then listens to authStateChanges
final authUserStreamProvider = StreamProvider<User?>((ref) {
  final auth = FirebaseAuth.instance;
  final controller = StreamController<User?>.broadcast();

  // Emit current user immediately
  controller.add(auth.currentUser);

  // Then listen to changes
  final subscription = auth.authStateChanges().listen(
    (user) => controller.add(user),
    onError: (error) => controller.addError(error),
  );

  // Cancel subscription when provider is disposed
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

final authControllerStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      final repo = ref.read(firebaseAuthRepositoryProvider);
      final lock = ref.read(biometricLockProvider);
      return AuthController(repo, lock);
    });
