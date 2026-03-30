import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

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

  Iterable<_FavoritesCategoryOption> get _options sync* {
    yield const _FavoritesCategoryOption(
      label: 'All',
      color: SpontiColors.primary,
      fallbackIcon: Icons.grid_view_rounded,
    );

    for (final category in LocationCategory.values) {
      yield _FavoritesCategoryOption(
        label: category.label,
        category: category,
        color: Color(category.colorValue),
        fallbackIcon: category.icon,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options.toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            _FavoritesCategoryChip(
              option: options[index],
              isSelected: selectedCategory == options[index].category,
              onTap: () => onChanged(
                selectedCategory == options[index].category
                    ? null
                    : options[index].category,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoritesCategoryOption {
  const _FavoritesCategoryOption({
    required this.label,
    required this.color,
    required this.fallbackIcon,
    this.category,
  });

  final String label;
  final LocationCategory? category;
  final Color color;
  final IconData fallbackIcon;
}

class _FavoritesCategoryChip extends StatelessWidget {
  const _FavoritesCategoryChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _FavoritesCategoryOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? option.color : SpontiColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: option.color.withValues(alpha: 0.1),
        highlightColor: option.color.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withValues(alpha: 0.12)
                : SpontiColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? option.color.withValues(alpha: 0.4)
                  : SpontiColors.outline,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: option.color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocationCategoryIcon(
                category: option.category,
                fallbackIcon: option.fallbackIcon,
                color: foregroundColor,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
