import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

/// Refetch map pins, explore feed, and trending IDs after engagement changes
/// (favorites, check-ins, reviews) so ranking filters reflect new data.
void invalidateLocationExploreRankingCaches(
  void Function(ProviderOrFamily provider) invalidate,
) {
  invalidate(locationsProvider);
  invalidate(exploreProvider);
  invalidate(trendingLocationIdsProvider);
}
