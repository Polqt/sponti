import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/view/widgets/explore_amenities_filter_modal.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_chips.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_sheets.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_map_markers.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/map_zoom_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _mapController = MapController();
  final ValueNotifier<double> _sheetProgress = ValueNotifier<double>(0.0);

  late final StateController<bool> _shellBarHiddenController;
  late final StateController<double> _shellChromeProgressController;

  String? _selectedLocationId;
  Location? _selectedLocation;
  bool _isPanelExpanded = false;
  LocationCategory? _lastAutoExpandedCategory;
  bool _wasPanelExpandedBeforeDetail = false;

  @override
  void initState() {
    super.initState();
    _shellBarHiddenController = ref.read(shellBarHiddenProvider.notifier);
    _shellChromeProgressController = ref.read(shellChromeProgressProvider.notifier);
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove || event is MapEventMoveEnd) {
        ref.read(mapZoomProvider.notifier).updateZoom(_mapController.camera.zoom);
      }
    });
  }

  void _setShellHidden(bool hidden) => _shellBarHiddenController.state = hidden;

  @override
  void dispose() {
    _sheetProgress.dispose();
    _setShellHidden(false);
    _shellChromeProgressController.state = 0.0;
    super.dispose();
  }

  void _setPanelExpanded(bool expanded) {
    setState(() => _isPanelExpanded = expanded);
    _setShellHidden(expanded);
  }

  void _syncSelection(List<Location> locations) {
    final newSelectedId = locations.isEmpty
        ? null
        : (locations.any((l) => l.id == _selectedLocationId)
            ? _selectedLocationId
            : locations.first.id);
    if (newSelectedId == _selectedLocationId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedLocationId = newSelectedId);
    });
  }

  void _selectLocation(Location location) {
    setState(() => _selectedLocationId = location.id);
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      currentZoom,
    );
  }

  void _showLocationDetails(Location location) {
    _wasPanelExpandedBeforeDetail = _isPanelExpanded;
    setState(() {
      _selectedLocationId = location.id;
      _selectedLocation = location;
      _isPanelExpanded = false;
    });
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
    _sheetProgress.value = 1.0;
    _shellChromeProgressController.state = 1.0;
    _setShellHidden(true);
  }

  void _closeLocationDetails() {
    setState(() {
      _selectedLocation = null;
      _isPanelExpanded = _wasPanelExpandedBeforeDetail;
    });
    final restoredProgress = _wasPanelExpandedBeforeDetail ? 1.0 : 0.0;
    _sheetProgress.value = restoredProgress;
    _shellChromeProgressController.state = restoredProgress;
    _setShellHidden(_wasPanelExpandedBeforeDetail);
  }

  void _toggleNowOpen() {
    ref.read(exploreFilterProvider.notifier).toggleNowOpen();
  }

  void _onCategoryChanged(LocationCategory? category) {
    ref.read(exploreFilterProvider.notifier).setCategory(category);
    _setPanelExpanded(true);
  }

  Future<void> _onAmenitiesTap(ExploreFilter filter) async {
    final picked = await showAmenitiesFilterModal(
      context: context,
      initialValue: AmenitiesFilterSelection(
        hasWifi: filter.hasWifi,
        petFriendly: filter.petFriendly,
        hasParking: filter.hasParking,
      ),
    );
    if (picked == null) return;
    ref.read(exploreFilterProvider.notifier).setAmenities(
      hasWifi: picked.hasWifi,
      petFriendly: picked.petFriendly,
      hasParking: picked.hasParking,
    );
  }

  void _syncPanelState(ExploreFilter filter) {
    if (filter.categoryFilter == null) {
      _lastAutoExpandedCategory = null;
      return;
    }
    if (_lastAutoExpandedCategory == filter.categoryFilter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lastAutoExpandedCategory = filter.categoryFilter;
      _setPanelExpanded(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(exploreProvider);
    final filter = ref.watch(exploreFilterProvider);
    final locations = locationsAsync.valueOrNull ?? const <Location>[];
    final trendingIds = ref.watch(
      trendingLocationIdsProvider.select((s) => s.valueOrNull ?? const <String>{}),
    );
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    _syncSelection(locations);
    _syncPanelState(filter);

    final selectedId = _selectedLocationId != null &&
            locations.any((l) => l.id == _selectedLocationId)
        ? _selectedLocationId
        : (locations.isNotEmpty ? locations.first.id : null);
    final selectedIndex =
        selectedId != null ? locations.indexWhere((l) => l.id == selectedId) : 0;
    final currentZoom = (() {
      try {
        return _mapController.camera.zoom;
      } catch (_) {
        return 15.5;
      }
    })();

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                  AppConstants.defaultLatitude,
                  AppConstants.defaultLongitude,
                ),
                initialZoom: 15.5,
                minZoom: 10,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  scrollWheelVelocity: 0.002,
                  pinchZoomThreshold: 0.4,
                  pinchMoveThreshold: 30.0,
                ),
                onTap: (_, _) => _setPanelExpanded(false),
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
                    keyPrefix: 'explore_marker',
                    onTap: _showLocationDetails,
                    trendingIds: trendingIds,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: ValueListenableBuilder<double>(
              valueListenable: _sheetProgress,
              builder: (context, progress, child) {
                final clamped = progress.clamp(0.0, 1.0);
                return Opacity(
                  opacity: 1.0 - clamped,
                  child: Transform.translate(
                    offset: Offset(-18 * clamped, 0),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ExploreFilterChips(
                  filter: filter,
                  onTapRanking: () => showRankingFilterSheet(context, ref, filter),
                  onTapPrice: () => showPriceFilterSheet(context, ref, filter),
                  onTapCategory: () => showCategoryFilterSheet(context, ref, filter),
                  onToggleNowOpen: _toggleNowOpen,
                  onTapAmenities: () => _onAmenitiesTap(filter),
                  showCategoryChip: false,
                ),
              ),
            ),
          ),
          if (locationsAsync.hasError)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset + (_isPanelExpanded ? 340 : 160),
              child: GestureDetector(
                onTap: () => ref.read(exploreProvider.notifier).refresh(),
                child: const FloatingMessage(
                  text: 'Unable to load explore spots. Tap to retry.',
                  icon: Icons.error_outline_rounded,
                  color: SpontiColors.error,
                ),
              ),
            ),
          if (_selectedLocation == null)
            ExploreBottomPanel(
              locationsAsync: locationsAsync,
              locations: locations,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              isExpanded: _isPanelExpanded,
              onExpandChanged: _setPanelExpanded,
              selectedCategory: filter.categoryFilter,
              onCategoryChanged: _onCategoryChanged,
              filter: filter,
              onRankingChanged: (ranking) {
                ref.read(exploreFilterProvider.notifier).setRanking(ranking);
              },
              onPriceChanged: (price) {
                ref.read(exploreFilterProvider.notifier).setPrice(price);
              },
              onSheetProgressChanged: (progress) {
                _sheetProgress.value = progress;
                _shellChromeProgressController.state = progress;
              },
              onSelectLocation: _selectLocation,
              onLocationTap: _showLocationDetails,
              hasMore: ref.read(exploreProvider.notifier).hasMore,
              isLoadingMore: locationsAsync.isLoading && locationsAsync.hasValue,
              onLoadMore: () =>
                  ref.read(exploreProvider.notifier).fetchNextPage(),
            ),
          if (_selectedLocation != null)
            Positioned.fill(
              child: LocationDetailSheet(
                key: ValueKey(_selectedLocation!.id),
                location: _selectedLocation!,
                onDismissed: _closeLocationDetails,
              ),
            ),
        ],
      ),
    );
  }
}
