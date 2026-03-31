import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

class LocationCategoryRow extends StatelessWidget {
  const LocationCategoryRow({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedCategory;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _CategoryPill(
            label: 'All',
            isSelected: selected == null,
            accent: SpontiColors.primary,
            onTap: () => onChanged(null),
            icon: const Icon(Icons.grid_view_rounded),
          ),
          for (final category in LocationCategory.values) ...[
            const SizedBox(width: 10),
            _CategoryPill(
              label: category.label,
              isSelected: selected == category,
              accent: Color(category.colorValue),
              onTap: () => onChanged(selected == category ? null : category),
              icon: LocationCategoryIcon(
                category: category,
                color: Color(category.colorValue),
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? accent : SpontiColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 48,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 8,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? accent.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                child: IconTheme(
                  data: IconThemeData(size: 18, color: foreground),
                  child: Center(child: icon),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
