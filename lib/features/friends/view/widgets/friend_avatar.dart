import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

/// Reusable circle avatar for friend-related widgets.
/// Shows [avatarUrl] if available, otherwise renders the first letter of [name].
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 22,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: SpontiColors.primaryLight.withValues(alpha: 0.3),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.65,
                fontWeight: FontWeight.w700,
                color: SpontiColors.primaryDark,
              ),
            )
          : null,
    );
  }
}
