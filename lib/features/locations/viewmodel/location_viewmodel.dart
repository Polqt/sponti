import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/constants/api_constants.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/repository/location_local_data_source.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:sponti/features/locations/repository/location_repository.dart';
import 'package:sponti/features/locations/repository/location_repository_impl.dart';
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
    ref.watch(locationRemoteDataSourceProvider),
    ref.watch(locationLocalDataSourceProvider),
  );
});

class LocationFilter {
  const LocationFilter({
    this.selectedCategory,
    this.onlyOpenNow = false,
    this.onlyHiddenGems = false,
    this.onlyPetFriendly = false,
    this.onlyWithWifi = false,
    this.searchQuery = '',
  });

  final LocationCategory? selectedCategory;
  final bool onlyOpenNow;
  final bool onlyHiddenGems;
  final bool onlyPetFriendly;
  final bool onlyWithWifi;
  final String searchQuery;

  bool get hasActiveFilters =>
      selectedCategory != null ||
      onlyOpenNow ||
      onlyHiddenGems ||
      onlyPetFriendly ||
      onlyWithWifi ||
      searchQuery.isNotEmpty;

  LocationFilter copyWith({
    Object? selectedCategory = _sentinel,
    bool? onlyOpenNow,
    bool? onlyHiddenGems,
    bool? onlyPetFriendly,
    bool? onlyWithWifi,
    String? searchQuery,
  }) => LocationFilter(
    selectedCategory: selectedCategory == _sentinel
        ? this.selectedCategory
        : selectedCategory as LocationCategory?,
    onlyOpenNow: onlyOpenNow ?? this.onlyOpenNow,
    onlyHiddenGems: onlyHiddenGems ?? this.onlyHiddenGems,
    onlyPetFriendly: onlyPetFriendly ?? this.onlyPetFriendly,
    onlyWithWifi: onlyWithWifi ?? this.onlyWithWifi,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  static const _sentinel = Object();
}

class LocationFilterViewModel extends Notifier<LocationFilter> {
  @override
  LocationFilter build() => const LocationFilter();

  void toggleCategory(LocationCategory cat) => state = state.copyWith(
    selectedCategory: state.selectedCategory == cat ? null : cat,
  );

  void setCategory(LocationCategory? cat) =>
      state = state.copyWith(selectedCategory: cat);

  void toggleOpenNow() =>
      state = state.copyWith(onlyOpenNow: !state.onlyOpenNow);

  void toggleHiddenGems() =>
      state = state.copyWith(onlyHiddenGems: !state.onlyHiddenGems);

  void togglePetFriendly() =>
      state = state.copyWith(onlyPetFriendly: !state.onlyPetFriendly);

  void toggleWithWifi() =>
      state = state.copyWith(onlyWithWifi: !state.onlyWithWifi);

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void clearAll() => state = const LocationFilter();
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
    List<Location> locations;

    if (filter.selectedCategory != null) {
      final result = await repository.filterByCategory(
        filter.selectedCategory!,
      );
      locations = result.fold((f) => throw Exception(f.message), (l) => l);
    } else {
      final result = await repository.getAllLocations();
      locations = result.fold((f) => throw Exception(f.message), (l) => l);
    }

    return _applyClientFilters(locations, filter);
  }

  List<Location> _applyClientFilters(
    List<Location> locations,
    LocationFilter filter,
  ) {
    var list = locations;
    if (filter.onlyOpenNow) list = list.where((l) => l.isOpenNow).toList();
    if (filter.onlyHiddenGems) list = list.where((l) => l.isHiddenGem).toList();
    if (filter.onlyPetFriendly) {
      list = list.where((l) => l.isPetFriendly).toList();
    }
    if (filter.onlyWithWifi) list = list.where((l) => l.hasWifi).toList();
    return list;
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    await _reload();
  }

  Future<void> onFilterChanged() async {
    await _reload();
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

class NearbyParams {
  const NearbyParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5,
  }) : assert(latitude >= -90 && latitude <= 90),
       assert(longitude >= -180 && longitude <= 180),
       assert(radiusKm > 0);

  final double latitude;
  final double longitude;
  final double radiusKm;
}

final nearbyLocationsProvider = FutureProvider.autoDispose
    .family<List<Location>, NearbyParams>((ref, params) async {
      final result = await ref
          .read(locationRepositoryProvider)
          .getNearbyLocations(
            latitude: params.latitude,
            longitude: params.longitude,
            radiusKm: params.radiusKm,
          );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (locations) => locations,
      );
    });

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Location>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final result = await ref
      .read(locationRepositoryProvider)
      .searchLocations(query);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (locations) => locations,
  );
});

class CreateLocationViewModel
    extends AutoDisposeFamilyAsyncNotifier<Location?, Location> {
  @override
  Future<Location?> build(Location arg) async => null;

  Future<bool> create(Location location) async {
    state = const AsyncLoading();
    final result = await ref
        .read(locationRepositoryProvider)
        .createLocation(location);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (created) {
        state = AsyncData(created);
        ref.invalidate(locationsProvider);
        return true;
      },
    );
  }
}

final createLocationProvider = AsyncNotifierProvider.autoDispose
    .family<CreateLocationViewModel, Location?, Location>(
      CreateLocationViewModel.new,
    );

class UpdateLocationViewModel
    extends AutoDisposeFamilyAsyncNotifier<Location?, Location> {
  @override
  Future<Location?> build(Location arg) async => null;

  Future<bool> updateLocation(Location location) async {
    state = const AsyncLoading();
    final result = await ref
        .read(locationRepositoryProvider)
        .updateLocation(location);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (updated) {
        state = AsyncData(updated);
        ref.invalidate(locationsProvider);
        ref.invalidate(locationDetailProvider(location.id));
        return true;
      },
    );
  }
}

final updateLocationProvider = AsyncNotifierProvider.autoDispose
    .family<UpdateLocationViewModel, Location?, Location>(
      UpdateLocationViewModel.new,
    );

class DeleteLocationViewModel extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await ref
        .read(locationRepositoryProvider)
        .deleteLocation(id);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(true);
        ref.invalidate(locationsProvider);
        return true;
      },
    );
  }
}

final deleteLocationProvider =
    AsyncNotifierProvider.autoDispose<DeleteLocationViewModel, bool>(
      DeleteLocationViewModel.new,
    );

class SurpriseMeNotifier extends AsyncNotifier<Location?> {
  @override
  Future<Location?> build() async => null;

  Future<void> pickRandom(List<String> categories) async {
    state = const AsyncLoading();
    final repo = ref.read(locationRepositoryProvider);
    final result = categories.isEmpty
        ? await repo.getAllLocations()
        : await repo.fetchByCategories(categories);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (locations) {
        if (locations.isEmpty) {
          return AsyncError('no spots found for those categories', StackTrace.current);
        }
        final random = Random();
        return AsyncData(locations[random.nextInt(locations.length)]);
      },
    );
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final surpriseMeProvider =
    AsyncNotifierProvider<SurpriseMeNotifier, Location?>(
      SurpriseMeNotifier.new,
    );

/// Streams a single location row from Supabase Realtime.
/// NOT autoDispose — keeps the WebSocket alive during navigation (e.g. when
/// the check-in page is pushed on top of the detail sheet) so the count
/// updates are received and reflected immediately on return.
final locationStreamProvider =
    StreamProvider.family<Location, String>((ref, locationId) {
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
