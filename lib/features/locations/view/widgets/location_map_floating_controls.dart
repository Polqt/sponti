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
    required this.currentLocationTitle,
    required this.currentLocationSubtitle,
    required this.isLocating,
    required this.onCategoryChanged,
    required this.onLocateMe,
    required this.onClearRanking,
    required this.onClearPrice,
  });

  final LocationCategory? selectedCategory;
  final LocationRanking? selectedRanking;
  final PriceRange? selectedPrice;
  final String currentLocationTitle;
  final String currentLocationSubtitle;
  final bool isLocating;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final VoidCallback onLocateMe;
  final VoidCallback onClearRanking;
  final VoidCallback onClearPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedRanking != null || selectedPrice != null)
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
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CurrentLocationButton(
            title: currentLocationTitle,
            subtitle: currentLocationSubtitle,
            isLoading: isLocating,
            onTap: onLocateMe,
          ),
        ),
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

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SpontiColors.secondary.withValues(alpha: 0.20),
                        SpontiColors.secondary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: SpontiColors.secondary,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: SpontiColors.secondary,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: SpontiColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: SpontiColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: SpontiColors.textSecondary.withValues(alpha: 0.9),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingFilterChip extends StatelessWidget {
  const _RankingFilterChip({
    required this.ranking,
    required this.onClear,
  });

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
  const _PriceFilterChip({
    required this.price,
    required this.onClear,
  });

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
  const _GlassSurface({
    required this.padding,
    required this.child,
  });

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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
            ),
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
