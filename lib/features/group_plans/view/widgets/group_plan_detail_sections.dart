import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';

class GroupPlanStatusRow extends StatelessWidget {
  const GroupPlanStatusRow({
    required this.plan,
    required this.acceptedParticipantCount,
    required this.invitedParticipantCount,
    super.key,
  });

  final GroupPlan plan;
  final int acceptedParticipantCount;
  final int invitedParticipantCount;

  @override
  Widget build(BuildContext context) {
    final statusStyle = switch (plan.status) {
      PlanStatus.voting => (SpontiColors.info, 'Voting open'),
      PlanStatus.decided => (SpontiColors.success, 'Decided'),
      PlanStatus.cancelled => (SpontiColors.error, 'Cancelled'),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
        const SizedBox(width: 10),
        const Icon(
          Icons.people_alt_rounded,
          size: 13,
          color: SpontiColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          '$acceptedParticipantCount going',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SpontiColors.textMuted,
              ),
        ),
        if (invitedParticipantCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '| $invitedParticipantCount invited',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SpontiColors.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}

class GroupPlanSectionLabel extends StatelessWidget {
  const GroupPlanSectionLabel({
    required this.icon,
    required this.label,
    super.key,
  });

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

class GroupPlanEmptyVoteHint extends StatelessWidget {
  const GroupPlanEmptyVoteHint({
    required this.isOnline,
    required this.canParticipate,
    super.key,
  });

  final bool isOnline;
  final bool canParticipate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.info.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              size: 26,
              color: SpontiColors.info,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No locations yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            !isOnline
                ? 'Reconnect to suggest a spot or cast a vote.'
                : canParticipate
                    ? 'Search for a spot below and add your vote.'
                    : 'Accept the invite to start suggesting and voting on spots.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SpontiColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
