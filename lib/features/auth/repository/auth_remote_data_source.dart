import 'dart:async' show TimeoutException;

import 'package:sponti/config/config.dart';
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
        redirectTo: SupabaseOptions.authRedirectTo,
      );

      if (!success) {
        throw AuthException('$providerLabel sign-in failed to launch.');
      }

      // Wait for sign-in or explicit cancellation (signedOut/passwordRecovery
      // won't fire here, but if user just closes the browser the stream never
      // emits, so we rely on the timeout).
      final authState = await _client.auth.onAuthStateChange
          .firstWhere(
            (state) =>
                state.event == AuthChangeEvent.signedIn ||
                state.event == AuthChangeEvent.signedOut,
          )
          .timeout(const Duration(seconds: 120));

      if (authState.event == AuthChangeEvent.signedOut ||
          authState.session == null) {
        throw AuthException('$providerLabel sign-in was cancelled.');
      }

      final user = authState.session?.user;
      if (user == null) {
        throw AuthException('$providerLabel sign-in failed.');
      }
      return user;
    } on TimeoutException {
      throw AuthException('$providerLabel sign-in timed out. Please try again.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
