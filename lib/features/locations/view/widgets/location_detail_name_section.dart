import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';

class LocationDetailNameSection extends StatelessWidget {
  const LocationDetailNameSection({
    super.key,
    required this.location,
  });

  final Location location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                location.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            if (location.isVerified) ...[
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: SpontiColors.info,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SpontiColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${SpontiFormatter.reviewCount(location.reviewCount)})',
              style: const TextStyle(
                fontSize: 13,
                color: SpontiColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: SpontiColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              location.priceRange.label,
              style: const TextStyle(
                fontSize: 13,
                color: SpontiColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                style: const TextStyle(
                  fontSize: 13,
                  color: SpontiColors.textSecondary,
                  height: 1.4,
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
