import 'package:equatable/equatable.dart';

class Coordinates extends Equatable {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object> get props => [latitude, longitude];

  @override
  String toString() =>
      'Coordinates(latitude: $latitude, longitude: $longitude)';
}
