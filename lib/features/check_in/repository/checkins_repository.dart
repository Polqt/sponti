import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/check_in/models/checkins.dart';

abstract interface class CheckinsRepository {
  Future<Either<Failure, List<CheckIn>>> getCheckInsForLocation(
    String locationId,
  );
  Future<Either<Failure, CheckIn>> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    String? photoUrl,
  });
  Future<Either<Failure, void>> deleteCheckIn(String checkInId);
  Future<Either<Failure, bool>> hasUserCheckedIn(
    String locationId,
    String userId,
  );
}
