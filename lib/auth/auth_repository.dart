import 'package:firebase_auth/firebase_auth.dart';

/// Social auth providers supported by the app.
enum SocialProvider { google, apple, microsoft, facebook }

/// Abstraction over authentication operations, implemented by Firebase.
abstract class AuthRepository {
  Stream<User?> authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});

  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<UserCredential> signInWithMicrosoft();
  Future<UserCredential> signInWithFacebook();

  Future<void> linkProvider(SocialProvider provider);
  Future<void> unlinkProvider(SocialProvider provider);

  Future<String?> getIdToken({bool forceRefresh = false});
  Future<void> refreshIdTokenIfExpired();

  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> reauthenticate();
}
