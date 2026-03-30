import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class SearchScaffoldBackground extends StatelessWidget {
  const SearchScaffoldBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFCF7),
            const Color(0xFFF7F2EA),
            SpontiColors.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _SearchGlowOrb(
              size: 220,
              color: SpontiColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 120,
            right: -50,
            child: _SearchGlowOrb(
              size: 180,
              color: SpontiColors.secondary.withValues(alpha: 0.10),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SearchGlowOrb extends StatelessWidget {
  const _SearchGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
