import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_marker_style.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/viewmodel/map_zoom_provider.dart';

class MapPin extends ConsumerWidget {
  const MapPin({
    super.key,
    required this.category,
    required this.isSelected,
    required this.priceRange,
    required this.onTap,
    this.ranking,
    this.activeRankingFilter,
    this.activePriceFilter,
    this.isTrending = false,
  });

  final LocationCategory category;
  final bool isSelected;
  final PriceRange priceRange;
  final VoidCallback onTap;
  final LocationRanking? ranking;
  final LocationRanking? activeRankingFilter;
  final PriceRange? activePriceFilter;
  final bool isTrending;
  static const double canvasWidth = 220;
  static const double canvasHeight = 152;
  static const double _basePinSize = 24;
  static const double _selectedPinSize = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(mapZoomProvider);
    final iconScale = zoomState.iconScale * (isSelected ? 1.15 : 1.0);
    final rankingIndicator = resolveLocationMarkerRanking(
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
    );
    final pinAccent = resolveLocationMarkerAccent(
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
      activePriceFilter: activePriceFilter,
    );
    final pinSize = isSelected ? _selectedPinSize : _basePinSize;

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: iconScale,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: pinSize,
                        height: pinSize,
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
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: isSelected ? 12 : 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: LocationCategoryIcon(
                            category: category,
                            color: Colors.black.withValues(alpha: 0.75),
                            size: isSelected ? 15 : 14,
                          ),
                        ),
                      ),
                      if (rankingIndicator != null)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 9,
                            height: 9,
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
                      if (isTrending)
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '🔥',
                                style: TextStyle(fontSize: 5, height: 1),
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
                            color: priceRange.accentColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPriceBadge extends StatelessWidget {
  const _PinPriceBadge({required this.symbol, required this.color});

  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
