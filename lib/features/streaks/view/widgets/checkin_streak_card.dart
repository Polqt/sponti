import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/streaks/model/checkin_streak.dart';

class CheckInStreakCard extends StatelessWidget {
  const CheckInStreakCard({required this.streak, super.key});

  final CheckInStreak streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '${streak.currentStreakDays} day streak',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            streak.hasStreak
                ? 'Keep checking in daily to protect your streak.'
                : 'Check in today to start your streak.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: SpontiColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tier in StreakBadgeTier.values)
                _BadgeChip(
                  tier: tier,
                  earned: streak.earnedBadges.contains(tier),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.tier, required this.earned});

  final StreakBadgeTier tier;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final bg = earned
        ? SpontiColors.secondary.withValues(alpha: 0.16)
        : SpontiColors.outline.withValues(alpha: 0.2);
    final fg = earned ? SpontiColors.secondary : SpontiColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.verified_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            tier.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
