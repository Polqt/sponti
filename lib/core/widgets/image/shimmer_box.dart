import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sponti/core/theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, required this.width, required this.height});

  final double width;
  final double height;

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
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
