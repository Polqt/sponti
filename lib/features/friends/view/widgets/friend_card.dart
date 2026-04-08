import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';

class FriendCard extends ConsumerWidget {
  const FriendCard({super.key, required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Avatar(avatarUrl: profile.avatarUrl, name: profile.fullName),
      title: Text(
        profile.fullName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
        ),
      ),
      subtitle: profile.username != null && profile.username!.isNotEmpty
          ? Text(
              '@${profile.username}',
              style: const TextStyle(
                fontSize: 13,
                color: SpontiColors.textMuted,
              ),
            )
          : null,
      onTap: () => context.push(RouteName.userProfilePath(profile.id)),
      trailing: _RemoveButton(friendId: profile.id),
    );
  }
}

class _RemoveButton extends ConsumerWidget {
  const _RemoveButton({required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      friendRequestNotifierProvider.select((s) => s.isLoading),
    );

    return TextButton(
      onPressed: isLoading
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirm = await _confirmRemove(context);
              if (!confirm) return;
              final err = await ref
                  .read(friendRequestNotifierProvider.notifier)
                  .removeFriend(friendId);
              if (err != null) {
                messenger.showSnackBar(SnackBar(content: Text(err)));
              }
            },
      style: TextButton.styleFrom(
        foregroundColor: SpontiColors.error,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: const Text('Remove'),
    );
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove Friend'),
            content: const Text('Are you sure you want to remove this friend?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: SpontiColors.error),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: SpontiColors.primaryLight.withValues(alpha: 0.3),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              initials,
              style: const TextStyle(
                color: SpontiColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            )
          : null,
    );
  }
}
