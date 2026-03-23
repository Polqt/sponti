import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/repository/checkins_remote_data_source.dart';
import 'package:sponti/features/check_in/repository/checkins_repository.dart';

class CheckinsRepositoryImpl implements CheckinsRepository {
  const CheckinsRepositoryImpl(this._remote);

  final CheckinsRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CheckIn>>> getCheckInsForLocation(
    String locationId,
  ) => _guard(() => _remote.getCheckInsForLocation(locationId));

  @override
  Future<Either<Failure, CheckIn>> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    String? photoUrl,
  }) => _guard(
    () => _remote.createCheckIn(
      locationId: locationId,
      userId: userId,
      note: note,
      photoUrl: photoUrl,
    ),
  );

  @override
  Future<Either<Failure, void>> deleteCheckIn(String checkInId) =>
      _guard(() => _remote.deleteCheckIn(checkInId));

  @override
  Future<Either<Failure, bool>> hasUserCheckedIn(
    String locationId,
    String userId,
  ) => _guard(() => _remote.hasUserCheckedIn(locationId, userId));
}
