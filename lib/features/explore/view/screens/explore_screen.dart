import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_chips.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_sheets.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
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

  String? _selectedLocationId;
  bool _isPanelExpanded = false;
  bool _didAutoExpandForFilter = false;
  bool _isLocationDetailOpen = false;

  @override
  void dispose() {
    _sheetProgress.dispose();
    ref.read(shellChromeProgressProvider.notifier).state = 0.0;
    super.dispose();
  }

  void _setPanelExpanded(bool expanded) {
    setState(() => _isPanelExpanded = expanded);
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

    final selectedId = locations.any((location) => location.id == _selectedLocationId)
        ? _selectedLocationId
        : locations.first.id;

    if (selectedId == _selectedLocationId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedLocationId = selectedId);
    });
  }

  void _focusLocation(Location location, {bool expandPanel = false}) {
    setState(() {
      _selectedLocationId = location.id;
      if (expandPanel) {
        _isPanelExpanded = true;
      }
    });

    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
  }

  Future<void> _showLocationDetails(Location location) async {
    _focusLocation(location);
    if (_isPanelExpanded) {
      setState(() => _isPanelExpanded = false);
    }
    if (_isLocationDetailOpen) return;

    _isLocationDetailOpen = true;
    try {
      await showLocationDetailSheet(context, location: location);
    } finally {
      _isLocationDetailOpen = false;
    }
  }

  Future<void> _toggleNowOpen() async {
    ref.read(exploreFilterProvider.notifier).toggleNowOpen();
    await ref.read(exploreProvider.notifier).onFilterChanged();
  }

  void _syncPanelState(ExploreFilter filter) {
    if (_didAutoExpandForFilter || filter.categoryFilter == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isPanelExpanded = true;
        _didAutoExpandForFilter = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(exploreProvider);
    final filter = ref.watch(exploreFilterProvider);
    final favoriteIds = ref.watch(favoriteIdSetProvider);
    final locations = locationsAsync.valueOrNull ?? const <Location>[];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final panelMaxHeight = MediaQuery.sizeOf(context).height * 0.62;
    final selectedId = locations.any((location) => location.id == _selectedLocationId)
        ? _selectedLocationId
        : (locations.isNotEmpty ? locations.first.id : null);
    final selectedIndex = selectedId == null
        ? 0
        : locations.indexWhere((location) => location.id == selectedId);

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
                onTap: (_, _) => setState(() => _isPanelExpanded = false),
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
                        child: MapPin(
                          icon: location.category.icon,
                          color: Color(location.category.colorValue),
                          isSelected: location.id == selectedId,
                          onTap: () => _showLocationDetails(location),
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
                ),
              ),
            ),
          ),
          if (locationsAsync.hasError)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset +
                  (_isPanelExpanded
                      ? panelMaxHeight + 28
                      : 152),
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
            favoriteIds: favoriteIds,
            onExpandChanged: _setPanelExpanded,
            onSheetProgressChanged: (progress) {
              _sheetProgress.value = progress;
              ref.read(shellChromeProgressProvider.notifier).state = progress;
            },
            onTapLocation: (location) {
              context.push(RouteName.locationDetailPath(location.id));
            },
            onSaveToggle: (location) =>
                ref.read(favoriteIdsProvider.notifier).toggle(location.id),
          ),
        ],
      ),
    );
  }
}
