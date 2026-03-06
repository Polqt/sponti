import 'package:hive_flutter/adapters.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/errors/exceptions.dart';
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

@LazySingleton(as: LocationLocalDataSource)
class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  const LocationLocalDataSourceImpl();

  // Internal helpers
  // Opens (or returns already-open) hive box for locations.
  Future<Box<dynamic>> get _box async =>
      Hive.isBoxOpen(AppConstants.hiveBoxLocations)
      ? Hive.box(AppConstants.hiveBoxLocations)
      : await Hive.openBox(AppConstants.hiveBoxLocations);

  static const String _locationsKey = 'locations_list';
  static const String _cachedAtKey = 'cached_at';

  @override
  Future<List<LocationModel>> getCachedLocations() async {
    try {
      final box = await _box;

      final cachedAt = box.get(_cachedAtKey) as DateTime?;
      if (cachedAt == null) throw const CacheException('No cached data.');

      final isStale =
          DateTime.now().difference(cachedAt) > AppConstants.cacheExpiry;
      if (isStale) throw const CacheException('Cached data is stale.');

      final raw = box.get(_locationsKey) as List<dynamic>?;
      if (raw == null) throw const CacheException('No cached data.');

      return raw
          .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheLocations(List<LocationModel> locations) async {
    try {
      final box = await _box;
      final jsonList = locations.map((l) => l.toJson()).toList();
      await box.put(_locationsKey, jsonList);
      await box.put(_cachedAtKey, DateTime.now());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<LocationModel?> getCachedLocationById(String id) async {
    try {
      final locations = await getCachedLocations();
      return locations.firstWhere(
        (l) => l.id == id,
        orElse: () => throw const NotFoundException(),
      );
    } on CacheException {
      return null;
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _box;
      await box.delete(_locationsKey);
      await box.delete(_cachedAtKey);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
