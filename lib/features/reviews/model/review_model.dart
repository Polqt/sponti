import 'package:sponti/features/reviews/model/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.locationId,
    required super.userId,
    required super.rating,
    required super.comment,
    required super.photos,
    required super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      userId: json['user_id'] as String,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory ReviewModel.fromEntity(Review entity) => ReviewModel(
    id: entity.id,
    locationId: entity.locationId,
    userId: entity.userId,
    rating: entity.rating,
    comment: entity.comment,
    photos: entity.photos,
    createdAt: entity.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'location_id': locationId,
    'user_id': userId,
    'rating': rating,
    'comment': comment,
    'photos': photos,
    'created_at': createdAt.toIso8601String(),
  };
}
