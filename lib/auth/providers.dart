import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'biometric_lock_service.dart';
import 'firebase_auth_repository.dart';
import 'secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());
final biometricLockProvider = Provider<BiometricLockService>((ref) => BiometricLockService(ref.read(secureStorageProvider)));
final firebaseAuthRepositoryProvider = Provider((ref) => FirebaseAuthRepository());

final authControllerStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.read(firebaseAuthRepositoryProvider);
  final lock = ref.read(biometricLockProvider);
  return AuthController(repo, lock);
});





