import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class DiscoveryFriendsPlaceholder extends StatelessWidget {
  const DiscoveryFriendsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('friends-coming-soon'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SpontiColors.outline),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: SpontiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Friends picks are coming soon',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are preparing a shared feed where you can browse places your friends are into, save their picks, and compare vibes in one scroll.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
