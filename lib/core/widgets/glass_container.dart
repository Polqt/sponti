import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: SpontiColors.surface.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(16),
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
