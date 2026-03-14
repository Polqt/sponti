import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : SpontiColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : SpontiColors.textSecondary,
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