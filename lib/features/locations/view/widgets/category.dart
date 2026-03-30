import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/icon_helpers.dart';
import 'package:sponti/features/locations/model/location.dart';

class CategoryChip extends StatefulWidget {
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
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isSelected ? widget.color : SpontiColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected 
                ? widget.color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              if (widget.isSelected) ...[
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                      ? [
                          widget.color.withValues(alpha: 0.18),
                          widget.color.withValues(alpha: 0.12),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.65),
                          Colors.white.withValues(alpha: 0.45),
                        ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                          ? widget.color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.isSelected
                              ? widget.color.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: widget.isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: IconTheme(
                          data: IconThemeData(size: 14, color: foreground),
                          child: widget.leading ?? Icon(widget.icon, size: 14, color: foreground),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontSize: widget.isSelected ? 12.5 : 12,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: foreground,
                        height: 1.0,
                        letterSpacing: widget.isSelected ? 0.2 : 0,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
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
