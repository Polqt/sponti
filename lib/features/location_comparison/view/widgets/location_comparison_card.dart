import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

class LocationComparisonCard extends StatelessWidget {
  const LocationComparisonCard({
    super.key,
    required this.location,
    required this.distanceLabel,
    this.compact = false,
  });

  final Location location;
  final String distanceLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTightLayout = compact || constraints.maxHeight < 320;
        final theme = _CardTheme.fromHeight(
          constraints.maxHeight.isFinite ? constraints.maxHeight : 320,
          forceCompact: useTightLayout,
        );
        final categoryColor = Color(location.category.colorValue);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SpontiColors.white,
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: Border.all(
              color: SpontiColors.outline.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: theme.heroHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (location.hasPhotos)
                      CachedNetworkImage(
                        imageUrl: location.primaryPhoto,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            CategoryShimmer(color: categoryColor),
                        errorWidget: (_, _, _) =>
                            CategoryGradient(category: location.category),
                      )
                    else
                      CategoryGradient(category: location.category),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.62),
                          ],
                          stops: const [0.38, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: theme.overlayInset,
                      left: theme.overlayInset,
                      child: _InfoBadge(
                        backgroundColor: categoryColor.withValues(alpha: 0.92),
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.badgeHorizontalPadding,
                          vertical: theme.badgeVerticalPadding,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              location.category.icon,
                              size: theme.badgeIconSize,
                              color: Colors.white,
                            ),
                            SizedBox(width: theme.badgeGap),
                            Text(
                              location.category.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: theme.badgeFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: theme.overlayInset,
                      right: theme.overlayInset,
                      child: _InfoBadge(
                        backgroundColor: location.isOpenNow
                            ? SpontiColors.success.withValues(alpha: 0.92)
                            : Colors.black.withValues(alpha: 0.55),
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.badgeHorizontalPadding,
                          vertical: theme.badgeVerticalPadding,
                        ),
                        child: Text(
                          location.isOpenNow ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: theme.badgeFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: theme.overlayInset,
                      right: theme.overlayInset,
                      bottom: theme.overlayInset,
                      child: Text(
                        location.name,
                        maxLines: useTightLayout ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: theme.titleFontSize,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.contentPadding,
                    theme.contentPadding,
                    theme.contentPadding,
                    theme.bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: theme.addressFontSize,
                          height: 1.2,
                          color: SpontiColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: theme.sectionGap),
                      Wrap(
                        spacing: theme.metricSpacing,
                        runSpacing: theme.metricRunSpacing,
                        children: [
                          _MetricChip(
                            icon: Icons.star_rounded,
                            color: SpontiColors.accent,
                            text:
                                '${SpontiFormatter.rating(location.rating)} - ${SpontiFormatter.reviewCount(location.reviewCount)}',
                            theme: theme,
                          ),
                          _MetricChip(
                            icon: Icons.payments_rounded,
                            color: SpontiColors.secondary,
                            text: location.priceRange.label,
                            theme: theme,
                          ),
                          _MetricChip(
                            icon: Icons.near_me_rounded,
                            color: SpontiColors.info,
                            text: distanceLabel,
                            theme: theme,
                          ),
                        ],
                      ),
                      SizedBox(height: theme.sectionGap),
                      Divider(
                        height: 1,
                        color: SpontiColors.outline.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: theme.sectionGap),
                      if (useTightLayout)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AmenityChip(
                              icon: Icons.wifi_rounded,
                              label: 'Wi-Fi',
                              isActive: location.hasWifi,
                              theme: theme,
                            ),
                            _AmenityChip(
                              icon: Icons.pets_rounded,
                              label: 'Pets',
                              isActive: location.isPetFriendly,
                              theme: theme,
                            ),
                            _AmenityChip(
                              icon: Icons.local_parking_rounded,
                              label: 'Park',
                              isActive: location.hasParking,
                              theme: theme,
                            ),
                          ],
                        )
                      else
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _AmenityDot(
                                  icon: Icons.wifi_rounded,
                                  label: 'Wi-Fi',
                                  isActive: location.hasWifi,
                                  theme: theme,
                                ),
                              ),
                              Expanded(
                                child: _AmenityDot(
                                  icon: Icons.pets_rounded,
                                  label: 'Pets',
                                  isActive: location.isPetFriendly,
                                  theme: theme,
                                ),
                              ),
                              Expanded(
                                child: _AmenityDot(
                                  icon: Icons.local_parking_rounded,
                                  label: 'Park',
                                  isActive: location.hasParking,
                                  theme: theme,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.backgroundColor,
    required this.padding,
    required this.child,
  });

  final Color backgroundColor;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.color,
    required this.text,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String text;
  final _CardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.metricHorizontalPadding,
        vertical: theme.metricVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: theme.metricIconSize, color: color),
          SizedBox(width: theme.metricIconGap),
          Text(
            text,
            style: TextStyle(
              fontSize: theme.metricFontSize,
              fontWeight: FontWeight.w700,
              color: SpontiColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityDot extends StatelessWidget {
  const _AmenityDot({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final _CardTheme theme;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SpontiColors.primary : SpontiColors.outline;
    final textColor =
        isActive ? SpontiColors.primary : SpontiColors.textMuted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: theme.amenityCircleSize,
          height: theme.amenityCircleSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isActive ? 0.14 : 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: theme.amenityIconSize,
            color: isActive ? color : SpontiColors.textMuted,
          ),
        ),
        SizedBox(height: theme.amenityGap),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: theme.amenityFontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final _CardTheme theme;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SpontiColors.primary : SpontiColors.textMuted;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.metricHorizontalPadding,
        vertical: theme.metricVerticalPadding - 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: theme.metricIconSize, color: color),
          SizedBox(width: theme.metricIconGap),
          Text(
            label,
            style: TextStyle(
              fontSize: theme.metricFontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTheme {
  const _CardTheme({
    required this.borderRadius,
    required this.heroHeight,
    required this.overlayInset,
    required this.titleFontSize,
    required this.badgeHorizontalPadding,
    required this.badgeVerticalPadding,
    required this.badgeIconSize,
    required this.badgeGap,
    required this.badgeFontSize,
    required this.contentPadding,
    required this.bottomPadding,
    required this.addressFontSize,
    required this.sectionGap,
    required this.metricSpacing,
    required this.metricRunSpacing,
    required this.metricHorizontalPadding,
    required this.metricVerticalPadding,
    required this.metricIconSize,
    required this.metricIconGap,
    required this.metricFontSize,
    required this.amenityCircleSize,
    required this.amenityIconSize,
    required this.amenityGap,
    required this.amenityFontSize,
  });

  factory _CardTheme.fromHeight(double height, {required bool forceCompact}) {
    if (forceCompact || height < 250) {
      return const _CardTheme(
        borderRadius: 20,
        heroHeight: 88,
        overlayInset: 10,
        titleFontSize: 16,
        badgeHorizontalPadding: 8,
        badgeVerticalPadding: 5,
        badgeIconSize: 10,
        badgeGap: 4,
        badgeFontSize: 10,
        contentPadding: 10,
        bottomPadding: 10,
        addressFontSize: 11,
        sectionGap: 6,
        metricSpacing: 6,
        metricRunSpacing: 6,
        metricHorizontalPadding: 9,
        metricVerticalPadding: 6,
        metricIconSize: 11,
        metricIconGap: 4,
        metricFontSize: 10,
        amenityCircleSize: 28,
        amenityIconSize: 14,
        amenityGap: 3,
        amenityFontSize: 9,
      );
    }

    if (height < 320) {
      return const _CardTheme(
        borderRadius: 22,
        heroHeight: 104,
        overlayInset: 12,
        titleFontSize: 18,
        badgeHorizontalPadding: 9,
        badgeVerticalPadding: 5,
        badgeIconSize: 11,
        badgeGap: 4,
        badgeFontSize: 10,
        contentPadding: 12,
        bottomPadding: 12,
        addressFontSize: 12,
        sectionGap: 8,
        metricSpacing: 8,
        metricRunSpacing: 8,
        metricHorizontalPadding: 10,
        metricVerticalPadding: 7,
        metricIconSize: 12,
        metricIconGap: 5,
        metricFontSize: 11,
        amenityCircleSize: 32,
        amenityIconSize: 15,
        amenityGap: 4,
        amenityFontSize: 10,
      );
    }

    return const _CardTheme(
      borderRadius: 24,
      heroHeight: 188,
      overlayInset: 14,
      titleFontSize: 22,
      badgeHorizontalPadding: 10,
      badgeVerticalPadding: 6,
      badgeIconSize: 12,
      badgeGap: 5,
      badgeFontSize: 11,
      contentPadding: 16,
      bottomPadding: 18,
      addressFontSize: 13,
      sectionGap: 14,
      metricSpacing: 10,
      metricRunSpacing: 10,
      metricHorizontalPadding: 12,
      metricVerticalPadding: 8,
      metricIconSize: 14,
      metricIconGap: 6,
      metricFontSize: 12,
      amenityCircleSize: 40,
      amenityIconSize: 18,
      amenityGap: 6,
      amenityFontSize: 11,
    );
  }

  final double borderRadius;
  final double heroHeight;
  final double overlayInset;
  final double titleFontSize;
  final double badgeHorizontalPadding;
  final double badgeVerticalPadding;
  final double badgeIconSize;
  final double badgeGap;
  final double badgeFontSize;
  final double contentPadding;
  final double bottomPadding;
  final double addressFontSize;
  final double sectionGap;
  final double metricSpacing;
  final double metricRunSpacing;
  final double metricHorizontalPadding;
  final double metricVerticalPadding;
  final double metricIconSize;
  final double metricIconGap;
  final double metricFontSize;
  final double amenityCircleSize;
  final double amenityIconSize;
  final double amenityGap;
  final double amenityFontSize;
}
