import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:sponti/core/constants/map_constants.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/map_label_layout.dart';
import 'package:sponti/features/locations/utils/location_google_marker_icon_factory.dart';
import 'package:sponti/features/locations/utils/marker_collision_detector.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/utils/map_pin_label_text.dart';
import 'package:sponti/features/locations/view/widgets/location_map_label_chip.dart';
import 'package:sponti/features/locations/viewmodel/map_zoom_provider.dart';

class LocationGoogleMapLayer extends StatefulWidget {
  const LocationGoogleMapLayer({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.initialCameraPosition,
    required this.mapPadding,
    required this.labelViewportPadding,
    required this.onMapTap,
    required this.onLocationTap,
    required this.onCameraPositionChanged,
    this.rankingSnapshot,
    this.activeRankingFilter,
    this.activePriceFilter,
    this.onMapCreated,
  });

  final List<Location> locations;
  final String? selectedId;
  final gmaps.CameraPosition initialCameraPosition;
  final EdgeInsets mapPadding;
  final EdgeInsets labelViewportPadding;
  final VoidCallback onMapTap;
  final ValueChanged<Location> onLocationTap;
  final ValueChanged<gmaps.CameraPosition> onCameraPositionChanged;
  final ValueChanged<gmaps.GoogleMapController>? onMapCreated;
  final LocationRankingSnapshot? rankingSnapshot;
  final LocationRanking? activeRankingFilter;
  final PriceRange? activePriceFilter;

  @override
  State<LocationGoogleMapLayer> createState() => _LocationGoogleMapLayerState();
}

class _LocationGoogleMapLayerState extends State<LocationGoogleMapLayer> {
  static const _layoutSyncDelay = Duration(milliseconds: 80);
  static const _labelVisibilitySlack = 12.0;

  final Map<String, MapPinLabelText> _labelTexts =
      <String, MapPinLabelText>{};

  gmaps.GoogleMapController? _controller;
  Timer? _layoutTimer;
  Size _viewportSize = Size.zero;
  Set<gmaps.Marker> _markers = const <gmaps.Marker>{};
  late MapZoomState _zoomState;
  Map<String, ScreenMapPinLabelLayout> _labelLayouts =
      const <String, ScreenMapPinLabelLayout>{};
  int _markerRequestId = 0;
  int _layoutRequestId = 0;
  int _labelRetryCount = 0;
  double _pendingZoom = MapConstants.defaultZoom;
  bool _isCameraInteracting = false;

  LocationRankingSnapshot get _rankingSnapshot =>
      widget.rankingSnapshot ?? widget.locations.createRankingSnapshot();

  bool get _shouldShowLabels =>
      !_isCameraInteracting && _zoomState.shouldShowLabels;

  @override
  void initState() {
    super.initState();
    _pendingZoom = widget.initialCameraPosition.zoom;
    _zoomState = MapZoomState(
      zoom: _pendingZoom,
      tier: ZoomTier.fromZoom(_pendingZoom),
    );
    _primeLabelTexts();
    unawaited(_rebuildMarkers());
  }

  @override
  void didUpdateWidget(covariant LocationGoogleMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final markerInputsChanged =
        widget.locations != oldWidget.locations ||
        widget.selectedId != oldWidget.selectedId ||
        widget.rankingSnapshot != oldWidget.rankingSnapshot ||
        widget.activeRankingFilter != oldWidget.activeRankingFilter ||
        widget.activePriceFilter != oldWidget.activePriceFilter;

    if (markerInputsChanged) {
      _primeLabelTexts();
      unawaited(_rebuildMarkers());
    }

    if (markerInputsChanged ||
        widget.mapPadding != oldWidget.mapPadding ||
        widget.labelViewportPadding != oldWidget.labelViewportPadding) {
      _scheduleLabelSync(immediate: markerInputsChanged);
    }
  }

  @override
  void dispose() {
    _layoutTimer?.cancel();
    super.dispose();
  }

  void _primeLabelTexts() {
    final activeIds = widget.locations.map((location) => location.id).toSet();
    _labelTexts.removeWhere((id, _) => !activeIds.contains(id));
    for (final location in widget.locations) {
      _labelTexts[location.id] = MapPinLabelText.fromName(location.name);
    }
  }

  Future<void> _rebuildMarkers() async {
    final requestId = ++_markerRequestId;
    final rankingSnapshot = _rankingSnapshot;

    if (widget.locations.isEmpty) {
      if (!mounted) return;
      setState(() => _markers = const <gmaps.Marker>{});
      return;
    }

    final markers = await Future.wait(
      widget.locations.map((location) async {
        final isSelected = location.id == widget.selectedId;
        final ranking = rankingSnapshot.rankingFor(location);
        final icon = await LocationGoogleMarkerIconFactory.resolve(
          category: location.category,
          priceRange: location.priceRange,
          isSelected: isSelected,
          ranking: ranking,
          activeRankingFilter: widget.activeRankingFilter,
          activePriceFilter: widget.activePriceFilter,
        );

        return gmaps.Marker(
          markerId: gmaps.MarkerId(location.id),
          position: _toGoogleLatLng(location),
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: true,
          icon: icon,
          zIndexInt: _markerZIndex(location, isSelected),
          onTap: () => widget.onLocationTap(location),
        );
      }),
    );

    if (!mounted || requestId != _markerRequestId) {
      return;
    }

    setState(() => _markers = markers.toSet());
    _scheduleLabelSync(immediate: true);
  }

  int _markerZIndex(Location location, bool isSelected) {
    if (isSelected) return 10000;
    final score =
        100 +
        (location.rating * 12).round() +
        location.reviewCount +
        (location.checkInCount / 2).round();
    if (score < 100) return 100;
    if (score > 9999) return 9999;
    return score;
  }

  void _setViewportSize(Size size) {
    if ((size.width - _viewportSize.width).abs() < 0.5 &&
        (size.height - _viewportSize.height).abs() < 0.5) {
      return;
    }

    _viewportSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleLabelSync(immediate: true);
    });
  }

  void _scheduleLabelSync({bool immediate = false}) {
    _layoutTimer?.cancel();

    if (!_shouldShowLabels ||
        widget.locations.isEmpty ||
        _controller == null ||
        _viewportSize.isEmpty) {
      if (_labelLayouts.isNotEmpty && mounted) {
        setState(() {
          _labelLayouts = const <String, ScreenMapPinLabelLayout>{};
        });
      }
      return;
    }

    if (immediate) {
      unawaited(_syncLabelLayouts());
      return;
    }

    _layoutTimer = Timer(_layoutSyncDelay, () {
      unawaited(_syncLabelLayouts());
    });
  }

  Future<void> _syncLabelLayouts() async {
    final controller = _controller;
    if (controller == null ||
        !mounted ||
        !_shouldShowLabels ||
        _viewportSize.isEmpty) {
      return;
    }

    final requestId = ++_layoutRequestId;

    try {
      final markerEntries = await Future.wait(
        widget.locations.map((location) async {
          final coordinate = await controller.getScreenCoordinate(
            _toGoogleLatLng(location),
          );
          return MapEntry<String, Offset>(
            location.id,
            Offset(coordinate.x.toDouble(), coordinate.y.toDouble()),
          );
        }),
      );

      if (!mounted || requestId != _layoutRequestId) {
        return;
      }

      final visibleMarkerCenters = <String, Offset>{
        for (final entry in markerEntries)
          if (_isWithinViewport(entry.value)) entry.key: entry.value,
      };

      final labelTexts = {
        for (final entry in _labelTexts.entries)
          if (visibleMarkerCenters.containsKey(entry.key)) entry.key: entry.value,
      };

      var layouts = MarkerCollisionDetector.computeScreenLabelLayouts(
        markerCenters: visibleMarkerCenters,
        labelTexts: labelTexts,
        viewportSize: _viewportSize,
        zoom: _zoomState.zoom,
        selectedId: widget.selectedId,
        markerDiameter: 46,
        viewportPadding: widget.labelViewportPadding,
      );

      if (!mounted || requestId != _layoutRequestId) {
        return;
      }

      var visibleLabelCount = layouts.values.where((layout) => layout.showLabel).length;
      if (visibleLabelCount == 0 &&
          visibleMarkerCenters.isNotEmpty &&
          _zoomState.zoom >= 15.0) {
        final relaxedPadding = EdgeInsets.fromLTRB(
          math.max(4.0, widget.labelViewportPadding.left - 8),
          math.max(8.0, widget.labelViewportPadding.top - 20),
          math.max(4.0, widget.labelViewportPadding.right - 8),
          math.max(10.0, widget.labelViewportPadding.bottom - 24),
        );
        final fallbackLayouts = MarkerCollisionDetector.computeScreenLabelLayouts(
          markerCenters: visibleMarkerCenters,
          labelTexts: labelTexts,
          viewportSize: _viewportSize,
          zoom: _zoomState.zoom + 0.25,
          selectedId: widget.selectedId,
          markerDiameter: 40,
          viewportPadding: relaxedPadding,
        );
        final fallbackVisibleCount = fallbackLayouts.values
            .where((layout) => layout.showLabel)
            .length;
        if (fallbackVisibleCount > visibleLabelCount) {
          layouts = fallbackLayouts;
          visibleLabelCount = fallbackVisibleCount;
        }
      }

      if (visibleLabelCount == 0 &&
          visibleMarkerCenters.isNotEmpty &&
          _zoomState.zoom >= 15.0 &&
          _labelRetryCount < 2) {
        _labelRetryCount += 1;
        _scheduleLabelSync();
        return;
      }

      _labelRetryCount = 0;
      setState(() => _labelLayouts = layouts);
    } catch (_) {
      if (!mounted || requestId != _layoutRequestId) {
        return;
      }
      setState(() {
        _labelLayouts = const <String, ScreenMapPinLabelLayout>{};
      });
    }
  }

  bool _isWithinViewport(Offset point) {
    final padding = widget.labelViewportPadding;
    final topInset = math.max(4.0, padding.top - 28);
    final bottomInset = math.max(8.0, padding.bottom - 32);

    return point.dx >= -20.0 &&
        point.dx <= _viewportSize.width + 20.0 &&
        point.dy >= topInset - _labelVisibilitySlack &&
        point.dy <= _viewportSize.height - bottomInset + _labelVisibilitySlack;
  }

  void _handleMapCreated(gmaps.GoogleMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
    _scheduleLabelSync(immediate: true);
  }

  void _handleCameraMoveStarted() {
    _layoutTimer?.cancel();
    if (_isCameraInteracting) return;

    setState(() {
      _isCameraInteracting = true;
      _labelLayouts = const <String, ScreenMapPinLabelLayout>{};
    });
  }

  void _handleCameraMove(gmaps.CameraPosition position) {
    _pendingZoom = position.zoom;
    widget.onCameraPositionChanged(position);
  }

  void _handleCameraIdle() {
    final nextZoomState = MapZoomState(
      zoom: _pendingZoom,
      tier: ZoomTier.fromZoom(_pendingZoom),
    );
    final shouldRefreshLabels =
        !_isSameZoomState(_zoomState, nextZoomState) ||
        _isCameraInteracting ||
        _labelLayouts.isEmpty;

    if (_isCameraInteracting || !_isSameZoomState(_zoomState, nextZoomState)) {
      setState(() {
        _zoomState = nextZoomState;
        _isCameraInteracting = false;
      });
    }

    if (shouldRefreshLabels) {
      _scheduleLabelSync(immediate: true);
    }
  }

  bool _isSameZoomState(MapZoomState left, MapZoomState right) {
    return left.tier == right.tier && (left.zoom - right.zoom).abs() < 0.02;
  }

  List<Widget> _buildLabelWidgets() {
    if (!_shouldShowLabels || _labelLayouts.isEmpty) {
      return const <Widget>[];
    }
    final orderedLocations = [...widget.locations]
      ..sort((left, right) {
        if (left.id == widget.selectedId) return 1;
        if (right.id == widget.selectedId) return -1;
        return 0;
      });

    return [
      for (final location in orderedLocations)
        if ((_labelLayouts[location.id]?.showLabel ?? false) &&
            _labelLayouts[location.id]?.rect != null)
          Positioned(
            key: ValueKey('location_label_${location.id}'),
            left: _labelLayouts[location.id]!.rect!.left,
            top: _labelLayouts[location.id]!.rect!.top,
            width: _labelLayouts[location.id]!.rect!.width,
            height: _labelLayouts[location.id]!.rect!.height,
            child: LocationMapLabelChip(
              labelText:
                  _labelTexts[location.id] ??
                  MapPinLabelText.fromName(location.name),
              placement: _labelLayouts[location.id]!.placement,
              opacity: _zoomState.labelOpacity,
              scale: _zoomState.labelScale,
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _setViewportSize(Size(constraints.maxWidth, constraints.maxHeight));

        return Stack(
          fit: StackFit.expand,
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: widget.initialCameraPosition,
              mapType: gmaps.MapType.normal,
              buildingsEnabled: true,
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              indoorViewEnabled: false,
              trafficEnabled: false,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              padding: widget.mapPadding,
              minMaxZoomPreference: const gmaps.MinMaxZoomPreference(
                MapConstants.minZoom,
                MapConstants.maxZoom,
              ),
              onMapCreated: _handleMapCreated,
              onCameraMoveStarted: _handleCameraMoveStarted,
              onTap: (_) => widget.onMapTap(),
              onCameraMove: _handleCameraMove,
              onCameraIdle: _handleCameraIdle,
              markers: _markers,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(children: _buildLabelWidgets()),
              ),
            ),
          ],
        );
      },
    );
  }
}

gmaps.LatLng _toGoogleLatLng(Location location) => gmaps.LatLng(
  location.coordinates.latitude,
  location.coordinates.longitude,
);
