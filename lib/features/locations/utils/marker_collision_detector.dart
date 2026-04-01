import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:latlong2/latlong.dart';
import 'package:sponti/core/constants/map_constants.dart';
import 'package:sponti/features/locations/utils/map_label_layout.dart';
import 'package:sponti/features/locations/utils/map_pin_label_text.dart';

class MarkerCollisionDetector {
  static const _geoDensityMultiplier = 2.45;
  static const _geoPinRadiusMultiplier = 0.56;
  static const _geoBaseGapMultiplier = 0.86;

  static Map<String, MapPinLabelLayout> computeLabelLayouts({
    required Map<String, LatLng> markerPositions,
    required Map<String, MapPinLabelText> labelTexts,
    required double zoom,
    String? selectedId,
  }) {
    if (markerPositions.isEmpty) {
      return const <String, MapPinLabelLayout>{};
    }

    if (zoom < MapConstants.labelVisibilityZoom) {
      return {
        for (final id in markerPositions.keys) id: const MapPinLabelLayout.hidden(),
      };
    }

    final separation = _geoSeparationForZoom(zoom);
    final occupiedRects = <String, _GeoRect>{};
    final pinRects = _buildGeoPinRects(markerPositions, separation);
    final densityRadius = separation * _geoDensityMultiplier;
    final orderedIds = _orderedIdsForGeoMarkers(
      markerPositions: markerPositions,
      labelTexts: labelTexts,
      selectedId: selectedId,
      densityRadiusSquared: densityRadius * densityRadius,
    );
    final layouts = <String, MapPinLabelLayout>{};

    for (final id in orderedIds) {
      final labelText = labelTexts[id] ?? MapPinLabelText.fromName(id);
      final placement = _findGeoPlacement(
        id: id,
        point: markerPositions[id]!,
        markerPositions: markerPositions,
        pinRects: pinRects,
        occupiedRects: occupiedRects.values,
        labelText: labelText,
        separation: separation,
        zoom: zoom,
      );

      final shouldShow =
          id == selectedId || placement.cost < _geoHideThreshold(zoom, labelText.lineCount);

      if (shouldShow && placement.rect != null) {
        occupiedRects[id] = placement.rect!;
      }

      layouts[id] = MapPinLabelLayout(
        showLabel: shouldShow,
        placement: placement.placement,
        distanceFactor: placement.distanceFactor,
      );
    }

    return layouts;
  }

  static Map<String, ScreenMapPinLabelLayout> computeScreenLabelLayouts({
    required Map<String, Offset> markerCenters,
    required Map<String, MapPinLabelText> labelTexts,
    required Size viewportSize,
    required double zoom,
    String? selectedId,
    double markerDiameter = 36,
    EdgeInsets viewportPadding = const EdgeInsets.all(
      MapConstants.labelViewportInset,
    ),
  }) {
    if (markerCenters.isEmpty || viewportSize.isEmpty) {
      return const <String, ScreenMapPinLabelLayout>{};
    }

    if (zoom < MapConstants.labelVisibilityZoom) {
      return {
        for (final id in markerCenters.keys)
          id: const ScreenMapPinLabelLayout.hidden(),
      };
    }

    final layouts = <String, ScreenMapPinLabelLayout>{};
    final occupiedRects = <String, Rect>{};
    final densityRadius = _screenDensityRadius(zoom);
    final markerRects = {
      for (final entry in markerCenters.entries)
        entry.key: Rect.fromCenter(
          center: entry.value,
          width: markerDiameter + 10,
          height: markerDiameter + 10,
        ),
    };
    final orderedIds = _orderedIdsForScreenMarkers(
      markerCenters: markerCenters,
      labelTexts: labelTexts,
      selectedId: selectedId,
      densityRadiusSquared: densityRadius * densityRadius,
    );

    for (final id in orderedIds) {
      final labelText = labelTexts[id] ?? MapPinLabelText.fromName(id);
      final placement = _findScreenPlacement(
        id: id,
        center: markerCenters[id]!,
        markerRects: markerRects,
        occupiedRects: occupiedRects.values,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        labelText: labelText,
        zoom: zoom,
      );

      final shouldShow =
          id == selectedId ||
          placement.isCollisionFree ||
          (zoom >= 16.15 && placement.rect != Rect.zero) ||
          placement.cost < _screenHideThreshold(zoom, labelText.lineCount);

      if (shouldShow && placement.rect != Rect.zero) {
        occupiedRects[id] = placement.rect;
      }

      layouts[id] = ScreenMapPinLabelLayout(
        showLabel: shouldShow,
        placement: placement.placement,
        rect: shouldShow && placement.rect != Rect.zero ? placement.rect : null,
      );
    }

    return layouts;
  }

  static double _geoSeparationForZoom(double zoom) {
    if (zoom < 14.0) return 0.01;
    if (zoom < 15.0) return 0.002;
    if (zoom < 16.0) return 0.001;
    return 0.0005;
  }

  static Map<String, _GeoRect> _buildGeoPinRects(
    Map<String, LatLng> markerPositions,
    double separation,
  ) {
    final pinRadius = separation * _geoPinRadiusMultiplier;
    return {
      for (final entry in markerPositions.entries)
        entry.key: _GeoRect.fromLatLng(entry.value, radius: pinRadius),
    };
  }

  static List<String> _orderedIdsForGeoMarkers({
    required Map<String, LatLng> markerPositions,
    required Map<String, MapPinLabelText> labelTexts,
    required String? selectedId,
    required double densityRadiusSquared,
  }) {
    final densities = {
      for (final id in markerPositions.keys)
        id: markerPositions.entries.where((other) {
          if (other.key == id) return false;
          final point = markerPositions[id]!;
          final dx = point.latitude - other.value.latitude;
          final dy = point.longitude - other.value.longitude;
          return (dx * dx + dy * dy) <= densityRadiusSquared;
        }).length,
    };

    final orderedIds = markerPositions.keys.toList(growable: false);
    orderedIds.sort((left, right) {
      if (left == selectedId) return -1;
      if (right == selectedId) return 1;

      final densityDiff =
          (densities[right] ?? 0).compareTo(densities[left] ?? 0);
      if (densityDiff != 0) return densityDiff;

      return _compareLabelPriority(
        left,
        right,
        labelTexts: labelTexts,
      );
    });
    return orderedIds;
  }

  static List<String> _orderedIdsForScreenMarkers({
    required Map<String, Offset> markerCenters,
    required Map<String, MapPinLabelText> labelTexts,
    required String? selectedId,
    required double densityRadiusSquared,
  }) {
    final densities = {
      for (final id in markerCenters.keys)
        id: markerCenters.entries.where((other) {
          if (other.key == id) return false;
          final point = markerCenters[id]!;
          final dx = point.dx - other.value.dx;
          final dy = point.dy - other.value.dy;
          return (dx * dx + dy * dy) <= densityRadiusSquared;
        }).length,
    };

    final orderedIds = markerCenters.keys.toList(growable: false);
    orderedIds.sort((left, right) {
      if (left == selectedId) return -1;
      if (right == selectedId) return 1;

      final densityDiff =
          (densities[right] ?? 0).compareTo(densities[left] ?? 0);
      if (densityDiff != 0) return densityDiff;

      return _compareLabelPriority(
        left,
        right,
        labelTexts: labelTexts,
      );
    });
    return orderedIds;
  }

  static int _compareLabelPriority(
    String left,
    String right, {
    required Map<String, MapPinLabelText> labelTexts,
  }) {
    final lineCountDiff =
        (labelTexts[right]?.lineCount ?? 0).compareTo(
          labelTexts[left]?.lineCount ?? 0,
        );
    if (lineCountDiff != 0) return lineCountDiff;

    return (labelTexts[right]?.maxLineLength ?? 0).compareTo(
      labelTexts[left]?.maxLineLength ?? 0,
    );
  }

  static _GeoPlacementResult _findGeoPlacement({
    required String id,
    required LatLng point,
    required Map<String, LatLng> markerPositions,
    required Map<String, _GeoRect> pinRects,
    required Iterable<_GeoRect> occupiedRects,
    required MapPinLabelText labelText,
    required double separation,
    required double zoom,
  }) {
    final maxLineLength = math.min(labelText.maxLineLength, 24);
    final lineCount = math.max(1, labelText.lineCount);

    var bestPlacement = MapPinLabelPlacement.right;
    var bestDistanceFactor = 1.0;
    var bestCost = double.infinity;
    _GeoRect? bestRect;

    for (final placement in MapPinLabelPlacement.values) {
      for (final distanceFactor in _geoDistanceFactorsForZoom(zoom)) {
        final rect = _buildGeoLabelRect(
          point: point,
          placement: placement,
          lineCount: lineCount,
          maxLineLength: maxLineLength,
          separation: separation,
          gap: separation * _geoBaseGapMultiplier * distanceFactor,
        );
        var cost = _placementBias(placement) + ((distanceFactor - 1) * 0.42);

        for (final otherEntry in markerPositions.entries) {
          if (otherEntry.key == id) continue;
          if (rect.containsPoint(otherEntry.value, padding: separation * 0.46)) {
            cost += 7.5;
          }
        }

        for (final pinEntry in pinRects.entries) {
          if (pinEntry.key == id) continue;
          if (rect.overlaps(pinEntry.value, padding: separation * 0.22)) {
            cost += 8.75;
          }
        }

        for (final occupiedRect in occupiedRects) {
          if (rect.overlaps(occupiedRect, padding: separation * 0.26)) {
            cost += 11.5;
          }
        }

        if (lineCount > 2 &&
            (placement == MapPinLabelPlacement.left ||
                placement == MapPinLabelPlacement.right)) {
          cost += 0.85;
        }

        if (cost < bestCost) {
          bestCost = cost;
          bestPlacement = placement;
          bestDistanceFactor = distanceFactor;
          bestRect = rect;
        }
      }
    }

    return _GeoPlacementResult(
      placement: bestPlacement,
      distanceFactor: bestDistanceFactor,
      cost: bestCost,
      rect: bestRect,
    );
  }

  static _ScreenPlacementResult _findScreenPlacement({
    required String id,
    required Offset center,
    required Map<String, Rect> markerRects,
    required Iterable<Rect> occupiedRects,
    required Size viewportSize,
    required EdgeInsets viewportPadding,
    required MapPinLabelText labelText,
    required double zoom,
  }) {
    final maxLineLength = math.min(labelText.maxLineLength, 24);
    final lineCount = math.max(1, labelText.lineCount);

    var bestPlacement = MapPinLabelPlacement.right;
    var bestRect = Rect.zero;
    var bestCost = double.infinity;
    var bestCollisionFreePlacement = MapPinLabelPlacement.right;
    var bestCollisionFreeRect = Rect.zero;
    var bestCollisionFreeCost = double.infinity;
    var hasCollisionFreeCandidate = false;

    for (final placement in MapPinLabelPlacement.values) {
      for (final distance in _screenDistancesForZoom(zoom)) {
        final rect = _clampRectToViewport(
          _buildScreenLabelRect(
            center: center,
            placement: placement,
            labelSize: _estimateScreenLabelSize(
              placement: placement,
              maxLineLength: maxLineLength,
              lineCount: lineCount,
            ),
            distance: distance,
          ),
          viewportSize,
          viewportPadding,
        );

        final ownMarkerRect = markerRects[id]!;
        if (rect.overlaps(ownMarkerRect.inflate(4))) {
          continue;
        }

        final overlapsOtherMarker = markerRects.entries.any(
          (entry) => entry.key != id && rect.overlaps(entry.value.inflate(6)),
        );
        final overlapsOtherLabel = occupiedRects.any(
          (occupiedRect) => rect.overlaps(occupiedRect.inflate(4)),
        );

        var cost = _placementBias(placement) + (distance / 100.0 * 0.22);
        cost += _offsetDistance(rect.center, center) / 14.0;
        cost += overlapsOtherMarker ? (zoom >= 16.0 ? 180.0 : 54.0) : 0.0;
        cost += overlapsOtherLabel ? (zoom >= 16.0 ? 220.0 : 72.0) : 0.0;

        if (lineCount > 2 &&
            (placement == MapPinLabelPlacement.left ||
                placement == MapPinLabelPlacement.right)) {
          cost += 1.2;
        }

        final isCollisionFree = !overlapsOtherMarker && !overlapsOtherLabel;
        if (isCollisionFree && cost < bestCollisionFreeCost) {
          hasCollisionFreeCandidate = true;
          bestCollisionFreeCost = cost;
          bestCollisionFreePlacement = placement;
          bestCollisionFreeRect = rect;
        }

        if (cost < bestCost) {
          bestCost = cost;
          bestPlacement = placement;
          bestRect = rect;
        }
      }
    }

    return hasCollisionFreeCandidate
        ? _ScreenPlacementResult(
            placement: bestCollisionFreePlacement,
            rect: bestCollisionFreeRect,
            cost: bestCollisionFreeCost,
            isCollisionFree: true,
          )
        : _ScreenPlacementResult(
            placement: bestPlacement,
            rect: bestRect,
            cost: bestCost,
            isCollisionFree: false,
          );
  }

  static _GeoRect _buildGeoLabelRect({
    required LatLng point,
    required MapPinLabelPlacement placement,
    required int lineCount,
    required int maxLineLength,
    required double separation,
    required double gap,
  }) {
    final labelWidth = placement == MapPinLabelPlacement.top ||
            placement == MapPinLabelPlacement.bottom
        ? separation * (1.58 + (maxLineLength / 8.8))
        : separation * (1.18 + (maxLineLength / 10.1));
    final labelHeight = separation * (0.34 + (lineCount * 0.56));

    return _GeoRect.fromLabel(
      point: point,
      placement: placement,
      labelWidth: labelWidth,
      labelHeight: labelHeight,
      gap: gap,
    );
  }

  static double _geoHideThreshold(double zoom, int lineCount) {
    final baseHideThreshold = zoom < 15.25
        ? 7.2
        : zoom < 15.95
        ? 10.4
        : double.infinity;
    return baseHideThreshold - ((lineCount - 1) * 0.45);
  }

  static double _screenHideThreshold(double zoom, int lineCount) {
    final baseHideThreshold = zoom < 15.2
        ? 15.0
        : zoom < 16.0
        ? 24.0
        : double.infinity;
    return baseHideThreshold - ((lineCount - 1) * 1.1);
  }

  static double _placementBias(MapPinLabelPlacement placement) =>
      switch (placement) {
        MapPinLabelPlacement.right => 0.0,
        MapPinLabelPlacement.left => 0.18,
        MapPinLabelPlacement.top => 0.26,
        MapPinLabelPlacement.bottom => 0.32,
      };

  static double _offsetDistance(Offset left, Offset right) {
    final delta = left - right;
    return delta.distance;
  }

  static Size _estimateScreenLabelSize({
    required MapPinLabelPlacement placement,
    required int maxLineLength,
    required int lineCount,
  }) {
    final isVertical =
        placement == MapPinLabelPlacement.top ||
        placement == MapPinLabelPlacement.bottom;
    final width = ((maxLineLength * 5.9) + (isVertical ? 8.0 : 4.0))
        .clamp(52.0, isVertical ? 156.0 : 144.0)
        .toDouble();
    final height =
        (14.0 + ((lineCount - 1) * 12.0)).clamp(16.0, 52.0).toDouble();
    return Size(width, height);
  }

  static Rect _buildScreenLabelRect({
    required Offset center,
    required MapPinLabelPlacement placement,
    required Size labelSize,
    required double distance,
  }) {
    final halfWidth = labelSize.width / 2;
    final halfHeight = labelSize.height / 2;

    return switch (placement) {
      MapPinLabelPlacement.right => Rect.fromLTWH(
        center.dx + distance,
        center.dy - halfHeight,
        labelSize.width,
        labelSize.height,
      ),
      MapPinLabelPlacement.left => Rect.fromLTWH(
        center.dx - distance - labelSize.width,
        center.dy - halfHeight,
        labelSize.width,
        labelSize.height,
      ),
      MapPinLabelPlacement.top => Rect.fromLTWH(
        center.dx - halfWidth,
        center.dy - distance - labelSize.height,
        labelSize.width,
        labelSize.height,
      ),
      MapPinLabelPlacement.bottom => Rect.fromLTWH(
        center.dx - halfWidth,
        center.dy + distance,
        labelSize.width,
        labelSize.height,
      ),
    };
  }

  static Rect _clampRectToViewport(
    Rect rect,
    Size viewportSize,
    EdgeInsets viewportPadding,
  ) {
    final leftBound = viewportPadding.left;
    final topBound = viewportPadding.top;
    final rightBound = viewportSize.width - viewportPadding.right;
    final bottomBound = viewportSize.height - viewportPadding.bottom;

    final shiftX = rect.left < leftBound
        ? leftBound - rect.left
        : rect.right > rightBound
        ? rightBound - rect.right
        : 0.0;
    final shiftY = rect.top < topBound
        ? topBound - rect.top
        : rect.bottom > bottomBound
        ? bottomBound - rect.bottom
        : 0.0;

    return rect.shift(Offset(shiftX, shiftY));
  }

  static double _screenDensityRadius(double zoom) {
    if (zoom < 15.0) return 74.0;
    if (zoom < 16.0) return 92.0;
    if (zoom < 17.0) return 108.0;
    return 122.0;
  }

  static List<double> _screenDistancesForZoom(double zoom) {
    if (zoom < 15.0) return const [20.0];
    if (zoom < 15.8) return const [20.0, 30.0, 42.0];
    if (zoom < 16.5) return const [20.0, 32.0, 46.0, 60.0];
    if (zoom < 17.2) return const [20.0, 34.0, 50.0, 66.0, 82.0];
    return const [20.0, 36.0, 54.0, 72.0, 92.0, 114.0];
  }

  static List<double> _geoDistanceFactorsForZoom(double zoom) {
    if (zoom < 15.05) return const [1.0];
    if (zoom < 15.85) return const [1.0, 1.28];
    if (zoom < 16.35) return const [1.0, 1.28, 1.56];
    if (zoom < 17.0) return const [1.0, 1.28, 1.56, 1.84];
    return const [1.0, 1.28, 1.56, 1.84, 2.08];
  }
}

class _GeoRect {
  const _GeoRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory _GeoRect.fromLatLng(LatLng point, {required double radius}) {
    return _GeoRect(
      left: point.longitude - radius,
      top: point.latitude - radius,
      right: point.longitude + radius,
      bottom: point.latitude + radius,
    );
  }

  factory _GeoRect.fromLabel({
    required LatLng point,
    required MapPinLabelPlacement placement,
    required double labelWidth,
    required double labelHeight,
    required double gap,
  }) {
    final x = point.longitude;
    final y = point.latitude;
    final halfWidth = labelWidth / 2;
    final halfHeight = labelHeight / 2;

    return switch (placement) {
      MapPinLabelPlacement.right => _GeoRect(
        left: x + gap,
        top: y - halfHeight,
        right: x + gap + labelWidth,
        bottom: y + halfHeight,
      ),
      MapPinLabelPlacement.left => _GeoRect(
        left: x - gap - labelWidth,
        top: y - halfHeight,
        right: x - gap,
        bottom: y + halfHeight,
      ),
      MapPinLabelPlacement.top => _GeoRect(
        left: x - halfWidth,
        top: y - gap - labelHeight,
        right: x + halfWidth,
        bottom: y - gap,
      ),
      MapPinLabelPlacement.bottom => _GeoRect(
        left: x - halfWidth,
        top: y + gap,
        right: x + halfWidth,
        bottom: y + gap + labelHeight,
      ),
    };
  }

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool overlaps(_GeoRect other, {double padding = 0}) {
    return left - padding < other.right + padding &&
        right + padding > other.left - padding &&
        top - padding < other.bottom + padding &&
        bottom + padding > other.top - padding;
  }

  bool containsPoint(LatLng point, {double padding = 0}) {
    final x = point.longitude;
    final y = point.latitude;
    return x >= left - padding &&
        x <= right + padding &&
        y >= top - padding &&
        y <= bottom + padding;
  }
}

class _GeoPlacementResult {
  const _GeoPlacementResult({
    required this.placement,
    required this.distanceFactor,
    required this.cost,
    required this.rect,
  });

  final MapPinLabelPlacement placement;
  final double distanceFactor;
  final double cost;
  final _GeoRect? rect;
}

class _ScreenPlacementResult {
  const _ScreenPlacementResult({
    required this.placement,
    required this.rect,
    required this.cost,
    required this.isCollisionFree,
  });

  final MapPinLabelPlacement placement;
  final Rect rect;
  final double cost;
  final bool isCollisionFree;
}
