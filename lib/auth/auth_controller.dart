import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'biometric_lock_service.dart';

class AuthState {
  const AuthState({
    required this.user,
    required this.locked,
    required this.biometricSupported,
    required this.biometricEnabled,
  });

  final User? user;
  final bool locked;
  final bool biometricSupported;
  final bool biometricEnabled;

  AuthState copyWith({User? user, bool? locked, bool? biometricSupported, bool? biometricEnabled}) => AuthState(
        user: user ?? this.user,
        locked: locked ?? this.locked,
        biometricSupported: biometricSupported ?? this.biometricSupported,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._lock) : super(const AuthState(user: null, locked: false, biometricSupported: false, biometricEnabled: false)) {
    _sub = _repo.authStateChanges().listen((u) async {
      try {
        final supported = await _lock.isBiometricSupported();
        final enabled = await _lock.isBiometricEnabled();
        state = state.copyWith(user: u, biometricSupported: supported, biometricEnabled: enabled);
      } catch (e) {
        // If biometric check fails, continue without biometrics
        state = state.copyWith(user: u, biometricSupported: false, biometricEnabled: false);
      }
    }, onError: (error) {
      // If stream fails, just set user to null
      state = state.copyWith(user: null);
    });
  }

  final AuthRepository _repo;
  final BiometricLockService _lock;
  StreamSubscription<User?>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> enableBiometrics(bool enabled) async {
    await _lock.setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<bool> unlockWithBiometrics() async {
    final ok = await _lock.authenticate();
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  void setLocked(bool locked) => state = state.copyWith(locked: locked);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError());
final biometricLockServiceProvider = Provider<BiometricLockService>((ref) => throw UnimplementedError());




