import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/profile/domain/repositories/profile_repository.dart';

class UploadProfilePhotoParams {
  const UploadProfilePhotoParams({
    required this.userId,
    required this.bytes,
    required this.extension,
  });

  final String userId;
  final Uint8List bytes;
  final String extension;
}

@lazySingleton
class UploadProfilePhotoUseCase
    implements UseCase<String, UploadProfilePhotoParams> {
  const UploadProfilePhotoUseCase(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadProfilePhotoParams params) =>
      _repository.uploadProfilePhoto(
        userId: params.userId,
        bytes: params.bytes,
        extension: params.extension,
      );
}
