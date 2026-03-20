import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/icon_helpers.dart';
import 'package:sponti/features/locations/model/location.dart';

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
