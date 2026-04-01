import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/map_label_layout.dart';
import 'package:sponti/features/locations/utils/map_pin_label_text.dart';
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
    this.labelText,
    this.ranking,
    this.activeRankingFilter,
    this.activePriceFilter,
    this.labelPlacement = MapPinLabelPlacement.right,
    this.labelDistanceFactor = 1.0,
  });

  final LocationCategory category;
  final bool isSelected;
  final PriceRange priceRange;
  final VoidCallback onTap;
  final MapPinLabelText? labelText;
  final LocationRanking? ranking;
  final LocationRanking? activeRankingFilter;
  final PriceRange? activePriceFilter;
  final MapPinLabelPlacement labelPlacement;
  final double labelDistanceFactor;

  static const _textStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF231F20),
    height: 1.18,
  );
  static const double canvasWidth = 220;
  static const double canvasHeight = 152;
  static const double _basePinSize = 30;
  static const double _selectedPinSize = 34;
  static const double _sideLabelWidth = 104;
  static const double _verticalLabelWidth = 126;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(mapZoomProvider);
    final showLabel = zoomState.shouldShowLabels &&
        labelText != null &&
        !labelText!.isEmpty;
    final labelOpacity = zoomState.labelOpacity;
    final labelScale = zoomState.labelScale;
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
          if (showLabel)
            _buildLabel(
              labelText: labelText!,
              placement: labelPlacement,
              opacity: labelOpacity,
              scale: labelScale,
              accent: pinAccent,
            ),
          SizedBox(
            width: 52,
            height: 52,
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
                            color: locationPriceAccentColor(priceRange),
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

  Widget _buildLabel({
    required MapPinLabelText labelText,
    required MapPinLabelPlacement placement,
    required double opacity,
    required double scale,
    required Color? accent,
  }) {
    final width = _isVerticalPlacement(placement)
        ? _verticalLabelWidth
        : _sideLabelWidth;
    final label = IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: _labelAlignment(placement),
          child: Container(
            constraints: BoxConstraints(maxWidth: width),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (accent ?? Colors.white).withValues(
                  alpha: accent == null ? 0.7 : 0.24,
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              labelText.displayText,
              style: _textStyle,
              textAlign: TextAlign.center,
              maxLines: labelText.lineCount,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: Padding(
        padding: _labelPadding(placement, labelDistanceFactor),
        child: Align(
          alignment: _labelAlignment(placement),
          child: label,
        ),
      ),
    );
  }

  Alignment _labelAlignment(MapPinLabelPlacement placement) => switch (placement) {
    MapPinLabelPlacement.right => Alignment.centerLeft,
    MapPinLabelPlacement.left => Alignment.centerRight,
    MapPinLabelPlacement.top => Alignment.bottomCenter,
    MapPinLabelPlacement.bottom => Alignment.topCenter,
  };

  bool _isVerticalPlacement(MapPinLabelPlacement placement) =>
      placement == MapPinLabelPlacement.top ||
      placement == MapPinLabelPlacement.bottom;

  EdgeInsets _labelPadding(
    MapPinLabelPlacement placement,
    double distanceFactor,
  ) {
    final extraHorizontal = ((distanceFactor - 1.0) * 42).clamp(0.0, 48.0);
    final extraVertical = ((distanceFactor - 1.0) * 34).clamp(0.0, 42.0);

    return switch (placement) {
      MapPinLabelPlacement.right => EdgeInsets.fromLTRB(
        96 + extraHorizontal,
        0,
        8,
        0,
      ),
      MapPinLabelPlacement.left => EdgeInsets.fromLTRB(
        8,
        0,
        96 + extraHorizontal,
        0,
      ),
      MapPinLabelPlacement.top => EdgeInsets.fromLTRB(
        22,
        4,
        22,
        64 + extraVertical,
      ),
      MapPinLabelPlacement.bottom => EdgeInsets.fromLTRB(
        22,
        64 + extraVertical,
        22,
        4,
      ),
    };
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
