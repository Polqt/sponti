import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class DiscoveryCuratorSectionsLoading extends StatelessWidget {
  const DiscoveryCuratorSectionsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscoveryCuratorLaneLoading(title: 'TOP CURATORS'),
        SizedBox(height: 20),
        DiscoveryCuratorLaneLoading(title: 'TOP REVIEWERS'),
        SizedBox(height: 20),
        DiscoveryCuratorLaneLoading(title: 'TOP VISITORS'),
      ],
    );
  }
}

class DiscoveryCuratorLaneLoading extends StatelessWidget {
  const DiscoveryCuratorLaneLoading({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: SpontiColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 160,
          height: 10,
          decoration: BoxDecoration(
            color: SpontiColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, _) => const DiscoveryCuratorLoadingTile(),
          ),
        ),
      ],
    );
  }
}

class DiscoveryCuratorLoadingTile extends StatelessWidget {
  const DiscoveryCuratorLoadingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: SpontiColors.outline),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 11,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 56,
            height: 9,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 70,
            height: 9,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
