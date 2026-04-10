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
    this.isSaved = false,
    this.onSaveToggle,
    this.savedIcon = Icons.favorite_border_rounded,
    this.savedActiveIcon = Icons.favorite_rounded,
    this.showShadow = true,
    this.isPinnedForComparison = false,
    this.onComparisonToggle,
    this.isTrending = false,
  });

  final Location location;
  final LocationCardVariant variant;
  final double width;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onSaveToggle;
  final IconData savedIcon;
  final IconData savedActiveIcon;
  final bool showShadow;
  final bool isPinnedForComparison;
  final VoidCallback? onComparisonToggle;
  final bool isTrending;

  bool get _isFullWidth => variant == LocationCardVariant.fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _isFullWidth ? double.infinity : width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SpontiColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: SpontiColors.shadow.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardImage(
                location: location,
                isSaved: isSaved,
                onSaveToggle: onSaveToggle,
                savedIcon: savedIcon,
                savedActiveIcon: savedActiveIcon,
                isPinnedForComparison: isPinnedForComparison,
                onComparisonToggle: onComparisonToggle,
                isTrending: isTrending,
              ),
              _CardBody(location: location),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.location,
    required this.isSaved,
    required this.onSaveToggle,
    required this.savedIcon,
    required this.savedActiveIcon,
    required this.isPinnedForComparison,
    required this.onComparisonToggle,
    required this.isTrending,
  });

  final Location location;
  final bool isSaved;
  final VoidCallback? onSaveToggle;
  final IconData savedIcon;
  final IconData savedActiveIcon;
  final bool isPinnedForComparison;
  final VoidCallback? onComparisonToggle;
  final bool isTrending;

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

          // Trending badge — below category pill, top left
          if (isTrending)
            Positioned(
              top: 34,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 9)),
                    SizedBox(width: 3),
                    Text(
                      'Trending',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
              right: onSaveToggle != null && onComparisonToggle != null
                  ? 88
                  : (onSaveToggle != null || onComparisonToggle != null ? 48 : 8),
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

          if (onSaveToggle != null)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSaveToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isSaved ? savedActiveIcon : savedIcon,
                      size: 16,
                      color: isSaved
                          ? SpontiColors.primary
                          : SpontiColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          if (onComparisonToggle != null)
            Positioned(
              top: 8,
              right: onSaveToggle != null ? 48 : 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onComparisonToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isPinnedForComparison
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 16,
                      color: isPinnedForComparison
                          ? SpontiColors.info
                          : SpontiColors.textSecondary,
                    ),
                  ),
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
                style: const TextStyle(
                  fontSize: 10,
                  color: SpontiColors.textMuted,
                ),
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                location.priceRange.symbol,
                style: const TextStyle(
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
