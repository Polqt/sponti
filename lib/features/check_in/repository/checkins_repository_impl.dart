import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/repository/checkins_remote_data_source.dart';
import 'package:sponti/features/check_in/repository/checkins_repository.dart';

class CheckinsRepositoryImpl extends BaseRepository
    implements CheckinsRepository {
  const CheckinsRepositoryImpl(this._remote);

  final CheckinsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<CheckIn>>> getCheckInsForLocation(
    String locationId,
  ) => guard(() => _remote.getCheckInsForLocation(locationId));

  @override
  Future<Either<Failure, List<CheckIn>>> getMyCheckIns() =>
      guard(_remote.getMyCheckIns);

  @override
  Future<Either<Failure, CheckIn>> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    List<String> photos = const [],
  }) => guard(
    () => _remote.createCheckIn(
      locationId: locationId,
      userId: userId,
      note: note,
      photos: photos,
    ),
  );

  @override
  Future<Either<Failure, CheckIn>> updateCheckIn({
    required String checkInId,
    String? note,
    List<String> photos = const [],
  }) => guard(
    () => _remote.updateCheckIn(
      checkInId: checkInId,
      note: note,
      photos: photos,
    ),
  );

  @override
  Future<Either<Failure, void>> deleteCheckIn(String checkInId) =>
      guard(() => _remote.deleteCheckIn(checkInId));

  @override
  Future<Either<Failure, bool>> hasUserCheckedIn(
    String locationId,
    String userId,
  ) => guard(() => _remote.hasUserCheckedIn(locationId, userId));
}
