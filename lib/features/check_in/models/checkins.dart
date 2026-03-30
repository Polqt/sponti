import 'package:equatable/equatable.dart';

class CheckIn extends Equatable {
  const CheckIn({
    required this.id,
    required this.locationId,
    required this.userId,
    required this.createdAt,
    this.note,
    this.photos = const [],
  });

  final String id;
  final String locationId;
  final String userId;
  final String? note;
  final List<String> photos;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, locationId, userId, note, photos, createdAt];
}
