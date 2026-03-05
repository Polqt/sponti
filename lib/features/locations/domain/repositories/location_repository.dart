import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';

abstract interface class LocationRepository {
  // Fetch all locations
  Future<Either<Failures, List<Location>>> getLocations({
    LocationCategory? category,
    bool? hiddenGemsOnly,
    int page = 0,
    int pageSize = 20,
  });

  // Fetch a single location by ID
  Future<Either<Failures, Location>> getLocationById(String id);

  // Location within [radiusKm] of coords
  Future<Either<Failures, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });

  // Full text + tag
  Future<Either<Failures, List<Location>>> searchLocations(String query);

  // Curated list of hidden gems
  Future<Either<Failures, List<Location>>> getHiddenGems();

  // Get a random location, optionally filtered by category
  Future<Either<Failures, Location>> getRandomLocation({
    LocationCategory? category,
  });
}
