import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/constants/api_constants.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/repository/location_local_data_source.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:sponti/features/locations/repository/location_repository.dart';
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
  @override
  Future<List<Location>> build() => _fetch();

  Future<List<Location>> _fetch() async {
    final filter = ref.read(locationFilterProvider);
    final repository = ref.read(locationRepositoryProvider);
    if (filter.selectedCategory != null) {
      final result = await repository.filterByCategory(
        filter.selectedCategory!,
      );
      return result.fold((f) => throw Exception(f.message), (l) => l);
    }

    final result = await repository.getAllLocations();
    return result.fold((f) => throw Exception(f.message), (l) => l);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
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
      .from(ApiConstants.locationsTable)
      .stream(primaryKey: ['id'])
      .eq('id', locationId)
      .map((rows) {
        if (rows.isEmpty) throw Exception('Location not found');
        return LocationModel.fromJson(remote.resolvePhotoUrls(rows.first));
      });
});
