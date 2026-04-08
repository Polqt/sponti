import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/friends/view/widgets/friend_card.dart';
import 'package:sponti/features/friends/view/widgets/friend_request_card.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingRequestCountProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      appBar: AppBar(
        backgroundColor: SpontiColors.surface,
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SpontiColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: SpontiColors.primary,
          labelColor: SpontiColors.primary,
          unselectedLabelColor: SpontiColors.textMuted,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            const Tab(text: 'My Friends'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: SpontiColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SpontiColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FriendsTab(searchController: _searchController),
          const _RequestsTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Friends tab
// ---------------------------------------------------------------------------

class _FriendsTab extends ConsumerStatefulWidget {
  const _FriendsTab({required this.searchController});

  final TextEditingController searchController;

  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(friendConnectionsStreamProvider);
    final searchState = ref.watch(searchUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: widget.searchController,
            onChanged: (q) {
              ref.read(searchUsersProvider.notifier).search(q);
              setState(() => _isSearching = q.trim().isNotEmpty);
            },
            decoration: InputDecoration(
              hintText: 'Search users…',
              hintStyle: const TextStyle(
                color: SpontiColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: SpontiColors.textMuted,
                size: 20,
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        widget.searchController.clear();
                        ref.read(searchUsersProvider.notifier).search('');
                        setState(() => _isSearching = false);
                      },
                    )
                  : null,
              filled: true,
              fillColor: SpontiColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: _isSearching
              ? _SearchResults(searchState: searchState)
              : _FriendsList(connectionsAsync: connectionsAsync),
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.searchState});

  final AsyncValue<List<UserProfileModel>> searchState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return searchState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: SpontiColors.textMuted)),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: SpontiColors.textMuted),
            ),
          );
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) => FriendCard(profile: users[i]),
        );
      },
    );
  }
}

class _FriendsList extends ConsumerWidget {
  const _FriendsList({required this.connectionsAsync});

  final AsyncValue<List<Map<String, dynamic>>> connectionsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text(
          'Could not load friends.',
          style: TextStyle(color: SpontiColors.textMuted),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 48, color: SpontiColors.outline),
                  SizedBox(height: 12),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SpontiColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Search for users above to add friends.',
                    style: TextStyle(
                        fontSize: 13, color: SpontiColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final friendId = rows[i]['friend_id'] as String? ?? '';
            return _FriendProfileTile(friendId: friendId);
          },
        );
      },
    );
  }
}

class _FriendProfileTile extends ConsumerWidget {
  const _FriendProfileTile({required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(friendId));
    return profileAsync.when(
      loading: () => const ListTile(
        leading: CircleAvatar(
          backgroundColor: SpontiColors.surfaceVariant,
        ),
        title: SizedBox(
          height: 12,
          width: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(color: SpontiColors.outline),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return FriendCard(
          profile: UserProfileModel.fromEntity(profile),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Requests tab
// ---------------------------------------------------------------------------

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text(
          'Could not load requests.',
          style: TextStyle(color: SpontiColors.textMuted),
        ),
      ),
      data: (requests) {
        final pending = requests
            .where((r) => r.status == FriendRequestStatus.pending)
            .toList();
        if (pending.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_read_rounded,
                      size: 48, color: SpontiColors.outline),
                  SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SpontiColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: pending.length,
          itemBuilder: (_, i) => FriendRequestCard(request: pending[i]),
        );
      },
    );
  }
}
