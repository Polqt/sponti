import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blurSigma,
    this.opacity,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? blurSigma;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 16;
    final blur = blurSigma ?? 12;
    final alpha = opacity ?? 0.56;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: SpontiColors.surface.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: SpontiColors.outline.withValues(alpha: 0.65),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Icon(icon, size: 22, color: SpontiColors.textPrimary),
      ),
    );
  }
}
