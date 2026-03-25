import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/viewmodel/map_zoom_provider.dart';

class MapPin extends ConsumerWidget {
  const MapPin({
    super.key,
    required this.category,
    required this.isSelected,
    this.locationName,
    this.onTap,
    this.rating,
  });

  final LocationCategory category;
  final bool isSelected;
  final String? locationName;
  final VoidCallback? onTap;
  final double? rating;

  static const _textStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Colors.black,
    height: 1.2,
    shadows: [
      Shadow(
        color: Colors.white,
        offset: Offset.zero,
        blurRadius: 4,
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(mapZoomProvider);
    final showLabel = zoomState.shouldShowLabels &&
        locationName != null &&
        locationName!.isNotEmpty;
    final labelOpacity = zoomState.labelOpacity;
    final iconScale = zoomState.iconScale * (isSelected ? 1.15 : 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: showLabel ? 100 : 50,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: iconScale,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                width: isSelected ? 34 : 30,
                height: isSelected ? 34 : 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
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
      ),
    );
  }
}
