import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessibilityState {
  const AccessibilityState({
    this.highContrastMode = false,
    this.largeText = false,
    this.simpleMode = false,
    this.voiceOverEnabled = false,
    this.isLoading = true,
  });

  final bool highContrastMode;
  final bool largeText;
  final bool simpleMode;
  final bool voiceOverEnabled;
  final bool isLoading;

  AccessibilityState copyWith({
    bool? highContrastMode,
    bool? largeText,
    bool? simpleMode,
    bool? voiceOverEnabled,
    bool? isLoading,
  }) {
    return AccessibilityState(
      highContrastMode: highContrastMode ?? this.highContrastMode,
      largeText: largeText ?? this.largeText,
      simpleMode: simpleMode ?? this.simpleMode,
      voiceOverEnabled: voiceOverEnabled ?? this.voiceOverEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AccessibilityCubit extends StateNotifier<AccessibilityState> {
  AccessibilityCubit(this._firestore, this._auth) : super(const AccessibilityState()) {
    _init();
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  void _init() {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final settings = (data['settings'] as Map?) ?? {};
      final accessibility = (settings['accessibility'] as Map?) ?? {};

      state = state.copyWith(
        highContrastMode: (accessibility['high_contrast_mode'] as bool?) ?? false,
        largeText: (accessibility['large_text'] as bool?) ?? false,
        simpleMode: (accessibility['simple_mode'] as bool?) ?? false,
        voiceOverEnabled: (accessibility['voice_over_enabled'] as bool?) ?? false,
        isLoading: false,
      );
    });
  }

  Future<void> updateHighContrastMode(bool value) async {
    state = state.copyWith(highContrastMode: value);
    await _saveToFirestore();
  }

  Future<void> updateLargeText(bool value) async {
    state = state.copyWith(largeText: value);
    await _saveToFirestore();
  }

  Future<void> updateSimpleMode(bool value) async {
    state = state.copyWith(simpleMode: value);
    await _saveToFirestore();
  }

  Future<void> updateVoiceOverEnabled(bool value) async {
    state = state.copyWith(voiceOverEnabled: value);
    await _saveToFirestore();
  }

  Future<void> resetToDefaults() async {
    state = const AccessibilityState(
      highContrastMode: false,
      largeText: false,
      simpleMode: false,
      voiceOverEnabled: false,
      isLoading: false,
    );
    await _saveToFirestore();
  }

  Future<void> _saveToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'settings': {
          'accessibility': {
            'high_contrast_mode': state.highContrastMode,
            'large_text': state.largeText,
            'simple_mode': state.simpleMode,
            'voice_over_enabled': state.voiceOverEnabled,
          }
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // Error handling - could emit error state if needed
      // For now, just log
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}

final accessibilityCubitProvider = StateNotifierProvider<AccessibilityCubit, AccessibilityState>((ref) {
  return AccessibilityCubit(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

