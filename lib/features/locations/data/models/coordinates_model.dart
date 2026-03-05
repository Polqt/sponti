import 'package:sponti/features/locations/domain/entities/coordinates.dart';

class CoordinatesModel extends Coordinates {
  const CoordinatesModel({required super.latitude, required super.longitude});

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) =>
      CoordinatesModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  // For supabase PostGIS which stored as separate columns in the locations table.
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory CoordinatesModel.fromEntity(Coordinates entity) =>
      CoordinatesModel(latitude: entity.latitude, longitude: entity.longitude);
}
