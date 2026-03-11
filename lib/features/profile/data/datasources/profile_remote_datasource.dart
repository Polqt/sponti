import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/profile/data/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String userId);
  Future<UserStatsModel> getUserStats(String userId);
  Future<UserProfileModel> updateProfile(UserProfileModel model);
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  });
}

@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);
  final SupabaseClient _client;

  static const _columns = ''' 
    id, full_name, username, bio, avatar_url,
    check_in_count, favorites_count, spots_suggested,
    created_at, updated_at
  ''';

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from(SupabaseTables.profiles)
          .select(_columns)
          .eq('id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == "PGRST116") throw const NotFoundException();
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserStatsModel> getUserStats(String userId) async {
    try {
      // Uses the get_user_stats RPC defined in the migration
      final response = await _client.rpc(
        SupabaseRPC.getUserStats,
        params: {'user_id': userId},
      );

      // The RPC returns a list, but we expect only one item (or none)
      final data = (response as List<dynamic>).isNotEmpty
          ? response.first as Map<String, dynamic>
          : <String, dynamic>{};

      return UserStatsModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfileModel> updateProfile(UserProfileModel model) async {
    try {
      // Update the profile in the database
      final response = await _client
          .from(SupabaseTables.profiles)
          .update(
            model.toJson()..['updated_at'] = DateTime.now().toIso8601String(),
          )
          .eq('id', model.id)
          .select(_columns)
          .single();

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final path = '$userId/avatar.$extension';

      // Upload the image to Supabase Storage
      await _client.storage
          .from(SupabaseBuckets.avatars)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );

      // Get the public URL of the uploaded image
      final url = _client.storage
          .from(SupabaseBuckets.avatars)
          .getPublicUrl(path);

      // Bust the cache by appending a timestamp query
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
