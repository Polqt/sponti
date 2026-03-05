import 'package:hive_flutter/adapters.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/features/locations/data/models/location_model.dart';

abstract interface class LocationLocalDataSource {
  // Returns cached locations.
  Future<List<LocationModel>> getCachedLocations();

  // Persist locations to local cache.
  Future<void> cacheLocations(List<LocationModel> locations);

  // Returns a single cached location by ID.
  Future<LocationModel?> getCachedLocationById(String id);

  // Clears all cached locations.
  Future<void> clearCache();
}

@LazySingleton()(as: LocationLocalDataSource)
class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  const LocationLocalDataSourceImpl();

  // Internal helpers
  // Opens (or returns already-open) hive box for locations.
  Future<Box<dynamic>> get _box async =>
    Hive.isBoxOpen(AppConst)
}
