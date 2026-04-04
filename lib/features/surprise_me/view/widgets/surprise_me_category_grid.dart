import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/location.dart';

class SurpriseMeCategoryGrid extends StatelessWidget {
  const SurpriseMeCategoryGrid({
    super.key,
    required this.selectedCategories,
    required this.onCategoryTapped,
  });

  final Set<LocationCategory> selectedCategories;
  final ValueChanged<LocationCategory> onCategoryTapped;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: LocationCategory.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final category = LocationCategory.values[index];
        return _CategoryChip(
          key: ValueKey(category.name),
          category: category,
          isSelected: selectedCategories.contains(category),
          onTap: () => onCategoryTapped(category),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final LocationCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
