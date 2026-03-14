import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/favorites/favorites_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';
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

  void _onTapCategory(LocationCategory category) {
    ref.read(locationFilterProvider.notifier).toggleCategory(category);
    ref.read(locationsProvider.notifier).onFilterChanged();
  }

  void _focusLocation(Location location) {
    setState(() => _selectedLocationId = location.id);
    _mapController.move(
      LatLng(location.coordinates.latitude, location.coordinates.longitude),
      14.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final filter = ref.watch(locationFilterProvider);
    final favoriteIds = ref.watch(favoriteIdSetProvider);
    final locations = locationsAsync.valueOrNull ?? const <Location>[];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final categoriesBottom = bottomInset + 104;
    final previewBottom = categoriesBottom + 72;

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
                onTap: (_, _) => setState(() => _selectedLocationId = null),
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
                          onTap: () => _focusLocation(location),
                          child: _MapPin(
                            icon: _iconForCategory(location.category),
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
                        child: _GlassBadge(
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
                      _GlassIconButton(
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
              child: _FloatingMessage(
                text: 'Unable to load spots. Pull refresh icon to retry.',
                icon: Icons.error_outline_rounded,
                color: SpontiColors.error,
              ),
            ),
          if (locations.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: previewBottom,
              child: _LocationPreviewRail(
                locations: locations,
                favoriteIds: favoriteIds,
                selectedId: selectedId,
                onTapLocation: (location) {
                  _focusLocation(location);
                  context.push(RouteName.locationDetailPath(location.id));
                },
                onToggleFavorite: (location) =>
                    ref.read(favoriteIdsProvider.notifier).toggle(location.id),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: categoriesBottom,
            child: _CategoryRail(
              selected: filter.selectedCategory,
              onTapCategory: _onTapCategory,
            ),
          ),
        ],
      ),
    );
  }
}


class _LocationPreviewRail extends StatelessWidget {
  const _LocationPreviewRail({
    required this.locations,
    required this.favoriteIds,
    required this.selectedId,
    required this.onTapLocation,
    required this.onToggleFavorite,
  });

  final List<Location> locations;
  final Set<String> favoriteIds;
  final String? selectedId;
  final ValueChanged<Location> onTapLocation;
  final ValueChanged<Location> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: locations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final location = locations[index];
          final isSelected = location.id == selectedId;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? SpontiColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: LocationCard(
              location: location,
              width: 248,
              isSaved: favoriteIds.contains(location.id),
              onTap: () => onTapLocation(location),
              onSaveToggle: () => onToggleFavorite(location),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.selected, required this.onTapCategory});

  final LocationCategory? selected;
  final ValueChanged<LocationCategory> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: SpontiColors.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: SpontiColors.outline.withValues(alpha: 0.65),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  color: SpontiColors.primary,
                  isSelected: selected == null,
                  onTap: () {
                    if (selected != null) {
                      onTapCategory(selected!);
                    }
                  },
                ),
                const SizedBox(width: 8),
                for (final category in LocationCategory.values) ...[
                  _CategoryChip(
                    label: _displayCategoryLabel(category),
                    icon: _iconForCategory(category),
                    color: Color(category.colorValue),
                    isSelected: selected == category,
                    onTap: () => onTapCategory(category),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
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
    return _GlassBadge(
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : SpontiColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : SpontiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.color,
    required this.isSelected,
  });

  final IconData icon;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final pinColor = isSelected ? color : color.withValues(alpha: 0.9);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: isSelected ? 46 : 40,
        height: isSelected ? 46 : 40,
        decoration: BoxDecoration(
          color: pinColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: pinColor.withValues(alpha: 0.35),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isSelected ? 20 : 18),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: SpontiColors.surface.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SpontiColors.outline.withValues(alpha: 0.65),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassBadge(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Icon(icon, size: 22, color: SpontiColors.textPrimary),
      ),
    );
  }
}

class _FloatingMessage extends StatelessWidget {
  const _FloatingMessage({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SpontiColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayCategoryLabel(LocationCategory category) => switch (category) {
  LocationCategory.food => 'Food',
  LocationCategory.coffee => 'Coffee',
  LocationCategory.nature => 'Nature',
  LocationCategory.nightlife => 'Nightlife',
  LocationCategory.arts => 'Arts',
  LocationCategory.activities => 'Fun',
};

IconData _iconForCategory(LocationCategory category) => switch (category) {
  LocationCategory.food => Icons.restaurant_rounded,
  LocationCategory.coffee => Icons.local_cafe_rounded,
  LocationCategory.nature => Icons.park_rounded,
  LocationCategory.nightlife => Icons.nightlife_rounded,
  LocationCategory.arts => Icons.palette_rounded,
  LocationCategory.activities => Icons.sports_esports_rounded,
};
