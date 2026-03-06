import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/data/datasources/location_local_datasource.dart';
import 'package:sponti/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:sponti/features/locations/data/models/location_model.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._remote, this._local);

  final LocationRemoteDataSource _remote;
  final LocationLocalDataSource _local;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Location>>> getAllLocations({
    int page = 0,
    int pageSize = 20,
  }) async {
    // Try remote first; fall back to cache on failure (1st page onleh)
    try {
      final locations = await _remote.getAllLocations(
        page: page,
        pageSize: pageSize,
      );

      // Cache only the first page, to avoid filling up the cache with too many items
      if (page == 0) {
        try {
          await _local.cacheLocations(locations);
        } on CacheException {
          // Best-effort cache write; do not fail the remote read.
        }
      }
      return Right(locations);
    } on ServerException catch (e) {
      // If remote fails, try cache (only for the first page)
      if (page == 0) {
        try {
          final cached = await _local.getCachedLocations();
          return Right(cached);
        } catch (_) {
          return Left(ServerFailure(e.message));
        }
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Location>> getLocationById(String id) async {
    // Try cache first for detail view to improve responsiveness; fall back to remote on failure
    final cached = await _local.getCachedLocationById(id);
    if (cached != null) return Right(cached);
    return _guard(() => _remote.getLocationById(id));
  }

  @override
  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) => _guard(
    () => _remote.getNearbyLocations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ),
  );

  @override
  Future<Either<Failure, List<Location>>> filterByCategory(
    LocationCategory category,
  ) => _guard(() => _remote.filterByCategory(category));

  @override
  Future<Either<Failure, List<Location>>> searchLocations(String query) =>
      _guard(() => _remote.searchLocations(query));

  @override
  Future<Either<Failure, Location>> createLocation(Location location) =>
      _guard(() => _remote.createLocation(LocationModel.fromEntity(location)));

  @override
  Future<Either<Failure, Location>> updateLocation(Location location) =>
      _guard(() => _remote.updateLocation(LocationModel.fromEntity(location)));

  @override
  Future<Either<Failure, void>> deleteLocation(String id) =>
      _guard(() => _remote.deleteLocation(id));
}
