import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/model/friend_activity.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';

class FriendActivityFeed extends ConsumerWidget {
  const FriendActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(friendActivityProvider);

    return feedAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: SpontiColors.primary),
        ),
      ),
      error: (e, _) => _EmptyState(
        icon: Icons.wifi_off_rounded,
        message: 'Could not load friend activity.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline_rounded,
            message:
                'No activity yet.\nAdd friends to see where they check in.',
          );
        }
        final notifier = ref.read(friendActivityProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map((item) => _ActivityCard(item: item)),
            if (notifier.hasMore) _LoadMoreButton(notifier: notifier),
          ],
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final FriendActivity item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteName.locationDetailPath(item.locationId)),
      child: Container(
        key: ValueKey(item.checkInId),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SpontiColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SpontiColors.outline),
          boxShadow: [
            BoxShadow(
              color: SpontiColors.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: SpontiColors.primaryLight.withValues(alpha: 0.3),
              backgroundImage: item.friendAvatar != null
                  ? NetworkImage(item.friendAvatar!)
                  : null,
              child: item.friendAvatar == null
                  ? Text(
                      item.friendFullName.isNotEmpty
                          ? item.friendFullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SpontiColors.primaryDark,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: SpontiColors.textPrimary,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: item.friendFullName.isNotEmpty
                              ? item.friendFullName
                              : '@${item.friendUsername}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' checked in at '),
                        TextSpan(
                          text: item.locationName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: SpontiColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${item.note}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SpontiColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: SpontiColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.locationAddress,
                          style: const TextStyle(
                            fontSize: 11,
                            color: SpontiColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(item.checkedInAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: SpontiColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _LoadMoreButton extends ConsumerWidget {
  const _LoadMoreButton({required this.notifier});

  final FriendActivityNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final err = await notifier.fetchNextPage();
          if (err != null) {
            messenger.showSnackBar(SnackBar(content: Text(err)));
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: SpontiColors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: const Text('Load more'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('friends-feed-empty'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: SpontiColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SpontiColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
