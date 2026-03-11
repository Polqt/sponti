import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/auth/model/auth_user.dart';
import 'package:sponti/features/auth/repository/auth_remote_data_source.dart';
import 'package:sponti/features/auth/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  AuthUser? get currentUser {
    final user = _remote.currentUser;
    return user != null ? _mapUser(user) : null;
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _remote.authStateChanges.map((authState) {
        final user = authState.session?.user;
        return user != null ? _mapUser(user) : null;
      });

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() =>
      _guard(() async => _mapUser(await _remote.signInWithGoogle()));

  @override
  Future<Either<Failure, AuthUser>> signInWithFacebook() =>
      _guard(() async => _mapUser(await _remote.signInWithFacebook()));

  @override
  Future<Either<Failure, void>> signOut() => _guard(_remote.signOut);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  AuthUser _mapUser(dynamic user) {
    final meta = user.userMetadata ?? {};
    final appMeta = user.appMetadata;

    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      fullName: (meta['full_name'] as String?) ?? (meta['name'] as String?),
      avatarUrl:
          (meta['avatar_url'] as String?) ?? (meta['picture'] as String?),
      provider:
          (appMeta['provider'] as String?) ??
          ((appMeta['providers'] as List?)?.firstOrNull as String?),
    );
  }
}
