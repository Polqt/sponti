import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:timeago/timeago.dart' as timeago;

class GroupPlanCard extends StatelessWidget {
  const GroupPlanCard({required this.plan, this.onTap, super.key});

  final GroupPlan plan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _PlanStatusStyle.of(plan.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: SpontiColors.primary.withValues(alpha: 0.04),
          highlightColor: SpontiColors.primary.withValues(alpha: 0.02),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: SpontiColors.outline.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: SpontiColors.shadow.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent stripe
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon badge
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: status.color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  status.icon,
                                  size: 20,
                                  color: status.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: SpontiColors.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      timeago.format(plan.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: SpontiColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusPill(
                                label: status.label,
                                color: status.color,
                              ),
                            ],
                          ),
                          if (plan.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              plan.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: SpontiColors.textSecondary,
                                    height: 1.45,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 13,
                                color: status.color.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to view & vote',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: status.color.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PlanStatusStyle {
  const _PlanStatusStyle({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  static _PlanStatusStyle of(PlanStatus status) => switch (status) {
    PlanStatus.voting => const _PlanStatusStyle(
      color: SpontiColors.info,
      icon: Icons.how_to_vote_rounded,
      label: 'Voting',
    ),
    PlanStatus.decided => const _PlanStatusStyle(
      color: SpontiColors.success,
      icon: Icons.check_circle_rounded,
      label: 'Decided',
    ),
    PlanStatus.cancelled => const _PlanStatusStyle(
      color: SpontiColors.error,
      icon: Icons.cancel_rounded,
      label: 'Cancelled',
    ),
  };
}
