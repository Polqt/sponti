import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/icon_helpers.dart';
import 'package:sponti/features/locations/model/location.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? color : SpontiColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: IconTheme(
                  data: IconThemeData(size: 14, color: foreground),
                  child: leading ?? Icon(icon, size: 14, color: foreground),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryGradient extends StatelessWidget {
  const CategoryGradient({
    super.key,
    required this.category,
    this.emojiFontSize = 36,
  });

  final LocationCategory category;
  final double emojiFontSize;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.5)],
        ),
      ),
      child: Center(
        child: Text(category.emoji, style: TextStyle(fontSize: emojiFontSize)),
      ),
    );
  }
}

extension LocationCategoryUi on LocationCategory {
  String? get assetPath => switch (this) {
    LocationCategory.food => 'assets/icons/munch.svg',
    LocationCategory.coffee => 'assets/icons/coffee.svg',
    LocationCategory.nature => 'assets/icons/stroll.svg',
    LocationCategory.nightlife => 'assets/icons/nightlife.svg',
    LocationCategory.arts => 'assets/icons/arts.svg',
    LocationCategory.activities => 'assets/icons/fun.svg',
  };
}

class LocationCategoryIcon extends StatelessWidget {
  const LocationCategoryIcon({
    super.key,
    this.category,
    this.assetPath,
    this.fallbackIcon,
    this.color = SpontiColors.textSecondary,
    this.size = 16,
  });

  final LocationCategory? category;
  final String? assetPath;
  final IconData? fallbackIcon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedAssetPath = assetPath ?? category?.assetPath;
    final resolvedFallbackIcon = fallbackIcon ?? category?.icon;

    if (resolvedAssetPath == null) {
      return Icon(
        resolvedFallbackIcon ?? Icons.category_rounded,
        size: size,
        color: color,
      );
    }

    return FutureBuilder<ResolvedCategoryIcon>(
      future: resolveCategoryIcon(resolvedAssetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(width: size, height: size);
        }

        final resolved = snapshot.data;
        if (resolved?.bytes != null) {
          return Image.memory(
            resolved!.bytes!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          );
        }

        if (resolved?.svg != null) {
          return SvgPicture.string(
            resolved!.svg!,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          );
        }

        return Icon(
          resolvedFallbackIcon ?? Icons.category_rounded,
          size: size,
          color: color,
        );
      },
    );
  }
}

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: color.withValues(alpha: 0.15),
      highlightColor: color.withValues(alpha: 0.05),
      child: Container(color: Colors.white),
    );
  }
}
