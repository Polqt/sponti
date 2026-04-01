import 'dart:ui' show Rect;

enum MapPinLabelPlacement {
  right,
  left,
  top,
  bottom,
}

class MapPinLabelLayout {
  const MapPinLabelLayout({
    required this.showLabel,
    required this.placement,
    required this.distanceFactor,
  });

  const MapPinLabelLayout.hidden()
    : showLabel = false,
      placement = MapPinLabelPlacement.right,
      distanceFactor = 1.0;

  final bool showLabel;
  final MapPinLabelPlacement placement;
  final double distanceFactor;
}

class ScreenMapPinLabelLayout {
  const ScreenMapPinLabelLayout({
    required this.showLabel,
    required this.placement,
    this.rect,
  });

  const ScreenMapPinLabelLayout.hidden()
    : showLabel = false,
      placement = MapPinLabelPlacement.right,
      rect = null;

  final bool showLabel;
  final MapPinLabelPlacement placement;
  final Rect? rect;
}
