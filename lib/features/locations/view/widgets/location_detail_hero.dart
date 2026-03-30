import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_pills.dart';

class LocationDetailHero extends StatelessWidget {
  const LocationDetailHero({
    super.key,
    required this.location,
    this.actionButtons,
  });

  final Location location;
  final Widget? actionButtons;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (location.hasPhotos)
                CachedNetworkImage(
                  imageUrl: location.primaryPhoto,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => CategoryShimmer(color: categoryColor),
                  errorWidget: (_, _, _) => CategoryGradient(
                    category: location.category,
                    emojiFontSize: 56,
                  ),
                )
              else
                CategoryGradient(
                  category: location.category,
                  emojiFontSize: 56,
                ),
              if (actionButtons != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: actionButtons!,
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          LocationCategoryPill(
                            location: location,
                            categoryColor: categoryColor,
                          ),
                          if (location.isHiddenGem) const LocationHiddenGemPill(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OpenStatusPill(isOpen: location.isOpenNow),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
