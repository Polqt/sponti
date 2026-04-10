import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/friends/model/friend_activity.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/friends/repository/friends_remote_data_source.dart';
import 'package:sponti/features/friends/repository/friends_repository.dart';
import 'package:sponti/features/friends/repository/friends_repository_impl.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final friendsRemoteDataSourceProvider = Provider<FriendsRemoteDataSource>((ref) {
  return FriendsRemoteDataSourceImpl(Supabase.instance.client);
});

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepositoryImpl(ref.read(friendsRemoteDataSourceProvider));
});


// Live stream of incoming pending friend requests for the current user.
final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final myId = ref.watch(currentUserIdProvider);
  if (myId == null) return const Stream.empty();
  return ref.read(friendsRepositoryProvider).watchIncomingRequests(myId);
});

// Count of pending incoming requests 
final pendingRequestCountProvider = Provider<int>((ref) {
  return ref
      .watch(incomingRequestsProvider.select((s) => s.valueOrNull?.length ?? 0));
});

// Live stream of the current user's raw friend_connections rows.
final friendConnectionsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final myId = ref.watch(currentUserIdProvider);
  if (myId == null) return const Stream.empty();
  return ref.read(friendsRepositoryProvider).watchConnections(myId);
});


enum FriendshipStatus { none, pendingSent, pendingReceived, friends }

final friendshipStatusProvider =
    FutureProvider.family<FriendshipStatus, String>((ref, userId) async {
  final myId = ref.watch(currentUserIdProvider);
  if (myId == null) return FriendshipStatus.none;

  // Check connections stream first (realtime).
  final connections = ref.watch(friendConnectionsStreamProvider).valueOrNull;
  if (connections != null) {
    final isFriend = connections.any((c) => c['friend_id'] == userId);
    if (isFriend) return FriendshipStatus.friends;
  }

  // Check incoming requests stream (realtime).
  final incoming = ref.watch(incomingRequestsProvider).valueOrNull;
  if (incoming != null) {
    final hasPendingFromThem =
        incoming.any((r) => r.senderId == userId && r.status == FriendRequestStatus.pending);
    if (hasPendingFromThem) return FriendshipStatus.pendingReceived;
  }

  // Fall back to RPC for sent requests.
  final repo = ref.read(friendsRepositoryProvider);
  final result = await repo.getRequestBetween(userId);
  return result.fold((_) => FriendshipStatus.none, (req) {
    if (req == null) return FriendshipStatus.none;
    if (req.status == FriendRequestStatus.accepted) return FriendshipStatus.friends;
    if (req.senderId == myId) return FriendshipStatus.pendingSent;
    return FriendshipStatus.pendingReceived;
  });
});


class FriendRequestNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> sendRequest(String receiverId) async {
    state = const AsyncLoading();
    final result =
        await ref.read(friendsRepositoryProvider).sendRequest(receiverId);
    state = const AsyncData(null);
    return result.fold((f) => f.message, (_) {
      // Invalidate status for this user so the button refreshes.
      ref.invalidate(friendshipStatusProvider(receiverId));
      return null;
    });
  }

  Future<String?> cancelRequest(String requestId, String otherUserId) async {
    state = const AsyncLoading();
    final result =
        await ref.read(friendsRepositoryProvider).cancelRequest(requestId);
    state = const AsyncData(null);
    return result.fold((f) => f.message, (_) {
      ref.invalidate(friendshipStatusProvider(otherUserId));
      return null;
    });
  }

  Future<String?> acceptRequest(String requestId, String senderId) async {
    state = const AsyncLoading();
    final result =
        await ref.read(friendsRepositoryProvider).acceptRequest(requestId);
    state = const AsyncData(null);
    return result.fold((f) => f.message, (_) {
      ref.invalidate(friendshipStatusProvider(senderId));
      return null;
    });
  }

  Future<String?> declineRequest(String requestId, String senderId) async {
    state = const AsyncLoading();
    final result =
        await ref.read(friendsRepositoryProvider).declineRequest(requestId);
    state = const AsyncData(null);
    return result.fold((f) => f.message, (_) {
      ref.invalidate(friendshipStatusProvider(senderId));
      return null;
    });
  }

  Future<String?> removeFriend(String friendId) async {
    state = const AsyncLoading();
    final result =
        await ref.read(friendsRepositoryProvider).removeFriend(friendId);
    state = const AsyncData(null);
    return result.fold((f) => f.message, (_) {
      ref.invalidate(friendshipStatusProvider(friendId));
      return null;
    });
  }
}

final friendRequestNotifierProvider =
    AsyncNotifierProvider<FriendRequestNotifier, void>(FriendRequestNotifier.new);


class SearchUsersNotifier extends AutoDisposeAsyncNotifier<List<UserProfileModel>> {
  @override
  Future<List<UserProfileModel>> build() async => const [];

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    final result =
        await ref.read(friendsRepositoryProvider).searchUsers(query.trim());
    state = result.fold(
      (f) => AsyncError(f.message, StackTrace.current),
      AsyncData.new,
    );
  }
}

final searchUsersProvider =
    AutoDisposeAsyncNotifierProvider<SearchUsersNotifier, List<UserProfileModel>>(
  SearchUsersNotifier.new,
);

const _friendActivityPageSize = 20;

class FriendActivityNotifier extends AsyncNotifier<List<FriendActivity>> {
  int _offset = 0;
  bool _hasMore = false;
  bool _isFetchingNextPage = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FriendActivity>> build() async {
    _offset = 0;
    _hasMore = false;
    final result = await ref
        .read(friendsRepositoryProvider)
        .getFriendActivity(limit: _friendActivityPageSize + 1, offset: 0);
    return result.fold((f) => throw f.message, (items) {
      _hasMore = items.length > _friendActivityPageSize;
      final page = _hasMore ? items.sublist(0, _friendActivityPageSize) : items;
      _offset = page.length;
      return page;
    });
  }

  Future<String?> fetchNextPage() async {
    if (!_hasMore || _isFetchingNextPage) return null;
    _isFetchingNextPage = true;
    try {
      final result = await ref.read(friendsRepositoryProvider).getFriendActivity(
            limit: _friendActivityPageSize + 1,
            offset: _offset,
          );
      return result.fold((f) => f.message, (items) {
        _hasMore = items.length > _friendActivityPageSize;
        final page = _hasMore ? items.sublist(0, _friendActivityPageSize) : items;
        _offset += page.length;
        final current = state.valueOrNull ?? [];
        state = AsyncData([...current, ...page]);
        return null;
      });
    } finally {
      _isFetchingNextPage = false;
    }
  }
}

final friendActivityProvider =
    AsyncNotifierProvider<FriendActivityNotifier, List<FriendActivity>>(
  FriendActivityNotifier.new,
);

/// Suggested users to add as friends (people you may know).
/// Reuses searchUsers with empty query — the RPC excludes existing friends.
final suggestedUsersProvider =
    FutureProvider.autoDispose<List<UserProfileModel>>((ref) async {
  final result =
      await ref.read(friendsRepositoryProvider).searchUsers('');
  return result.fold((_) => const [], (users) => users);
});
