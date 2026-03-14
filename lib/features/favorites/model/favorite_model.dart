import 'package:sponti/features/favorites/model/favorite.dart';
import 'package:sponti/features/locations/model/location_model.dart';

class FavoriteModel extends Favorite {
  const FavoriteModel({
    required super.locationId,
    required super.userId,
    required super.createdAt,
    super.location,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    final locationJson = json['locations'];

    return FavoriteModel(
      locationId: json['location_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      location: locationJson is Map<String, dynamic>
          ? LocationModel.fromJson(locationJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'location_id': locationId,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
  };
}
