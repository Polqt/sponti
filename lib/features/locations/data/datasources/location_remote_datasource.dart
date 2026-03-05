import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/locations/data/models/location_model.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';

abstract interface class LocationRemoteDatasource {
  Future<List<LocationModel>> getLocations({
    LocationCategory? category,
    bool? hiddenGemsOnly,
    int page = 0,
    int pageSize = 20,
  });

  Future<LocationModel> getLocationById(String id);

  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });

  Future<List<LocationModel>> searchLocations(String query);
  Future<List<LocationModel>> getHiddenGems();
  Future<LocationModel> getRandomLocation({LocationCategory? category});
}

@LazySingleton(as: LocationRemoteDatasource)
class LocationRemoteDataSourceImpl implements LocationRemoteDatasource {
  const LocationRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  // Base query selecting all necessary fields from the locations table
  PostgrestFilterBuilder<List<Map<String, dynamic>>> get _baseQuery =>
      _client.from(SupabaseTables.locations).select('''
        id, name, description, category, latitude, longitude, address,
        landmark, price_range, photos, tags, rating, review_count,
        check_in_count, is_hidden_gem, is_verified, has_wifi,
        is_pet_friendly, has_parking, open_time, close_time, days_open,
        special_hours_note, contact_number, website_url, instagram_handle,
        created_at
      ''');

  // Implementation of getLocations with pagination,
  // filtering by category and hidden gems
  @override
  Future<List<LocationModel>> getLocations({
    LocationCategory? category,
    bool? hiddenGemsOnly,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _baseQuery;

      if (category != null) {
        query = query.eq('category', category.name);
      }
      if (hiddenGemsOnly == true) {
        query = query.eq('is_hidden_gem', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response.map(LocationModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch locations: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch locations: $e');
    }
  }

  @override
  Future<LocationModel> getLocationById(String id) async {
    try {
      final response = await _baseQuery.eq('id', id).single();
      return LocationModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw ServerException('Location not found');
      }
      throw ServerException('Failed to fetch location: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch location: $e');
    }
  }

  @override
  Future<List<LocationModel>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // For simplicity, we assume the RPC function uses the user's current location
      // to compute distances and return nearby locations. In a real implementation,
      // you would pass the latitude and longitude as parameters to the RPC function.
      final response = await _client.rpc(
        SupabaseRPC.getNearbyLocations,
        params: {},
      );
      return (response as List<dynamic>)
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch nearby locations: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch nearby locations: $e');
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      // For simplicity, we assume the RPC function performs a full-text search on the locations table.
      final response = await _client.rpc(
        SupabaseRPC.searchLocations,
        params: {'search_query': query},
      );

      return (response as List<dynamic>)
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Failed to search locations: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to search locations: $e');
    }
  }

  @override
  Future<List<LocationModel>> getHiddenGems() async {
    try {
      final response = await _baseQuery
          .eq('is_hidden_gem', true)
          .order('rating', ascending: false)
          .limit(20);

      return response.map(LocationModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LocationModel> getRandomLocation({LocationCategory? category}) async {
    try {
      var query = _client.from(SupabaseTables.locations).select();

      // Supabase doesn't support random ordering directly,
      // so we use a workaround by ordering by a random UUID
      if (category != null) {
        query = query.eq('category', category.name) as dynamic;
      }

      final response = await (query as PostgrestFilterBuilder)
          .order('created_at', ascending: false)
          .limit(50);

      final list =
          (response as List<dynamic>)
              .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
              .toList()
            ..shuffle();

      if (list.isEmpty) {
        throw NotFoundException('No locations found');
      }
      return list.first;
    } catch (e) {
      throw ServerException('Failed to fetch random location: $e');
    }
  }
}
