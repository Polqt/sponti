import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/models/group_plan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

abstract interface class GroupPlansRemoteDataSource {
  Future<GroupPlan> createGroupPlan({
    required String name,
    required String description,
  });

  Future<GroupPlan> getGroupPlan(String planId);

  Future<List<GroupPlan>> getUserGroupPlans();

  Future<void> addParticipant({required String planId, required String userId});

  Future<List<PlanParticipant>> getPlanParticipants(String planId);

  Future<void> respondToInvite({
    required String planId,
    required PlanParticipationStatus status,
  });

  Future<List<PlanLocationSuggestion>> getPlanSuggestions(String planId);

  Future<void> vote({required String planId, required String locationId});

  Future<List<PlanVote>> getPlanVotes(String planId);

  Future<void> decidePlan({
    required String planId,
    required String winningLocationId,
  });

  Future<void> cancelPlan(String planId);
}

class GroupPlansRemoteDataSourceImpl implements GroupPlansRemoteDataSource {
  const GroupPlansRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<GroupPlan> createGroupPlan({
    required String name,
    required String description,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException(
          'You must be signed in to create a group plan.',
        );
      }

      final model = GroupPlanModel(
        id: '',
        name: name,
        description: description,
        createdBy: userId,
        status: PlanStatus.voting,
        createdAt: DateTime.now(),
      );

      final response = await _client
          .from(SupabaseTables.groupPlans)
          .insert(model.toInsertJson())
          .select()
          .single();

      return GroupPlanModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<GroupPlan> getGroupPlan(String planId) async {
    try {
      final response = await _client
          .from(SupabaseTables.groupPlans)
          .select()
          .eq('id', planId)
          .single();

      return GroupPlanModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<GroupPlan>> getUserGroupPlans() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('You must be signed in to view group plans.');
      }

      // Fetch plans the user created OR participates in via a single OR filter.
      // RLS ensures only accessible rows are returned.
      final response = await _client
          .from(SupabaseTables.groupPlans)
          .select()
          .or(
            'created_by.eq.$userId,'
            'id.in.(${await _getParticipatedPlanIds(userId)})',
          )
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => GroupPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<String> _getParticipatedPlanIds(String userId) async {
    final rows = await _client
        .from(SupabaseTables.planParticipants)
        .select('plan_id')
        .eq('user_id', userId);
    final ids = (rows as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['plan_id'] as String)
        .toList(growable: false);
    // Supabase `.in_()` needs a non-empty list; return a dummy UUID if empty
    // so the OR clause is syntactically valid but matches nothing.
    return ids.isEmpty ? '00000000-0000-0000-0000-000000000000' : ids.join(',');
  }

  @override
  Future<void> addParticipant({
    required String planId,
    required String userId,
  }) async {
    try {
      final inviterId = _client.auth.currentUser?.id;
      if (inviterId == null) {
        throw const AuthException(
          'You must be signed in to invite participants.',
        );
      }

      final model = PlanParticipantModel(
        id: '',
        planId: planId,
        userId: userId,
        joinedAt: DateTime.now(),
        status: PlanParticipationStatus.pending,
        invitedBy: inviterId,
      );

      await _client
          .from(SupabaseTables.planParticipants)
          .insert(model.toInsertJson());
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PlanParticipant>> getPlanParticipants(String planId) async {
    try {
      final response = await _client
          .from(SupabaseTables.planParticipants)
          .select()
          .eq('plan_id', planId)
          .order('joined_at', ascending: true);

      return (response as List<dynamic>)
          .map((e) => PlanParticipantModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> respondToInvite({
    required String planId,
    required PlanParticipationStatus status,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException(
          'You must be signed in to respond to this invite.',
        );
      }

      await _client
          .from(SupabaseTables.planParticipants)
          .update({
            'status': status.name,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('plan_id', planId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PlanLocationSuggestion>> getPlanSuggestions(String planId) async {
    try {
      final response = await _client
          .from(SupabaseTables.planLocationSuggestions)
          .select()
          .eq('plan_id', planId)
          .order('suggested_at', ascending: true);

      return (response as List<dynamic>)
          .map(
            (item) => PlanLocationSuggestionModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> vote({
    required String planId,
    required String locationId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('You must be signed in to vote.');
      }

      final suggestion = PlanLocationSuggestionModel(
        id: '',
        planId: planId,
        locationId: locationId,
        suggestedBy: userId,
        suggestedAt: DateTime.now(),
      );

      try {
        await _client
            .from(SupabaseTables.planLocationSuggestions)
            .insert(suggestion.toInsertJson());
      } on PostgrestException catch (e) {
        final isDuplicateSuggestion =
            e.code == '23505' ||
            e.message.toLowerCase().contains('duplicate key value');
        if (!isDuplicateSuggestion) {
          throw ServerException(e.message);
        }
      }

      final model = PlanVoteModel(
        id: '',
        planId: planId,
        userId: userId,
        locationId: locationId,
        votedAt: DateTime.now(),
      );

      await _client
          .from(SupabaseTables.planVotes)
          .upsert(model.toInsertJson(), onConflict: 'plan_id,user_id');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PlanVote>> getPlanVotes(String planId) async {
    try {
      final response = await _client
          .from(SupabaseTables.planVotes)
          .select()
          .eq('plan_id', planId)
          .order('voted_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => PlanVoteModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> decidePlan({
    required String planId,
    required String winningLocationId,
  }) async {
    try {
      await _client
          .from(SupabaseTables.groupPlans)
          .update({
            'status': 'decided',
            'winning_location_id': winningLocationId,
          })
          .eq('id', planId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelPlan(String planId) async {
    try {
      await _client
          .from(SupabaseTables.groupPlans)
          .update({'status': 'cancelled'})
          .eq('id', planId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
