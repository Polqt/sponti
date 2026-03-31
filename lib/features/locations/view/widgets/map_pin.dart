import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/viewmodel/map_zoom_provider.dart';

class MapPin extends ConsumerWidget {
  const MapPin({
    super.key,
    required this.category,
    required this.isSelected,
    required this.priceRange,
    this.locationName,
    this.ranking,
    this.activeRankingFilter,
    this.activePriceFilter,
  });

  final LocationCategory category;
  final bool isSelected;
  final PriceRange priceRange;
  final String? locationName;
  final LocationRanking? ranking;
  final LocationRanking? activeRankingFilter;
  final PriceRange? activePriceFilter;

  static const _textStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Colors.black,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(mapZoomProvider);
    final showLabel = zoomState.shouldShowLabels &&
        locationName != null &&
        locationName!.isNotEmpty;
    final labelOpacity = zoomState.labelOpacity;
    final iconScale = zoomState.iconScale * (isSelected ? 1.15 : 1.0);
    final rankingIndicator = activeRankingFilter ?? ranking;
    final rankingAccent = rankingIndicator?.indicatorColor;
    final priceAccent = activePriceFilter != null
        ? _priceAccentColor(activePriceFilter!)
        : null;
    final pinAccent = rankingAccent ?? priceAccent;

    return SizedBox(
      width: showLabel ? 100 : 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: iconScale,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isSelected ? 34 : 30,
                  height: isSelected ? 34 : 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: pinAccent == null
                        ? null
                        : Border.all(
                            color: pinAccent.withValues(
                              alpha: isSelected ? 0.95 : 0.72,
                            ),
                            width: isSelected ? 2.5 : 1.8,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 3),
                        spreadRadius: isSelected ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: LocationCategoryIcon(
                      category: category,
                      color: Colors.black.withValues(alpha: 0.75),
                      size: isSelected ? 18 : 16,
                    ),
                  ),
                ),
                if (rankingIndicator != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: rankingIndicator.indicatorColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                if (activePriceFilter != null)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: _PinPriceBadge(
                      symbol: priceRange.symbol,
                      color: _priceAccentColor(priceRange),
                    ),
                  ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Flexible(
              child: AnimatedOpacity(
                opacity: labelOpacity,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Text(
                  (locationName!.length > 18
                          ? '${locationName!.substring(0, 18)}...'
                          : locationName!)
                      .toUpperCase(),
                  style: _textStyle,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinPriceBadge extends StatelessWidget {
  const _PinPriceBadge({
    required this.symbol,
    required this.color,
  });

  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

Color _priceAccentColor(PriceRange price) => switch (price) {
  PriceRange.free => SpontiColors.secondary,
  PriceRange.budget => SpontiColors.primary,
  PriceRange.moderate => SpontiColors.warning,
  PriceRange.expensive => const Color(0xFF7B4F2E),
};
