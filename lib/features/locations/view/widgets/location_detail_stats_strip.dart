import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';

class LocationDetailStatsStrip extends StatelessWidget {
  const LocationDetailStatsStrip({
    super.key,
    required this.reviewCount,
    required this.rating,
    required this.checkInCount,
  });

  final int reviewCount;
  final double rating;
  final int checkInCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LocationDetailStatItem(
          value: SpontiFormatter.compactNumber(reviewCount),
          label: 'Reviews',
          color: SpontiColors.primary,
        ),
        const _LocationDetailStatDivider(),
        _LocationDetailStatItem(
          value: SpontiFormatter.compactNumber(checkInCount),
          label: 'Check-ins',
          color: SpontiColors.secondary,
        ),
        const _LocationDetailStatDivider(),
        _LocationDetailStatItem(
          value: SpontiFormatter.rating(rating),
          label: 'Rating',
          color: SpontiColors.accent,
        ),
      ],
    );
  }
}

class _LocationDetailStatItem extends StatelessWidget {
  const _LocationDetailStatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SpontiColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDetailStatDivider extends StatelessWidget {
  const _LocationDetailStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: SpontiColors.outline,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
