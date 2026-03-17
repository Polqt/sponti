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
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
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
  String? _selectedLocationId;
  bool _didAutoCenter = false;
  bool _isExplorePanelVisible = false;
  bool _isExplorePanelExpanded = false;

  void _onTapCategory(LocationCategory category) {
    ref.read(locationFilterProvider.notifier).toggleCategory(category);
    ref.read(locationsProvider.notifier).onFilterChanged();
    setState(() {
      _isExplorePanelVisible = true;
      _isExplorePanelExpanded = true;
    });
    _sheetProgress.value = 1.0;
    ref.read(shellChromeProgressProvider.notifier).state = 1.0;
  }

  void _selectLocation(Location location) {
    setState(() {
      _selectedLocationId = location.id;
      _isExplorePanelVisible = true;
      _isExplorePanelExpanded = true;
    });
    _sheetProgress.value = 1.0;
    ref.read(shellChromeProgressProvider.notifier).state = 1.0;
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
  }

  void _setExplorePanelExpanded(bool expanded) {
    setState(() => _isExplorePanelExpanded = expanded);
  }

  @override
  void dispose() {
    _sheetProgress.dispose();
    ref.read(shellChromeProgressProvider.notifier).state = 0.0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final filter = ref.watch(locationFilterProvider);
    final favoriteIds = ref.watch(favoriteIdSetProvider);
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
                onTap: (_, _) => setState(() {
                  _selectedLocationId = null;
                  _isExplorePanelExpanded = false;
                  _isExplorePanelVisible = false;
                  _sheetProgress.value = 0.0;
                  ref.read(shellChromeProgressProvider.notifier).state = 0.0;
                }),
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
                          onTap: () => _selectLocation(location),
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
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomInset + 78 + 10,
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
              child: _CategoryIconRail(
                selectedCategory: filter.selectedCategory,
                onTapAll: () {
                  ref.read(locationFilterProvider.notifier).clearAll();
                  ref.read(locationsProvider.notifier).onFilterChanged();
                  setState(() {
                    _isExplorePanelVisible = true;
                    _isExplorePanelExpanded = true;
                  });
                  _sheetProgress.value = 1.0;
                  ref.read(shellChromeProgressProvider.notifier).state = 1.0;
                },
                onTapCategory: _onTapCategory,
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
              favoriteIds: favoriteIds,
              onExpandChanged: _setExplorePanelExpanded,
              edgeToEdge: true,
              onSheetProgressChanged: (progress) {
                _sheetProgress.value = progress;
                ref.read(shellChromeProgressProvider.notifier).state = progress;
              },
              onClose: () {
                setState(() {
                  _isExplorePanelVisible = false;
                  _isExplorePanelExpanded = false;
                });
                _sheetProgress.value = 0.0;
                ref.read(shellChromeProgressProvider.notifier).state = 0.0;
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

class _CategoryIconRail extends StatelessWidget {
  const _CategoryIconRail({
    required this.selectedCategory,
    required this.onTapAll,
    required this.onTapCategory,
  });

  final LocationCategory? selectedCategory;
  final VoidCallback onTapAll;
  final ValueChanged<LocationCategory> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryIconChip(
                label: 'All',
                icon: Icons.grid_view_rounded,
                color: SpontiColors.primary,
                isSelected: selectedCategory == null,
                onTap: onTapAll,
              ),
              const SizedBox(width: 10),
              for (final category in LocationCategory.values) ...[
                _CategoryIconChip(
                  label: category.label,
                  icon: category.icon,
                  color: Color(category.colorValue),
                  isSelected: selectedCategory == category,
                  onTap: () => onTapCategory(category),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIconChip extends StatelessWidget {
  const _CategoryIconChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? color : SpontiColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
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
