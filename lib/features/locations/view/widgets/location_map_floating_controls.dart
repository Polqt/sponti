import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/location_category_row.dart';

class LocationMapFloatingControls extends StatelessWidget {
  const LocationMapFloatingControls({
    super.key,
    required this.selectedCategory,
    required this.selectedRanking,
    required this.selectedPrice,
    required this.isLocating,
    required this.isRefreshing,
    required this.onCategoryChanged,
    required this.onLocateMe,
    required this.onRefresh,
    required this.onClearRanking,
    required this.onClearPrice,
    this.hasWifiFilter = false,
    this.hasPetFriendlyFilter = false,
    this.hasParkingFilter = false,
    this.onWifiFilterChanged,
    this.onPetFriendlyFilterChanged,
    this.onParkingFilterChanged,
  });

  final LocationCategory? selectedCategory;
  final LocationRanking? selectedRanking;
  final PriceRange? selectedPrice;
  final bool isLocating;
  final bool isRefreshing;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final VoidCallback onLocateMe;
  final VoidCallback onRefresh;
  final VoidCallback onClearRanking;
  final VoidCallback onClearPrice;
  
  // Quick filters
  final bool hasWifiFilter;
  final bool hasPetFriendlyFilter;
  final bool hasParkingFilter;
  final ValueChanged<bool>? onWifiFilterChanged;
  final ValueChanged<bool>? onPetFriendlyFilterChanged;
  final ValueChanged<bool>? onParkingFilterChanged;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedRanking != null || 
        selectedPrice != null || 
        hasWifiFilter || 
        hasPetFriendlyFilter || 
        hasParkingFilter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Active filter chips
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (selectedRanking != null)
                  _RankingFilterChip(
                    ranking: selectedRanking!,
                    onClear: onClearRanking,
                  ),
                if (selectedPrice != null)
                  _PriceFilterChip(
                    price: selectedPrice!,
                    onClear: onClearPrice,
                  ),
                if (hasWifiFilter)
                  _QuickFilterChip(
                    icon: Icons.wifi_rounded,
                    label: 'WiFi',
                    color: SpontiColors.info,
                    onClear: () => onWifiFilterChanged?.call(false),
                  ),
                if (hasPetFriendlyFilter)
                  _QuickFilterChip(
                    icon: Icons.pets_rounded,
                    label: 'Pet Friendly',
                    color: SpontiColors.warning,
                    onClear: () => onPetFriendlyFilterChanged?.call(false),
                  ),
                if (hasParkingFilter)
                  _QuickFilterChip(
                    icon: Icons.local_parking_rounded,
                    label: 'Parking',
                    color: SpontiColors.secondary,
                    onClear: () => onParkingFilterChanged?.call(false),
                  ),
              ],
            ),
          ),
        // Quick filter buttons row + locate me button
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _QuickFiltersRow(
                    hasWifi: hasWifiFilter,
                    hasPetFriendly: hasPetFriendlyFilter,
                    hasParking: hasParkingFilter,
                    onWifiTap: () => onWifiFilterChanged?.call(!hasWifiFilter),
                    onPetFriendlyTap: () => onPetFriendlyFilterChanged?.call(!hasPetFriendlyFilter),
                    onParkingTap: () => onParkingFilterChanged?.call(!hasParkingFilter),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapActionButton(
                    icon: Icons.refresh_rounded,
                    accentColor: SpontiColors.primary,
                    borderColor: SpontiColors.primary.withValues(alpha: 0.3),
                    isLoading: isRefreshing,
                    onTap: onRefresh,
                  ),
                  const SizedBox(width: 8),
                  _MapActionButton(
                    icon: Icons.person_pin_circle_rounded,
                    accentColor: SpontiColors.secondary,
                    borderColor: SpontiColors.secondary.withValues(alpha: 0.3),
                    isLoading: isLocating,
                    onTap: onLocateMe,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Category row
        _GlassSurface(
          padding: const EdgeInsets.all(10),
          child: LocationCategoryRow(
            selectedCategory: selectedCategory,
            onChanged: onCategoryChanged,
          ),
        ),
      ],
    );
  }
}

/// Row of quick filter toggle buttons
class _QuickFiltersRow extends StatelessWidget {
  const _QuickFiltersRow({
    required this.hasWifi,
    required this.hasPetFriendly,
    required this.hasParking,
    required this.onWifiTap,
    required this.onPetFriendlyTap,
    required this.onParkingTap,
  });

  final bool hasWifi;
  final bool hasPetFriendly;
  final bool hasParking;
  final VoidCallback onWifiTap;
  final VoidCallback onPetFriendlyTap;
  final VoidCallback onParkingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickFilterButton(
          icon: Icons.wifi_rounded,
          label: 'WiFi',
          isActive: hasWifi,
          activeColor: SpontiColors.info,
          onTap: onWifiTap,
        ),
        const SizedBox(width: 8),
        _QuickFilterButton(
          icon: Icons.pets_rounded,
          label: 'Pet Friendly',
          isActive: hasPetFriendly,
          activeColor: SpontiColors.warning,
          onTap: onPetFriendlyTap,
        ),
        const SizedBox(width: 8),
        _QuickFilterButton(
          icon: Icons.local_parking_rounded,
          label: 'Parking',
          isActive: hasParking,
          activeColor: SpontiColors.secondary,
          onTap: onParkingTap,
        ),
      ],
    );
  }
}

/// Individual quick filter toggle button
class _QuickFilterButton extends StatelessWidget {
  const _QuickFilterButton({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: isActive 
              ? null 
              : Border.all(color: SpontiColors.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : SpontiColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : SpontiColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip showing an active quick filter with clear button
class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SpontiColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: SpontiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.accentColor,
    required this.borderColor,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final Color borderColor;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: accentColor,
                ),
              )
            : Icon(
                icon,
                color: accentColor,
                size: 26,
              ),
      ),
    );
  }
}

class _RankingFilterChip extends StatelessWidget {
  const _RankingFilterChip({required this.ranking, required this.onClear});

  final LocationRanking ranking;
  final VoidCallback onClear;

  String get _label => switch (ranking) {
    LocationRanking.trending => 'Trending',
    LocationRanking.popular => 'Popular',
    LocationRanking.lowkey => 'Lowkey',
    LocationRanking.newest => 'New',
  };

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ranking.indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _label.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SpontiColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: SpontiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceFilterChip extends StatelessWidget {
  const _PriceFilterChip({required this.price, required this.onClear});

  final PriceRange price;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = _priceChipColor(price);

    return _GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            price.symbol,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SpontiColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: SpontiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.78),
                Colors.white.withValues(alpha: 0.56),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

Color _priceChipColor(PriceRange price) => switch (price) {
  PriceRange.free => SpontiColors.secondary,
  PriceRange.budget => SpontiColors.primary,
  PriceRange.moderate => SpontiColors.warning,
  PriceRange.expensive => const Color(0xFF7B4F2E),
};
