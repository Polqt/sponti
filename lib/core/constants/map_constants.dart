import 'package:flutter/widgets.dart';

abstract final class MapConstants {
  // Default center coordinates (Bacolod City, Philippines)
  static const double defaultLatitude = 10.6765;
  static const double defaultLongitude = 122.9509;

  // Camera defaults
  static const double defaultZoom = 16.0;
  static const double defaultTilt = 42.0;
  static const double defaultBearing = -12.0;

  // Zoom bounds
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;

  // Zoom tier thresholds (DRY: single source of truth)
  static const double zoomTierCity = 14.0;
  static const double zoomTierDistrict = 16.0;

  // Label visibility thresholds
  static const double labelVisibilityZoom = 13.7;
  static const double labelFadeInStart = 13.95;
  static const double labelFadeInEnd = 16.0;
  static const double labelScaleStart = 14.1;
  static const double labelScaleEnd = 16.05;
  static const double iconScaleStart = 13.6;
  static const double iconScaleEnd = 16.0;

  // Marker collision thresholds
  static const double geoLowDensityZoom = 14.0;
  static const double geoMediumDensityZoom = 15.0;
  static const double geoHighDensityZoom = 16.0;

  // Screen density thresholds
  static const double screenDensityLowZoom = 15.0;
  static const double screenDensityMediumZoom = 16.0;
  static const double screenDensityHighZoom = 17.0;

  // Label viewport padding
  static const double labelViewportInset = 8.0;

  static EdgeInsets defaultLabelViewportPadding({
    required double topInset,
    required double bottomInset,
  }) {
    return EdgeInsets.fromLTRB(12, topInset + 64, 12, bottomInset + 132);
  }
}
