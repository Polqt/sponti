import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/model/location.dart';

abstract interface class LocationRepository {
  Future<Either<Failure, List<Location>>> getAllLocations({
    int page = 0,
    int pageSize = 20,
  });

  Future<Either<Failure, Location>> getLocationById(String id);

  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });

  Future<Either<Failure, List<Location>>> filterByCategory(
    LocationCategory category,
  );

  Future<Either<Failure, List<Location>>> searchLocations(String query);
  Future<Either<Failure, Location>> createLocation(Location location);
  Future<Either<Failure, Location>> updateLocation(Location location);
  Future<Either<Failure, void>> deleteLocation(String id);
}
