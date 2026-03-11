import 'package:sponti/features/profile/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    required super.createdAt,
    super.username,
    super.bio,
    super.avatarUrl,
    super.checkInCount,
    super.favoritesCount,
    super.spotsSuggested,
    super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        username: json['username'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        checkInCount: (json['check_in_count'] as num?)?.toInt() ?? 0,
        favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
        spotsSuggested: (json['spots_suggested'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    if (username != null) 'username': username,
    if (bio != null) 'bio': bio,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  factory UserProfileModel.fromEntity(UserProfile entity) => UserProfileModel(
    id: entity.id,
    fullName: entity.fullName,
    username: entity.username,
    bio: entity.bio,
    avatarUrl: entity.avatarUrl,
    checkInCount: entity.checkInCount,
    favoritesCount: entity.favoritesCount,
    spotsSuggested: entity.spotsSuggested,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}

class UserStatsModel extends UserStats {
  const UserStatsModel({
    required super.checkInCount,
    required super.favoritesCount,
    required super.spotsSuggested,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) => UserStatsModel(
    checkInCount: (json['check_in_count'] as num?)?.toInt() ?? 0,
    favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
    spotsSuggested: (json['spots_suggested'] as num?)?.toInt() ?? 0,
  );
}
