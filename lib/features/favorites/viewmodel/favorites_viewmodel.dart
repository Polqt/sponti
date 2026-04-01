import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/favorites/model/favorite.dart';
import 'package:sponti/features/favorites/repository/favorites_remote_data_source.dart';
import 'package:sponti/features/favorites/repository/favorites_repository.dart';
import 'package:sponti/features/favorites/repository/favorites_repository_impl.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>((
  ref,
) {
  return FavoritesRemoteDataSourceImpl(Supabase.instance.client);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(favoritesRemoteDataSourceProvider));
});

class FavoritesViewModel extends AsyncNotifier<List<String>> {
  FavoritesRepository get _repository => ref.read(favoritesRepositoryProvider);

  @override
  Future<List<String>> build() async {
    final result = await _repository.getFavoriteLocationIds();
    return result.fold((failure) {
      throw StateError(failure.message);
    }, (ids) => ids);
  }

  Future<void> toggle(String locationId) async {
    final current = [...await future];
    final isSaved = current.contains(locationId);

    final updated = isSaved
        ? (current..remove(locationId))
        : ([locationId, ...current]);

    state = AsyncData(updated);

    final result = isSaved
        ? await _repository.removeFavorite(locationId)
        : await _repository.addFavorite(locationId);

    result.fold(
      (failure) =>
          state = AsyncError(StateError(failure.message), StackTrace.current),
      (_) => _invalidateDependentProviders(),
    );

    if (result.isLeft()) {
      state = AsyncData(current);
    }
  }

  Future<void> remove(String locationId) => _updateFavorite(
    locationId: locationId,
    updater: (current) => current..remove(locationId),
    operation: () => _repository.removeFavorite(locationId),
  );

  Future<void> _updateFavorite({
    required String locationId,
    required List<String> Function(List<String>) updater,
    required Future<Either<Failure, void>> Function() operation,
  }) async {
    final current = [...await future];
    final updated = updater([...current]);
    state = AsyncData(updated);

    final result = await operation();
    result.fold(
      (failure) =>
          state = AsyncError(StateError(failure.message), StackTrace.current),
      (_) => _invalidateDependentProviders(),
    );

    if (result.isLeft()) {
      state = AsyncData(current);
    }
  }

  Future<void> clear() async {
    final current = [...await future];
    state = const AsyncData(<String>[]);

    for (final locationId in current) {
      final result = await _repository.removeFavorite(locationId);
      if (result.isLeft()) {
        state = AsyncData(current);
        return;
      }
    }

    _invalidateDependentProviders();
  }

  void _invalidateDependentProviders() {
    ref.invalidate(favoritesProvider);
    ref.invalidate(favoriteLocationsProvider);
    // Invalidate stats only - profile data hasn't changed, just the counts
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      ref.invalidate(userStatsProvider(userId));
    }
  }
}

final favoriteIdsProvider =
    AsyncNotifierProvider<FavoritesViewModel, List<String>>(
      FavoritesViewModel.new,
    );

final favoriteIdSetProvider = Provider<Set<String>>((ref) {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>[];
  return ids.toSet();
});

final favoritesProvider = FutureProvider<List<Favorite>>((ref) async {
  final result = await ref.read(favoritesRepositoryProvider).getFavorites();
  return result.fold((failure) {
    throw StateError(failure.message);
  }, (favorites) => favorites);
});

final favoriteLocationsProvider = FutureProvider<List<Location>>((ref) async {
  final result = await ref
      .read(favoritesRepositoryProvider)
      .getFavoriteLocations();
  return result.fold((failure) {
    throw StateError(failure.message);
  }, (locations) => locations);
});

final favoritesSearchQueryProvider = StateProvider<String>((ref) => '');
final favoritesCategoryFilterProvider = StateProvider<LocationCategory?>(
  (ref) => null,
);
