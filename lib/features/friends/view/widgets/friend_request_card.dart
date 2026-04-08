import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/friends/view/widgets/friend_avatar.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class FriendRequestCard extends ConsumerWidget {
  const FriendRequestCard({super.key, required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(friendRequestNotifierProvider.notifier);
    final isLoading = ref.watch(
      friendRequestNotifierProvider.select((s) => s.isLoading),
    );
    final profile = ref.watch(userProfileProvider(request.senderId)).valueOrNull;

    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : profile?.username != null
            ? '@${profile!.username}'
            : '…';
    final handle = profile?.username != null ? '@${profile!.username}' : 'Wants to be friends';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(RouteName.userProfilePath(request.senderId)),
            child: FriendAvatar(
              name: profile?.fullName ?? '',
              avatarUrl: profile?.avatarUrl,
              radius: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  handle,
                  style: const TextStyle(fontSize: 12, color: SpontiColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButtons(
            isLoading: isLoading,
            onAccept: () => _act(context, () => notifier.acceptRequest(request.id, request.senderId)),
            onDecline: () => _act(context, () => notifier.declineRequest(request.id, request.senderId)),
          ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, Future<String?> Function() action) async {
    final err = await action();
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  static const _style = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: isLoading ? null : onAccept,
          style: FilledButton.styleFrom(
            backgroundColor: SpontiColors.primary,
            foregroundColor: SpontiColors.white,
          ).merge(_style),
          child: const Text('Accept'),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: isLoading ? null : onDecline,
          style: OutlinedButton.styleFrom(
            foregroundColor: SpontiColors.textSecondary,
            side: const BorderSide(color: SpontiColors.outline),
          ).merge(_style),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}
