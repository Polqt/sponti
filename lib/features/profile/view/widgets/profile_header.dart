import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_network_image.dart';
import 'package:sponti/features/profile/model/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.onEditTap,
    this.onAvatarTap,
  });

  final UserProfile profile;
  final VoidCallback? onEditTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SpontiColors.primary.withValues(alpha: 0.2),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: profile.hasAvatar
                        ? AppNetworkImage.circle(
                            url: profile.avatarUrl!,
                            size: 90,
                          )
                        : _DefaultAvatar(name: profile.fullName),
                  ),
                ),
                if (onAvatarTap != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: SpontiColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          if (profile.username != null && profile.username!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '@${profile.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SpontiColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SpontiColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (onEditTap != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: SpontiColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SpontiColors.outline),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SpontiColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.name});

  final String name;

  String get _initial => name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      color: SpontiColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: SpontiColors.primary,
          ),
        ),
      ),
    );
  }
}
