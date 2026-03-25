import 'package:latlong2/latlong.dart';

class MarkerCollisionDetector {
  static double _getMinSeparationDegrees(double zoom) {
    if (zoom < 14.0) return 0.01;
    if (zoom < 15.0) return 0.002;
    if (zoom < 16.0) return 0.001;
    return 0.0005;
  }

  static bool hasCollision({
    required LatLng point1,
    required LatLng point2,
    required double zoom,
  }) {
    final minSep = _getMinSeparationDegrees(zoom);
    final dx = point1.latitude - point2.latitude;
    final dy = point1.longitude - point2.longitude;
    final distance = (dx * dx + dy * dy);
    return distance < (minSep * minSep);
  }

  static List<String> getCollidingMarkerIds({
    required Map<String, LatLng> markerPositions,
    required double zoom,
  }) {
    if (zoom < 14.0) return [];
    if (zoom >= 16.0) return [];

    final colliding = <String>[];
    final entries = markerPositions.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        if (hasCollision(
          point1: entries[i].value,
          point2: entries[j].value,
          zoom: zoom,
        )) {
          colliding.add(entries[j].key);
        }
      }
    }

    return colliding;
  }
}
