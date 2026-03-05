import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/location.dart';

abstract interface class LocationRepository {
  // Fetch all locations with pagination
  Future<Either<Failure, List<Location>>> getAllLocations({
    int page = 0,
    int pageSize = 20,
  });

  // Fetch a single location by its ID
  Future<Either<Failure, Location>> getLocationById(String id);

  // Fetch locations near a specific latitude and longitude within a certain radius
  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });

  // Fetch locations that belong to a specific category
  Future<Either<Failure, List<Location>>> filterByCategory(
    LocationCategory category,
  );

  // Search for locations by name or description
  Future<Either<Failure, List<Location>>> searchLocations(String query);

  // Create a new location
  Future<Either<Failure, Location>> createLocation(Location location);

  // Update an existing location
  Future<Either<Failure, Location>> updateLocation(Location location);

  // Delete a location by its ID
  Future<Either<Failure, void>> deleteLocation(String id);
}
