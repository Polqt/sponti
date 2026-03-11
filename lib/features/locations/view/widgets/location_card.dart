import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/locations/model/location.dart';

enum LocationCardVariant { compact, fullWidth }

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    this.variant = LocationCardVariant.compact,
    this.width = 220,
    this.isSaved = false,
    this.onTap,
    this.onSaveToggle,
  });

  final Location location;
  final LocationCardVariant variant;
  final double width;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToggle;

  bool get _isFullWidth => variant == LocationCardVariant.fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _isFullWidth ? double.infinity : width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: SpontiColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpontiColors.outline),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardPhoto(
                location: location,
                isSaved: isSaved,
                onSaveToggle: onSaveToggle,
              ),
              _CardBody(location: location),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPhoto extends StatelessWidget {
  const _CardPhoto({
    required this.location,
    required this.isSaved,
    this.onSaveToggle,
  });

  final Location location;
  final bool isSaved;
  final VoidCallback? onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 155,
            child: location.hasPhotos
                ? CachedNetworkImage(
                    imageUrl: location.primaryPhoto,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _PhotoShimmer(),
                    errorWidget: (_, _, _) => const _PhotoFallback(),
                  )
                : const _PhotoFallback(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: _CategoryBadge(category: location.category),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location.isHiddenGem) ...[
                  const _Badge(label: 'Hidden Gem'),
                  const SizedBox(width: 4),
                ],
                SaveButton(isSaved: isSaved, onTap: onSaveToggle),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 10,
            child: _OpenBadge(isOpen: location.isOpenNow),
          ),
          if (location.distanceKm != null)
            Positioned(
              bottom: 8,
              right: 10,
              child: _DistanceBadge(km: location.distanceKm!),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: SpontiColors.textMuted,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  location.address,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: SpontiColors.accent,
              ),
              const SizedBox(width: 3),
              Text(
                SpontiFormatter.rating(location.rating),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: SpontiColors.textPrimary,
                ),
              ),
              Text(
                ' (${SpontiFormatter.reviewCount(location.reviewCount)})',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                location.priceRange.symbol,
                style: theme.textTheme.labelMedium?.copyWith(
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

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final LocationCategory category;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Color(category.colorValue).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '${category.emoji} ${category.label}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: SpontiColors.textPrimary,
      ),
    ),
  );
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: SpontiColors.surfaceVariant,
    child: const Center(
      child: Icon(
        Icons.image_outlined,
        color: SpontiColors.textMuted,
        size: 32,
      ),
    ),
  );
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: isOpen
          ? SpontiColors.success.withValues(alpha: 0.88)
          : Colors.black54,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      isOpen ? 'â— Open' : 'â— Closed',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.km});
  final double km;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      SpontiFormatter.distance(km),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PhotoShimmer extends StatelessWidget {
  const _PhotoShimmer();

  @override
  Widget build(BuildContext context) => Container(
    color: SpontiColors.surfaceVariant,
    child: const Center(
      child: Icon(
        Icons.image_outlined,
        color: SpontiColors.textMuted,
        size: 32,
      ),
    ),
  );
}
