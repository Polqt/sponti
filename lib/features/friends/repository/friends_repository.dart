import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/friends/model/friend_activity.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';

abstract interface class FriendsRepository {
  /// Live stream of incoming pending requests for the current user.
  Stream<List<FriendRequest>> watchIncomingRequests(String myId);

  /// Live stream of confirmed friend connections for the current user.
  /// Returns raw maps; use [getFriendConnections] to get hydrated models.
  Stream<List<Map<String, dynamic>>> watchConnections(String myId);

  /// Send a friend request to [receiverId].
  Future<Either<Failure, FriendRequest>> sendRequest(String receiverId);

  /// Cancel a sent request.
  Future<Either<Failure, void>> cancelRequest(String requestId);

  /// Accept an incoming request.
  Future<Either<Failure, void>> acceptRequest(String requestId);

  /// Decline an incoming request.
  Future<Either<Failure, void>> declineRequest(String requestId);

  /// Remove a friend.
  Future<Either<Failure, void>> removeFriend(String friendId);

  /// Fetch the friendship status between the current user and [otherUserId].
  Future<Either<Failure, FriendRequest?>> getRequestBetween(String otherUserId);

  /// Search users by username or full name.
  Future<Either<Failure, List<UserProfileModel>>> searchUsers(String query);

  /// Paginated friend activity feed.
  Future<Either<Failure, List<FriendActivity>>> getFriendActivity({
    int limit = 20,
    int offset = 0,
  });
}
