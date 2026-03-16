import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/core/utils/icon_helpers.dart';

List<Location> filterLocations(
  List<Location> locations,
  String rawQuery,
  LocationCategory? selectedCategory,
) {
  final query = rawQuery.trim().toLowerCase();

  return locations
      .where((location) {
        final matchesCategory =
            selectedCategory == null || location.category == selectedCategory;
        if (!matchesCategory) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final haystack = [
          location.name,
          location.address,
          location.category.label,
          ...location.tags,
        ].join(' ').toLowerCase();

        return haystack.contains(query);
      })
      .toList(growable: false);
}

class FavoritesCategoryFilters extends StatelessWidget {
  const FavoritesCategoryFilters({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FavoritesCategoryChip(
            label: 'All',
            iconAssetPath: null,
            fallbackIcon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null,
            color: SpontiColors.primary,
            onTap: () => onChanged(null),
          ),
          for (final category in LocationCategory.values) ...[
            const SizedBox(width: 10),
            _FavoritesCategoryChip(
              label: category.label,
              iconAssetPath: _categoryFilterAsset(category),
              fallbackIcon: _categoryFilterIcon(category),
              isSelected: selectedCategory == category,
              color: Color(category.colorValue),
              onTap: () =>
                  onChanged(selectedCategory == category ? null : category),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoritesCategoryChip extends StatelessWidget {
  const _FavoritesCategoryChip({
    required this.label,
    required this.iconAssetPath,
    required this.fallbackIcon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? iconAssetPath;
  final IconData fallbackIcon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? color : SpontiColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FavoritesCategoryIcon(
                assetPath: iconAssetPath,
                fallbackIcon: fallbackIcon,
                foregroundColor: foregroundColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryFilterIcon(LocationCategory category) {
  return switch (category) {
    LocationCategory.food => Icons.restaurant_rounded,
    LocationCategory.coffee => Icons.local_cafe_rounded,
    LocationCategory.nature => Icons.park_rounded,
    LocationCategory.nightlife => Icons.nightlife_rounded,
    LocationCategory.arts => Icons.palette_rounded,
    LocationCategory.activities => Icons.sports_esports_rounded,
  };
}

class _FavoritesCategoryIcon extends StatelessWidget {
  const _FavoritesCategoryIcon({
    required this.assetPath,
    required this.fallbackIcon,
    required this.foregroundColor,
  });

  final String? assetPath;
  final IconData fallbackIcon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return Icon(fallbackIcon, size: 16, color: foregroundColor);
    }

    return FutureBuilder<ResolvedCategoryIcon>(
      future: resolveCategoryIcon(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 16, height: 16);
        }

        final resolved = snapshot.data;
        if (resolved == null) {
          return Icon(fallbackIcon, size: 16, color: foregroundColor);
        }

        if (resolved.bytes != null) {
          return Image.memory(
            resolved.bytes!,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          );
        }

        if (resolved.svg != null) {
          return SvgPicture.string(
            resolved.svg!,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
          );
        }

        return Icon(fallbackIcon, size: 16, color: foregroundColor);
      },
    );
  }
}

String? _categoryFilterAsset(LocationCategory category) {
  return switch (category) {
    LocationCategory.food => 'assets/icons/munch.svg',
    LocationCategory.coffee => 'assets/icons/coffee.svg',
    LocationCategory.nature => 'assets/icons/stroll.svg',
    LocationCategory.nightlife => 'assets/icons/nightlife.svg',
    LocationCategory.arts => 'assets/icons/arts.svg',
    LocationCategory.activities => 'assets/icons/fun.svg',
  };
}
