import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

const int searchMinQueryLength = 2;

String normalizeSearchQuery(String query) =>
    query.trim().replaceAll(RegExp(r'\s+'), ' ');

String _searchCacheKey(String query) => normalizeSearchQuery(query).toLowerCase();

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final normalizedSearchQueryProvider = Provider.autoDispose<String>((ref) {
  return normalizeSearchQuery(ref.watch(searchQueryProvider));
});

final _searchResultsCacheProvider =
    StateProvider.autoDispose<Map<String, List<Location>>>(
      (ref) => const <String, List<Location>>{},
    );

List<Location> _dedupeLocations(List<Location> locations) {
  final uniqueLocations = <String, Location>{};
  for (final location in locations) {
    uniqueLocations[location.id] = location;
  }

  return List.unmodifiable(uniqueLocations.values);
}

final searchResultsProvider = FutureProvider.autoDispose<List<Location>>((
  ref,
) async {
  final query = ref.watch(normalizedSearchQueryProvider);
  final cacheKey = _searchCacheKey(query);

  if (query.length < searchMinQueryLength) {
    return const <Location>[];
  }

  final cachedResults = ref.read(_searchResultsCacheProvider)[cacheKey];
  if (cachedResults != null) {
    return cachedResults;
  }

  final result = await ref.read(locationRepositoryProvider).searchLocations(
    query,
  );

  return result.fold(
    (failure) => throw StateError(failure.message),
    (locations) {
      final uniqueLocations = _dedupeLocations(locations);
      ref.read(_searchResultsCacheProvider.notifier).update(
        (state) => <String, List<Location>>{
          ...state,
          cacheKey: uniqueLocations,
        },
      );
      return uniqueLocations;
    },
  );
});
