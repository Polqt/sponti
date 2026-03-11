import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';
import 'package:sponti/features/profile/repository/profile_remote_data_source.dart';
import 'package:sponti/features/profile/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.toString()));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.toString()));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) =>
      _guard(() => _remote.getUserProfile(userId));

  @override
  Future<Either<Failure, UserStats>> getUserStats(String userId) =>
      _guard(() => _remote.getUserStats(userId));

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) =>
      _guard(() => _remote.updateProfile(UserProfileModel.fromEntity(profile)));

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) => _guard(
    () => _remote.uploadProfilePhoto(
      userId: userId,
      bytes: bytes,
      extension: extension,
    ),
  );
}
