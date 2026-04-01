import 'package:hive_flutter/adapters.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/locations/model/location_model.dart';

abstract interface class LocationLocalDataSource {
  Future<List<LocationModel>> getCachedLocations();
  Future<void> cacheLocations(List<LocationModel> locations);
  Future<LocationModel?> getCachedLocationById(String id);
  Future<void> clearCache();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  const LocationLocalDataSourceImpl();

  Future<Box<dynamic>> get _box async =>
      Hive.isBoxOpen(AppConstants.hiveBoxLocations)
      ? Hive.box(AppConstants.hiveBoxLocations)
      : Hive.openBox(AppConstants.hiveBoxLocations);

  static const String _locationsKey = 'locations_list';
  static const String _indexKey = 'locations_index';
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

      // Build index map for O(1) lookups: {id: position}
      final index = <String, int>{};
      for (var i = 0; i < locations.length; i++) {
        index[locations[i].id] = i;
      }

      await box.put(_locationsKey, jsonList);
      await box.put(_indexKey, index);
      await box.put(_cachedAtKey, DateTime.now());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<LocationModel?> getCachedLocationById(String id) async {
    try {
      final box = await _box;

      final cachedAt = box.get(_cachedAtKey) as DateTime?;
      if (cachedAt == null) return null;

      final isStale =
          DateTime.now().difference(cachedAt) > AppConstants.cacheExpiry;
      if (isStale) return null;

      // Use index for O(1) lookup
      final index = box.get(_indexKey) as Map<dynamic, dynamic>?;
      final raw = box.get(_locationsKey) as List<dynamic>?;

      if (index == null || raw == null) return null;

      final position = index[id] as int?;
      if (position == null || position >= raw.length) return null;

      return LocationModel.fromJson(
        Map<String, dynamic>.from(raw[position] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _box;
      await box.delete(_locationsKey);
      await box.delete(_indexKey);
      await box.delete(_cachedAtKey);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
