import 'package:sponti/features/locations/model/location.dart';

class Favorite {
  const Favorite({
    required this.locationId,
    required this.userId,
    required this.createdAt,
    this.location,
  });

  final String locationId;
  final String userId;
  final DateTime createdAt;
  final Location? location;
}
