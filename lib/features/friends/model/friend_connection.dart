import 'package:equatable/equatable.dart';
import 'package:sponti/features/profile/model/user_profile.dart';

/// A confirmed mutual friendship, includes the friend's profile for display.
class FriendConnection extends Equatable {
  const FriendConnection({
    required this.friendId,
    required this.profile,
    required this.connectedAt,
  });

  final String friendId;
  final UserProfile profile;
  final DateTime connectedAt;

  @override
  List<Object?> get props => [friendId, connectedAt];
}
