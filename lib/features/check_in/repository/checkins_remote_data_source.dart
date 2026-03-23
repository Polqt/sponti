import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/models/checkins_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class CheckinsRemoteDataSource {
  Future<List<CheckIn>> getCheckInsForLocation(String locationId);
  Future<CheckIn> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    String? photoUrl,
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
          .select()
          .eq('location_id', locationId)
          .order('created_at', ascending: false);

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
    String? photoUrl,
  }) async {
    try {
      final payload = CheckInModel(
        id: '',
        locationId: locationId,
        userId: userId,
        note: note,
        photoUrl: photoUrl,
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
  Future<void> deleteCheckIn(String checkInId) async {
    try {
      await _client
          .from(SupabaseTables.checkIns)
          .delete()
          .eq('id', checkInId);
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
}
