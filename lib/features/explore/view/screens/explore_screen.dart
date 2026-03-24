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
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/view/widgets/map_pin.dart';

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
  LocationCategory? _lastAutoExpandedCategory;
  bool _isLocationDetailOpen = false;

  @override
  void initState() {
    super.initState();
    _shellBarHiddenController = ref.read(shellBarHiddenProvider.notifier);
    _shellChromeProgressController = ref.read(
      shellChromeProgressProvider.notifier,
    );
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
    if (locations.isEmpty) {
      if (_selectedLocationId == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedLocationId = null);
      });
      return;
    }

    final selectedId = locations.any((l) => l.id == _selectedLocationId)
        ? _selectedLocationId
        : locations.first.id;

    if (selectedId == _selectedLocationId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedLocationId = selectedId);
    });
  }

  void _selectLocation(Location location) {
    setState(() => _selectedLocationId = location.id);
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
  }

  Future<void> _showLocationDetails(Location location) async {
    if (_isLocationDetailOpen) return;

    _selectLocation(location);
    _setPanelExpanded(false);
    _setShellHidden(true);
    _isLocationDetailOpen = true;

    try {
      await showLocationDetailSheet(context, location: location);
    } finally {
      _isLocationDetailOpen = false;
      _setShellHidden(_isPanelExpanded);
    }
  }

  Future<void> _toggleNowOpen() async {
    ref.read(exploreFilterProvider.notifier).toggleNowOpen();
    await ref.read(exploreProvider.notifier).onFilterChanged();
  }

  Future<void> _onCategoryChanged(LocationCategory? category) async {
    ref.read(exploreFilterProvider.notifier).setCategory(category);
    _setPanelExpanded(true);
    await ref.read(exploreProvider.notifier).onFilterChanged();
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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final selectedId = locations.any((l) => l.id == _selectedLocationId)
        ? _selectedLocationId
        : (locations.isNotEmpty ? locations.first.id : null);
    final selectedIndex = selectedId == null
        ? 0
        : locations.indexWhere((l) => l.id == selectedId);

    _syncSelection(locations);
    _syncPanelState(filter);

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
                initialZoom: 12.8,
                minZoom: 10,
                maxZoom: 18,
                onTap: (_, _) => _setPanelExpanded(false),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.sponti.app',
                ),
                MarkerLayer(
                  markers: [
                    for (final location in locations)
                      Marker(
                        point: LatLng(
                          location.coordinates.latitude,
                          location.coordinates.longitude,
                        ),
                        width: 62,
                        height: 62,
                        child: GestureDetector(
                          key: ValueKey('explore_marker_${location.id}'),
                          onTap: () => _showLocationDetails(location),
                          child: MapPin(
                            category: location.category,
                            color: Color(location.category.colorValue),
                            isSelected: location.id == selectedId,
                          ),
                        ),
                      ),
                  ],
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
            isExpanded: _isPanelExpanded,
            bottomInset: bottomInset,
            onExpandChanged: _setPanelExpanded,
            selectedCategory: filter.categoryFilter,
            onCategoryChanged: _onCategoryChanged,
            onSheetProgressChanged: (progress) {
              _sheetProgress.value = progress;
              _shellChromeProgressController.state = progress;
            },
            // Card tap → highlight map pin only (no navigation)
            onSelectLocation: _selectLocation,
          ),
        ],
      ),
    );
  }
}
