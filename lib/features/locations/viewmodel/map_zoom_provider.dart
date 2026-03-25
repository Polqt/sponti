import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ZoomTier {
  city,
  district,
  street;

  static ZoomTier fromZoom(double zoom) {
    if (zoom < 14.0) return ZoomTier.city;
    if (zoom < 16.0) return ZoomTier.district;
    return ZoomTier.street;
  }
}

class MapZoomState {
  const MapZoomState({
    this.zoom = 15.5,
    this.tier = ZoomTier.district,
  });

  final double zoom;
  final ZoomTier tier;

  MapZoomState copyWith({double? zoom, ZoomTier? tier}) {
    return MapZoomState(
      zoom: zoom ?? this.zoom,
      tier: tier ?? this.tier,
    );
  }

  double get labelOpacity {
    return switch (tier) {
      ZoomTier.city => 0.0,
      ZoomTier.district => ((zoom - 14.0) / 2.0).clamp(0.0, 1.0),
      ZoomTier.street => 1.0,
    };
  }

  double get iconScale {
    return switch (tier) {
      ZoomTier.city => 0.75,
      ZoomTier.district => 0.85 + ((zoom - 14.0) / 2.0) * 0.15,
      ZoomTier.street => 1.0,
    };
  }

  bool get shouldShowLabels => tier != ZoomTier.city;
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
