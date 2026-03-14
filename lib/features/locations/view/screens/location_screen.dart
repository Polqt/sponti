import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/floating_message.dart';
import 'package:sponti/core/widgets/glass_container.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/bottom_rail_panel.dart';
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
  String? _selectedLocationId;
  bool _didAutoCenter = false;
  bool _isRailExpanded = false;

  void _onTapCategory(LocationCategory category) {
    ref.read(locationFilterProvider.notifier).toggleCategory(category);
    ref.read(locationsProvider.notifier).onFilterChanged();
  }

  void _selectLocation(Location location) {
    setState(() {
      _selectedLocationId = location.id;
      _isRailExpanded = true;
    });
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
  }

  void _setRailExpanded(bool expanded) {
    setState(() => _isRailExpanded = expanded);
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
                  _isRailExpanded = false;
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
          BottomRailPanel(
            locations: locations,
            selectedId: selectedId,
            selectedCategory: filter.selectedCategory,
            isExpanded: _isRailExpanded,
            bottomInset: bottomInset,
            onExpandChanged: _setRailExpanded,
            onTapCategory: _onTapCategory,
            onTapLocation: (location) {
              context.push(RouteName.locationDetailPath(location.id));
            },
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
