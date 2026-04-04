import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

class LocationComparisonCard extends StatelessWidget {
  const LocationComparisonCard({super.key, required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return Container(
      width: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SpontiColors.outline.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Photo ──────────────────────────────────────────
          SizedBox(
            height: 148,
            width: double.infinity,
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
                // Gradient overlay for name legibility
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                // Category pill top-left
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          location.category.icon,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location.category.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Open/Closed badge top-right
                Positioned(
                  top: 10,
                  right: 10,
                  child: _OpenBadge(isOpen: location.isOpenNow),
                ),
                // Name bottom
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    location.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Details ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DataRow(
                  icon: Icons.star_rounded,
                  iconColor: SpontiColors.accent,
                  value:
                      '${SpontiFormatter.rating(location.rating)}  ·  ${SpontiFormatter.reviewCount(location.reviewCount)}',
                ),
                const SizedBox(height: 7),
                _DataRow(
                  icon: Icons.payments_rounded,
                  iconColor: SpontiColors.secondary,
                  value: location.priceRange.label,
                ),
                const SizedBox(height: 7),
                _DataRow(
                  icon: Icons.near_me_rounded,
                  iconColor: SpontiColors.info,
                  value: location.distanceKm != null
                      ? SpontiFormatter.distance(location.distanceKm!)
                      : 'Distance N/A',
                ),
                const SizedBox(height: 12),
                const _Divider(),
                const SizedBox(height: 10),
                // Amenities row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AmenityDot(
                      icon: Icons.wifi_rounded,
                      label: 'Wi-Fi',
                      isActive: location.hasWifi,
                    ),
                    _AmenityDot(
                      icon: Icons.pets_rounded,
                      label: 'Pets',
                      isActive: location.isPetFriendly,
                    ),
                    _AmenityDot(
                      icon: Icons.local_parking_rounded,
                      label: 'Park',
                      isActive: location.hasParking,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final bg = isOpen
        ? SpontiColors.success.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isOpen ? Colors.white : Colors.white60,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor ?? SpontiColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SpontiColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: SpontiColors.outline.withValues(alpha: 0.5),
    );
  }
}

class _AmenityDot extends StatelessWidget {
  const _AmenityDot({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SpontiColors.primary : SpontiColors.outline;
    final textColor =
        isActive ? SpontiColors.primary : SpontiColors.textMuted;

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isActive ? 0.12 : 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: isActive ? color : SpontiColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
