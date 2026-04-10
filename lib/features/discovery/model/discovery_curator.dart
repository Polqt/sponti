import 'package:equatable/equatable.dart';

class DiscoveryCurator extends Equatable {
  const DiscoveryCurator({
    required this.id,
    required this.fullName,
    required this.totalReviews,
    required this.totalCheckIns,
    required this.activityScore,
    this.username,
    this.avatarUrl,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? username;
  final String? avatarUrl;
  final int totalReviews;
  final int totalCheckIns;
  final int activityScore;
  final DateTime? updatedAt;

  factory DiscoveryCurator.fromJson(Map<String, dynamic> json) =>
      DiscoveryCurator._fromJson(json);

  factory DiscoveryCurator._fromJson(Map<String, dynamic> json) {
    final totalReviews = (json['total_reviews'] as num?)?.toInt() ?? 0;
    final totalCheckIns = (json['total_check_ins'] as num?)?.toInt() ?? 0;

    return DiscoveryCurator(
      id: (json['profile_id'] ?? json['id']) as String,
      fullName: (json['full_name'] as String? ?? '').trim(),
      username: (json['username'] as String?)?.trim(),
      avatarUrl: (json['avatar_url'] as String?)?.trim(),
      totalReviews: totalReviews,
      totalCheckIns: totalCheckIns,
      activityScore:
          (json['activity_score'] as num?)?.toInt() ??
          totalReviews + totalCheckIns,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (username != null && username!.isNotEmpty) return '@$username';
    return 'Sponti Curator';
  }

  String? get handle =>
      username != null && username!.isNotEmpty ? '@$username' : null;

  String get rankingKey {
    if (fullName.isNotEmpty) {
      return fullName.toLowerCase();
    }

    return (username ?? '').toLowerCase();
  }

  String get highlightLabel =>
      totalReviews >= totalCheckIns ? 'Review leader' : 'Check-in leader';

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    avatarUrl,
    totalReviews,
    totalCheckIns,
    activityScore,
    updatedAt,
  ];
}
