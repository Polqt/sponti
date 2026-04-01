import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/map_label_layout.dart';
import 'package:sponti/features/locations/utils/map_pin_label_text.dart';
import 'package:sponti/features/locations/utils/marker_collision_detector.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/map_pin.dart';

typedef LocationMarkerTapCallback = void Function(Location location);

List<Marker> buildLocationMarkers({
  required List<Location> locations,
  required String? selectedId,
  required double zoom,
  required String keyPrefix,
  required LocationMarkerTapCallback onTap,
  LocationRankingSnapshot? rankingSnapshot,
  LocationRanking? activeRankingFilter,
  PriceRange? activePriceFilter,
}) {
  final effectiveRankingSnapshot = rankingSnapshot ?? locations.createRankingSnapshot();
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
      ranking: effectiveRankingSnapshot.rankingFor(location),
    );
  }).toList()
    ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  final markerPositions = {
    for (final data in markerData) data.location.id: data.point,
  };
  final labelTexts = {
    for (final data in markerData)
      data.location.id: MapPinLabelText.fromName(data.location.name),
  };
  final labelLayouts = MarkerCollisionDetector.computeLabelLayouts(
    markerPositions: markerPositions,
    labelTexts: labelTexts,
    zoom: zoom,
    selectedId: selectedId,
  );

  return markerData.map((data) {
    final labelLayout = labelLayouts[data.location.id] ?? const MapPinLabelLayout.hidden();

    return Marker(
      point: data.point,
      width: MapPin.canvasWidth,
      height: MapPin.canvasHeight,
      alignment: Alignment.center,
      child: RepaintBoundary(
        child: MapPin(
          key: ValueKey('${keyPrefix}_${data.location.id}'),
          category: data.location.category,
          isSelected: data.isSelected,
          onTap: () => onTap(data.location),
          labelText: labelLayout.showLabel ? labelTexts[data.location.id] : null,
          priceRange: data.location.priceRange,
          ranking: data.ranking,
          activeRankingFilter: activeRankingFilter,
          activePriceFilter: activePriceFilter,
          labelPlacement: labelLayout.placement,
          labelDistanceFactor: labelLayout.distanceFactor,
        ),
      ),
    );
  }).toList(growable: false);
}
