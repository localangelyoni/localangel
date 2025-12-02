import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Microsoft login is stubbed for now; integrate MSAL as needed
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:math';

import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }
    final googleUser = await GoogleSignIn(
      scopes: ['email', 'profile'],
    ).signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'User canceled Google Sign-In',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );
    return _auth.signInWithCredential(oauth);
  }

  @override
  Future<UserCredential> signInWithMicrosoft() async {
    throw FirebaseAuthException(
      code: 'provider-unavailable',
      message: 'Microsoft login not configured',
    );
  }

  @override
  Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.accessToken == null) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'User canceled Facebook Login',
        );
      }
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      return _auth.signInWithCredential(credential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'facebook-unavailable',
        message: 'Facebook login not available: $e',
      );
    }
  }

  @override
  Future<void> linkProvider(SocialProvider provider) async {
    final user = _auth.currentUser;
    if (user == null)
      throw FirebaseAuthException(code: 'no-user', message: 'No current user');
    AuthCredential credential;
    switch (provider) {
      case SocialProvider.google:
        final google = await GoogleSignIn(
          scopes: ['email', 'profile'],
        ).signIn();
        if (google == null)
          throw FirebaseAuthException(code: 'canceled', message: 'Canceled');
        final ga = await google.authentication;
        credential = GoogleAuthProvider.credential(
          idToken: ga.idToken,
          accessToken: ga.accessToken,
        );
        break;
      case SocialProvider.apple:
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
          nonce: nonce,
        );
        credential = OAuthProvider('apple.com').credential(
          idToken: apple.identityToken,
          accessToken: apple.authorizationCode,
          rawNonce: rawNonce,
        );
        break;
      case SocialProvider.microsoft:
        throw FirebaseAuthException(
          code: 'provider-unavailable',
          message: 'Microsoft link not configured',
        );

      case SocialProvider.facebook:
        final res = await FacebookAuth.instance.login(permissions: ['email']);
        if (res.accessToken == null)
          throw FirebaseAuthException(code: 'canceled', message: 'Canceled');
        credential = FacebookAuthProvider.credential(
          res.accessToken!.tokenString,
        );
        break;
    }
    await user.linkWithCredential(credential);
  }

  @override
  Future<void> unlinkProvider(SocialProvider provider) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String providerId;
    switch (provider) {
      case SocialProvider.google:
        providerId = GoogleAuthProvider.PROVIDER_ID;
        break;
      case SocialProvider.apple:
        providerId = 'apple.com';
        break;
      case SocialProvider.microsoft:
        providerId = 'microsoft.com';
        break;
      case SocialProvider.facebook:
        providerId = FacebookAuthProvider.PROVIDER_ID;
        break;
    }
    await user.unlink(providerId);
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  @override
  Future<void> refreshIdTokenIfExpired() async {
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }

  @override
  Future<void> reauthenticate() async {
    // App-specific: show UI to pick a method and call user.reauthenticateWithCredential
    throw UnimplementedError('Provide a UI-driven reauthentication flow');
  }

  // Helpers for Apple nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = crypto.sha256.convert(input.codeUnits).bytes;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
