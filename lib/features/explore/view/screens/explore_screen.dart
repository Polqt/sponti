import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_chips.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_sheets.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/view/widgets/map_pin.dart';
import 'package:sponti/features/locations/view/widgets/marker_collision_detector.dart';
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
  bool _isPanelExpanded = false;
  bool _isPanelVisible = true;
  bool _isLocationDetailOpen = false;
  LocationCategory? _lastAutoExpandedCategory;
  bool _wasPanelExpandedBeforeDetail = false;

  @override
  void initState() {
    super.initState();
    _shellBarHiddenController = ref.read(shellBarHiddenProvider.notifier);
    _shellChromeProgressController = ref.read(
      shellChromeProgressProvider.notifier,
    );
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove || event is MapEventMoveEnd) {
        ref.read(mapZoomProvider.notifier).updateZoom(_mapController.camera.zoom);
      }
    });
  }

  void _setShellHidden(bool hidden) {
    _shellBarHiddenController.state = hidden;
  }

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

  Future<void> _showLocationDetails(Location location) async {
    if (_isLocationDetailOpen) return;
    _wasPanelExpandedBeforeDetail = _isPanelExpanded;
    setState(() {
      _selectedLocationId = location.id;
      _isPanelExpanded = false;
      _isPanelVisible = false;
    });
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
    _sheetProgress.value = 1.0;
    _shellChromeProgressController.state = 1.0;
    _setShellHidden(true);
    _isLocationDetailOpen = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      await showLocationDetailSheet(context, location: location);
    } finally {
      if (!mounted) return;
      _isLocationDetailOpen = false;
      final restoredProgress = _wasPanelExpandedBeforeDetail ? 1.0 : 0.0;
      setState(() {
        _isPanelVisible = true;
        _isPanelExpanded = _wasPanelExpandedBeforeDetail;
      });
      _sheetProgress.value = restoredProgress;
      _shellChromeProgressController.state = restoredProgress;
      _setShellHidden(_wasPanelExpandedBeforeDetail);
    }
  }

  Future<void> _toggleNowOpen() async {
    ref.read(exploreFilterProvider.notifier).toggleNowOpen();
    await ref.read(exploreProvider.notifier).refresh();
  }

  Future<void> _onCategoryChanged(LocationCategory? category) async {
    ref.read(exploreFilterProvider.notifier).setCategory(category);
    _setPanelExpanded(true);
    await ref.read(exploreProvider.notifier).refresh();
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

  List<Marker> _buildSortedMarkers(List<Location> locations, String? selectedId) {
    double currentZoom;
    try {
      currentZoom = _mapController.camera.zoom;
    } catch (_) {
      currentZoom = 15.5;
    }

    final markerData = locations.map((location) {
      final isSelected = location.id == selectedId;
      final zIndex = isSelected ? 1000.0 : 100.0 + (location.rating * 10).clamp(0.0, 100.0);
      final ranking = location.getPrimaryRanking(locations);
      return (
        location: location,
        isSelected: isSelected,
        zIndex: zIndex,
        point: LatLng(location.coordinates.latitude, location.coordinates.longitude),
        ranking: ranking,
      );
    }).toList();

    markerData.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final markerPositions = {
      for (var data in markerData) data.location.id: data.point,
    };

    final collidingIds = MarkerCollisionDetector.getCollidingMarkerIds(
      markerPositions: markerPositions,
      zoom: currentZoom,
    );

    return markerData.map((data) {
      final shouldHideLabel = currentZoom < 16.0 &&
          collidingIds.contains(data.location.id) &&
          !data.isSelected;
      return Marker(
        point: data.point,
        width: 100,
        height: 50,
        alignment: Alignment.center,
        child: RepaintBoundary(
          child: GestureDetector(
            key: ValueKey('explore_marker_${data.location.id}'),
            onTap: () => _showLocationDetails(data.location),
            child: MapPin(
              category: data.location.category,
              isSelected: data.isSelected,
              locationName: shouldHideLabel ? null : data.location.name,
              rating: data.location.rating,
              ranking: data.ranking,
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(exploreProvider);
    final filter = ref.watch(exploreFilterProvider);
    final locations = locationsAsync.valueOrNull ?? const <Location>[];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    _syncSelection(locations);
    _syncPanelState(filter);

    final selectedId = _selectedLocationId != null &&
            locations.any((l) => l.id == _selectedLocationId)
        ? _selectedLocationId
        : (locations.isNotEmpty ? locations.first.id : null);
    final selectedIndex =
        selectedId != null ? locations.indexWhere((l) => l.id == selectedId) : 0;

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
                  markers: _buildSortedMarkers(locations, selectedId),
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
                  onTapRanking: () =>
                      showRankingFilterSheet(context, ref, filter),
                  onTapPrice: () => showPriceFilterSheet(context, ref, filter),
                  onTapCategory: () =>
                      showCategoryFilterSheet(context, ref, filter),
                  onToggleNowOpen: _toggleNowOpen,
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
          ExploreBottomPanel(
            locationsAsync: locationsAsync,
            locations: locations,
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            isVisible: _isPanelVisible,
            bottomInset: bottomInset,
            isExpanded: _isPanelExpanded,
            onExpandChanged: _setPanelExpanded,
            selectedCategory: filter.categoryFilter,
            onCategoryChanged: _onCategoryChanged,
            filter: filter,
            onSheetProgressChanged: (progress) {
              _sheetProgress.value = progress;
              _shellChromeProgressController.state = progress;
            },
            onSelectLocation: _selectLocation,
            onLocationTap: _showLocationDetails,
          ),
        ],
      ),
    );
  }
}
