import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/view/widgets/invite_friends_modal.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';

class GroupPlanAddLocationButton extends StatelessWidget {
  const GroupPlanAddLocationButton({
    required this.planId,
    required this.canParticipate,
    required this.isOnline,
    super.key,
  });

  final String planId;
  final bool canParticipate;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final isEnabled = canParticipate && isOnline;
    final backgroundColor = isEnabled
        ? SpontiColors.primary
        : SpontiColors.textMuted.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: isEnabled ? () => context.push(RouteName.searchVotePath(planId)) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_location_alt_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              !isOnline
                  ? 'Reconnect to participate'
                  : canParticipate
                      ? 'Search, suggest, and vote'
                      : 'Accept invite to participate',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupPlanBottomActions extends StatelessWidget {
  const GroupPlanBottomActions({
    required this.planId,
    required this.winner,
    required this.isLoading,
    required this.existingParticipantIds,
    required this.canManagePlan,
    required this.isOnline,
    required this.ref,
    required this.context,
    super.key,
  });

  final String planId;
  final String? winner;
  final bool isLoading;
  final Set<String> existingParticipantIds;
  final bool canManagePlan;
  final bool isOnline;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final actionsEnabled = canManagePlan && isOnline;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canManagePlan) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: actionsEnabled
                      ? () => InviteFriendsModal.show(
                            context,
                            planId: planId,
                            existingParticipantIds: existingParticipantIds,
                          )
                      : null,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text(
                    isOnline ? 'Invite Friends' : 'Invite Friends (Offline)',
                  ),
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
            ],
            if (canManagePlan && winner != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: actionsEnabled && !isLoading
                      ? () => ref
                            .read(groupPlanDetailProvider(planId).notifier)
                            .decidePlan(winner!)
                      : null,
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
            if (canManagePlan && winner != null) const SizedBox(height: 8),
            if (canManagePlan)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: actionsEnabled && !isLoading
                      ? () async {
                          final confirmed = await _confirmCancel(context);
                          if (confirmed) {
                            final ok = await ref
                                .read(groupPlanDetailProvider(planId).notifier)
                                .cancelPlan();
                            if (ok && context.mounted) {
                              context.pop();
                            }
                          }
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: SpontiColors.textMuted,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  child: Text(
                    isOnline ? 'Cancel this plan' : 'Cancel this plan (Offline)',
                  ),
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
