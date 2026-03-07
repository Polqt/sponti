import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SignInWithGoogleUseCase implements NoParamsUseCase<AuthUser> {
  const SignInWithGoogleUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthUser>> call() => _repository.signInWithGoogle();
}

@lazySingleton
class SignInWithFacebookUseCase implements NoParamsUseCase<AuthUser> {
  const SignInWithFacebookUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthUser>> call() => _repository.signInWithFacebook();
}

@lazySingleton
class SignOutUseCase implements NoParamsUseCase<void> {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call() => _repository.signOut();
}

@lazySingleton
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  AuthUser? call() => _repository.currentUser;
}