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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF9),
            Color(0xFFF7F1EA),
            Color(0xFFF0F4F0),
            SpontiColors.surface,
          ],
          stops: [0.0, 0.28, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -92,
            left: -54,
            child: _SearchBlurOrb(
              size: 240,
              color: Color(0x33E8612C),
            ),
          ),
          const Positioned(
            top: 64,
            right: -72,
            child: _SearchBlurOrb(
              size: 210,
              color: Color(0x262C8C8E),
            ),
          ),
          const Positioned(
            bottom: 160,
            left: -40,
            child: _SearchBlurOrb(
              size: 180,
              color: Color(0x22FFB830),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.26),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SearchBackdropPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SearchBlurOrb extends StatelessWidget {
  const _SearchBlurOrb({
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

class _SearchBackdropPainter extends CustomPainter {
  const _SearchBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = SpontiColors.outline.withValues(alpha: 0.14)
      ..strokeWidth = 1;

    final topArcRect = Rect.fromLTWH(
      size.width * 0.42,
      -size.height * 0.10,
      size.width * 0.78,
      size.height * 0.44,
    );
    canvas.drawArc(topArcRect, 2.7, 1.1, false, linePaint);

    final middleArcRect = Rect.fromLTWH(
      -size.width * 0.20,
      size.height * 0.44,
      size.width * 0.76,
      size.height * 0.28,
    );
    canvas.drawArc(middleArcRect, 4.2, 1.0, false, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
