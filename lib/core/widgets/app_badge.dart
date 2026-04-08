import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

/// Wraps [child] with a small red dot badge when [count] > 0.
/// Used on the Profile tab icon to indicate pending friend requests.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: SpontiColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: SpontiColors.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
