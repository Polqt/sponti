import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';

class LocationNameSection extends StatelessWidget {
  const LocationNameSection({
    super.key,
    required this.location,
    required this.categoryColor,
  });

  final Location location;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                location.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: SpontiColors.textPrimary,
                  height: 1.15,
                ),
              ),
            ),
            if (location.isVerified) ...[
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.verified_rounded,
                  size: 22,
                  color: SpontiColors.info,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Rating pill + price + address
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SpontiColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: SpontiColors.accent,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    SpontiFormatter.rating(location.rating),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: SpontiColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${SpontiFormatter.reviewCount(location.reviewCount)} reviews',
              style: TextStyle(
                fontSize: 12,
                color: SpontiColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SpontiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${location.priceRange.symbol}  ${location.priceRange.label}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: SpontiColors.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SpontiColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              icon: Icons.reviews_outlined,
              value: SpontiFormatter.compactNumber(location.reviewCount),
              label: 'Reviews',
              color: SpontiColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: SpontiColors.outline),
          Expanded(
            child: _StatColumn(
              icon: Icons.pin_drop_outlined,
              value: SpontiFormatter.compactNumber(location.checkInCount),
              label: 'Check-ins',
              color: SpontiColors.secondary,
            ),
          ),
          Container(width: 1, height: 40, color: SpontiColors.outline),
          Expanded(
            child: _StatColumn(
              icon: Icons.star_outline_rounded,
              value: SpontiFormatter.rating(location.rating),
              label: 'Rating',
              color: SpontiColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: SpontiColors.textPrimary,
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
    );
  }
}
