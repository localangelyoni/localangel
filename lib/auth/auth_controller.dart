import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'biometric_lock_service.dart';
import 'firebase_auth_repository.dart';

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

  AuthState copyWith({
    User? user,
    bool? locked,
    bool? biometricSupported,
    bool? biometricEnabled,
  }) => AuthState(
    user: user ?? this.user,
    locked: locked ?? this.locked,
    biometricSupported: biometricSupported ?? this.biometricSupported,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._lock)
    : super(
        const AuthState(
          user: null,
          locked: false,
          biometricSupported: false,
          biometricEnabled: false,
        ),
      ) {
    // Initialize with current user immediately if available
    _initializeAuthState();

    // Listen to auth state changes
    _sub = _repo.authStateChanges().listen(
      (u) async {
        await _updateAuthState(u);
      },
      onError: (error) {
        // If stream fails, just set user to null
        state = state.copyWith(user: null);
      },
    );
  }

  Future<void> _initializeAuthState() async {
    // Get current user synchronously from Firebase Auth
    // This ensures we have the initial state immediately
    User? currentUser;
    if (_repo is FirebaseAuthRepository) {
      // Access Firebase Auth directly for synchronous current user check
      currentUser = FirebaseAuth.instance.currentUser;
    } else {
      // Fallback: get first value from stream (async)
      try {
        currentUser = await _repo.authStateChanges().first;
      } catch (_) {
        currentUser = null;
      }
    }
    await _updateAuthState(currentUser);
  }

  Future<void> _updateAuthState(User? user) async {
    // CRITICAL: Update user immediately (synchronously) so UI reacts right away
    // This must happen before any async operations
    if (state.user != user) {
      state = state.copyWith(user: user);
    }

    // Then update biometric settings asynchronously (non-blocking)
    _updateBiometricSettings();
  }

  Future<void> _updateBiometricSettings() async {
    try {
      final supported = await _lock.isBiometricSupported();
      final enabled = await _lock.isBiometricEnabled();
      state = state.copyWith(
        biometricSupported: supported,
        biometricEnabled: enabled,
      );
    } catch (e) {
      // If biometric check fails, continue without biometrics
      state = state.copyWith(
        biometricSupported: false,
        biometricEnabled: false,
      );
    }
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

  /// Manually refresh the auth state by checking current user
  /// This is useful after login/logout when the stream might not emit immediately
  /// Returns immediately after updating user state (synchronously)
  Future<void> refreshAuthState() async {
    User? currentUser;
    if (_repo is FirebaseAuthRepository) {
      // Get current user synchronously - this is the key!
      currentUser = FirebaseAuth.instance.currentUser;
    } else {
      try {
        currentUser = await _repo.authStateChanges().first;
      } catch (_) {
        currentUser = null;
      }
    }
    // Update state immediately - user update is synchronous
    if (state.user != currentUser) {
      state = state.copyWith(user: currentUser);
    }
    // Update biometrics in background (non-blocking)
    _updateBiometricSettings();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(),
);
final biometricLockServiceProvider = Provider<BiometricLockService>(
  (ref) => throw UnimplementedError(),
);
