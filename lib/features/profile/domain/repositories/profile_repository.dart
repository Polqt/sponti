import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  // Fetch the user profile for any user by [userid]
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);

  // Fetch aggregated stats
  Future<Either<Failure, UserStats>> getUserStats(String userId);

  // Update the current user's profile fields.
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile);

  // Upload a new avatar photo and return the public url
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  });
}
