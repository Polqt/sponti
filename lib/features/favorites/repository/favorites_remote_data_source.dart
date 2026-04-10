import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/favorites/model/favorite_model.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

abstract interface class FavoritesRemoteDataSource {
  Future<List<FavoriteModel>> getFavorites();
  Future<void> addFavorite(String locationId);
  Future<void> removeFavorite(String locationId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  const FavoritesRemoteDataSourceImpl(this._client, this._locationRemote);

  final SupabaseClient _client;
  final LocationRemoteDataSource _locationRemote;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to manage favorites.');
    }
    return user.id;
  }

  Future<T> _executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<FavoriteModel>> getFavorites() => _executeQuery(() async {
        final response = await _client
            .from(SupabaseTables.favorites)
            .select('location_id, user_id, created_at, locations(*)')
            .eq('user_id', _userId)
            .order('created_at', ascending: false);

        return (response as List<dynamic>)
            .map((row) {
              final json = Map<String, dynamic>.from(row as Map);
              final locationJson = json['locations'];
              if (locationJson is Map<String, dynamic>) {
                json['locations'] = _locationRemote.resolvePhotoUrls(locationJson);
              }
              return FavoriteModel.fromJson(json);
            })
            .toList(growable: false);
      });

  @override
  Future<void> addFavorite(String locationId) => _executeQuery(() async {
        await _client.from(SupabaseTables.favorites).upsert(
          {'location_id': locationId, 'user_id': _userId},
          onConflict: 'location_id,user_id',
          ignoreDuplicates: true,
        );
      });

  @override
  Future<void> removeFavorite(String locationId) => _executeQuery(() async {
        await _client
            .from(SupabaseTables.favorites)
            .delete()
            .eq('user_id', _userId)
            .eq('location_id', locationId);
      });
}
