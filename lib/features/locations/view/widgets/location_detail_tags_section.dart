import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';

class LocationTagsSection extends StatelessWidget {
  const LocationTagsSection({
    super.key,
    required this.tags,
  });

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return LocationDetailSection(
      title: 'Tags',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map((tag) => _LocationTagChip(key: ValueKey(tag), tag: tag))
            .toList(growable: false),
      ),
    );
  }
}

class _LocationTagChip extends StatelessWidget {
  const _LocationTagChip({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textSecondary,
        ),
      ),
    );
  }
}
