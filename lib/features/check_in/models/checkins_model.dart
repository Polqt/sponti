import 'package:sponti/features/check_in/models/checkins.dart';

class CheckInModel extends CheckIn {
  const CheckInModel({
    required super.id,
    required super.locationId,
    required super.userId,
    required super.createdAt,
    super.note,
    super.photoUrl,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) => CheckInModel(
    id: json['id'] as String,
    locationId: json['location_id'] as String,
    userId: json['user_id'] as String,
    note: json['note'] as String?,
    photoUrl: json['photo_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'location_id': locationId,
    'user_id': userId,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (photoUrl != null) 'photo_url': photoUrl,
  };
}
