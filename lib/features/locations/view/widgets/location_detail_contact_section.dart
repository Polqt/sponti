import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';

class LocationContactSection extends StatelessWidget {
  const LocationContactSection({
    super.key,
    required this.location,
  });

  final Location location;

  @override
  Widget build(BuildContext context) {
    final rows = <({IconData icon, String value})>[
      if (location.contactNumber case final contactNumber?)
        (icon: Icons.phone_outlined, value: contactNumber),
      if (location.websiteUrl case final websiteUrl?)
        (icon: Icons.language_rounded, value: websiteUrl),
      if (location.instagramHandle case final instagramHandle?)
        (icon: Icons.camera_alt_outlined, value: '@$instagramHandle'),
    ];

    return LocationDetailSection(
      title: 'Contact',
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _LocationContactRow(
              icon: rows[index].icon,
              value: rows[index].value,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationContactRow extends StatelessWidget {
  const _LocationContactRow({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SpontiColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: SpontiColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
