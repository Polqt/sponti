import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/providers/connectivity_provider.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/repository/group_plans_remote_data_source.dart';
import 'package:sponti/features/group_plans/repository/group_plans_repository.dart';
import 'package:sponti/features/group_plans/repository/group_plans_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _offlinePlansMessage =
    'You are offline. Connect once to load your group plans.';
const _offlinePlanDetailMessage =
    'You are offline. Connect once to load this plan.';
const _offlineReadOnlyMessage =
    'You are offline. Group plans are read-only until the connection returns.';
const _genericGroupPlanErrorMessage =
    'Something went wrong while updating this group plan.';

final groupPlansRemoteDataSourceProvider = Provider<GroupPlansRemoteDataSource>(
  (ref) => GroupPlansRemoteDataSourceImpl(Supabase.instance.client),
);

final groupPlansRepositoryProvider = Provider<GroupPlansRepository>(
  (ref) => GroupPlansRepositoryImpl(
    ref.watch(groupPlansRemoteDataSourceProvider),
  ),
);

final _groupPlansCacheProvider =
    StateProvider<List<GroupPlan>>((ref) => const <GroupPlan>[]);

final _groupPlanDetailCacheProvider =
    StateProvider<Map<String, GroupPlanDetailState>>(
      (ref) => const <String, GroupPlanDetailState>{},
    );

String _friendlyGroupPlanErrorMessage(String message) {
  final normalized = message.trim();
  final lower = normalized.toLowerCase();

  if (lower.isEmpty) {
    return _genericGroupPlanErrorMessage;
  }

  if (lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('connection abort') ||
      lower.contains('software caused connection abort') ||
      lower.contains('failed host lookup')) {
    return _offlineReadOnlyMessage;
  }

  if (lower.contains('row-level security policy') ||
      lower.contains('new row violates row-level security policy')) {
    return 'You can only vote after joining the plan, and only on locations available to the group.';
  }

  return normalized;
}

class GroupPlanDetailState {
  const GroupPlanDetailState({
    this.plan,
    this.participants = const [],
    this.suggestions = const [],
    this.votes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.userVote,
  });

  final GroupPlan? plan;
  final List<PlanParticipant> participants;
  final List<PlanLocationSuggestion> suggestions;
  final List<PlanVote> votes;
  final bool isLoading;
  final String? errorMessage;
  final PlanVote? userVote;

  PlanParticipant? participantForUser(String? userId) {
    if (userId == null) return null;
    return participants
        .where((participant) => participant.userId == userId)
        .cast<PlanParticipant?>()
        .firstOrNull;
  }

  GroupPlanDetailState copyWith({
    GroupPlan? plan,
    List<PlanParticipant>? participants,
    List<PlanLocationSuggestion>? suggestions,
    List<PlanVote>? votes,
    bool? isLoading,
    String? errorMessage,
    PlanVote? userVote,
    bool clearPlan = false,
    bool clearUserVote = false,
  }) {
    return GroupPlanDetailState(
      plan: clearPlan ? null : (plan ?? this.plan),
      participants: participants ?? this.participants,
      suggestions: suggestions ?? this.suggestions,
      votes: votes ?? this.votes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userVote: clearUserVote ? null : (userVote ?? this.userVote),
    );
  }
}

class GroupPlanDetailNotifier
    extends FamilyAsyncNotifier<GroupPlanDetailState, String> {
  @override
  Future<GroupPlanDetailState> build(String planId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const GroupPlanDetailState();

    return _loadPlanDetail(planId, userId);
  }

  Future<GroupPlanDetailState> _loadPlanDetail(
    String planId,
    String userId,
  ) async {
    final cached = _cachedDetail(planId);
    final isConnected = await ref.read(isConnectedProvider.future);

    if (!isConnected) {
      if (cached != null) {
        return cached.copyWith(errorMessage: _offlineReadOnlyMessage);
      }
      throw StateError(_offlinePlanDetailMessage);
    }

    final repo = ref.read(groupPlansRepositoryProvider);
    final results = await Future.wait([
      repo.getGroupPlan(planId),
      repo.getPlanParticipants(planId),
      repo.getPlanSuggestions(planId),
      repo.getPlanVotes(planId),
    ]);

    final plan = results[0].fold((_) => null, (value) => value as GroupPlan?);
    final participants = results[1].fold(
      (_) => <PlanParticipant>[],
      (value) => value as List<PlanParticipant>,
    );
    final suggestions = results[2].fold(
      (_) => <PlanLocationSuggestion>[],
      (value) => value as List<PlanLocationSuggestion>,
    );
    final votes = results[3].fold(
      (_) => <PlanVote>[],
      (value) => value as List<PlanVote>,
    );

    final detailState = GroupPlanDetailState(
      plan: plan,
      participants: participants,
      suggestions: suggestions,
      votes: votes,
      userVote: _findUserVote(votes, userId),
    );

    _cacheDetail(planId, detailState);
    return detailState;
  }

  GroupPlanDetailState? _cachedDetail(String planId) {
    return ref.read(_groupPlanDetailCacheProvider)[planId];
  }

  void _cacheDetail(String planId, GroupPlanDetailState detailState) {
    ref.read(_groupPlanDetailCacheProvider.notifier).update(
      (state) => <String, GroupPlanDetailState>{
        ...state,
        planId: detailState,
      },
    );
  }

  Future<bool> _ensureConnected(String message) async {
    final isConnected = await ref.read(isConnectedProvider.future);
    if (isConnected) return true;

    final current = state.valueOrNull ?? const GroupPlanDetailState();
    state = AsyncData(
      current.copyWith(
        isLoading: false,
        errorMessage: message,
      ),
    );
    return false;
  }

  PlanVote? _findUserVote(List<PlanVote> votes, String? userId) {
    if (userId == null) return null;
    return votes
        .where((vote) => vote.userId == userId)
        .cast<PlanVote?>()
        .firstOrNull;
  }

  Future<void> _refreshPlanDetail() async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final refreshed = await _loadPlanDetail(arg, userId);
      state = AsyncData(
        refreshed.copyWith(
          isLoading: false,
          errorMessage: refreshed.errorMessage ?? current.errorMessage,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          errorMessage: current.errorMessage,
        ),
      );
    }
  }

  Future<bool> vote(String locationId) async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    final userId = ref.read(currentUserIdProvider);
    final plan = current.plan;
    final participant = current.participantForUser(userId);
    final canVote =
        plan != null &&
        (plan.createdBy == userId || participant?.isAccepted == true);

    if (!canVote) {
      state = AsyncData(
        current.copyWith(
          errorMessage:
              'Accept the invite first before suggesting or voting on locations.',
        ),
      );
      return false;
    }

    if (!await _ensureConnected(_offlineReadOnlyMessage)) {
      return false;
    }

    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref
        .read(groupPlansRepositoryProvider)
        .vote(planId: arg, locationId: locationId);

    if (result.isLeft()) {
      final failure = result.swap().getOrElse(
        () => throw StateError('Vote failed.'),
      );
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          errorMessage: _friendlyGroupPlanErrorMessage(failure.message),
        ),
      );
      return false;
    }

    await _refreshPlanDetail();
    return true;
  }

  Future<bool> respondToInvite(PlanParticipationStatus status) async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    if (!await _ensureConnected(_offlineReadOnlyMessage)) {
      return false;
    }

    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref
        .read(groupPlansRepositoryProvider)
        .respondToInvite(planId: arg, status: status);

    if (result.isLeft()) {
      final failure = result.swap().getOrElse(
        () => throw StateError('Invite response failed.'),
      );
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          errorMessage: _friendlyGroupPlanErrorMessage(failure.message),
        ),
      );
      return false;
    }

    ref.invalidate(userGroupPlansProvider);
    await _refreshPlanDetail();
    return true;
  }

  Future<bool> decidePlan(String winningLocationId) async {
    final current = state.valueOrNull ?? const GroupPlanDetailState();
    if (!await _ensureConnected(_offlineReadOnlyMessage)) {
      return false;
    }

    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref.read(groupPlansRepositoryProvider).decidePlan(
          planId: arg,
          winningLocationId: winningLocationId,
        );

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(
            isLoading: false,
            errorMessage: _friendlyGroupPlanErrorMessage(failure.message),
          ),
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
    if (!await _ensureConnected(_offlineReadOnlyMessage)) {
      return false;
    }

    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref.read(groupPlansRepositoryProvider).cancelPlan(arg);

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(
            isLoading: false,
            errorMessage: _friendlyGroupPlanErrorMessage(failure.message),
          ),
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

final groupPlanDetailProvider = AsyncNotifierProviderFamily<
  GroupPlanDetailNotifier,
  GroupPlanDetailState,
  String
>(GroupPlanDetailNotifier.new);

final userGroupPlansProvider = FutureProvider<List<GroupPlan>>((ref) async {
  final cachedPlans = ref.read(_groupPlansCacheProvider);
  final isConnected = await ref.read(isConnectedProvider.future);

  if (!isConnected) {
    if (cachedPlans.isNotEmpty) return cachedPlans;
    throw StateError(_offlinePlansMessage);
  }

  final result = await ref.read(groupPlansRepositoryProvider).getUserGroupPlans();
  return result.fold((failure) {
    if (cachedPlans.isNotEmpty) {
      return cachedPlans;
    }
    throw StateError(failure.message);
  }, (plans) {
    ref.read(_groupPlansCacheProvider.notifier).state = plans;
    return plans;
  });
});

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

final planCandidateIdsProvider = Provider.family<List<String>, String>((
  ref,
  planId,
) {
  final detail = ref.watch(groupPlanDetailProvider(planId)).valueOrNull;
  final orderedIds = <String>[];
  final seenIds = <String>{};

  for (final suggestion
      in detail?.suggestions ?? const <PlanLocationSuggestion>[]) {
    if (seenIds.add(suggestion.locationId)) {
      orderedIds.add(suggestion.locationId);
    }
  }

  for (final vote in detail?.votes ?? const <PlanVote>[]) {
    if (seenIds.add(vote.locationId)) {
      orderedIds.add(vote.locationId);
    }
  }

  return List.unmodifiable(orderedIds);
});

final planWinnerProvider = Provider.family<String?, String>((ref, planId) {
  final counts = ref.watch(planVoteCountsProvider(planId));
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
});
