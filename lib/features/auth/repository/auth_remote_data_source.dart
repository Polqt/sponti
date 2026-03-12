import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDataSource {
  User? get currentUser;
  Stream<AuthState> get authStateChanges;
  Future<User> signInWithGoogle();
  Future<User> signInWithFacebook();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;
  static const String _redirectTo = 'io.supabase.sponti://login-callback/';

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<User> signInWithGoogle() async {
    return _signInWithOAuth(
      provider: OAuthProvider.google,
      providerLabel: 'Google',
    );
  }

  @override
  Future<User> signInWithFacebook() async {
    return _signInWithOAuth(
      provider: OAuthProvider.facebook,
      providerLabel: 'Facebook',
    );
  }

  Future<User> _signInWithOAuth({
    required OAuthProvider provider,
    required String providerLabel,
  }) async {
    try {
      final success = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: _redirectTo,
      );

      if (!success) {
        throw AuthException('$providerLabel sign-in failed to launch.');
      }

      final authState = await _client.auth.onAuthStateChange
          .firstWhere((state) => state.event == AuthChangeEvent.signedIn)
          .timeout(const Duration(minutes: 2));

      final user = authState.session?.user;
      if (user == null) {
        throw AuthException('$providerLabel sign-in failed.');
      }
      return user;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}
