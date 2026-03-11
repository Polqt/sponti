import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/model/auth_user.dart';
import 'package:sponti/features/auth/repository/auth_remote_data_source.dart';
import 'package:sponti/features/auth/repository/auth_repository.dart';
import 'package:sponti/features/auth/repository/auth_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(Supabase.instance.client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

class AuthViewModel extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final sub = repository.authStateChanges.listen(
      (user) => state = AsyncData(user),
    );

    ref.onDispose(sub.cancel);
    return repository.currentUser;
  }

  Future<bool> signInWithGoogle() async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final result = await repository.signInWithGoogle();
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
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final result = await repository.signInWithFacebook();
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
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signOut();
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}

final authProvider = AsyncNotifierProvider<AuthViewModel, AuthUser?>(
  AuthViewModel.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
