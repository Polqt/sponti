import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/model/friend_activity.dart';
import 'package:sponti/features/friends/view/widgets/add_friend_button.dart';
import 'package:sponti/features/friends/view/widgets/friend_avatar.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';

class FriendActivityFeed extends ConsumerWidget {
  const FriendActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(friendActivityProvider);
    final suggestionsAsync = ref.watch(suggestedUsersProvider);

    return feedAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: SpontiColors.primary),
        ),
      ),
      error: (_, _) => _SuggestionsSection(suggestionsAsync: suggestionsAsync),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SuggestionsSection(suggestionsAsync: suggestionsAsync),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'Friend Activity'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyCard(
              icon: Icons.location_searching_rounded,
              title: 'No check-ins yet',
              subtitle: "When your friends check in somewhere, you'll see it here.",
            )
          else ...[
            ...items.map((item) => _ActivityCard(item: item)),
            if (ref.read(friendActivityProvider.notifier).hasMore)
              _LoadMoreButton(notifier: ref.read(friendActivityProvider.notifier)),
          ],
        ],
      ),
    );
  }
}

// ─── Suggestions (vertical list, no section header) ─────────────────────────

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({required this.suggestionsAsync});

  final AsyncValue<List<UserProfileModel>> suggestionsAsync;

  @override
  Widget build(BuildContext context) {
    return suggestionsAsync.when(
      loading: () => Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _SuggestionSkeleton(),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (users) {
        if (users.isEmpty) return const SizedBox.shrink();
        return Column(
          children: users
              .map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SuggestionCard(profile: u),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteName.userProfilePath(profile.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SpontiColors.white,
          borderRadius: BorderRadius.circular(14),
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
          children: [
            FriendAvatar(
              name: profile.fullName,
              avatarUrl: profile.avatarUrl,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.isNotEmpty ? profile.fullName : 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SpontiColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.username?.isNotEmpty == true)
                    Text(
                      '@${profile.username}',
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
            const SizedBox(width: 10),
            AddFriendButton(userId: profile.id),
          ],
        ),
      ),
    );
  }
}

class _SuggestionSkeleton extends StatelessWidget {
  const _SuggestionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ─── Activity feed ───────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final FriendActivity item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteName.locationDetailPath(item.locationId)),
      child: Container(
        key: ValueKey(item.checkInId),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SpontiColors.white,
          borderRadius: BorderRadius.circular(14),
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
            FriendAvatar(
              name: item.friendFullName,
              avatarUrl: item.friendAvatar,
              radius: 20,
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

// ─── Shared ───────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SpontiColors.textMuted, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SpontiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: SpontiColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: SpontiColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}
