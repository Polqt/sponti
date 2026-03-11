import 'dart:typed_data';

import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';
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
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserStatsModel> getUserStats(String userId) async {
    try {
      final response = await _client.rpc(
        SupabaseRPC.getUserStats,
        params: {'user_id': userId},
      );

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

      await _client.storage.from(SupabaseBuckets.avatars).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: true,
        ),
      );

      final url = _client.storage.from(SupabaseBuckets.avatars).getPublicUrl(
        path,
      );

      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
