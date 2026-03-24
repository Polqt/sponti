import 'package:sponti/features/check_in/models/checkins.dart';

class CheckInModel extends CheckIn {
  const CheckInModel({
    required super.id,
    required super.locationId,
    required super.userId,
    required super.createdAt,
    super.note,
    super.photos,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    final photoList = (json['photos'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final legacyPhotoUrl = json['photo_url'] as String?;

    return CheckInModel(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      userId: json['user_id'] as String,
      note: json['note'] as String?,
      photos: photoList.isNotEmpty
          ? photoList
          : switch (legacyPhotoUrl) {
              final String url when url.isNotEmpty => [url],
              _ => const [],
            },
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'location_id': locationId,
    'user_id': userId,
    if (note != null && note!.isNotEmpty) 'note': note,
    'photos': photos,
    'photo_url': photos.isEmpty ? null : photos.first,
  };
}
