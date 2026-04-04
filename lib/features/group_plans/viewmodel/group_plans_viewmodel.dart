import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/repository/group_plans_remote_data_source.dart';
import 'package:sponti/features/group_plans/repository/group_plans_repository.dart';
import 'package:sponti/features/group_plans/repository/group_plans_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final groupPlansRemoteDataSourceProvider = Provider<GroupPlansRemoteDataSource>(
  (ref) {
    return GroupPlansRemoteDataSourceImpl(Supabase.instance.client);
  },
);

final groupPlansRepositoryProvider = Provider<GroupPlansRepository>((ref) {
  return GroupPlansRepositoryImpl(
    ref.watch(groupPlansRemoteDataSourceProvider),
  );
});

/// State for a single group plan with votes and participants.
class GroupPlanDetailState {
  const GroupPlanDetailState({
    this.plan,
    this.participants = const [],
    this.votes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.userVote,
  });

  final GroupPlan? plan;
  final List<PlanParticipant> participants;
  final List<PlanVote> votes;
  final bool isLoading;
  final String? errorMessage;
  final PlanVote? userVote;

  GroupPlanDetailState copyWith({
    GroupPlan? plan,
    List<PlanParticipant>? participants,
    List<PlanVote>? votes,
    bool? isLoading,
    String? errorMessage,
    PlanVote? userVote,
    bool clearPlan = false,
    bool clearUserVote = false,
  }) => GroupPlanDetailState(
    plan: clearPlan ? null : (plan ?? this.plan),
    participants: participants ?? this.participants,
    votes: votes ?? this.votes,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    userVote: clearUserVote ? null : (userVote ?? this.userVote),
  );
}

/// Notifier for a single group plan detail page.
/// Pass the planId via the family parameter.
class GroupPlanDetailNotifier
    extends FamilyAsyncNotifier<GroupPlanDetailState, String> {
  @override
  Future<GroupPlanDetailState> build(String planId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const GroupPlanDetailState();

    final repo = ref.read(groupPlansRepositoryProvider);

    final results = await Future.wait([
      repo.getGroupPlan(planId),
      repo.getPlanParticipants(planId),
      repo.getPlanVotes(planId),
    ]);

    final plan = results[0].fold((_) => null, (v) => v as GroupPlan?);
    final participants = results[1].fold(
      (_) => <PlanParticipant>[],
      (v) => v as List<PlanParticipant>,
    );
    final votes = results[2].fold(
      (_) => <PlanVote>[],
      (v) => v as List<PlanVote>,
    );

    final userVote = votes
        .where((v) => v.userId == userId)
        .cast<PlanVote?>()
        .firstOrNull;

    return GroupPlanDetailState(
      plan: plan,
      participants: participants,
      votes: votes,
      userVote: userVote,
    );
  }

  Future<void> _refreshVotes() async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    final repo = ref.read(groupPlansRepositoryProvider);

    final result = await repo.getPlanVotes(arg);
    result.fold((failure) => null, (votes) {
      final userId = ref.read(currentUserIdProvider);
      final userVote = votes
          .where((v) => v.userId == userId)
          .cast<PlanVote?>()
          .firstOrNull;

      state = AsyncData(current.copyWith(votes: votes, userVote: userVote));
    });
  }

  Future<bool> vote(String locationId) async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final repo = ref.read(groupPlansRepositoryProvider);
    final result = await repo.vote(planId: arg, locationId: locationId);

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: failure.message),
        );
        return false;
      },
      (_) {
        _refreshVotes();
        return true;
      },
    );
  }

  Future<bool> decidePlan(String winningLocationId) async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final repo = ref.read(groupPlansRepositoryProvider);
    final result = await repo.decidePlan(
      planId: arg,
      winningLocationId: winningLocationId,
    );

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: failure.message),
        );
        return false;
      },
      (_) {
        ref.invalidate(groupPlanDetailProvider(arg));
        return true;
      },
    );
  }

  Future<bool> cancelPlan() async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final repo = ref.read(groupPlansRepositoryProvider);
    final result = await repo.cancelPlan(arg);

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: failure.message),
        );
        return false;
      },
      (_) {
        ref.invalidate(userGroupPlansProvider);
        return true;
      },
    );
  }

}

final groupPlanDetailProvider =
    AsyncNotifierProviderFamily<
      GroupPlanDetailNotifier,
      GroupPlanDetailState,
      String
    >(GroupPlanDetailNotifier.new);

/// Provider for user's created group plans.
final userGroupPlansProvider = FutureProvider<List<GroupPlan>>((ref) async {
  final result = await ref
      .read(groupPlansRepositoryProvider)
      .getUserGroupPlans();
  return result.fold(
    (failure) => throw StateError(failure.message),
    (plans) => plans,
  );
});

/// Compute vote counts per candidate location in a group plan.
/// Returns a map of locationId → vote count, derived from all cast votes.
final planVoteCountsProvider = Provider.family<Map<String, int>, String>((
  ref,
  planId,
) {
  final votes =
      ref.watch(groupPlanDetailProvider(planId)).valueOrNull?.votes ?? const [];
  final counts = <String, int>{};
  for (final vote in votes) {
    counts[vote.locationId] = (counts[vote.locationId] ?? 0) + 1;
  }
  return counts;
});

/// Distinct candidate location IDs in a group plan (all locations anyone has voted for).
final planCandidateIdsProvider = Provider.family<List<String>, String>((
  ref,
  planId,
) {
  final counts = ref.watch(planVoteCountsProvider(planId));
  return counts.keys.toList(growable: false);
});

/// Get the winning location ID (most votes). Null if no votes yet.
final planWinnerProvider = Provider.family<String?, String>((ref, planId) {
  final counts = ref.watch(planVoteCountsProvider(planId));
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
});
