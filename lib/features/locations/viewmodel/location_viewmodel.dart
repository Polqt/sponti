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
  });

  final LocationCategory? selectedCategory;

  LocationFilter copyWith({
    Object? selectedCategory = _sentinel,
  }) => LocationFilter(
    selectedCategory: selectedCategory == _sentinel
        ? this.selectedCategory
        : selectedCategory as LocationCategory?,
  );

  static const _sentinel = Object();
}

class LocationFilterViewModel extends Notifier<LocationFilter> {
  @override
  LocationFilter build() => const LocationFilter();

  void setCategory(LocationCategory? cat) =>
      state = state.copyWith(selectedCategory: cat);
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

class SurpriseMeNotifier extends AutoDisposeAsyncNotifier<Location?> {
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
          return AsyncError(
            'No spots found for those categories.',
            StackTrace.current,
          );
        }
        final random = Random();
        return AsyncData(locations[random.nextInt(locations.length)]);
      },
    );
  }
}

final surpriseMeProvider =
    AsyncNotifierProvider.autoDispose<SurpriseMeNotifier, Location?>(
      SurpriseMeNotifier.new,
    );

/// Holds a location that should be auto-opened when LocationScreen mounts.
/// Set before navigating to /location; cleared after consumed.
final pendingLocationProvider = StateProvider<Location?>((ref) => null);

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
