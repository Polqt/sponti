import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.category,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  final LocationCategory category;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedScale(
          scale: isSelected ? 1.18 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            width: isSelected ? 48 : 44,
            height: isSelected ? 48 : 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: isSelected ? 0.95 : 0.84),
                width: isSelected ? 2.6 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isSelected ? 0.28 : 0.18),
                  blurRadius: isSelected ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: isSelected ? 22 : 20,
                height: isSelected ? 22 : 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: LocationCategoryIcon(
                  category: category,
                  fallbackIcon: category.icon,
                  color: Colors.white,
                  size: isSelected ? 17 : 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
