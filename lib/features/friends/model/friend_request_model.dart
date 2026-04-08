import 'package:sponti/features/friends/model/friend_request.dart';

class FriendRequestModel extends FriendRequest {
  const FriendRequestModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.status,
    required super.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'sender_id': senderId,
    'receiver_id': receiverId,
    'status': 'pending',
  };

  Map<String, dynamic> toUpdateJson(FriendRequestStatus newStatus) => {
    'status': _statusToString(newStatus),
  };

  static FriendRequestStatus _parseStatus(String raw) => switch (raw) {
    'accepted' => FriendRequestStatus.accepted,
    'declined' => FriendRequestStatus.declined,
    _ => FriendRequestStatus.pending,
  };

  static String _statusToString(FriendRequestStatus s) => switch (s) {
    FriendRequestStatus.pending => 'pending',
    FriendRequestStatus.accepted => 'accepted',
    FriendRequestStatus.declined => 'declined',
  };
}
