import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/model/location_query.dart';
import 'package:sponti/features/locations/repository/location_local_data_source.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:sponti/features/locations/repository/location_repository.dart';

class LocationRepositoryImpl extends BaseRepository
    implements LocationRepository {
  const LocationRepositoryImpl(this._remote, this._local);

  final LocationRemoteDataSource _remote;
  final LocationLocalDataSource _local;

  Future<Either<Failure, List<Location>>> _getCachedOrFail(
    String message,
    Failure Function(String) failureFactory,
  ) async {
    try {
      final cached = await _local.getCachedLocations();
      return Right(cached);
    } catch (_) {
      return Left(failureFactory(message));
    }
  }

  @override
  Future<Either<Failure, List<Location>>> getAllLocations({
    int page = 0,
    int pageSize = 1000,
  }) async {
    try {
      final locations = await _remote.getAllLocations(
        page: page,
        pageSize: pageSize,
      );

      if (page == 0) {
        try {
          await _local.cacheLocations(locations);
        } on CacheException {
          // Cache writes are best-effort; the remote result is still valid.
        }
      }
      return Right(locations);
    } on ServerException catch (e) {
      if (page == 0) return _getCachedOrFail(e.message, ServerFailure.new);
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      if (page == 0) return _getCachedOrFail(e.message, NetworkFailure.new);
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationPage>> getLocationsPage({
    LocationPageCursor? cursor,
    int limit = 30,
  }) => guard(() => _remote.getLocationsPage(cursor: cursor, limit: limit));

  @override
  Future<Either<Failure, Location>> getLocationById(String id) async {
    final cached = await _local.getCachedLocationById(id);
    if (cached != null) return Right(cached);
    return guard(() => _remote.getLocationById(id));
  }

  @override
  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) => guard(
    () => _remote.getNearbyLocations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ),
  );

  @override
  Future<Either<Failure, List<Location>>> filterByCategory(
    LocationCategory category,
  ) => guard(() => _remote.filterByCategory(category));

  @override
  Future<Either<Failure, List<Location>>> fetchByCategories(
    List<String> categories,
  ) => guard(() => _remote.fetchByCategories(categories));

  @override
  Future<Either<Failure, List<Location>>> searchLocations(String query) =>
      guard(() => _remote.searchLocations(query));

  @override
  Future<Either<Failure, List<Location>>> searchLocationsRanked(
    RankedLocationSearchRequest request,
  ) => guard(() => _remote.searchLocationsRanked(request));

  @override
  Future<Either<Failure, Location>> createLocation(Location location) =>
      guard(() => _remote.createLocation(LocationModel.fromEntity(location)));

  @override
  Future<Either<Failure, Location>> updateLocation(Location location) =>
      guard(() => _remote.updateLocation(LocationModel.fromEntity(location)));

  @override
  Future<Either<Failure, void>> deleteLocation(String id) =>
      guard(() => _remote.deleteLocation(id));
}
