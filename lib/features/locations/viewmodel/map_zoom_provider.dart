import 'package:flutter/animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/constants/map_constants.dart';

enum ZoomTier {
  city,
  district,
  street;

  static ZoomTier fromZoom(double zoom) {
    if (zoom < MapConstants.zoomTierCity) return ZoomTier.city;
    if (zoom < MapConstants.zoomTierDistrict) return ZoomTier.district;
    return ZoomTier.street;
  }
}

class MapZoomState {
  const MapZoomState({this.zoom = 15.5, this.tier = ZoomTier.district});

  final double zoom;
  final ZoomTier tier;

  MapZoomState copyWith({double? zoom, ZoomTier? tier}) {
    return MapZoomState(zoom: zoom ?? this.zoom, tier: tier ?? this.tier);
  }

  double _progress(double start, double end) {
    if (zoom <= start) return 0.0;
    if (zoom >= end) return 1.0;
    return ((zoom - start) / (end - start)).clamp(0.0, 1.0);
  }

  double get labelOpacity {
    final progress = _progress(
      MapConstants.labelFadeInStart,
      MapConstants.labelFadeInEnd,
    );
    return Curves.easeOutCubic.transform(progress);
  }

  double get labelScale {
    final progress = Curves.easeOut.transform(
      _progress(MapConstants.labelScaleStart, MapConstants.labelScaleEnd),
    );
    return 0.9 + (progress * 0.1);
  }

  double get iconScale {
    final progress = Curves.easeOut.transform(
      _progress(MapConstants.iconScaleStart, MapConstants.iconScaleEnd),
    );
    return 0.76 + (progress * 0.24);
  }

  bool get shouldShowLabels => labelOpacity > 0.045;
}

class MapZoomNotifier extends Notifier<MapZoomState> {
  @override
  MapZoomState build() => const MapZoomState();

  void updateZoom(double zoom) {
    final newTier = ZoomTier.fromZoom(zoom);
    if (zoom != state.zoom || newTier != state.tier) {
      state = MapZoomState(zoom: zoom, tier: newTier);
    }
  }
}

final mapZoomProvider = NotifierProvider<MapZoomNotifier, MapZoomState>(
  MapZoomNotifier.new,
);
