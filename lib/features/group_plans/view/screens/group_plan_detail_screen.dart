import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/providers/connectivity_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/friends/view/widgets/invite_friends_modal.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_detail_actions.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_detail_invite_widgets.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_detail_result_banners.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_detail_sections.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_offline_banner.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_page_header.dart';
import 'package:sponti/features/group_plans/view/widgets/vote_card.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';

class GroupPlanDetailScreen extends ConsumerWidget {
  const GroupPlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(groupPlanDetailProvider(planId));
    final voteCounts = ref.watch(planVoteCountsProvider(planId));
    final candidateIds = ref.watch(planCandidateIdsProvider(planId));
    final winner = ref.watch(planWinnerProvider(planId));
    final totalVotes = voteCounts.values.fold(0, (sum, value) => sum + value);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

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

            final currentParticipant = state.participantForUser(currentUserId);
            final isCreator = currentUserId == plan.createdBy;
            final canRespondToInvite =
                plan.status == PlanStatus.voting &&
                currentParticipant?.isPending == true;
            final hasDeclinedInvite = currentParticipant?.isDeclined == true;
            final canParticipate =
                plan.status == PlanStatus.voting &&
                (isCreator || currentParticipant?.isAccepted == true);
            final canVote = isOnline && canParticipate;
            final acceptedParticipantCount =
                state.participants
                    .where((participant) => participant.isAccepted)
                    .length +
                1;
            final errorMessage = state.errorMessage;
            final shouldShowInlineError =
                errorMessage != null &&
                !(!isOnline &&
                    errorMessage.toLowerCase().contains(
                      'group plans are read-only until the connection returns',
                    ));

            return Column(
              children: [
                GroupPlanPageHeader(title: plan.name),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GroupPlanStatusRow(
                      plan: plan,
                      acceptedParticipantCount: acceptedParticipantCount,
                      invitedParticipantCount: state.participants.length,
                    ),
                  ),
                ),
                if (!isOnline)
                  const GroupPlanOfflineBanner(
                    message:
                        'You are offline. Group plan details are read-only until the connection returns.',
                  ),
                if (plan.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        plan.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SpontiColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canRespondToInvite) ...[
                          GroupPlanInviteResponseCard(
                            isLoading: state.isLoading,
                            isEnabled: isOnline,
                            onAccept: () => ref
                                .read(groupPlanDetailProvider(planId).notifier)
                                .respondToInvite(
                                  PlanParticipationStatus.accepted,
                                ),
                            onDecline: () => ref
                                .read(groupPlanDetailProvider(planId).notifier)
                                .respondToInvite(
                                  PlanParticipationStatus.declined,
                                ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (hasDeclinedInvite) ...[
                          const GroupPlanInfoBanner(
                            icon: Icons.block_rounded,
                            title: 'Invite declined',
                            subtitle:
                                'You declined this plan invite, so voting is disabled for you.',
                            color: SpontiColors.error,
                          ),
                          const SizedBox(height: 16),
                        ] else if (!isCreator &&
                            currentParticipant?.isAccepted == true) ...[
                          const GroupPlanInfoBanner(
                            icon: Icons.verified_rounded,
                            title: 'You joined the plan',
                            subtitle:
                                'You can suggest another spot and vote on the current options.',
                            color: SpontiColors.success,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (plan.status == PlanStatus.voting) ...[
                          GroupPlanSectionLabel(
                            icon: Icons.how_to_vote_rounded,
                            label: !isOnline
                                ? 'Reconnect to suggest or vote'
                                : !canParticipate
                                ? 'Voting opens after you accept the invite'
                                : candidateIds.isEmpty
                                ? 'Be the first to vote'
                                : '${candidateIds.length} location${candidateIds.length == 1 ? '' : 's'} nominated',
                          ),
                          const SizedBox(height: 12),
                          if (candidateIds.isEmpty)
                            GroupPlanEmptyVoteHint(
                              isOnline: isOnline,
                              canParticipate: canParticipate,
                            )
                          else
                            ...candidateIds.map(
                              (locationId) => VoteCard(
                                locationId: locationId,
                                voteCount: voteCounts[locationId] ?? 0,
                                totalVotes: totalVotes,
                                isUserVote:
                                    state.userVote?.locationId == locationId,
                                isWinner: winner == locationId,
                                isVotingEnabled: canVote,
                                onVote: canVote
                                    ? () => ref
                                          .read(
                                            groupPlanDetailProvider(
                                              planId,
                                            ).notifier,
                                          )
                                          .vote(locationId)
                                    : null,
                              ),
                            ),
                          const SizedBox(height: 16),
                          GroupPlanAddLocationButton(
                            planId: planId,
                            canParticipate: canParticipate,
                            isOnline: isOnline,
                          ),
                          if (shouldShowInlineError)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _ErrorCard(message: errorMessage),
                            ),
                        ],
                        if (plan.status == PlanStatus.decided) ...[
                          GroupPlanDecidedBanner(
                            winningLocationId: plan.winningLocationId,
                          ),
                          if (shouldShowInlineError)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _ErrorCard(message: errorMessage),
                            ),
                        ],
                        if (plan.status == PlanStatus.cancelled) ...[
                          const GroupPlanCancelledBanner(),
                          if (shouldShowInlineError)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _ErrorCard(message: errorMessage),
                            ),
                        ],
                        if (state.participants.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const GroupPlanSectionLabel(
                            icon: Icons.group_rounded,
                            label: 'Invite progress',
                          ),
                          const SizedBox(height: 12),
                          GroupPlanParticipantStatusSummary(
                            participants: state.participants,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (plan.status == PlanStatus.voting)
                  GroupPlanBottomActions(
                    planId: planId,
                    winner: winner,
                    isLoading: state.isLoading,
                    existingParticipantIds: state.participants.toIdSet(),
                    canManagePlan: isCreator,
                    isOnline: isOnline,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SpontiColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SpontiColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: SpontiColors.error, fontSize: 13),
      ),
    );
  }
}
