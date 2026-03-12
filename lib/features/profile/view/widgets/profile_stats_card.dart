import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/profile/model/user_profile.dart';

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(label: 'Check-ins', value: profile.checkInCount),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(label: 'Saved', value: profile.favoritesCount),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(label: 'Suggested', value: profile.spotsSuggested),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: SpontiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: SpontiColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: SpontiColors.outline,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}