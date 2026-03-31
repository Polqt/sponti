import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_map_markers.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/view/widgets/location_map_atmosphere_overlay.dart';
import 'package:sponti/features/locations/view/widgets/location_map_floating_controls.dart';
import 'package:sponti/features/locations/view/widgets/location_map_header.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/map_zoom_provider.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  static const _defaultCenter = LatLng(10.6765, 122.9509);

  final MapController _mapController = MapController();
  final ValueNotifier<double> _sheetProgress = ValueNotifier<double>(0.0);

  late final StateController<bool> _shellBarHiddenController;
  late final StateController<double> _shellChromeProgressController;

  String? _selectedLocationId;
  Location? _detailLocation;
  bool _didAutoCenter = false;
  bool _isExplorePanelVisible = false;
  bool _isExplorePanelExpanded = false;

  @override
  void initState() {
    super.initState();
    _shellBarHiddenController = ref.read(shellBarHiddenProvider.notifier);
    _shellChromeProgressController = ref.read(shellChromeProgressProvider.notifier);
    ref.read(mapZoomProvider.notifier).updateZoom(15.5);
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePending());
  }

  void _consumePending() {
    final pending = ref.read(pendingLocationProvider);
    if (pending == null) return;
    ref.read(pendingLocationProvider.notifier).state = null;
    _showLocationDetails(pending);
  }

  void _setShellHidden(bool hidden) => _shellBarHiddenController.state = hidden;

  Future<void> _onCategoryChanged(LocationCategory? category) async {
    ref.read(locationFilterProvider.notifier).setCategory(category);
    ref.read(locationFilterProvider.notifier).setRanking(null);
    await ref.read(locationsProvider.notifier).refresh();
    _openPanel();
  }

  void _setSheetProgress(double progress) {
    _sheetProgress.value = progress;
    _shellChromeProgressController.state = progress;
  }

  void _focusLocation(Location location) {
    final currentZoom = _mapController.camera.zoom;
    final optimalZoom = currentZoom < 15.0 ? 15.5 : currentZoom;
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      optimalZoom,
    );
  }

  void _openPanel() {
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
    setState(() {
      _detailLocation = null;
      _isExplorePanelVisible = true;
      _isExplorePanelExpanded = true;
    });
    _setSheetProgress(1.0);
    _setShellHidden(true);
  }

  void _setPanelExpanded(bool expanded) {
    setState(() => _isExplorePanelExpanded = expanded);
  }

  void _hidePanel() {
    setState(() {
      _isExplorePanelVisible = false;
      _isExplorePanelExpanded = false;
    });
    _setSheetProgress(0.0);
    _setShellHidden(false);
  }

  @override
  void dispose() {
    _shellChromeProgressController.state = 0.0;
    _setShellHidden(false);
    _sheetProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final filter = ref.watch(locationFilterProvider);
    final mapZoom = ref.watch(mapZoomProvider);
    final allLocations = locationsAsync.valueOrNull ?? const <Location>[];
    final filteredResult = applyLocationFilters(
      locations: allLocations,
      filter: filter,
    );
    final locations = filteredResult.visibleLocations;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final rankingSnapshot = filteredResult.rankingSnapshot;

    if (!_didAutoCenter && locations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final mapCenter = LatLng(
          locations.first.coordinates.latitude,
          locations.first.coordinates.longitude,
        );
        _mapController.move(mapCenter, 15.5);
        _didAutoCenter = true;
      });
    }

    final mapCenter = locations.isNotEmpty
        ? LatLng(
            locations.first.coordinates.latitude,
            locations.first.coordinates.longitude,
          )
        : _defaultCenter;

    final selectedId = _selectedLocationId != null &&
            locations.any((l) => l.id == _selectedLocationId)
        ? _selectedLocationId
        : (locations.isNotEmpty ? locations.first.id : null);
    final selectedIndex =
        selectedId != null ? locations.indexWhere((l) => l.id == selectedId) : 0;
    final currentZoom = mapZoom.zoom;

    // Build an ExploreFilter that reflects the current locationFilterProvider
    // state so the panel pills show the correct active selection.
    final panelFilter = ExploreFilter(
      rankingFilter: filter.selectedRanking != null
          ? ExploreRanking.values.firstWhere(
              (r) => r.name == filter.selectedRanking!.name,
              orElse: () => ExploreRanking.trending,
            )
          : ExploreRanking.trending,
      hasRankingFilter: filter.selectedRanking != null,
      priceFilter: filter.selectedPrice,
    );

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 15.5,
                minZoom: 10,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  scrollWheelVelocity: 0.002,
                  pinchZoomThreshold: 0.4,
                  pinchMoveThreshold: 30.0,
                ),
                onTap: (_, _) {
                  if (_detailLocation != null) return;
                  _hidePanel();
                },
                onPositionChanged: (camera, _) {
                  ref.read(mapZoomProvider.notifier).updateZoom(camera.zoom);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.sponti.app',
                  tileProvider: NetworkTileProvider(),
                  maxNativeZoom: 18,
                  keepBuffer: 2,
                  panBuffer: 1,
                ),
                MarkerLayer(
                  rotate: false,
                  markers: buildLocationMarkers(
                    locations: locations,
                    selectedId: selectedId,
                    zoom: currentZoom,
                    keyPrefix: 'location_marker',
                    onTap: _showLocationDetails,
                    rankingSnapshot: rankingSnapshot,
                    activeRankingFilter: filter.selectedRanking,
                    activePriceFilter: filter.selectedPrice,
                  ),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: LocationMapAtmosphereOverlay()),
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
              bottom: 194,
              child: FloatingMessage(
                text: 'Unable to load spots. Pull refresh icon to retry.',
                icon: Icons.error_outline_rounded,
                color: SpontiColors.error,
              ),
            ),
          if (!_isExplorePanelVisible)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset,
              child: SafeArea(
                top: false,
                child: LocationMapFloatingControls(
                  selectedCategory: filter.selectedCategory,
                  selectedRanking: filter.selectedRanking,
                  selectedPrice: filter.selectedPrice,
                  onCategoryChanged: _onCategoryChanged,
                  onClearRanking: () {
                    ref.read(locationFilterProvider.notifier).setRanking(null);
                  },
                  onClearPrice: () {
                    ref.read(locationFilterProvider.notifier).setPrice(null);
                  },
                ),
              ),
            ),
          if (_isExplorePanelVisible && _detailLocation == null)
            ExploreBottomPanel(
              locationsAsync: locationsAsync,
              locations: locations,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              isExpanded: _isExplorePanelExpanded,
              bottomInset: bottomInset,
              selectedCategory: filter.selectedCategory,
              onCategoryChanged: _onCategoryChanged,
              filter: panelFilter,
              onRankingChanged: (ranking) {
                ref.read(locationFilterProvider.notifier).setRanking(
                  ranking == null
                      ? null
                      : LocationRanking.values.firstWhere(
                          (value) => value.name == ranking.name,
                          orElse: () => LocationRanking.trending,
                        ),
                );
              },
              onPriceChanged: (price) {
                ref.read(locationFilterProvider.notifier).setPrice(price);
              },
              onExpandChanged: _setPanelExpanded,
              onDismissed: _hidePanel,
              edgeToEdge: true,
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
        ],
      ),
    );
  }
}
