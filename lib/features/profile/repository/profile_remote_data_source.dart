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
    total_check_ins,
    created_at, updated_at
  ''';

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final profile = await _fetchProfile(userId);
      if (profile != null) {
        return profile;
      }

      await _createProfileIfMissing(userId);

      final repaired = await _fetchProfile(userId);
      if (repaired == null) throw const NotFoundException();

      return repaired;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserProfileModel?> _fetchProfile(String userId) async {
    final response = await _client
        .from(SupabaseTables.profiles)
        .select(_columns)
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfileModel.fromJson(response);
  }

  Future<void> _createProfileIfMissing(String userId) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null || authUser.id != userId) {
      return;
    }

    final meta = authUser.userMetadata ?? const <String, dynamic>{};
    final fullName =
        _metaString(meta, 'full_name') ?? _metaString(meta, 'name') ?? '';
    final avatarUrl =
        _metaString(meta, 'avatar_url') ?? _metaString(meta, 'picture') ?? '';

    await _client.from(SupabaseTables.profiles).upsert({
      'id': userId,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': '',
    }, onConflict: 'id');
  }

  String? _metaString(Map<String, dynamic> meta, String key) {
    final raw = meta[key];
    if (raw is! String) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
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
