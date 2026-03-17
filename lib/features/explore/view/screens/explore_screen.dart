import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/constants/app_constants.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_chips.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_sheets.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/map_pin.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _mapController = MapController();
  final _pageController = PageController(viewportFraction: 0.84);

  String? _selectedLocationId;
  bool _isPanelExpanded = false;
  bool _didAutoExpandForFilter = false;

  @override
  void dispose() {
    _pageController.dispose();
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
      _jumpToLocation(selectedId!, locations);
    });
  }

  void _jumpToLocation(String locationId, List<Location> locations) {
    final index = locations.indexWhere((location) => location.id == locationId);
    if (index < 0 || !_pageController.hasClients) return;
    _pageController.jumpToPage(index);
  }

  void _focusLocation(
    Location location,
    List<Location> locations, {
    bool expandPanel = false,
    bool animatePage = false,
  }) {
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

    if (!animatePage || !_pageController.hasClients) return;

    final index = locations.indexWhere((item) => item.id == location.id);
    if (index < 0) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
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
                        child: GestureDetector(
                          onTap: () => _focusLocation(
                            location,
                            locations,
                            expandPanel: true,
                            animatePage: true,
                          ),
                          child: MapPin(
                            icon: location.category.icon,
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
          if (locationsAsync.hasError)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset +
                  (_isPanelExpanded
                      ? MediaQuery.sizeOf(context).height * 0.55 + 36
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
            useListView: filter.categoryFilter != null,
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            isExpanded: _isPanelExpanded,
            bottomInset: bottomInset,
            pageController: _pageController,
            favoriteIds: favoriteIds,
            onExpandChanged: _setPanelExpanded,
            onPageChanged: (index) {
              if (index < 0 || index >= locations.length) return;
              _focusLocation(locations[index], locations);
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
