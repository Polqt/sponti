import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/friends/model/friend_activity.dart';
import 'package:sponti/features/friends/model/friend_request.dart';
import 'package:sponti/features/friends/repository/friends_remote_data_source.dart';
import 'package:sponti/features/friends/repository/friends_repository.dart';
import 'package:sponti/features/profile/model/user_profile_model.dart';

class FriendsRepositoryImpl extends BaseRepository implements FriendsRepository {
  const FriendsRepositoryImpl(this._remote);

  final FriendsRemoteDataSource _remote;

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String myId) =>
      _remote.watchIncomingRequests(myId);

  @override
  Stream<List<Map<String, dynamic>>> watchConnections(String myId) =>
      _remote.watchConnections(myId);

  @override
  Future<Either<Failure, FriendRequest>> sendRequest(String receiverId) =>
      guard(() => _remote.sendRequest(receiverId));

  @override
  Future<Either<Failure, void>> cancelRequest(String requestId) =>
      guard(() => _remote.cancelRequest(requestId));

  @override
  Future<Either<Failure, void>> acceptRequest(String requestId) =>
      guard(() => _remote.acceptRequest(requestId));

  @override
  Future<Either<Failure, void>> declineRequest(String requestId) =>
      guard(() => _remote.declineRequest(requestId));

  @override
  Future<Either<Failure, void>> removeFriend(String friendId) =>
      guard(() => _remote.removeFriend(friendId));

  @override
  Future<Either<Failure, FriendRequest?>> getRequestBetween(String otherUserId) =>
      guard(() => _remote.getRequestBetween(otherUserId));

  @override
  Future<Either<Failure, List<UserProfileModel>>> searchUsers(String query) =>
      guard(() => _remote.searchUsers(query));

  @override
  Future<Either<Failure, List<FriendActivity>>> getFriendActivity({
    int limit = 20,
    int offset = 0,
  }) => guard(() => _remote.getFriendActivity(limit: limit, offset: offset));
}
