import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:sponti/core/constants/map_constants.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_google_marker_icon_factory.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';

class LocationGoogleMapLayer extends StatefulWidget {
  const LocationGoogleMapLayer({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.initialCameraPosition,
    required this.mapPadding,
    required this.labelViewportPadding,
    required this.showUserLocation,
    this.currentLocationCoordinates,
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
  final bool showUserLocation;
  final gmaps.LatLng? currentLocationCoordinates;
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
  Set<gmaps.Marker> _markers = const <gmaps.Marker>{};
  int _markerRequestId = 0;

  LocationRankingSnapshot get _rankingSnapshot =>
      widget.rankingSnapshot ?? widget.locations.createRankingSnapshot();

  @override
  void initState() {
    super.initState();
    _rebuildMarkers();
  }

  @override
  void didUpdateWidget(covariant LocationGoogleMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final markerInputsChanged =
        widget.locations != oldWidget.locations ||
        widget.selectedId != oldWidget.selectedId ||
        widget.currentLocationCoordinates != oldWidget.currentLocationCoordinates ||
        widget.rankingSnapshot != oldWidget.rankingSnapshot ||
        widget.activeRankingFilter != oldWidget.activeRankingFilter ||
        widget.activePriceFilter != oldWidget.activePriceFilter;

    if (markerInputsChanged) {
      _rebuildMarkers();
    }
  }

  Future<void> _rebuildMarkers() async {
    final requestId = ++_markerRequestId;
    final rankingSnapshot = _rankingSnapshot;
    final currentLocationIcon = widget.currentLocationCoordinates == null
        ? null
        : await LocationGoogleMarkerIconFactory.resolveCurrentLocationPin();

    final locationMarkers = await Future.wait(
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

    final markers = <gmaps.Marker>{...locationMarkers};
    if (widget.currentLocationCoordinates case final myLocation?) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId(_myLocationMarkerId),
          position: myLocation,
          icon:
              currentLocationIcon ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueAzure,
              ),
          zIndexInt: 12000,
          anchor: const Offset(0.5, 1.0),
          infoWindow: const gmaps.InfoWindow(title: 'You are here'),
        ),
      );
    }

    setState(() => _markers = markers);
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

  void _handleMapCreated(gmaps.GoogleMapController controller) {
    widget.onMapCreated?.call(controller);
  }

  void _handleCameraMove(gmaps.CameraPosition position) {
    widget.onCameraPositionChanged(position);
  }

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      mapType: gmaps.MapType.normal,
      buildingsEnabled: true,
      compassEnabled: false,
      mapToolbarEnabled: false,
      myLocationEnabled: widget.showUserLocation,
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
      onTap: (_) => widget.onMapTap(),
      onCameraMove: _handleCameraMove,
      markers: _markers,
    );
  }
}

const _myLocationMarkerId = 'current_user_location_pin';

gmaps.LatLng _toGoogleLatLng(Location location) => gmaps.LatLng(
  location.coordinates.latitude,
  location.coordinates.longitude,
);
