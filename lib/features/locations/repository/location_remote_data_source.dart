import 'package:sponti/core/constants/api_constants.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class LocationRemoteDataSource {
  Future<List<LocationModel>> getAllLocations({int page, int pageSize});
  Future<LocationModel> getLocationById(String id);
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
  Future<List<LocationModel>> filterByCategory(LocationCategory category);
  Future<List<LocationModel>> searchLocations(String query);
  Future<LocationModel> createLocation(LocationModel model);
  Future<LocationModel> updateLocation(LocationModel model);
  Future<void> deleteLocation(String id);
}

const _columns = '''
  id, name, description, category, latitude, longitude, address,
  landmark, price_range, photos, tags, rating, review_count,
  check_in_count, is_hidden_gem, is_verified, has_wifi,
  is_pet_friendly, has_parking, open_time, close_time, days_open,
  special_hours_note, contact_number, website_url, instagram_handle,
  submitted_by, created_at, updated_at
''';

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  const LocationRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// Converts storage paths in [photos] JSONB to full public URLs.
  Map<String, dynamic> _resolvePhotoUrls(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];
    if (rawPhotos.isEmpty) return json;

    final resolved = rawPhotos.map((path) {
      final p = path.toString();
      if (p.startsWith('http')) return p;
      return _client.storage
          .from(ApiConstants.locationPhotosBucket)
          .getPublicUrl(p);
    }).toList();

    return {...json, 'photos': resolved};
  }

  @override
  Future<List<LocationModel>> getAllLocations({
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client
          .from(ApiConstants.locationsTable)
          .select(_columns)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (e) => LocationModel.fromJson(
              _resolvePhotoUrls(e as Map<String, dynamic>),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LocationModel> getLocationById(String id) async {
    try {
      final response = await _client
          .from(ApiConstants.locationsTable)
          .select(_columns)
          .eq('id', id)
          .single();

      return LocationModel.fromJson(_resolvePhotoUrls(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _client.rpc(
        ApiConstants.rpcGetNearbyLocations,
        params: {'lat': latitude, 'lng': longitude, 'radius_km': radiusKm},
      );

      return (response as List<dynamic>)
          .map(
            (e) => LocationModel.fromJson(
              _resolvePhotoUrls(e as Map<String, dynamic>),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<LocationModel>> filterByCategory(
    LocationCategory category,
  ) async {
    try {
      final response = await _client
          .from(ApiConstants.locationsTable)
          .select(_columns)
          .eq('category', category.name)
          .order('rating', ascending: false);

      return (response as List<dynamic>)
          .map(
            (e) => LocationModel.fromJson(
              _resolvePhotoUrls(e as Map<String, dynamic>),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      final response = await _client.rpc(
        ApiConstants.rpcSearchLocations,
        params: {'search_query': query.trim()},
      );

      return (response as List<dynamic>)
          .map(
            (e) => LocationModel.fromJson(
              _resolvePhotoUrls(e as Map<String, dynamic>),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LocationModel> createLocation(LocationModel model) async {
    try {
      final response = await _client
          .from(ApiConstants.locationsTable)
          .insert(model.toJson())
          .select(_columns)
          .single();

      return LocationModel.fromJson(_resolvePhotoUrls(response));
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LocationModel> updateLocation(LocationModel model) async {
    try {
      final response = await _client
          .from(ApiConstants.locationsTable)
          .update(
            model.toJson()..['updated_at'] = DateTime.now().toIso8601String(),
          )
          .eq('id', model.id)
          .select(_columns)
          .single();

      return LocationModel.fromJson(_resolvePhotoUrls(response));
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    try {
      await _client.from(ApiConstants.locationsTable).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
