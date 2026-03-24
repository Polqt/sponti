import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';

class LocationCategoryPill extends StatelessWidget {
  const LocationCategoryPill({
    super.key,
    required this.location,
    required this.categoryColor,
  });

  final Location location;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: categoryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(location.category.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            location.category.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationHiddenGemPill extends StatelessWidget {
  const LocationHiddenGemPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: SpontiColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            'Hidden gem',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: SpontiColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
