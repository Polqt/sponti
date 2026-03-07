import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  //  Returns the currently signed in user, or null if there is no user signed in.
  AuthUser? get currentUser;

  // Stream that emits the current authentication state of the user. 
  //It emits an AuthUser object when the user is signed in, and null when the user is signed out.
  Stream<AuthUser?> get authStateChanges;

  Future<Either<Failure, AuthUser>> signInWithGoogle();
  Future<Either<Failure, AuthUser>> signInWithFacebook();
  Future<Either<Failure, void>> signOut();
}