import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class SearchGlassPanel extends StatelessWidget {
  const SearchGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.backgroundColor,
    this.borderColor,
    this.gradientColors,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final resolvedGradient =
        gradientColors ??
        [
          Colors.white.withValues(alpha: 0.72),
          Colors.white.withValues(alpha: 0.46),
        ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: LinearGradient(
              colors: resolvedGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.86),
            ),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: SpontiColors.shadow.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}
