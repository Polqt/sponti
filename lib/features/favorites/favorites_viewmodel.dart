import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/favorites/favorites_remote_data_source.dart';
import 'package:sponti/features/favorites/favorites_repository.dart';
import 'package:sponti/features/favorites/favorites_repository_impl.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final updated = [...current];

    if (isSaved) {
      updated.remove(locationId);
    } else {
      updated.insert(0, locationId);
    }

    state = AsyncData(updated);

    final result = isSaved
        ? await _repository.removeFavorite(locationId)
        : await _repository.addFavorite(locationId);

    result.fold(
      (failure) => state = AsyncError(
        StateError(failure.message),
        StackTrace.current,
      ),
      (_) {
        ref.invalidate(favoriteLocationsProvider);
        ref.invalidate(profileProvider);
      },
    );

    if (result.isLeft()) {
      state = AsyncData(current);
    }
  }

  Future<void> remove(String locationId) async {
    final current = [...await future];
    final updated = [...current]..remove(locationId);
    state = AsyncData(updated);

    final result = await _repository.removeFavorite(locationId);
    result.fold(
      (failure) => state = AsyncError(
        StateError(failure.message),
        StackTrace.current,
      ),
      (_) {
        ref.invalidate(favoriteLocationsProvider);
        ref.invalidate(profileProvider);
      },
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

    ref.invalidate(favoriteLocationsProvider);
    ref.invalidate(profileProvider);
  }
}

final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>((
  ref,
) {
  return FavoritesRemoteDataSourceImpl(Supabase.instance.client);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(favoritesRemoteDataSourceProvider));
});

final favoriteIdsProvider =
    AsyncNotifierProvider<FavoritesViewModel, List<String>>(
      FavoritesViewModel.new,
    );

final favoriteIdSetProvider = Provider<Set<String>>((ref) {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>[];
  return ids.toSet();
});

final favoriteLocationsProvider = FutureProvider<List<Location>>((ref) async {
  final result = await ref.read(favoritesRepositoryProvider).getFavoriteLocations();
  return result.fold((failure) {
    throw StateError(failure.message);
  }, (locations) => locations);
});

final favoritesSearchQueryProvider = StateProvider<String>((ref) => '');
