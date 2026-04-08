import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

/// A card showing an incoming friend request with Accept / Decline buttons.
/// Hydrates the sender's name and avatar via [userProfileProvider].
class FriendRequestCard extends ConsumerWidget {
  const FriendRequestCard({super.key, required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(friendRequestNotifierProvider.notifier);
    final isLoading = ref.watch(
      friendRequestNotifierProvider.select((s) => s.isLoading),
    );
    final profileAsync = ref.watch(userProfileProvider(request.senderId));

    final senderName = profileAsync.when(
      loading: () => '…',
      error: (_, _) => request.senderId,
      data: (p) => p == null
          ? request.senderId
          : (p.fullName.isNotEmpty ? p.fullName : '@${p.username ?? ''}'),
    );
    final senderHandle = profileAsync.valueOrNull?.username != null
        ? '@${profileAsync.valueOrNull!.username}'
        : null;
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    final initials = profileAsync.valueOrNull?.fullName.isNotEmpty == true
        ? profileAsync.valueOrNull!.fullName[0].toUpperCase()
        : '?';

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
            onTap: () =>
                context.push(RouteName.userProfilePath(request.senderId)),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: SpontiColors.primaryLight.withValues(alpha: 0.3),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SpontiColors.primaryDark,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  senderHandle ?? 'Wants to be friends',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SpontiColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final err = await notifier.acceptRequest(
                          request.id,
                          request.senderId,
                        );
                        if (err != null) {
                          messenger.showSnackBar(
                              SnackBar(content: Text(err)));
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: SpontiColors.primary,
                  foregroundColor: SpontiColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final err = await notifier.declineRequest(
                          request.id,
                          request.senderId,
                        );
                        if (err != null) {
                          messenger.showSnackBar(
                              SnackBar(content: Text(err)));
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: SpontiColors.textSecondary,
                  side: const BorderSide(color: SpontiColors.outline),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
