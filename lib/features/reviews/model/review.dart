import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.locationId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.photos,
    required this.createdAt,
  });

  final String id;
  final String locationId;
  final String userId;
  final int rating;
  final String comment;
  final List<String> photos;
  final DateTime createdAt;

  bool get hasPhotos => photos.isNotEmpty;

  Review copyWith({
    int? rating,
    String? comment,
    List<String>? photos,
  }) => Review(
    id: id,
    locationId: locationId,
    userId: userId,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    photos: photos ?? this.photos,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    locationId,
    userId,
    rating,
    comment,
    photos,
    createdAt,
  ];
}
