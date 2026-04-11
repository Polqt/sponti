import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/location_comparison/view/widgets/location_comparison_card.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/current_location_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationComparisonScreen extends ConsumerStatefulWidget {
  const LocationComparisonScreen({super.key});

  @override
  ConsumerState<LocationComparisonScreen> createState() =>
      _LocationComparisonScreenState();
}

class _LocationComparisonScreenState
    extends ConsumerState<LocationComparisonScreen> {
  String? _primaryLocationId;
  String? _secondaryLocationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentLocationProvider.notifier).locate();
    });
  }

  void _syncSelectedLocations(List<Location> locations) {
    if (locations.length < 2) return;

    final validIds = locations.map((location) => location.id).toSet();
    var nextPrimary = validIds.contains(_primaryLocationId)
        ? _primaryLocationId
        : locations.first.id;
    var nextSecondary =
        validIds.contains(_secondaryLocationId) &&
            _secondaryLocationId != nextPrimary
        ? _secondaryLocationId
        : locations.firstWhere((location) => location.id != nextPrimary).id;

    if (nextPrimary == nextSecondary) {
      nextSecondary =
          locations.firstWhere((location) => location.id != nextPrimary).id;
    }

    if (nextPrimary == _primaryLocationId && nextSecondary == _secondaryLocationId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _primaryLocationId = nextPrimary;
        _secondaryLocationId = nextSecondary;
      });
    });
  }

  void _switchOtherLocation(List<Location> locations) {
    if (locations.length < 3 || _primaryLocationId == null) return;

    final candidates = locations
        .where((location) => location.id != _primaryLocationId)
        .toList(growable: false);
    if (candidates.length < 2) return;

    final currentIndex = candidates.indexWhere(
      (location) => location.id == _secondaryLocationId,
    );
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % candidates.length;
    setState(() => _secondaryLocationId = candidates[nextIndex].id);
  }

  void _openCompareMapPicker() {
    ref.read(compareSelectionModeProvider.notifier).state = true;
    ref.read(pendingLocationProvider.notifier).state = null;
    context.go(RouteName.location);
  }

  @override
  Widget build(BuildContext context) {
    final pinnedIdsAsync = ref.watch(pinnedComparisonIdsProvider);
    final locationsAsync = ref.watch(pinnedComparisonLocationsProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: SpontiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare Spots',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        pinnedIdsAsync.maybeWhen(
                          data: (ids) => Text(
                            ids.isEmpty
                                ? 'Pin spots from any location card'
                                : '${ids.length} of $kLocationComparisonMaxPins spots pinned',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SpontiColors.textMuted,
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  pinnedIdsAsync.maybeWhen(
                    data: (ids) => ids.isNotEmpty
                        ? TextButton(
                            onPressed: () => ref
                                .read(pinnedComparisonIdsProvider.notifier)
                                .clear(),
                            style: TextButton.styleFrom(
                              foregroundColor: SpontiColors.error,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Clear all'),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: pinnedIdsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: SpontiColors.primary),
                ),
                error: (e, _) => AppErrorState(message: e.toString()),
                data: (pinnedIds) {
                  if (pinnedIds.isEmpty) {
                    return AppEmptyState(
                      emoji: 'PIN',
                      title: 'Nothing pinned yet',
                      subtitle:
                          'Tap the pin icon on any location to add it here. Pin 2-3 to compare.',
                      actionLabel: 'Pick from map',
                      onAction: _openCompareMapPicker,
                    );
                  }

                  if (locationsAsync.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: SpontiColors.primary,
                      ),
                    );
                  }

                  if (locationsAsync.hasError) {
                    return AppErrorState(
                      message: locationsAsync.error.toString(),
                    );
                  }

                  final locations =
                      locationsAsync.valueOrNull ?? const <Location>[];
                  if (locations.length < kLocationComparisonMinPins) {
                    return AppEmptyState(
                      emoji: 'VS',
                      title: 'Need at least 2',
                      subtitle: 'Pin one more location to start the comparison.',
                      actionLabel: 'Add location',
                      onAction: _openCompareMapPicker,
                    );
                  }

                  _syncSelectedLocations(locations);
                  final primary = locations.firstWhere(
                    (location) => location.id == _primaryLocationId,
                    orElse: () => locations.first,
                  );
                  final secondary = locations.firstWhere(
                    (location) => location.id == _secondaryLocationId,
                    orElse: () => locations.firstWhere(
                      (location) => location.id != primary.id,
                    ),
                  );

                  return _ComparisonBody(
                    primary: primary,
                    secondary: secondary,
                    pinnedCount: pinnedIds.length,
                    onSwitchOther: locations.length > 2
                        ? () => _switchOtherLocation(locations)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBody extends ConsumerWidget {
  const _ComparisonBody({
    required this.primary,
    required this.secondary,
    required this.pinnedCount,
    required this.onSwitchOther,
  });

  final Location primary;
  final Location secondary;
  final int pinnedCount;
  final VoidCallback? onSwitchOther;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(currentLocationProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: _ComparisonSlot(
              location: primary,
              distanceLabel: _distanceLabel(primary, currentLocation),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _CompareSwitcher(
              canSwitch: onSwitchOther != null,
              hasExtraPinnedLocation: pinnedCount > 2,
              onSwitchOther: onSwitchOther,
            ),
          ),
          Expanded(
            child: _ComparisonSlot(
              location: secondary,
              distanceLabel: _distanceLabel(secondary, currentLocation),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                backgroundColor: SpontiColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  String _distanceLabel(Location location, CurrentLocationState currentLocation) {
    if (!currentLocation.hasCoordinates) {
      return 'Distance unavailable';
    }

    final distanceMeters = Geolocator.distanceBetween(
      currentLocation.latitude!,
      currentLocation.longitude!,
      location.coordinates.latitude,
      location.coordinates.longitude,
    );

    return SpontiFormatter.distance(distanceMeters / 1000);
  }
}

class _ComparisonSlot extends ConsumerWidget {
  const _ComparisonSlot({
    required this.location,
    required this.distanceLabel,
  });

  final Location location;
  final String distanceLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(RouteName.locationDetailPath(location.id)),
            child: LocationComparisonCard(
              location: location,
              distanceLabel: distanceLabel,
              compact: true,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => ref
                .read(pinnedComparisonIdsProvider.notifier)
                .unpin(location.id),
            icon: const Icon(
              Icons.push_pin_outlined,
              size: 16,
              color: SpontiColors.error,
            ),
            label: const Text(
              'Unpin',
              style: TextStyle(
                color: SpontiColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: SpontiColors.error.withValues(alpha: 0.22),
              ),
              backgroundColor: SpontiColors.error.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompareSwitcher extends StatelessWidget {
  const _CompareSwitcher({
    required this.canSwitch,
    required this.hasExtraPinnedLocation,
    required this.onSwitchOther,
  });

  final bool canSwitch;
  final bool hasExtraPinnedLocation;
  final VoidCallback? onSwitchOther;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SpontiColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: SpontiColors.outline.withValues(alpha: 0.7),
            ),
          ),
          child: const Icon(
            Icons.compare_arrows_rounded,
            color: SpontiColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: canSwitch ? onSwitchOther : () => context.push('${RouteName.search}?mode=compare'),
            icon: Icon(canSwitch ? Icons.swap_horiz_rounded : Icons.add_rounded),
            label: Text(
              hasExtraPinnedLocation
                  ? 'Switch compared location'
                  : 'Compare another location',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: SpontiColors.primary,
              side: BorderSide(color: SpontiColors.primary.withValues(alpha: 0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
