import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/shell/shell_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/core/widgets/glass_container.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_category_row.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_sheet.dart';
import 'package:sponti/features/locations/view/widgets/map_pin.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  static const _defaultCenter = LatLng(10.6765, 122.9509);

  final _mapController = MapController();
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
    _shellChromeProgressController = ref.read(
      shellChromeProgressProvider.notifier,
    );
  }

  void _setShellHidden(bool hidden) {
    _shellBarHiddenController.state = hidden;
  }

  Future<void> _onCategoryChanged(LocationCategory? category) async {
    ref.read(locationFilterProvider.notifier).setCategory(category);
    await ref.read(locationsProvider.notifier).onFilterChanged();
    _openPanel();
  }

  void _openPanel() {
    setState(() {
      _isExplorePanelVisible = true;
      _isExplorePanelExpanded = true;
    });
    _sheetProgress.value = 1.0;
    _shellChromeProgressController.state = 1.0;
    _setShellHidden(true);
  }

  void _selectLocation(Location location) {
    setState(() => _selectedLocationId = location.id);
    _openPanel();
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
  }

  Future<void> _showLocationDetails(Location location) async {
    if (_isLocationDetailOpen) return;

    setState(() {
      _selectedLocationId = location.id;
      _isExplorePanelVisible = false;
      _isExplorePanelExpanded = false;
    });
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
    _sheetProgress.value = 0.0;
    _shellChromeProgressController.state = 0.0;
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
    _sheetProgress.value = 0.0;
    _shellChromeProgressController.state = 0.0;
    _setShellHidden(false);
  }

  @override
  void dispose() {
    _sheetProgress.dispose();
    _setShellHidden(false);
    _shellChromeProgressController.state = 0.0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final filter = ref.watch(locationFilterProvider);
    final locations = locationsAsync.valueOrNull ?? const <Location>[];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final mapCenter = locations.isNotEmpty
        ? LatLng(
            locations.first.coordinates.latitude,
            locations.first.coordinates.longitude,
          )
        : _defaultCenter;

    if (!_didAutoCenter && locations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(mapCenter, 13.3);
        _didAutoCenter = true;
      });
    }

    final hasSelected = locations.any((l) => l.id == _selectedLocationId);
    final selectedId = hasSelected
        ? _selectedLocationId
        : (locations.isNotEmpty ? locations.first.id : null);
    final selectedIndex = selectedId == null
        ? 0
        : locations.indexWhere((l) => l.id == selectedId);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 12.8,
                minZoom: 10,
                maxZoom: 18,
                onTap: (_, _) => _hidePanel(),
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
                          key: ValueKey('location_marker_${location.id}'),
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
                child: Column(
                  children: [
                    const _GlassSearchBar(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Bacolod Spots',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: SpontiColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${locations.length} places nearby',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: SpontiColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GlassIconButton(
                          icon: Icons.refresh_rounded,
                          onTap: () =>
                              ref.read(locationsProvider.notifier).refresh(),
                        ),
                      ],
                    ),
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
                child: _FloatingCategoryRow(
                  selectedCategory: filter.selectedCategory,
                  onChanged: _onCategoryChanged,
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
              onExpandChanged: _setPanelExpanded,
              onDismissed: _hidePanel,
              edgeToEdge: true,
              onSheetProgressChanged: (progress) {
                _sheetProgress.value = progress;
                _shellChromeProgressController.state = progress;
              },
              onSelectLocation: _selectLocation,
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
    return GlassContainer(
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
