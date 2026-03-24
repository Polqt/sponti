import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';

class LocationAboutSection extends StatelessWidget {
  const LocationAboutSection({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    return LocationDetailSection(
      title: 'About',
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          color: SpontiColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}
