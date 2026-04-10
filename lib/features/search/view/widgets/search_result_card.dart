import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/search/view/widgets/search_glass_panel.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.location,
    required this.index,
    required this.isPrimary,
    required this.onTap,
  });

  final Location location;
  final int index;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delayIndex = index > 5 ? 5 : index;

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(location.id),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + (delayIndex * 45)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          );
        },
        child: isPrimary
            ? _PrimarySearchResultCard(
                location: location,
                onTap: onTap,
              )
            : _CompactSearchResultCard(
                location: location,
                onTap: onTap,
              ),
      ),
    );
  }
}

class _PrimarySearchResultCard extends StatelessWidget {
  const _PrimarySearchResultCard({
    required this.location,
    required this.onTap,
  });

  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return SearchGlassPanel(
      radius: 34,
      padding: EdgeInsets.zero,
      gradientColors: [
        Colors.white.withValues(alpha: 0.74),
        const Color(0xFFF5EEE6).withValues(alpha: 0.48),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 228,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _SearchPhoto(
                      location: location,
                      categoryColor: categoryColor,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.54),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _CategoryChip(location: location),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _GlassTag(
                        icon: location.isOpenNow
                            ? Icons.radio_button_checked_rounded
                            : Icons.schedule_rounded,
                        label: location.isOpenNow ? 'Open now' : 'Closed',
                        foreground: location.isOpenNow
                            ? const Color(0xFF1E9E61)
                            : Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _GlassTag(
                                icon: Icons.star_rounded,
                                label:
                                    '${SpontiFormatter.rating(location.rating)} | ${SpontiFormatter.reviewCount(location.reviewCount)}',
                              ),
                              _GlassTag(
                                icon: Icons.payments_rounded,
                                label: location.priceRange.label,
                              ),
                              if (location.distanceKm != null)
                                _GlassTag(
                                  icon: Icons.near_me_rounded,
                                  label: SpontiFormatter.distance(
                                    location.distanceKm!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AddressLine(location: location),
                    if (location.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        location.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SpontiColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _MetaWrap(location: location)),
                        const SizedBox(width: 12),
                        _ActionOrb(color: categoryColor),
                      ],
                    ),
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

class _CompactSearchResultCard extends StatelessWidget {
  const _CompactSearchResultCard({
    required this.location,
    required this.onTap,
  });

  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return SearchGlassPanel(
      radius: 30,
      padding: EdgeInsets.zero,
      gradientColors: [
        Colors.white.withValues(alpha: 0.70),
        const Color(0xFFF7F0E8).withValues(alpha: 0.52),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: _SearchPhoto(
                      location: location,
                      categoryColor: categoryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: SpontiColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionOrb(color: categoryColor, compact: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _AddressLine(location: location),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TintedMetaPill(
                            icon: Icons.star_rounded,
                            label: SpontiFormatter.rating(location.rating),
                            color: SpontiColors.warning,
                          ),
                          _TintedMetaPill(
                            icon: location.category.icon,
                            label: location.category.label,
                            color: categoryColor,
                          ),
                          if (location.distanceKm != null)
                            _TintedMetaPill(
                              icon: Icons.near_me_rounded,
                              label: SpontiFormatter.distance(location.distanceKm!),
                              color: SpontiColors.secondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPhoto extends StatelessWidget {
  const _SearchPhoto({
    required this.location,
    required this.categoryColor,
  });

  final Location location;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return location.hasPhotos
        ? CachedNetworkImage(
            imageUrl: location.primaryPhoto,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => _SearchImageFallback(
              color: categoryColor,
              icon: location.category.icon,
            ),
          )
        : _SearchImageFallback(
            color: categoryColor,
            icon: location.category.icon,
          );
  }
}

class _SearchImageFallback extends StatelessWidget {
  const _SearchImageFallback({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.58),
            const Color(0xFFF3E7DA),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Colors.white.withValues(alpha: 0.84),
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.place_rounded,
          size: 16,
          color: SpontiColors.textSecondary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            location.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaWrap extends StatelessWidget {
  const _MetaWrap({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (location.isHiddenGem)
          const _TintedMetaPill(
            icon: Icons.auto_awesome_rounded,
            label: 'Hidden gem',
            color: SpontiColors.accent,
          ),
        if (location.hasWifi)
          const _TintedMetaPill(
            icon: Icons.wifi_rounded,
            label: 'Wi-Fi',
            color: SpontiColors.secondary,
          ),
        if (location.isPetFriendly)
          const _TintedMetaPill(
            icon: Icons.pets_rounded,
            label: 'Pet friendly',
            color: Color(0xFF7B4F2E),
          ),
      ],
    );
  }
}

class _ActionOrb extends StatelessWidget {
  const _ActionOrb({
    required this.color,
    this.compact = false,
  });

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 40 : 42,
      height: compact ? 40 : 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_outward_rounded,
        color: color,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final color = Color(location.category.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(location.category.icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            location.category.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({
    required this.icon,
    required this.label,
    this.foreground = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: foreground == Colors.white ? 0.14 : 0.72,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TintedMetaPill extends StatelessWidget {
  const _TintedMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
