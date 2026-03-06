import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/dependency_injection.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/usecases/create_location_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/delete_location_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/filter_by_category_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/get_all_locations_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/get_location_by_id_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/get_nearby_locations_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/search_locations_usecase.dart';
import 'package:sponti/features/locations/domain/usecases/update_location_usecase.dart';

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

class LocationFilterNotifier extends Notifier<LocationFilter> {
  @override
  LocationFilter build() => const LocationFilter();

  void toggleCategory(LocationCategory cat) => state = state.copyWith(
    selectedCategory: state.selectedCategory == cat ? null : cat,
  );

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
    NotifierProvider<LocationFilterNotifier, LocationFilter>(
      LocationFilterNotifier.new,
    );

// All Location List State
class LocationsNotifier extends AsyncNotifier<List<Location>> {
  @override
  Future<List<Location>> build() => _fetch();

  Future<List<Location>> _fetch() async {
    final filter = ref.read(locationFilterProvider);
    List<Location> locations;

    // If a category is selected, use the category use case; else fetch all
    if (filter.selectedCategory != null) {
      final result = await getIt<FilterByCategoryUseCase>()(
        filter.selectedCategory!,
      );
      locations = result.fold((f) => throw Exception(f.message), (l) => l);
    } else {
      final result = await getIt<GetAllLocationsUseCase>()(
        const GetAllLocationsParams(),
      );
      locations = result.fold((f) => throw Exception(f.message), (l) => l);
    }

    // Client-side filtering based on other criteria
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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // Listen to filter changes and refresh locations
  void onFilterChanged() {
    state = const AsyncLoading();
    AsyncValue.guard(_fetch).then((value) => state = value);
  }
}

// Provider for the list of locations, which listens to filter changes
final locationsProvider =
    AsyncNotifierProvider<LocationsNotifier, List<Location>>(
      LocationsNotifier.new,
    );

// Location Detail
final locationDetailProvider = FutureProvider.autoDispose
    .family<Location, String>((ref, id) async {
      final result = await getIt<GetLocationByIdUseCase>()(id);
      return result.fold((f) => throw Exception(f.message), (l) => l);
    });

// Nearby Locations
class NearbyParams {
  const NearbyParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5,
  });
  final double latitude;
  final double longitude;
  final double radiusKm;
}

final nearbyLocationsProvider = FutureProvider.autoDispose
    .family<List<Location>, NearbyParams>((ref, params) async {
      final result = await getIt<GetNearbyLocationsUseCase>()(
        GetNearbyLocationsParams(
          latitude: params.latitude,
          longitude: params.longitude,
          radiusKm: params.radiusKm,
        ),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (locations) => locations,
      );
    });

// Search
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Location>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final result = await getIt<SearchLocationsUseCase>()(query);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (locations) => locations,
  );
});

// Mutation - Create Location
class CreateLocationNotifier
    extends AutoDisposeFamilyAsyncNotifier<Location?, Location> {
  @override
  Future<Location?> build(Location arg) async => null;

  Future<bool> create(Location location) async {
    state = const AsyncLoading();
    final result = await getIt<CreateLocationUseCase>()(location);
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
    .family<CreateLocationNotifier, Location?, Location>(
      CreateLocationNotifier.new,
    );

// Mutation - Update Location
class UpdateLocationNotifier
    extends AutoDisposeFamilyAsyncNotifier<Location?, Location> {
  @override
  Future<Location?> build(Location arg) async => null;

  Future<bool> updateLocation(Location location) async {
    state = const AsyncLoading();
    final result = await getIt<UpdateLocationUseCase>()(location);
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
    .family<UpdateLocationNotifier, Location?, Location>(
      UpdateLocationNotifier.new,
    );

// Mutation - Delete Location
class DeleteLocationNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await getIt<DeleteLocationUseCase>()(id);
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
    AsyncNotifierProvider.autoDispose<DeleteLocationNotifier, bool>(
      DeleteLocationNotifier.new,
    );
