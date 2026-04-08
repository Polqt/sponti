import 'package:equatable/equatable.dart';

class FriendActivity extends Equatable {
  const FriendActivity({
    required this.checkInId,
    required this.checkedInAt,
    this.note,
    this.photos = const [],
    required this.locationId,
    required this.locationName,
    required this.locationAddress,
    required this.locationCategory,
    this.locationPhoto,
    required this.friendId,
    required this.friendUsername,
    required this.friendFullName,
    this.friendAvatar,
  });

  final String checkInId;
  final DateTime checkedInAt;
  final String? note;
  final List<String> photos;
  final String locationId;
  final String locationName;
  final String locationAddress;
  final String locationCategory;
  final String? locationPhoto;
  final String friendId;
  final String friendUsername;
  final String friendFullName;
  final String? friendAvatar;

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final photosList = rawPhotos is List
        ? rawPhotos.map((e) => e.toString()).toList()
        : const <String>[];

    // location_photo comes back as a JSON-quoted string e.g. '"https://..."'
    String? parsePhoto(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString().replaceAll('"', '');
      return s.isEmpty ? null : s;
    }

    return FriendActivity(
      checkInId: json['check_in_id'] as String,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String).toLocal(),
      note: json['note'] as String?,
      photos: photosList,
      locationId: json['location_id'] as String,
      locationName: json['location_name'] as String,
      locationAddress: json['location_address'] as String? ?? '',
      locationCategory: json['location_category'] as String? ?? '',
      locationPhoto: parsePhoto(json['location_photo']),
      friendId: json['friend_id'] as String,
      friendUsername: json['friend_username'] as String? ?? '',
      friendFullName: json['friend_full_name'] as String? ?? '',
      friendAvatar: json['friend_avatar'] as String?,
    );
  }

  @override
  List<Object?> get props => [checkInId];
}
