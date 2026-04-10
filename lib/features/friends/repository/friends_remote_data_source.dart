import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart' as app_ex;
import 'package:sponti/features/friends/model/friend_activity.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/friends/model/friend_request_model.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FriendsRemoteDataSource {
  /// Live stream of incoming pending requests for the current user.
  Stream<List<FriendRequest>> watchIncomingRequests(String myId);

  /// Live stream of confirmed friend connections for the current user.
  Stream<List<Map<String, dynamic>>> watchConnections(String myId);

  /// Send a friend request to [receiverId].
  Future<FriendRequest> sendRequest(String receiverId);

  /// Cancel a sent request (delete).
  Future<void> cancelRequest(String requestId);

  /// Accept an incoming request.
  Future<void> acceptRequest(String requestId);

  /// Decline an incoming request.
  Future<void> declineRequest(String requestId);

  /// Remove a friend (deletes the connection row; trigger removes both sides).
  Future<void> removeFriend(String friendId);

  /// Fetch the friendship status between the current user and [otherUserId].
  /// Returns the request row if one exists, null if strangers.
  Future<FriendRequest?> getRequestBetween(String otherUserId);

  /// Search users by username or full name.
  Future<List<UserProfileModel>> searchUsers(String query);

  /// Paginated friend activity feed (check-ins from friends).
  Future<List<FriendActivity>> getFriendActivity({int limit = 20, int offset = 0});
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  const FriendsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String myId) {
    return _client
        .from(SupabaseTables.friendRequests)
        .stream(primaryKey: const ['id'])
        .eq('receiver_id', myId)
        .map((rows) => rows
            .where((r) => r['status'] == 'pending')
            .map((r) => FriendRequestModel.fromJson(
                Map<String, dynamic>.from(r as Map)))
            .toList(growable: false));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConnections(String myId) {
    return _client
        .from(SupabaseTables.friendConnections)
        .stream(primaryKey: const ['user_id', 'friend_id'])
        .eq('user_id', myId)
        .map((rows) => rows
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList(growable: false));
  }

  @override
  Future<FriendRequest> sendRequest(String receiverId) async {
    try {
      final response = await _client
          .from(SupabaseTables.friendRequests)
          .insert({'sender_id': _client.auth.currentUser!.id, 'receiver_id': receiverId})
          .select()
          .single();
      return FriendRequestModel.fromJson(
          Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    try {
      await _client
          .from(SupabaseTables.friendRequests)
          .delete()
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    try {
      await _client
          .from(SupabaseTables.friendRequests)
          .update({'status': 'accepted'})
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<void> declineRequest(String requestId) async {
    try {
      await _client
          .from(SupabaseTables.friendRequests)
          .update({'status': 'declined'})
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFriend(String friendId) async {
    try {
      final myId = _client.auth.currentUser!.id;
      await _client
          .from(SupabaseTables.friendConnections)
          .delete()
          .eq('user_id', myId)
          .eq('friend_id', friendId);
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<FriendRequest?> getRequestBetween(String otherUserId) async {
    try {
      final myId = _client.auth.currentUser!.id;
      final response = await _client
          .from(SupabaseTables.friendRequests)
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$myId)')
          .maybeSingle();
      if (response == null) return null;
      return FriendRequestModel.fromJson(
          Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<List<UserProfileModel>> searchUsers(String query) async {
    try {
      final response = await _client.rpc(
        SupabaseRPC.searchUsers,
        params: {'query': query, 'p_limit': 20, 'p_offset': 0},
      );
      return (response as List<dynamic>)
          .map((r) => UserProfileModel.fromJson(
              Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }

  @override
  Future<List<FriendActivity>> getFriendActivity({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc(
        SupabaseRPC.getFriendActivity,
        params: {'p_limit': limit + 1, 'p_offset': offset},
      );
      return (response as List<dynamic>)
          .map((r) => FriendActivity.fromJson(
              Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw app_ex.ServerException(e.message);
    } catch (e) {
      throw app_ex.ServerException(e.toString());
    }
  }
}
