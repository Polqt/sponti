import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/view/widgets/vote_card.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';
import 'package:sponti/features/friends/view/widgets/invite_friends_modal.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class GroupPlanDetailScreen extends ConsumerWidget {
  const GroupPlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(groupPlanDetailProvider(planId));
    final voteCounts = ref.watch(planVoteCountsProvider(planId));
    final candidateIds = ref.watch(planCandidateIdsProvider(planId));
    final winner = ref.watch(planWinnerProvider(planId));
    final totalVotes = voteCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: SpontiColors.primary),
          ),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: SpontiColors.error),
            ),
          ),
          data: (state) {
            final plan = state.plan;
            if (plan == null) {
              return const Center(child: Text('Plan not found'));
            }

            return Column(
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: SpontiColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _StatusRow(plan: plan, participantCount: state.participants.length),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (plan.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      plan.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SpontiColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // ── Body ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Voting section
                        if (plan.status == PlanStatus.voting) ...[
                          _SectionLabel(
                            icon: Icons.how_to_vote_rounded,
                            label: candidateIds.isEmpty
                                ? 'Be the first to vote'
                                : '${candidateIds.length} location${candidateIds.length == 1 ? '' : 's'} nominated',
                          ),
                          const SizedBox(height: 10),
                          if (candidateIds.isEmpty)
                            _EmptyVoteHint(planId: planId)
                          else
                            ...candidateIds.map(
                              (locationId) => VoteCard(
                                locationId: locationId,
                                voteCount: voteCounts[locationId] ?? 0,
                                totalVotes: totalVotes,
                                isUserVote:
                                    state.userVote?.locationId == locationId,
                                isWinner: winner == locationId,
                                onVote: () => ref
                                    .read(groupPlanDetailProvider(planId).notifier)
                                    .vote(locationId),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Add location button
                          _AddLocationButton(planId: planId),
                        ],
                        // Decided banner
                        if (plan.status == PlanStatus.decided)
                          _DecidedBanner(
                            winningLocationId: plan.winningLocationId,
                          ),
                        // Cancelled banner
                        if (plan.status == PlanStatus.cancelled)
                          _CancelledBanner(),
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SpontiColors.error.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: SpontiColors.error.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: SpontiColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // ── Bottom actions ───────────────────────────
                if (plan.status == PlanStatus.voting)
                  _BottomActions(
                    planId: planId,
                    winner: winner,
                    isLoading: state.isLoading,
                    existingParticipantIds:
                        state.participants.toIdSet(),
                    ref: ref,
                    context: context,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.plan, required this.participantCount});

  final GroupPlan plan;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(plan.status);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusStyle.$1.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusStyle.$2,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusStyle.$1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.people_alt_rounded,
          size: 12,
          color: SpontiColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          '$participantCount',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: SpontiColors.textMuted,
          ),
        ),
      ],
    );
  }

  (Color, String) _statusStyle(PlanStatus s) => switch (s) {
    PlanStatus.voting => (SpontiColors.info, 'Voting open'),
    PlanStatus.decided => (SpontiColors.success, 'Decided'),
    PlanStatus.cancelled => (SpontiColors.error, 'Cancelled'),
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: SpontiColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: SpontiColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EmptyVoteHint extends StatelessWidget {
  const _EmptyVoteHint({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SpontiColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SpontiColors.info.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            'No locations yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search for a spot and tap it to add your vote.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: SpontiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLocationButton extends StatelessWidget {
  const _AddLocationButton({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteName.searchVotePath(planId)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SpontiColors.outline,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_location_alt_rounded,
              size: 18,
              color: SpontiColors.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Search & vote for a location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SpontiColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.planId,
    required this.winner,
    required this.isLoading,
    required this.existingParticipantIds,
    required this.ref,
    required this.context,
  });

  final String planId;
  final String? winner;
  final bool isLoading;
  final Set<String> existingParticipantIds;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => InviteFriendsModal.show(
                  context,
                  planId: planId,
                  existingParticipantIds: existingParticipantIds,
                ),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Invite Friends'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SpontiColors.secondary,
                  side: const BorderSide(color: SpontiColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (winner != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(groupPlanDetailProvider(planId).notifier)
                            .decidePlan(winner!),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Lock in the winner'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SpontiColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            if (winner != null) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final confirmed = await _confirmCancel(context);
                        if (confirmed) {
                          final ok = await ref
                              .read(groupPlanDetailProvider(planId).notifier)
                              .cancelPlan();
                          if (ok && context.mounted) context.pop();
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: SpontiColors.textMuted,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Cancel this plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmCancel(BuildContext ctx) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Cancel plan?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: const Text(
              'This cannot be undone. Everyone in the plan will lose their votes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep it'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: SpontiColors.error,
                ),
                child: const Text('Yes, cancel'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _DecidedBanner extends ConsumerWidget {
  const _DecidedBanner({required this.winningLocationId});

  final String? winningLocationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = winningLocationId != null
        ? ref
              .watch(locationDetailProvider(winningLocationId!))
              .valueOrNull
              ?.name
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpontiColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpontiColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: SpontiColors.success,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You're going here!",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: SpontiColors.success,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locationName ?? winningLocationId ?? '—',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: SpontiColors.textPrimary,
            ),
          ),
          if (winningLocationId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  RouteName.locationDetailPath(winningLocationId!),
                ),
                icon: const Icon(Icons.place_rounded, size: 16),
                label: const Text('View location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SpontiColors.success,
                  side: BorderSide(
                    color: SpontiColors.success.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpontiColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpontiColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SpontiColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: SpontiColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan cancelled',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SpontiColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This plan was cancelled and is no longer active.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SpontiColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
