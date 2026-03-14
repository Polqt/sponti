import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

enum LocationCardVariant { compact, fullWidth }

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    this.variant = LocationCardVariant.compact,
    this.width = 220,
    this.onTap,
  });

  final Location location;
  final LocationCardVariant variant;
  final double width;
  final VoidCallback? onTap;

  bool get _isFullWidth => variant == LocationCardVariant.fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _isFullWidth ? double.infinity : width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SpontiColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardImage(location: location),
              _CardBody(location: location),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return SizedBox(
      width: double.infinity,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (location.hasPhotos)
            CachedNetworkImage(
              imageUrl: location.primaryPhoto,
              fit: BoxFit.cover,
              placeholder: (_, _) => CategoryShimmer(color: categoryColor),
              errorWidget: (_, _, _) =>
                  CategoryGradient(category: location.category),
            )
          else
            CategoryGradient(category: location.category),

          // Bottom gradient for readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // Category pill — top left
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location.category.emoji,
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location.category.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hidden gem sparkle — top right
          if (location.isHiddenGem)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: SpontiColors.accent,
                ),
              ),
            ),

          // Name + open status on image bottom
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: location.isOpenNow
                        ? SpontiColors.success
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 11,
                color: SpontiColors.textMuted,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  location.address,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: SpontiColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: SpontiColors.accent,
              ),
              const SizedBox(width: 2),
              Text(
                SpontiFormatter.rating(location.rating),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.textPrimary,
                ),
              ),
              Text(
                ' (${SpontiFormatter.reviewCount(location.reviewCount)})',
                style: TextStyle(fontSize: 10, color: SpontiColors.textMuted),
              ),
              const Spacer(),
              if (location.distanceKm != null) ...[
                Icon(
                  Icons.near_me_rounded,
                  size: 10,
                  color: SpontiColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 2),
                Text(
                  SpontiFormatter.distance(location.distanceKm!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                location.priceRange.symbol,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
