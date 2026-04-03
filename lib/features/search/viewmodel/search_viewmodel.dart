import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/feature_flags.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_query.dart';
import 'package:sponti/features/locations/viewmodel/current_location_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

const int searchMinQueryLength = 2;

String normalizeSearchQuery(String query) =>
    query.trim().replaceAll(RegExp(r'\s+'), ' ');

String _searchCacheKey(String query, {required bool useRankedSearch}) {
  final normalized = normalizeSearchQuery(query).toLowerCase();
  final strategy = useRankedSearch ? 'ranked' : 'legacy';
  return '$strategy::$normalized';
}

String _normalizedSearchText(String value) =>
    normalizeSearchQuery(value).toLowerCase();

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final normalizedSearchQueryProvider = Provider.autoDispose<String>((ref) {
  return normalizeSearchQuery(ref.watch(searchQueryProvider));
});

final _searchResultsCacheProvider =
    StateProvider<Map<String, List<Location>>>(
      (ref) => const <String, List<Location>>{},
    );

List<Location> _dedupeLocations(List<Location> locations) {
  final uniqueLocations = <String, Location>{};
  for (final location in locations) {
    uniqueLocations[location.id] = location;
  }

  return List.unmodifiable(uniqueLocations.values);
}

List<String> _queryTokens(String query) {
  final normalized = normalizeSearchQuery(query).toLowerCase();
  if (normalized.isEmpty) return const <String>[];

  return normalized
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

int _scoreTextMatch(String text, String query, List<String> tokens) {
  if (text.isEmpty) return 0;

  var score = 0;
  if (text == query) score += 1400;
  if (text.startsWith(query)) score += 900;
  if (text.contains(query)) score += 450;

  for (final token in tokens) {
    if (text.startsWith(token)) {
      score += 180;
      continue;
    }

    if (text.contains(token)) {
      score += 90;
    }
  }

  return score;
}

int _locationSearchScore(Location location, String query, List<String> tokens) {
  final name = _normalizedSearchText(location.name);
  final address = _normalizedSearchText(location.address);
  final category = _normalizedSearchText(location.category.label);
  final description = _normalizedSearchText(location.description);
  final landmark = _normalizedSearchText(location.landmark ?? '');
  final tags = _normalizedSearchText(location.tags.join(' '));

  var score = 0;
  score += _scoreTextMatch(name, query, tokens) * 4;
  score += _scoreTextMatch(category, query, tokens) * 2;
  score += _scoreTextMatch(address, query, tokens) * 2;
  score += _scoreTextMatch(landmark, query, tokens);
  score += _scoreTextMatch(tags, query, tokens);
  score += _scoreTextMatch(description, query, tokens);
  score += (location.rating * 18).round();
  score += location.reviewCount.clamp(0, 250);
  score += location.checkInCount.clamp(0, 180);

  return score;
}

List<Location> _rankLocations(List<Location> locations, String query) {
  final uniqueLocations = _dedupeLocations(locations);
  final normalizedQuery = normalizeSearchQuery(query).toLowerCase();
  final tokens = _queryTokens(normalizedQuery);
  final rankedLocations = uniqueLocations.toList(growable: true);
  final scoreByLocationId = <String, int>{
    for (final location in rankedLocations)
      location.id: _locationSearchScore(location, normalizedQuery, tokens),
  };

  rankedLocations.sort((left, right) {
    final scoreDiff =
        (scoreByLocationId[right.id] ?? 0) - (scoreByLocationId[left.id] ?? 0);
    if (scoreDiff != 0) return scoreDiff;

    final ratingDiff = right.rating.compareTo(left.rating);
    if (ratingDiff != 0) return ratingDiff;

    final reviewDiff = right.reviewCount.compareTo(left.reviewCount);
    if (reviewDiff != 0) return reviewDiff;

    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return List.unmodifiable(rankedLocations);
}

String searchErrorMessage(Object error) {
  final rawMessage = error.toString().trim();
  if (rawMessage.startsWith('Bad state: ')) {
    return rawMessage.substring('Bad state: '.length).trim();
  }

  if (rawMessage.isEmpty) {
    return 'Something went wrong while searching.';
  }

  return rawMessage;
}

final searchResultsProvider = FutureProvider.autoDispose<List<Location>>((
  ref,
) async {
  final query = ref.watch(normalizedSearchQueryProvider);
  final flags = ref.watch(featureFlagsProvider);
  final cacheKey = _searchCacheKey(
    query,
    useRankedSearch: flags.useRankedSearch,
  );

  if (query.length < searchMinQueryLength) {
    return const <Location>[];
  }

  final cachedResults = ref.read(_searchResultsCacheProvider)[cacheKey];
  if (cachedResults != null) {
    return cachedResults;
  }

  final repository = ref.read(locationRepositoryProvider);
  late final Future<Either<Failure, List<Location>>> pendingResult;
  var usedRankedSearch = false;

  if (flags.useRankedSearch) {
    final currentLocation = ref.read(currentLocationProvider);
    final rankedResult = await repository.searchLocationsRanked(
      RankedLocationSearchRequest(
        query: query,
        latitude: currentLocation.hasCoordinates ? currentLocation.latitude : null,
        longitude: currentLocation.hasCoordinates
            ? currentLocation.longitude
            : null,
      ),
    );

    if (rankedResult.isLeft()) {
      pendingResult = repository.searchLocations(query);
    } else {
      usedRankedSearch = true;
      pendingResult = Future.value(rankedResult);
    }
  } else {
    pendingResult = repository.searchLocations(query);
  }

  final result = await pendingResult;
  return result.fold(
    (failure) => throw StateError(failure.message),
    (locations) {
      final rankedLocations = usedRankedSearch
          ? _dedupeLocations(locations)
          : _rankLocations(locations, query);
      ref.read(_searchResultsCacheProvider.notifier).update(
        (state) => <String, List<Location>>{
          ...state,
          cacheKey: rankedLocations,
        },
      );
      return rankedLocations;
    },
  );
});
