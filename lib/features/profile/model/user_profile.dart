import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.createdAt,
    this.username,
    this.bio,
    this.avatarUrl,
    this.checkInCount = 0,
    this.favoritesCount = 0,
    this.spotsSuggested = 0,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final int checkInCount;
  final int favoritesCount;
  final int spotsSuggested;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get displayName =>
      username != null && username!.isNotEmpty ? '@$username' : fullName;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  UserProfile copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    int? checkInCount,
    int? favoritesCount,
    int? spotsSuggested,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id,
    fullName: fullName ?? this.fullName,
    createdAt: createdAt,
    username: username ?? this.username,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    checkInCount: checkInCount ?? this.checkInCount,
    favoritesCount: favoritesCount ?? this.favoritesCount,
    spotsSuggested: spotsSuggested ?? this.spotsSuggested,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    bio,
    avatarUrl,
    checkInCount,
    favoritesCount,
    spotsSuggested,
  ];
}

// Stats summary returned from the API for the profile screen
class UserStats extends Equatable {
  const UserStats({
    required this.checkInCount,
    required this.favoritesCount,
    required this.spotsSuggested,
  });

  final int checkInCount;
  final int favoritesCount;
  final int spotsSuggested;

  @override
  List<Object?> get props => [checkInCount, favoritesCount, spotsSuggested];
}
