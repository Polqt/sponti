import 'package:sponti/features/locations/model/coordinates.dart';

class CoordinatesModel extends Coordinates {
  const CoordinatesModel({required super.latitude, required super.longitude});

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) =>
      CoordinatesModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory CoordinatesModel.fromEntity(Coordinates entity) =>
      CoordinatesModel(latitude: entity.latitude, longitude: entity.longitude);
}
