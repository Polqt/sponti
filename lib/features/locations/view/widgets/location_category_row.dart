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
            const SizedBox(width: 8),
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

class _CategoryPill extends StatefulWidget {
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
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isSelected ? widget.accent : SpontiColors.textSecondary;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSelected ? 14 : 8,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.accent.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected
                          ? widget.accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                  ),
                  child: IconTheme(
                    data: IconThemeData(size: 18, color: foreground),
                    child: Center(child: widget.icon),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
