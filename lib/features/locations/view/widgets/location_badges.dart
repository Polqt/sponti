import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';

class OpenStatusPill extends StatelessWidget {
  const OpenStatusPill({super.key, required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOpen
            ? SpontiColors.success.withValues(alpha: 0.9)
            : Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickInfoRow extends StatelessWidget {
  const QuickInfoRow({super.key, required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      if (location.hasWifi) (Icons.wifi_rounded, 'WiFi'),
      if (location.isPetFriendly) (Icons.pets_rounded, 'Pets OK'),
      if (location.hasParking) (Icons.local_parking_rounded, 'Parking'),
      if (location.distanceKm != null)
        (Icons.near_me_rounded, SpontiFormatter.distance(location.distanceKm!)),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, label) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SpontiColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SpontiColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: SpontiColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SpontiColors.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
