import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class LocationMapAtmosphereOverlay extends StatelessWidget {
  const LocationMapAtmosphereOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.transparent,
                SpontiColors.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: _IsoGridPainter(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.8),
              radius: 1.1,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                SpontiColors.dark.withValues(alpha: 0.08),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _IsoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    final warmLinePaint = Paint()
      ..color = SpontiColors.primary.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 52.0;
    final diagonalSpan = size.height * 0.7;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + diagonalSpan, size.height),
        lightLinePaint,
      );
    }

    for (double x = 0; x < size.width + size.height; x += spacing * 1.2) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x - (size.height * 0.45), 0),
        warmLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
