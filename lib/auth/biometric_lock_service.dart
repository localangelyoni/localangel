import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

import 'secure_storage_service.dart';

/// Biometric authentication service using local_auth.
class BiometricLockService {
  BiometricLockService(this._storage) : _localAuth = LocalAuthentication();

  final SecureStorageService _storage;
  final LocalAuthentication _localAuth;

  Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: 'biometric_enabled')) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: 'biometric_enabled',
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> authenticate({String? reason}) async {
    try {
      final isAvailable = await isBiometricSupported();
      if (!isAvailable) {
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason ?? 'אנא הזהה את עצמך כדי להמשיך',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }
}
