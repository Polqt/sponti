import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';

class GroupPlanInviteResponseCard extends StatelessWidget {
  const GroupPlanInviteResponseCard({
    required this.isLoading,
    required this.isEnabled,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpontiColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpontiColors.info.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You were invited to this plan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Accept to suggest locations and vote. Declining keeps the plan visible but disables participation.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SpontiColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: isLoading || !isEnabled ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: SpontiColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading || !isEnabled ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SpontiColors.error,
                    side: BorderSide(
                      color: SpontiColors.error.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GroupPlanInfoBanner extends StatelessWidget {
  const GroupPlanInfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SpontiColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SpontiColors.textSecondary,
                        height: 1.4,
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

class GroupPlanParticipantStatusSummary extends StatelessWidget {
  const GroupPlanParticipantStatusSummary({
    required this.participants,
    super.key,
  });

  final List<PlanParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        participants.where((participant) => participant.isPending).length;
    final acceptedCount =
        participants.where((participant) => participant.isAccepted).length;
    final declinedCount =
        participants.where((participant) => participant.isDeclined).length;

    Widget buildPill({
      required IconData icon,
      required String label,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildPill(
          icon: Icons.mark_email_unread_rounded,
          label: '$pendingCount pending',
          color: SpontiColors.info,
        ),
        buildPill(
          icon: Icons.check_circle_rounded,
          label: '$acceptedCount accepted',
          color: SpontiColors.success,
        ),
        buildPill(
          icon: Icons.cancel_rounded,
          label: '$declinedCount declined',
          color: SpontiColors.error,
        ),
      ],
    );
  }
}
