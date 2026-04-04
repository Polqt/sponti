import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/explore/view/widgets/explore_loading.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class ExploreBottomPanelList extends ConsumerWidget {
  const ExploreBottomPanelList({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.selectedIndex,
    required this.listScrollController,
    required this.itemKeys,
    required this.onSelectLocation,
    this.onLocationTap,
  });

  final AsyncValue<List<Location>> locationsAsync;
  final List<Location> locations;
  final int selectedIndex;
  final ScrollController listScrollController;
  final Map<String, GlobalKey> itemKeys;
  final ValueChanged<Location> onSelectLocation;
  final ValueChanged<Location>? onLocationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteIdSetProvider);
    final pinnedIds = ref.watch(pinnedComparisonIdSetProvider);

    if (locationsAsync.isLoading) {
      return ListView(
        controller: listScrollController,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: const [LoadingList()],
      );
    }

    if (locations.isEmpty) {
      return ListView(
        controller: listScrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        children: const [
          AppEmptyState(
            emoji: '🔍',
            title: 'Nothing found',
            subtitle: 'Try a different filter combo',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: listScrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: locations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final location = locations[index];
        final isSelected = index == selectedIndex;
        final key = itemKeys.putIfAbsent(
          location.id,
          () => GlobalKey(debugLabel: 'explore_item_${location.id}'),
        );

        return KeyedSubtree(
          key: key,
          child: RepaintBoundary(
            child: AnimatedContainer(
              key: ValueKey(location.id),
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Color(location.category.colorValue)
                      : const Color(0x14A68F7B),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: LocationCard(
                location: location,
                variant: LocationCardVariant.fullWidth,
                isSaved: favoriteIds.contains(location.id),
                showShadow: false,
                onTap: () {
                  final locationTap = onLocationTap;
                  if (locationTap != null) {
                    locationTap(location);
                    return;
                  }

                  onSelectLocation(location);
                },
                onSaveToggle: () =>
                    ref.read(favoriteIdsProvider.notifier).toggle(location.id),
                isPinnedForComparison: pinnedIds.contains(location.id),
                onComparisonToggle: () async {
                  final success = await ref
                      .read(pinnedComparisonIdsProvider.notifier)
                      .togglePin(location.id);
                  if (!context.mounted || success) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You can compare up to 3 locations only.'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
