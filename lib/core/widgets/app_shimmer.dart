import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sponti/core/theme/app_colors.dart';

// Shimmer skeleton placeholder, use for any loading state.
class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  }) : _isCircle = false;

  const AppShimmer.circle({super.key, required double size})
    : height = size,
      width = size,
      borderRadius = 0,
      _isCircle = true;

  final double height;
  final double? width;
  final double borderRadius;
  final bool _isCircle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SpontiColors.surfaceVariant,
      highlightColor: SpontiColors.white,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: SpontiColors.surfaceVariant,
          shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: _isCircle ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// A column of shimmer lines that mimics a loading paragraph.
class ShimmerTextBlock extends StatelessWidget {
  const ShimmerTextBlock({
    super.key,
    this.lines = 3,
    this.lineHeight = 13,
    this.spacing = 8,
  });

  final int lines;
  final double lineHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (i) {
        final isLast = i == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: AppShimmer(
            height: lineHeight,
            // Last line is shorter to look natural
            width: isLast ? 140.0 : double.infinity,
          ),
        );
      }),
    );
  }
}
