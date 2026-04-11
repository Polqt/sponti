import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/config.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/repository/location_local_data_source.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:sponti/features/locations/repository/location_repository.dart';
import 'package:sponti/features/locations/model/location_query.dart';
import 'package:sponti/features/locations/repository/location_repository_impl.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final locationLocalDataSourceProvider = Provider<LocationLocalDataSource>((
  ref,
) {
  return const LocationLocalDataSourceImpl();
});

final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((
  ref,
) {
  return LocationRemoteDataSourceImpl(Supabase.instance.client);
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    ref.read(locationRemoteDataSourceProvider),
    ref.read(locationLocalDataSourceProvider),
  );
});

class LocationFilter {
  const LocationFilter({
    this.selectedCategory,
    this.selectedRanking,
    this.selectedPrice,
    this.hasWifi = false,
    this.isPetFriendly = false,
    this.hasParking = false,
  });

  final LocationCategory? selectedCategory;
  final LocationRanking? selectedRanking;
  final PriceRange? selectedPrice;
  final bool hasWifi;
  final bool isPetFriendly;
  final bool hasParking;

  LocationFilter copyWith({
    Object? selectedCategory = _sentinel,
    Object? selectedRanking = _sentinel,
    Object? selectedPrice = _sentinel,
    bool? hasWifi,
    bool? isPetFriendly,
    bool? hasParking,
  }) => LocationFilter(
    selectedCategory: selectedCategory == _sentinel
        ? this.selectedCategory
        : selectedCategory as LocationCategory?,
    selectedRanking: selectedRanking == _sentinel
        ? this.selectedRanking
        : selectedRanking as LocationRanking?,
    selectedPrice: selectedPrice == _sentinel
        ? this.selectedPrice
        : selectedPrice as PriceRange?,
    hasWifi: hasWifi ?? this.hasWifi,
    isPetFriendly: isPetFriendly ?? this.isPetFriendly,
    hasParking: hasParking ?? this.hasParking,
  );

  static const _sentinel = Object();
}

class FilteredLocationsResult {
  const FilteredLocationsResult({
    required this.visibleLocations,
    required this.rankingSnapshot,
  });

  final List<Location> visibleLocations;
  final LocationRankingSnapshot? rankingSnapshot;
}

FilteredLocationsResult applyLocationFilters({
  required List<Location> locations,
  required LocationFilter filter,
}) {
  final rankingSnapshot = locations.isEmpty
      ? null
      : locations.createRankingSnapshot();
  var filtered = locations;

  if (filter.selectedRanking != null && rankingSnapshot != null) {
    filtered = filtered
        .where(
          (location) =>
              rankingSnapshot.rankingFor(location) == filter.selectedRanking,
        )
        .toList(growable: false);
  }

  if (filter.selectedPrice != null) {
    filtered = filtered
        .where((location) => location.priceRange == filter.selectedPrice)
        .toList(growable: false);
  }

  if (filter.hasWifi) {
    filtered = filtered.where((location) => location.hasWifi).toList(
      growable: false,
    );
  }

  if (filter.isPetFriendly) {
    filtered = filtered.where((location) => location.isPetFriendly).toList(
      growable: false,
    );
  }

  if (filter.hasParking) {
    filtered = filtered.where((location) => location.hasParking).toList(
      growable: false,
    );
  }

  return FilteredLocationsResult(
    visibleLocations: List.unmodifiable(filtered),
    rankingSnapshot: rankingSnapshot,
  );
}

class LocationFilterViewModel extends Notifier<LocationFilter> {
  @override
  LocationFilter build() => const LocationFilter();

  void setCategory(LocationCategory? cat) =>
      state = state.copyWith(selectedCategory: cat);

  void setRanking(LocationRanking? ranking) =>
      state = state.copyWith(selectedRanking: ranking);

  void setPrice(PriceRange? price) =>
      state = state.copyWith(selectedPrice: price);

  void setWifi(bool enabled) => state = state.copyWith(hasWifi: enabled);

  void setPetFriendly(bool enabled) =>
      state = state.copyWith(isPetFriendly: enabled);

  void setParking(bool enabled) => state = state.copyWith(hasParking: enabled);

  void clearFilters() => state = const LocationFilter();
}

final locationFilterProvider =
    NotifierProvider<LocationFilterViewModel, LocationFilter>(
      LocationFilterViewModel.new,
    );

class LocationsViewModel extends AsyncNotifier<List<Location>> {
  LocationPageCursor? _nextCursor;
  bool _hasMore = false;
  bool _isFetchingNextPage = false;
  int _offset = 0;

  bool get hasMore => _hasMore;

  @override
  Future<List<Location>> build() {
    final filter = ref.watch(locationFilterProvider);
    return _fetch(filter);
  }

  String _rankingRpcValue(LocationRanking ranking) => switch (ranking) {
    LocationRanking.trending => 'trending',
    LocationRanking.popular => 'popular',
    LocationRanking.lowkey => 'lowkey',
    LocationRanking.newest => 'new',
  };

  List<Location> _mapRpcRowsToLocations(dynamic response) {
    final remote = ref.read(locationRemoteDataSourceProvider);
    final rows = response is List<dynamic> ? response : const <dynamic>[];

    return rows
        .map(
          (row) => LocationModel.fromJson(
            remote.resolvePhotoUrls(
              Map<String, dynamic>.from(row as Map),
            ),
          ),
        )
        .cast<Location>()
        .toList(growable: false);
  }

  Future<List<Location>> _fetchRankedLocations(
    LocationFilter filter, {
    required int offset,
    int limit = 30,
  }) async {
    final ranking = filter.selectedRanking;
    if (ranking == null) return const <Location>[];

    final response = await Supabase.instance.client.rpc(
      SupabaseRPC.getTrendingLocations,
      params: {
        'ranking_filter': _rankingRpcValue(ranking),
        'category_filter': filter.selectedCategory?.name,
        'price_filter': filter.selectedPrice?.name,
        'now_open_only': false,
        'has_wifi_only': filter.hasWifi,
        'pet_friendly_only': filter.isPetFriendly,
        'has_parking_only': filter.hasParking,
        'limit_count': limit + 1,
        'offset_count': offset,
      },
    );

    final all = _mapRpcRowsToLocations(response);
    _hasMore = all.length > limit;
    _offset = offset + (_hasMore ? limit : all.length);
    return _hasMore ? all.take(limit).toList(growable: false) : all;
  }

  Future<List<Location>> _fetch(LocationFilter filter) async {
    _nextCursor = null;
    _hasMore = false;
    _offset = 0;

    final repository = ref.read(locationRepositoryProvider);
    if (filter.selectedRanking != null) {
      return _fetchRankedLocations(filter, offset: 0);
    }

    if (filter.selectedCategory != null) {
      final result = await repository.filterByCategory(
        filter.selectedCategory!,
      );
      return result.fold((f) => throw Exception(f.message), (l) => l);
    }

    final useCursor = ref.read(featureFlagsProvider).useCursorPagination;
    if (useCursor) {
      final result = await repository.getLocationsPage();
      return result.fold(
        (f) => throw Exception(f.message),
        (page) {
          _nextCursor = page.nextCursor;
          _hasMore = page.hasMore;
          return page.items;
        },
      );
    }

    final result = await repository.getAllLocations();
    return result.fold((f) => throw Exception(f.message), (l) => l);
  }

  Future<void> refresh() async {
    final filter = ref.read(locationFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filter));
  }

  /// Appends the next page of locations to the current list.
  /// No-op when already at the last page, cursor mode is off, or mid-fetch.
  Future<void> fetchNextPage() async {
    if (!_hasMore || _isFetchingNextPage) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _isFetchingNextPage = true;
    try {
      final filter = ref.read(locationFilterProvider);
      if (filter.selectedRanking != null) {
        final next = await _fetchRankedLocations(filter, offset: _offset);
        state = AsyncData([...current, ...next]);
        return;
      }

      if (_nextCursor == null) return;
      final repository = ref.read(locationRepositoryProvider);
      final result = await repository.getLocationsPage(cursor: _nextCursor);
      result.fold(
        (f) => null, // silently ignore; existing data stays visible
        (page) {
          _nextCursor = page.nextCursor;
          _hasMore = page.hasMore;
          state = AsyncData([...current, ...page.items]);
        },
      );
    } finally {
      _isFetchingNextPage = false;
    }
  }
}

final locationsProvider =
    AsyncNotifierProvider<LocationsViewModel, List<Location>>(
      LocationsViewModel.new,
    );

final locationDetailProvider = FutureProvider.autoDispose
    .family<Location, String>((ref, id) async {
      final result = await ref
          .read(locationRepositoryProvider)
          .getLocationById(id);
      return result.fold((f) => throw Exception(f.message), (l) => l);
    });

/// Holds a location that should be auto-opened when LocationScreen mounts.
/// Set before navigating to /location; cleared after consumed.
final pendingLocationProvider = StateProvider<Location?>((ref) => null);

/// When true, the location map/detail flow should offer adding a tapped place
/// into the comparison tray instead of behaving like a normal browse session.
final compareSelectionModeProvider = StateProvider<bool>((ref) => false);

/// IDs of locations that have above-average check-in activity in the last 7
/// days, sourced from the location_metrics_daily materialized view.
/// Returns an empty set when FEATURE_LOCATION_METRICS is off.
/// Kept alive for 15 minutes to match the pg_cron MV refresh cadence.
final trendingLocationIdsProvider = FutureProvider<Set<String>>((ref) async {
  final flags = ref.watch(featureFlagsProvider);
  if (!flags.useLocationMetrics) return const <String>{};

  // Keep alive and auto-invalidate every 15 min (matches pg_cron schedule).
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 15), () {
    link.close();
    ref.invalidateSelf();
  });

  final since = DateTime.now().toUtc().subtract(const Duration(days: 7));
  final client = Supabase.instance.client;

  final rows = await client
      .from('location_metrics_daily')
      .select('location_id, check_in_count')
      .gte('metric_date', since.toIso8601String().substring(0, 10));

  final totals = <String, int>{};
  for (final row in rows as List<dynamic>) {
    final id = row['location_id'] as String;
    final count = (row['check_in_count'] as num).toInt();
    totals[id] = (totals[id] ?? 0) + count;
  }

  return totals.entries
      .where((e) => e.value >= flags.trendingMinCheckIns)
      .map((e) => e.key)
      .toSet();
});

/// Streams a single location row from Supabase Realtime.
/// NOT autoDispose — keeps the WebSocket alive during navigation (e.g. when
/// the check-in page is pushed on top of the detail sheet) so the count
/// updates are received and reflected immediately on return.
final locationStreamProvider = StreamProvider.family<Location, String>((
  ref,
  locationId,
) {
  final client = Supabase.instance.client;
  final remote = ref.read(locationRemoteDataSourceProvider);

  return client
      .from(SupabaseTables.locations)
      .stream(primaryKey: ['id'])
      .eq('id', locationId)
      .map((rows) {
        if (rows.isEmpty) throw Exception('Location not found');
        return LocationModel.fromJson(remote.resolvePhotoUrls(rows.first));
      });
});
