import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';
import 'package:sponti/features/profile/repository/profile_remote_data_source.dart';
import 'package:sponti/features/profile/repository/profile_repository.dart';

class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) =>
      guard(() => _remote.getUserProfile(userId));

  @override
  Future<Either<Failure, UserStats>> getUserStats(String userId) =>
      guard(() => _remote.getUserStats(userId));

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) =>
      guard(() => _remote.updateProfile(UserProfileModel.fromEntity(profile)));

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) => guard(
    () => _remote.uploadProfilePhoto(
      userId: userId,
      bytes: bytes,
      extension: extension,
      contentType: contentType,
    ),
  );
}
