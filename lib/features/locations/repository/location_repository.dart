import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_query.dart';

abstract interface class LocationRepository {
  Future<Either<Failure, List<Location>>> getAllLocations({
    int page = 0,
    int pageSize = 1000,
  });
  Future<Either<Failure, LocationPage>> getLocationsPage({
    LocationPageCursor? cursor,
    int limit = 30,
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

  Future<Either<Failure, List<Location>>> fetchByCategories(
    List<String> categories,
  );

  Future<Either<Failure, List<Location>>> searchLocations(String query);
  Future<Either<Failure, List<Location>>> searchLocationsRanked(
    RankedLocationSearchRequest request,
  );
  Future<Either<Failure, Location>> createLocation(Location location);
  Future<Either<Failure, Location>> updateLocation(Location location);
  Future<Either<Failure, void>> deleteLocation(String id);
}
