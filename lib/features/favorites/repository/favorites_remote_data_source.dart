import 'package:sponti/core/constants/api_constants.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/favorites/model/favorite_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

abstract interface class FavoritesRemoteDataSource {
  Future<List<FavoriteModel>> getFavorites();
  Future<void> addFavorite(String locationId);
  Future<void> removeFavorite(String locationId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  const FavoritesRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to manage favorites.');
    }
    return user.id;
  }

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    try {
      final response = await _client
          .from(ApiConstants.favoritesTable)
          .select('location_id, user_id, created_at, locations(*)')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((row) => FavoriteModel.fromJson(row as Map<String, dynamic>))
          .toList(growable: false);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> addFavorite(String locationId) async {
    try {
      await _client.from(ApiConstants.favoritesTable).upsert({
        'location_id': locationId,
        'user_id': _userId,
      }, onConflict: 'location_id,user_id');
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFavorite(String locationId) async {
    try {
      await _client
          .from(ApiConstants.favoritesTable)
          .delete()
          .eq('user_id', _userId)
          .eq('location_id', locationId);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
