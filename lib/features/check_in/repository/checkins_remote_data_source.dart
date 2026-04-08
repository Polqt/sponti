import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/models/checkins_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

abstract interface class CheckinsRemoteDataSource {
  Future<List<CheckIn>> getCheckInsForLocation(String locationId);
  Future<CheckInPage> getMyCheckInsPage({
    CheckInPageCursor? cursor,
    int limit = 30,
  });
  Future<CheckIn> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    List<String> photos = const [],
  });
  Future<CheckIn> updateCheckIn({
    required String checkInId,
    String? note,
    List<String> photos = const [],
  });
  Future<void> deleteCheckIn(String checkInId);
  Future<bool> hasUserCheckedIn(String locationId, String userId);
}

class CheckinsRemoteDataSourceImpl implements CheckinsRemoteDataSource {
  const CheckinsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CheckIn>> getCheckInsForLocation(String locationId) async {
    try {
      final response = await _client
          .from(SupabaseTables.checkIns)
          .select(_selectColumns)
          .eq('location_id', locationId)
          .order('created_at', ascending: false)
          .order('id', ascending: false);

      return (response as List<dynamic>)
          .map((e) => CheckInModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CheckIn> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    List<String> photos = const [],
  }) async {
    try {
      final payload = CheckInModel(
        id: '',
        locationId: locationId,
        userId: userId,
        note: note,
        photos: photos,
        createdAt: DateTime.now(),
      ).toInsertJson();

      final response = await _client
          .from(SupabaseTables.checkIns)
          .insert(payload)
          .select()
          .single();

      return CheckInModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CheckInPage> getMyCheckInsPage({
    CheckInPageCursor? cursor,
    int limit = 30,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('You must be signed in to view check-ins.');
      }

      final effectiveLimit = limit.clamp(1, 100).toInt();
      dynamic query = _client
          .from(SupabaseTables.checkIns)
          .select(_selectColumns)
          .eq('user_id', userId)
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
      final items = pageRows
          .map((row) => CheckInModel.fromJson(row))
          .toList(growable: false);
      final nextCursor = hasMore && pageRows.isNotEmpty
          ? CheckInPageCursor(
              createdAt: DateTime.parse(pageRows.last['created_at'] as String)
                  .toUtc(),
              id: pageRows.last['id'] as String,
            )
          : null;

      return CheckInPage(items: items, hasMore: hasMore, nextCursor: nextCursor);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CheckIn> updateCheckIn({
    required String checkInId,
    String? note,
    List<String> photos = const [],
  }) async {
    try {
      final payload = <String, dynamic>{
        'note': note ?? '',
        'photos': photos,
        'photo_url': photos.isEmpty ? null : photos.first,
      };

      final response = await _client
          .from(SupabaseTables.checkIns)
          .update(payload)
          .eq('id', checkInId)
          .select()
          .single();

      return CheckInModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteCheckIn(String checkInId) async {
    try {
      await _client.from(SupabaseTables.checkIns).delete().eq('id', checkInId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> hasUserCheckedIn(String locationId, String userId) async {
    try {
      final response = await _client
          .from(SupabaseTables.checkIns)
          .select('id')
          .eq('location_id', locationId)
          .eq('user_id', userId)
          .limit(1);

      return (response as List<dynamic>).isNotEmpty;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _buildCursorFilter(CheckInPageCursor cursor) {
    final createdAt = cursor.createdAt.toUtc().toIso8601String();
    return 'created_at.lt.$createdAt,and(created_at.eq.$createdAt,id.lt.${cursor.id})';
  }
}
  const _selectColumns = '''
    id, location_id, user_id, note, photos, photo_url, created_at
  ''';
