import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/view/widgets/friend_avatar.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';

class FriendCard extends ConsumerWidget {
  const FriendCard({super.key, required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      friendRequestNotifierProvider.select((s) => s.isLoading),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: FriendAvatar(name: profile.fullName, avatarUrl: profile.avatarUrl),
      title: Text(
        profile.fullName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
        ),
      ),
      subtitle: profile.username?.isNotEmpty == true
          ? Text(
              '@${profile.username}',
              style: const TextStyle(fontSize: 13, color: SpontiColors.textMuted),
            )
          : null,
      onTap: () => context.push(RouteName.userProfilePath(profile.id)),
      trailing: TextButton(
        onPressed: isLoading ? null : () => _confirmAndRemove(context, ref),
        style: TextButton.styleFrom(
          foregroundColor: SpontiColors.error,
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: const Text('Remove'),
      ),
    );
  }

  Future<void> _confirmAndRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SpontiColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await ref.read(friendRequestNotifierProvider.notifier).removeFriend(profile.id);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
