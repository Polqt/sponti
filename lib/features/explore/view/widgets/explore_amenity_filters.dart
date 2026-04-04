import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

/// Horizontal row of toggle pills for WiFi / Pet-friendly / Parking filters.
/// Shown inside the explore bottom panel when it's expanded.
class ExploreAmenityFilters extends StatelessWidget {
  const ExploreAmenityFilters({
    super.key,
    required this.hasWifi,
    required this.isPetFriendly,
    required this.hasParking,
    required this.onWifiChanged,
    required this.onPetFriendlyChanged,
    required this.onParkingChanged,
  });

  final bool hasWifi;
  final bool isPetFriendly;
  final bool hasParking;
  final ValueChanged<bool> onWifiChanged;
  final ValueChanged<bool> onPetFriendlyChanged;
  final ValueChanged<bool> onParkingChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _AmenityPill(
            icon: Icons.wifi_rounded,
            label: 'WiFi',
            isActive: hasWifi,
            activeColor: SpontiColors.info,
            onTap: () => onWifiChanged(!hasWifi),
          ),
          const SizedBox(width: 8),
          _AmenityPill(
            icon: Icons.pets_rounded,
            label: 'Pet Friendly',
            isActive: isPetFriendly,
            activeColor: SpontiColors.warning,
            onTap: () => onPetFriendlyChanged(!isPetFriendly),
          ),
          const SizedBox(width: 8),
          _AmenityPill(
            icon: Icons.local_parking_rounded,
            label: 'Parking',
            isActive: hasParking,
            activeColor: SpontiColors.secondary,
            onTap: () => onParkingChanged(!hasParking),
          ),
        ],
      ),
    );
  }
}

class _AmenityPill extends StatelessWidget {
  const _AmenityPill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.12)
                : SpontiColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.45)
                  : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? activeColor : SpontiColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? activeColor : SpontiColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
