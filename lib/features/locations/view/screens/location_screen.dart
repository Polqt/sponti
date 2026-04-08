import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/constants/map_constants.dart';
import 'package:sponti/core/providers/connectivity_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/view/widgets/location_google_map_layer.dart';
import 'package:sponti/features/locations/view/widgets/location_map_header.dart';
import 'package:sponti/features/locations/view/widgets/location_screen_explore_panel.dart';
import 'package:sponti/features/locations/view/widgets/location_screen_map_controls.dart';
import 'package:sponti/features/locations/viewmodel/current_location_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  static const _defaultCenter = gmaps.LatLng(
    MapConstants.defaultLatitude,
    MapConstants.defaultLongitude,
  );

  final ValueNotifier<double> _sheetProgress = ValueNotifier<double>(0.0);

  late final StateController<bool> _shellBarHiddenController;
  late final StateController<double> _shellChromeProgressController;

  gmaps.GoogleMapController? _mapController;
  gmaps.CameraPosition _cameraPosition = const gmaps.CameraPosition(
    target: _defaultCenter,
    zoom: MapConstants.defaultZoom,
    tilt: MapConstants.defaultTilt,
    bearing: MapConstants.defaultBearing,
  );
  String? _selectedLocationId;
  Location? _detailLocation;
  DateTime? _ignoreMapTapUntil;
  bool _panelWasVisibleBeforeDetails = false;
  bool _panelWasExpandedBeforeDetails = false;
  bool _isExplorePanelVisible = false;
  bool _isExplorePanelExpanded = false;

  @override
  void initState() {
    super.initState();
    _shellBarHiddenController = ref.read(shellBarHiddenProvider.notifier);
    _shellChromeProgressController = ref.read(
      shellChromeProgressProvider.notifier,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumePending();
      _autoInitializeLocation();
    });
  }

  void _consumePending() {
    final pending = ref.read(pendingLocationProvider);
    if (pending == null) return;
    ref.read(pendingLocationProvider.notifier).state = null;
    _showLocationDetails(pending);
  }

  Future<void> _autoInitializeLocation() async {
    try {
      final box = await Hive.openBox(AppConstants.hiveBoxUserPrefs);
      final hasAutoInitialized =
          box.get('map_auto_initialized', defaultValue: false) as bool;

      if (!hasAutoInitialized) {
        await box.put('map_auto_initialized', true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await _moveToCurrentLocation();
      }
    } catch (_) {
      // Silent fail - not critical
    }
  }

  void _setShellHidden(bool hidden) => _shellBarHiddenController.state = hidden;

  Future<void> _onCategoryChanged(LocationCategory? category) async {
    final filterNotifier = ref.read(locationFilterProvider.notifier);
    filterNotifier.setCategory(category);
    filterNotifier.setRanking(null);
    await ref.read(locationsProvider.notifier).refresh();
    _openPanel();
  }

  void _setSheetProgress(double progress) {
    _sheetProgress.value = progress;
    _shellChromeProgressController.state = progress;
  }

  bool get _shouldIgnoreMapTap {
    final until = _ignoreMapTapUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  Future<void> _focusLocation(Location location) async {
    final controller = _mapController;
    if (controller == null) return;

    final optimalZoom = _cameraPosition.zoom < 15.8
        ? MapConstants.defaultZoom + 0.5
        : _cameraPosition.zoom;
    await controller.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            location.coordinates.latitude,
            location.coordinates.longitude,
          ),
          zoom: optimalZoom,
          tilt: _cameraPosition.tilt < MapConstants.defaultTilt
              ? MapConstants.defaultTilt
              : _cameraPosition.tilt,
          bearing: _cameraPosition.bearing,
        ),
      ),
    );
  }

  void _handleMapCreated(
    gmaps.GoogleMapController controller,
    List<Location> visibleLocations,
  ) {
    if (_mapController != null && _mapController != controller) {
      _mapController!.dispose();
    }
    _mapController = controller;

    if (_detailLocation != null) {
      _focusLocation(_detailLocation!);
      return;
    }

    final selectedId = _selectedLocationId;
    if (selectedId == null) return;
    final selectedLocation = visibleLocations.where(
      (location) => location.id == selectedId,
    );
    if (selectedLocation.isNotEmpty) {
      _focusLocation(selectedLocation.first);
    }
  }

  void _openPanel() {
    _ignoreMapTapUntil = null;
    setState(() {
      _isExplorePanelVisible = true;
      _isExplorePanelExpanded = true;
    });
    _setSheetProgress(1.0);
    _setShellHidden(true);
  }

  void _selectLocation(Location location) {
    setState(() => _selectedLocationId = location.id);
    _openPanel();
    _focusLocation(location);
  }

  void _showLocationDetails(Location location) {
    _ignoreMapTapUntil = null;
    _panelWasVisibleBeforeDetails = _isExplorePanelVisible;
    _panelWasExpandedBeforeDetails = _isExplorePanelExpanded;
    setState(() {
      _selectedLocationId = location.id;
      _detailLocation = location;
      _isExplorePanelVisible = false;
      _isExplorePanelExpanded = false;
    });
    _focusLocation(location);
    _setSheetProgress(1.0);
    _setShellHidden(true);
  }

  void _restorePanelFromDetails() {
    _ignoreMapTapUntil = DateTime.now().add(const Duration(milliseconds: 260));
    setState(() {
      _detailLocation = null;
      _isExplorePanelVisible = _panelWasVisibleBeforeDetails;
      _isExplorePanelExpanded = _panelWasExpandedBeforeDetails;
    });
    final shellVisible = _panelWasVisibleBeforeDetails;
    _setSheetProgress(shellVisible ? 1.0 : 0.0);
    _setShellHidden(shellVisible);
  }

  void _setPanelExpanded(bool expanded) {
    setState(() => _isExplorePanelExpanded = expanded);
  }

  void _hidePanel() {
    _ignoreMapTapUntil = null;
    setState(() {
      _isExplorePanelVisible = false;
      _isExplorePanelExpanded = false;
    });
    _setSheetProgress(0.0);
    _setShellHidden(false);
  }

  Future<void> _refreshLocations() {
    return ref.read(locationsProvider.notifier).refresh();
  }

  Future<void> _moveToCurrentLocation() async {
    await ref.read(currentLocationProvider.notifier).locate();
    if (!mounted) return;

    final currentLocation = ref.read(currentLocationProvider);
    if (!currentLocation.hasCoordinates || _mapController == null) return;

    await _mapController!.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          ),
          zoom: _cameraPosition.zoom < 16.3 ? 16.3 : _cameraPosition.zoom,
          tilt: _cameraPosition.tilt < MapConstants.defaultTilt
              ? MapConstants.defaultTilt
              : _cameraPosition.tilt,
          bearing: _cameraPosition.bearing,
        ),
      ),
    );
  }

  @override
  void dispose() {
    final shellChromeController = _shellChromeProgressController;
    final shellBarController = _shellBarHiddenController;
    Future<void>(() {
      shellChromeController.state = 0.0;
      shellBarController.state = false;
    });
    _mapController?.dispose();
    _sheetProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final filter = ref.watch(locationFilterProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final trendingIds = ref.watch(
      trendingLocationIdsProvider.select((s) => s.valueOrNull ?? const <String>{}),
    );
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final allLocations = locationsAsync.valueOrNull ?? const <Location>[];
    final filteredResult = applyLocationFilters(
      locations: allLocations,
      filter: filter,
    );
    final locations = filteredResult.visibleLocations;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final rankingSnapshot = filteredResult.rankingSnapshot;
    final floatingControlsBottom = bottomInset + kShellBottomBarClearance + 20;
    final mapPadding = EdgeInsets.fromLTRB(
      10,
      topInset + 92,
      10,
      bottomInset + 188,
    );
    final labelViewportPadding = MapConstants.defaultLabelViewportPadding(
      topInset: topInset,
      bottomInset: bottomInset,
    );

    final selectedId =
        _selectedLocationId != null &&
            locations.any((l) => l.id == _selectedLocationId)
        ? _selectedLocationId
        : null;
    final selectedIndex = selectedId != null
        ? locations.indexWhere((l) => l.id == selectedId)
        : 0;

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: LocationGoogleMapLayer(
              locations: locations,
              selectedId: selectedId,
              initialCameraPosition: gmaps.CameraPosition(
                target: _defaultCenter,
                zoom: MapConstants.defaultZoom,
                tilt: MapConstants.defaultTilt,
                bearing: MapConstants.defaultBearing,
              ),
              mapPadding: mapPadding,
              labelViewportPadding: labelViewportPadding,
              showUserLocation: currentLocation.isPermissionGranted,
              currentLocationCoordinates: currentLocation.hasCoordinates
                  ? gmaps.LatLng(
                      currentLocation.latitude!,
                      currentLocation.longitude!,
                    )
                  : null,
              rankingSnapshot: rankingSnapshot,
              activeRankingFilter: filter.selectedRanking,
              activePriceFilter: filter.selectedPrice,
              trendingIds: trendingIds,
              onMapCreated: (controller) =>
                  _handleMapCreated(controller, locations),
              onMapTap: () {
                if (_detailLocation != null || _shouldIgnoreMapTap) return;
                _hidePanel();
              },
              onLocationTap: _showLocationDetails,
              onCameraPositionChanged: (position) {
                _cameraPosition = position;
              },
            ),
          ),
          LocationMapHeader(sheetProgress: _sheetProgress),
          if (locationsAsync.isLoading)
            const Center(
              child: CircularProgressIndicator(color: SpontiColors.primary),
            ),
          if (locationsAsync.hasError)
            Positioned(
              left: 16,
              right: 16,
              bottom: floatingControlsBottom + 74,
              child: GestureDetector(
                onTap: _refreshLocations,
                child: const FloatingMessage(
                  text: 'Unable to load spots. Tap refresh to retry.',
                  icon: Icons.error_outline_rounded,
                  color: SpontiColors.error,
                ),
              ),
            ),
          // Category row + action buttons stacked just above the shell bar
          if (!_isExplorePanelVisible && _detailLocation == null)
            LocationScreenMapControls(
              bottomInset: bottomInset,
              locationsLoading: locationsAsync.isLoading,
              onCategoryChanged: _onCategoryChanged,
              onLocateMe: _moveToCurrentLocation,
              onRefresh: _refreshLocations,
            ),
          if (_isExplorePanelVisible && _detailLocation == null)
            LocationScreenExplorePanel(
              locationsAsync: locationsAsync,
              locations: locations,
              selectedIndex: selectedIndex,
              isExpanded: _isExplorePanelExpanded,
              onCategoryChanged: _onCategoryChanged,
              onExpandChanged: _setPanelExpanded,
              onDismissed: _hidePanel,
              onSheetProgressChanged: _setSheetProgress,
              onSelectLocation: _selectLocation,
              onLocationTap: _showLocationDetails,
            ),
          if (_detailLocation != null)
            Positioned.fill(
              child: LocationDetailSheet(
                key: ValueKey(_detailLocation!.id),
                location: _detailLocation!,
                onDismissed: _restorePanelFromDetails,
              ),
            ),
          if (!isOnline)
            Positioned(
              left: 16,
              right: 16,
              bottom: floatingControlsBottom + 78,
              child: FloatingMessage(
                text: 'You\'re offline. Showing cached spots.',
                icon: Icons.wifi_off_rounded,
                color: SpontiColors.warning,
              ),
            ),
        ],
      ),
    );
  }
}
