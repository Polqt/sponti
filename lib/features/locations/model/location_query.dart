import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:sponti/features/locations/model/location.dart';

class LocationPageCursor extends Equatable {
  const LocationPageCursor({
    required this.createdAt,
    required this.id,
  });

  factory LocationPageCursor.fromLocation(Location location) {
    return LocationPageCursor(
      createdAt: location.createdAt.toUtc(),
      id: location.id,
    );
  }

  final DateTime createdAt;
  final String id;

  String encode() {
    return base64Url.encode(
      utf8.encode(
        jsonEncode(<String, dynamic>{
          'created_at': createdAt.toUtc().toIso8601String(),
          'id': id,
        }),
      ),
    );
  }

  static LocationPageCursor? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(raw)));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final createdAtRaw = json['created_at'] as String?;
      final id = json['id'] as String?;
      if (createdAtRaw == null || id == null || id.isEmpty) {
        return null;
      }

      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) return null;

      return LocationPageCursor(createdAt: createdAt.toUtc(), id: id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [createdAt, id];
}

class LocationPage extends Equatable {
  const LocationPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Location> items;
  final bool hasMore;
  final LocationPageCursor? nextCursor;

  @override
  List<Object?> get props => [items, hasMore, nextCursor];
}

class RankedLocationSearchRequest extends Equatable {
  const RankedLocationSearchRequest({
    required this.query,
    this.latitude,
    this.longitude,
    this.limit = 50,
  });

  final String query;
  final double? latitude;
  final double? longitude;
  final int limit;

  @override
  List<Object?> get props => [query, latitude, longitude, limit];
}
