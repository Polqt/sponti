import 'package:flutter/widgets.dart';

abstract final class MapConstants {
  static const double defaultLatitude = 10.6765;
  static const double defaultLongitude = 122.9509;

  static const double defaultZoom = 16.0;
  static const double defaultTilt = 42.0;
  static const double defaultBearing = -12.0;

  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;

  static const double labelVisibilityZoom = 14.15;
  static const double labelViewportInset = 8.0;

  static EdgeInsets defaultLabelViewportPadding({
    required double topInset,
    required double bottomInset,
  }) {
    return EdgeInsets.fromLTRB(
      16,
      topInset + 76,
      16,
      bottomInset + 150,
    );
  }
}
