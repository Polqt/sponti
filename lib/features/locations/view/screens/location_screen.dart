import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/core/widgets/glass_container.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_map_markers.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/view/widgets/location_category_row.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

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
  bool _didAutoCenter = false;
  bool _isExplorePanelVisible = false;
  bool _isExplorePanelExpanded = false;
  bool _isLocationDetailOpen = false;

  @override
  void initState() {
    super.initState();
    _shellBarHiddenController = ref.read(shellBarHiddenProvider.notifier);
    _shellChromeProgressController = ref.read(shellChromeProgressProvider.notifier);
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

  Future<void> _showLocationDetails(Location location) async {
    if (_isLocationDetailOpen) return;

    setState(() {
      _selectedLocationId = location.id;
      _isExplorePanelVisible = false;
      _isExplorePanelExpanded = false;
    });
    _focusLocation(location);
    _setSheetProgress(0.0);
    _setShellHidden(true);
    _isLocationDetailOpen = true;

    try {
      await showLocationDetailSheet(context, location: location);
    } finally {
      _isLocationDetailOpen = false;
      _setShellHidden(false);
    }
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
    var locations = locationsAsync.valueOrNull ?? const <Location>[];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final rankingSnapshot = locations.isEmpty
        ? null
        : locations.createRankingSnapshot();

    if (filter.selectedRanking != null && rankingSnapshot != null) {
      locations = locations
          .where((loc) => rankingSnapshot.rankingFor(loc) == filter.selectedRanking)
          .toList();
    }

    if (filter.selectedPrice != null) {
      locations = locations
          .where((loc) => loc.priceRange == filter.selectedPrice)
          .toList();
    }

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
    final currentZoom = (() {
      try {
        return _mapController.camera.zoom;
      } catch (_) {
        return 15.5;
      }
    })();

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
                onTap: (_, _) => _hidePanel(),
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
                child: const Column(
                  children: [
                    _GlassSearchBar(),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter.selectedRanking != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RankingFilterChip(
                          ranking: filter.selectedRanking!,
                          onClear: () {
                            ref.read(locationFilterProvider.notifier).setRanking(null);
                          },
                        ),
                      ),
                    _FloatingCategoryRow(
                      selectedCategory: filter.selectedCategory,
                      onChanged: _onCategoryChanged,
                    ),
                  ],
                ),
              ),
            ),
          if (_isExplorePanelVisible)
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
        ],
      ),
    );
  }
}

class _GlassSearchBar extends StatelessWidget {
  const _GlassSearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(RouteName.search),
        child: GlassContainer(
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 20,
                color: SpontiColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search spots, cafes, parks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: SpontiColors.textSecondary.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCategoryRow extends StatelessWidget {
  const _FloatingCategoryRow({
    required this.selectedCategory,
    required this.onChanged,
  });

  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: SpontiColors.surface.withValues(alpha: 0.74),
          ),
          padding: const EdgeInsets.all(10),
          child: LocationCategoryRow(
            selectedCategory: selectedCategory,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _RankingFilterChip extends StatelessWidget {
  const _RankingFilterChip({
    required this.ranking,
    required this.onClear,
  });

  final LocationRanking ranking;
  final VoidCallback onClear;

  String get _label => switch (ranking) {
        LocationRanking.trending => 'Trending',
        LocationRanking.popular => 'Popular',
        LocationRanking.lowkey => 'Lowkey',
        LocationRanking.newest => 'New',
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: SpontiColors.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ranking.indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: SpontiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
