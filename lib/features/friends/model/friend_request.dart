import 'package:equatable/equatable.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequest extends Equatable {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, senderId, receiverId, status, createdAt];
}
