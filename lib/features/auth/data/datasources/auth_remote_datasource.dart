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

  static final _googleServerClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID']!;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<User> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: _googleServerClientId);

      // Trigger the Google Sign-In flow
      final googleUser = await googleSignIn.authenticate();
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
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw const AuthException('Facebook sign-in cancelled.');
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AuthException(result.message ?? 'Facebook sign-in failed.');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: result.accessToken!.tokenString,
      );

      final user = response.user;
      if (user == null) throw const AuthException('Facebook sign-in failed.');
      return user;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        GoogleSignIn.instance.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}
