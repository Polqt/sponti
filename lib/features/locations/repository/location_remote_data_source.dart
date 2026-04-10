import 'dart:async';
import 'dart:io';

import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/model/location_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class LocationRemoteDataSource {
  Future<List<LocationModel>> getAllLocations({int page, int pageSize});
  Future<LocationPage> getLocationsPage({
    LocationPageCursor? cursor,
    int limit,
  });
  Future<LocationModel> getLocationById(String id);
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
  Future<List<LocationModel>> filterByCategory(LocationCategory category);
  Future<List<LocationModel>> fetchByCategories(List<String> categories);
  Future<List<LocationModel>> searchLocations(String query);
  Future<List<LocationModel>> searchLocationsRanked(
    RankedLocationSearchRequest request,
  );
  Future<LocationModel> createLocation(LocationModel model);
  Future<LocationModel> updateLocation(LocationModel model);
  Future<void> deleteLocation(String id);
  Map<String, dynamic> resolvePhotoUrls(Map<String, dynamic> json);
}

const _defaultLocationsPageSize = 100;

const _columns = '''
  id, name, description, category, latitude, longitude, address,
  landmark, price_range, photos, tags, rating, review_count,
  check_in_count, is_hidden_gem, is_verified, has_wifi,
  is_pet_friendly, has_parking, open_time, close_time, days_open,
  special_hours_note, contact_number, website_url, instagram_handle,
  submitted_by, created_at, updated_at, is_seeded, seeded_at
''';

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  LocationRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// Cache for resolved photo URLs to avoid repeated Supabase storage calls.
  /// Key: storage path, Value: resolved public URL
  /// Limited to 500 entries to prevent unbounded memory growth.
  static const _maxCacheSize = 500;
  static final Map<String, String> _photoUrlCache = <String, String>{};

  void _trimCacheIfNeeded() {
    if (_photoUrlCache.length > _maxCacheSize) {
      // Remove oldest entries (first 100)
      final keysToRemove = _photoUrlCache.keys.take(100).toList();
      for (final key in keysToRemove) {
        _photoUrlCache.remove(key);
      }
    }
  }

  Future<T> _executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw ServerException(e.message);
    } on TimeoutException catch (e) {
      throw NetworkException(e.message ?? 'Request timed out.');
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on HttpException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  List<LocationModel> _parseLocationList(dynamic response) {
    return (response as List<dynamic>)
        .map(
          (e) => LocationModel.fromJson(
            resolvePhotoUrls(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// Converts storage paths in [photos] JSONB to full public URLs.
  /// Results are cached to avoid repeated Supabase storage API calls.
  @override
  Map<String, dynamic> resolvePhotoUrls(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];
    if (rawPhotos.isEmpty) return json;

    _trimCacheIfNeeded();

    final resolved = rawPhotos.map((path) {
      final p = path.toString();
      if (p.startsWith('http')) return p;

      // Check cache first
      return _photoUrlCache.putIfAbsent(
        p,
        () => _client.storage
            .from(SupabaseBuckets.locationPhotos)
            .getPublicUrl(p),
      );
    }).toList();

    return {...json, 'photos': resolved};
  }

  @override
  Future<List<LocationModel>> getAllLocations({
    int page = 0,
    int pageSize = _defaultLocationsPageSize,
  }) => _executeQuery(() async {
    final effectiveLimit = pageSize.clamp(1, 100).toInt();
    LocationPageCursor? cursor;
    var currentPage = 0;

    while (currentPage < page) {
      final skippedPage = await getLocationsPage(
        cursor: cursor,
        limit: effectiveLimit,
      );
      if (!skippedPage.hasMore || skippedPage.nextCursor == null) {
        return const <LocationModel>[];
      }
      cursor = skippedPage.nextCursor;
      currentPage++;
    }

    final pageResult = await getLocationsPage(cursor: cursor, limit: effectiveLimit);
    return pageResult.items.cast<LocationModel>();
  });

  @override
  Future<LocationPage> getLocationsPage({
    LocationPageCursor? cursor,
    int limit = 30,
  }) => _executeQuery(() async {
    final effectiveLimit = limit.clamp(1, 100).toInt();
    dynamic query = _client
        .from(SupabaseTables.locations)
        .select(_columns)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(effectiveLimit + 1);

    if (cursor != null) {
      query = query.or(_buildCursorFilter(cursor));
    }

    final response = await query;
    final rows = (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final hasMore = rows.length > effectiveLimit;
    final pageRows = hasMore ? rows.take(effectiveLimit).toList() : rows;
    final items = _parseLocationList(pageRows);
    final nextCursor = hasMore && pageRows.isNotEmpty
        ? LocationPageCursor(
            createdAt: DateTime.parse(pageRows.last['created_at'] as String).toUtc(),
            id: pageRows.last['id'] as String,
          )
        : null;

    return LocationPage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  });

  @override
  Future<LocationModel> getLocationById(String id) => _executeQuery(() async {
    final response = await _client
        .from(SupabaseTables.locations)
        .select(_columns)
        .eq('id', id)
        .single();

    return LocationModel.fromJson(resolvePhotoUrls(response));
  });

  @override
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) => _executeQuery(() async {
    final response = await _client.rpc(
      SupabaseRPC.getNearbyLocations,
      params: {'lat': latitude, 'lng': longitude, 'radius_km': radiusKm},
    );

    return _parseLocationList(response);
  });

  @override
  Future<List<LocationModel>> filterByCategory(LocationCategory category) =>
      _executeQuery(() async {
        final response = await _client
            .from(SupabaseTables.locations)
            .select(_columns)
            .eq('category', category.name)
            .order('rating', ascending: false);

        return _parseLocationList(response);
      });

  @override
  Future<List<LocationModel>> fetchByCategories(List<String> categories) =>
      _executeQuery(() async {
        final response = await _client
            .from(SupabaseTables.locations)
            .select(_columns)
            .inFilter('category', categories)
            .order('created_at', ascending: false);

        return _parseLocationList(response);
      });

  @override
  Future<List<LocationModel>> searchLocations(String query) =>
      _executeQuery(() async {
        final response = await _client.rpc(
          SupabaseRPC.searchLocations,
          params: {'search_query': query.trim()},
        );

        return _parseLocationList(response);
      });

  @override
  Future<List<LocationModel>> searchLocationsRanked(
    RankedLocationSearchRequest request,
  ) => _executeQuery(() async {
    final response = await _client.rpc(
      SupabaseRPC.searchLocationsRanked,
      params: {
        'search_query': request.query.trim(),
        'viewer_lat': request.latitude,
        'viewer_lng': request.longitude,
        'limit_count': request.limit,
      },
    );

    return _parseLocationList(response);
  });

  @override
  Future<LocationModel> createLocation(LocationModel model) =>
      _executeQuery(() async {
        final response = await _client
            .from(SupabaseTables.locations)
            .insert(model.toJson())
            .select(_columns)
            .single();

        return LocationModel.fromJson(resolvePhotoUrls(response));
      });

  @override
  Future<LocationModel> updateLocation(LocationModel model) =>
      _executeQuery(() async {
        final response = await _client
            .from(SupabaseTables.locations)
            .update(
              model.toJson()..['updated_at'] = DateTime.now().toIso8601String(),
            )
            .eq('id', model.id)
            .select(_columns)
            .single();

        return LocationModel.fromJson(resolvePhotoUrls(response));
      });

  @override
  Future<void> deleteLocation(String id) => _executeQuery(() async {
    await _client.from(SupabaseTables.locations).delete().eq('id', id);
  });

  String _buildCursorFilter(LocationPageCursor cursor) {
    final createdAt = cursor.createdAt.toUtc().toIso8601String();
    return 'created_at.lt.$createdAt,and(created_at.eq.$createdAt,id.lt.${cursor.id})';
  }
}
