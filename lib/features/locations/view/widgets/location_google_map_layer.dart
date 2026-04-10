import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:sponti/core/constants/map_constants.dart';
import 'package:sponti/core/constants/map_style.dart';
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
    this.trendingIds = const <String>{},
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
  final Set<String> trendingIds;

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

    final locationsChanged = !listEquals(widget.locations, oldWidget.locations);
    final rankingSnapshotChanged = !_sameRankingSnapshot(
      widget.rankingSnapshot,
      oldWidget.rankingSnapshot,
    );
    final filterVisualsChanged =
        widget.activeRankingFilter != oldWidget.activeRankingFilter ||
        widget.activePriceFilter != oldWidget.activePriceFilter ||
        !_sameTrendingIds(widget.trendingIds, oldWidget.trendingIds);
    final selectedChanged = widget.selectedId != oldWidget.selectedId;
    final currentLocationChanged = !_sameLatLng(
      widget.currentLocationCoordinates,
      oldWidget.currentLocationCoordinates,
    );

    if (locationsChanged || rankingSnapshotChanged || filterVisualsChanged) {
      _rebuildMarkers();
      return;
    }

    if (selectedChanged && currentLocationChanged) {
      _rebuildMarkers();
      return;
    }

    if (selectedChanged) {
      _updateSelectedMarkers(
        previousSelectedId: oldWidget.selectedId,
        nextSelectedId: widget.selectedId,
      );
    }

    if (currentLocationChanged) {
      _updateCurrentLocationMarker();
    }
  }

  Future<void> _rebuildMarkers() async {
    final requestId = ++_markerRequestId;
    final rankingSnapshot = _rankingSnapshot;
    final currentLocationIcon = widget.currentLocationCoordinates == null
        ? null
        : await LocationGoogleMarkerIconFactory.resolveCurrentLocationPin();

    final markerRequests = widget.locations
        .map(
          (location) => _MarkerBuildRequest(
            location: location,
            isSelected: location.id == widget.selectedId,
            isTrending: widget.trendingIds.contains(location.id),
            ranking: rankingSnapshot.rankingFor(location),
            descriptorKey: LocationGoogleMarkerIconFactory.cacheKeyFor(
              category: location.category,
              priceRange: location.priceRange,
              isSelected: location.id == widget.selectedId,
              isTrending: widget.trendingIds.contains(location.id),
              ranking: rankingSnapshot.rankingFor(location),
              activeRankingFilter: widget.activeRankingFilter,
              activePriceFilter: widget.activePriceFilter,
            ),
          ),
        )
        .toList(growable: false);
    final descriptorsByKey = await _resolveDescriptors(markerRequests);
    final locationMarkers = markerRequests.map(
      (request) => _buildLocationMarker(
        location: request.location,
        isSelected: request.isSelected,
        icon: descriptorsByKey[request.descriptorKey]!,
      ),
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

  Future<void> _updateSelectedMarkers({
    required String? previousSelectedId,
    required String? nextSelectedId,
  }) async {
    if (_markers.isEmpty && widget.locations.isNotEmpty) {
      await _rebuildMarkers();
      return;
    }

    final changedIds = <String>{?previousSelectedId, ?nextSelectedId};
    if (changedIds.isEmpty) return;

    final requestId = ++_markerRequestId;
    final rankingSnapshot = _rankingSnapshot;
    final locationById = {
      for (final location in widget.locations) location.id: location,
    };
    final markerRequests = changedIds
        .map((id) => locationById[id])
        .whereType<Location>()
        .map(
          (location) => _MarkerBuildRequest(
            location: location,
            isSelected: location.id == widget.selectedId,
            isTrending: widget.trendingIds.contains(location.id),
            ranking: rankingSnapshot.rankingFor(location),
            descriptorKey: LocationGoogleMarkerIconFactory.cacheKeyFor(
              category: location.category,
              priceRange: location.priceRange,
              isSelected: location.id == widget.selectedId,
              isTrending: widget.trendingIds.contains(location.id),
              ranking: rankingSnapshot.rankingFor(location),
              activeRankingFilter: widget.activeRankingFilter,
              activePriceFilter: widget.activePriceFilter,
            ),
          ),
        )
        .toList(growable: false);
    if (markerRequests.isEmpty) return;

    final descriptorsByKey = await _resolveDescriptors(markerRequests);
    if (!mounted || requestId != _markerRequestId) {
      return;
    }

    final markersById = <String, gmaps.Marker>{
      for (final marker in _markers) marker.markerId.value: marker,
    };
    for (final request in markerRequests) {
      markersById[request.location.id] = _buildLocationMarker(
        location: request.location,
        isSelected: request.isSelected,
        icon: descriptorsByKey[request.descriptorKey]!,
      );
    }

    setState(() => _markers = markersById.values.toSet());
  }

  Future<void> _updateCurrentLocationMarker() async {
    if (_markers.isEmpty && widget.locations.isNotEmpty) {
      await _rebuildMarkers();
      return;
    }

    final requestId = ++_markerRequestId;
    final markersById = <String, gmaps.Marker>{
      for (final marker in _markers) marker.markerId.value: marker,
    }..remove(_myLocationMarkerId);

    if (widget.currentLocationCoordinates case final myLocation?) {
      final icon =
          await LocationGoogleMarkerIconFactory.resolveCurrentLocationPin();
      if (!mounted || requestId != _markerRequestId) {
        return;
      }
      markersById[_myLocationMarkerId] = _buildCurrentLocationMarker(
        coordinates: myLocation,
        icon: icon,
      );
    } else if (!mounted || requestId != _markerRequestId) {
      return;
    }

    setState(() => _markers = markersById.values.toSet());
  }

  Future<Map<String, gmaps.BitmapDescriptor>> _resolveDescriptors(
    List<_MarkerBuildRequest> requests,
  ) async {
    final descriptorFutures = <String, Future<gmaps.BitmapDescriptor>>{};
    for (final request in requests) {
      descriptorFutures.putIfAbsent(
        request.descriptorKey,
        () => LocationGoogleMarkerIconFactory.resolve(
          category: request.location.category,
          priceRange: request.location.priceRange,
          isSelected: request.isSelected,
          isTrending: request.isTrending,
          ranking: request.ranking,
          activeRankingFilter: widget.activeRankingFilter,
          activePriceFilter: widget.activePriceFilter,
        ),
      );
    }

    final entries = await Future.wait(
      descriptorFutures.entries.map(
        (entry) async => MapEntry(entry.key, await entry.value),
      ),
    );

    return {for (final entry in entries) entry.key: entry.value};
  }

  gmaps.Marker _buildLocationMarker({
    required Location location,
    required bool isSelected,
    required gmaps.BitmapDescriptor icon,
  }) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(location.id),
      position: _toGoogleLatLng(location),
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: true,
      icon: icon,
      zIndexInt: _markerZIndex(location, isSelected),
      onTap: () => widget.onLocationTap(location),
    );
  }

  gmaps.Marker _buildCurrentLocationMarker({
    required gmaps.LatLng coordinates,
    required gmaps.BitmapDescriptor icon,
  }) {
    return gmaps.Marker(
      markerId: const gmaps.MarkerId(_myLocationMarkerId),
      position: coordinates,
      icon: icon,
      zIndexInt: 12000,
      anchor: const Offset(0.5, 1.0),
      infoWindow: const gmaps.InfoWindow(title: 'You are here'),
    );
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
      style: kMapStyle,
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

gmaps.LatLng _toGoogleLatLng(Location location) =>
    gmaps.LatLng(location.coordinates.latitude, location.coordinates.longitude);

bool _sameLatLng(gmaps.LatLng? left, gmaps.LatLng? right) {
  if (left == null || right == null) return left == right;
  return left.latitude == right.latitude && left.longitude == right.longitude;
}

bool _sameRankingSnapshot(
  LocationRankingSnapshot? left,
  LocationRankingSnapshot? right,
) {
  if (identical(left, right)) return true;
  if (left == null || right == null) return left == right;

  return left.thirtyDaysAgo == right.thirtyDaysAgo &&
      left.checkInP75 == right.checkInP75 &&
      left.reviewP75 == right.reviewP75 &&
      left.checkInP25 == right.checkInP25;
}

class _MarkerBuildRequest {
  const _MarkerBuildRequest({
    required this.location,
    required this.isSelected,
    required this.isTrending,
    required this.ranking,
    required this.descriptorKey,
  });

  final Location location;
  final bool isSelected;
  final bool isTrending;
  final LocationRanking? ranking;
  final String descriptorKey;
}

bool _sameTrendingIds(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
