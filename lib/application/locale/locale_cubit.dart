import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Controls the app Locale and syncs it with Firestore under users/{uid}.settings.language
class LocaleCubit extends ChangeNotifier {
  LocaleCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Locale _locale = const Locale('he');
  Locale get locale => _locale;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  Future<void> init() async {
    // Set default Hebrew
    _locale = const Locale('he');
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) return;

    _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final settings = (data['settings'] as Map?) ?? {};
      final languageCode = (settings['language'] as String?) ?? 'he';
      final code = (languageCode == 'en') ? 'en' : 'he';
      if (_locale.languageCode != code) {
        _locale = Locale(code);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> setLanguage(String code) async {
    final normalized = (code == 'en') ? 'en' : 'he';
    if (_locale.languageCode != normalized) {
      _locale = Locale(normalized);
      notifyListeners();
    }

    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'settings': {'language': normalized}
    }, SetOptions(merge: true));
  }
}














