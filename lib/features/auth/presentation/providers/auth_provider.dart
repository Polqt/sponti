import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/dependency_injection.dart';
import 'package:sponti/features/auth/domain/entities/auth_user.dart';
import 'package:sponti/features/auth/domain/repositories/auth_repository.dart';
import 'package:sponti/features/auth/domain/usecases/auth_usecases.dart';

// Auth Notifier
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // Subscribe to real-time auth state changes (sign in / sign out from anywhere)
    final sub = getIt<AuthRepository>()
        .authStateChanges
        .listen((user) => state = AsyncData(user));

    // Cancel subscription when the provider is disposed
    ref.onDispose(sub.cancel);

    // Return the current user synchronously on first build
    return getIt<GetCurrentUserUseCase>()();
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await getIt<SignInWithGoogleUseCase>()();
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (user) {
        state = AsyncData(user);
        return true;
      },
    );
  }

  Future<bool> signInWithFacebook() async {
    state = const AsyncLoading();
    final result = await getIt<SignInWithFacebookUseCase>()();
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (user) {
        state = AsyncData(user);
        return true;
      },
    );
  }

  Future<void> signOut() async {
    await getIt<SignOutUseCase>()();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

// Whether the user is currently authenticated. 
//This can be used to show/hide UI elements based on authentication state.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});

// The current authenticated user, or null if not authenticated. 
//This can be used to access user details in the UI.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
