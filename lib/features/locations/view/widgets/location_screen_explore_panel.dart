import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/explore/view/widgets/explore_bottom_panel.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationScreenExplorePanel extends ConsumerWidget {
  const LocationScreenExplorePanel({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.selectedIndex,
    required this.isExpanded,
    required this.onCategoryChanged,
    required this.onExpandChanged,
    required this.onDismissed,
    required this.onSheetProgressChanged,
    required this.onSelectLocation,
    required this.onLocationTap,
  });

  final AsyncValue<List<Location>> locationsAsync;
  final List<Location> locations;
  final int selectedIndex;
  final bool isExpanded;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final ValueChanged<bool> onExpandChanged;
  final VoidCallback onDismissed;
  final ValueChanged<double> onSheetProgressChanged;
  final ValueChanged<Location> onSelectLocation;
  final ValueChanged<Location> onLocationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(locationFilterProvider);
    final filterNotifier = ref.read(locationFilterProvider.notifier);
    final locationsNotifier = ref.read(locationsProvider.notifier);
    final hasMore = locationsNotifier.hasMore;
    final isLoadingMore = ref.watch(
      locationsProvider.select((s) => s.isLoading && s.hasValue),
    );

    final panelFilter = ExploreFilter(
      rankingFilter: filter.selectedRanking != null
          ? ExploreRanking.values.firstWhere(
              (ranking) => ranking.name == filter.selectedRanking!.name,
              orElse: () => ExploreRanking.trending,
            )
          : ExploreRanking.trending,
      hasRankingFilter: filter.selectedRanking != null,
      priceFilter: filter.selectedPrice,
      hasWifi: filter.hasWifi,
      petFriendly: filter.isPetFriendly,
      hasParking: filter.hasParking,
    );

    return ExploreBottomPanel(
      locationsAsync: locationsAsync,
      locations: locations,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      isExpanded: isExpanded,
      selectedCategory: filter.selectedCategory,
      onCategoryChanged: onCategoryChanged,
      filter: panelFilter,
      onRankingChanged: (ranking) {
        filterNotifier.setRanking(
          ranking == null
              ? null
              : LocationRanking.values.firstWhere(
                  (value) => value.name == ranking.name,
                  orElse: () => LocationRanking.trending,
                ),
        );
      },
      onPriceChanged: filterNotifier.setPrice,
      onWifiChanged: filterNotifier.setWifi,
      onPetFriendlyChanged: filterNotifier.setPetFriendly,
      onParkingChanged: filterNotifier.setParking,
      onExpandChanged: onExpandChanged,
      onDismissed: onDismissed,
      edgeToEdge: true,
      onSheetProgressChanged: onSheetProgressChanged,
      onSelectLocation: onSelectLocation,
      onLocationTap: onLocationTap,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      onLoadMore: () => locationsNotifier.fetchNextPage(),
    );
  }
}
