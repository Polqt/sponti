import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDataSource {
  User? get currentUser;
  Stream<AuthState>
  get authStateChanges; // non-nullable — Supabase always emits
  Future<User> signInWithGoogle();
  Future<User> signInWithFacebook();
  Future<void> signOut();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static String get _googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  static bool _googleInitialized = false;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
      _googleInitialized = true;
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // Trigger the Google Sign-In flow
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('No ID token from Google.');
      }

      // Exchange with supabase to create a session
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Google sign-in failed: No user returned from Supabase.',
        );
      }
      return user;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<User> signInWithFacebook() async {
    try {
      // Facebook on Android doesn't provide OIDC ID tokens, so we use
      // Supabase's server-side OAuth flow (opens browser).
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.sponti://login-callback/',
      );

      if (!success) {
        throw const AuthException('Facebook sign-in failed to launch.');
      }

      // Wait for the auth state to change after the browser redirect
      final authState = await _client.auth.onAuthStateChange
          .firstWhere((state) => state.event == AuthChangeEvent.signedIn)
          .timeout(const Duration(minutes: 2));

      final user = authState.session?.user;
      if (user == null) throw const AuthException('Facebook sign-in failed.');
      return user;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    // Always clear the local Supabase session first, even if provider
    // sign-outs fail (e.g. no internet).
    await _client.auth.signOut(scope: SignOutScope.local);

    // Best-effort sign out from third-party providers
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
