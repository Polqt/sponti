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
      child: Row(
        children: [
          _CategoryIconButton(
            isSelected: selected == null,
            color: SpontiColors.primary,
            onTap: () => onChanged(null),
            child: const Icon(Icons.grid_view_rounded),
          ),
          for (final category in LocationCategory.values) ...[
            const SizedBox(width: 10),
            _CategoryIconButton(
              isSelected: selected == category,
              color: Color(category.colorValue),
              onTap: () => onChanged(selected == category ? null : category),
              child: LocationCategoryIcon(
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

class _CategoryIconButton extends StatelessWidget {
  const _CategoryIconButton({
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? color : SpontiColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          child: IconTheme(
            data: IconThemeData(size: 18, color: foreground),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
