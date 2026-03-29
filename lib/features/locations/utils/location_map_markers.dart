import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/map_pin.dart';
import 'package:sponti/features/locations/view/widgets/marker_collision_detector.dart';

typedef LocationMarkerTapCallback = void Function(Location location);

List<Marker> buildLocationMarkers({
  required List<Location> locations,
  required String? selectedId,
  required double zoom,
  required String keyPrefix,
  required LocationMarkerTapCallback onTap,
}) {
  final rankingSnapshot = locations.createRankingSnapshot();
  final markerData = locations.map((location) {
    final isSelected = location.id == selectedId;
    final zIndex =
        isSelected ? 1000.0 : 100.0 + (location.rating * 10).clamp(0.0, 100.0);

    return (
      location: location,
      isSelected: isSelected,
      zIndex: zIndex,
      point: LatLng(
        location.coordinates.latitude,
        location.coordinates.longitude,
      ),
      ranking: rankingSnapshot.rankingFor(location),
    );
  }).toList()
    ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  final markerPositions = {
    for (final data in markerData) data.location.id: data.point,
  };

  final collidingIds = MarkerCollisionDetector.getCollidingMarkerIds(
    markerPositions: markerPositions,
    zoom: zoom,
  );

  return markerData.map((data) {
    final shouldHideLabel =
        zoom < 16.0 && collidingIds.contains(data.location.id) && !data.isSelected;

    return Marker(
      point: data.point,
      width: 100,
      height: 50,
      alignment: Alignment.center,
      child: RepaintBoundary(
        child: GestureDetector(
          key: ValueKey('${keyPrefix}_${data.location.id}'),
          onTap: () => onTap(data.location),
          child: MapPin(
            category: data.location.category,
            isSelected: data.isSelected,
            locationName: shouldHideLabel ? null : data.location.name,
            ranking: data.ranking,
          ),
        ),
      ),
    );
  }).toList(growable: false);
}
