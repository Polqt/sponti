import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/coordinates_model.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/utils/location_explore_cache.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/suggestions/model/suggestion_model.dart';
import 'package:sponti/features/suggestions/repository/suggestions_remote_data_source.dart';
import 'package:sponti/features/suggestions/repository/suggestions_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// DI chain

final suggestionsDataSourceProvider = Provider<SuggestionsRemoteDataSource>((
  ref,
) {
  return SuggestionsRemoteDataSourceImpl(Supabase.instance.client);
});

final suggestionsRepositoryProvider = Provider<SuggestionsRepository>((ref) {
  return SuggestionsRepositoryImpl(ref.read(suggestionsDataSourceProvider));
});

// Read — my suggestions list
// Kept alive for 10 minutes then auto-invalidated so navigating back after
// a long gap re-fetches rather than showing stale data.

final mySuggestionsProvider = FutureProvider<List<SuggestionModel>>((
  ref,
) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 10), () {
    link.close();
    ref.invalidateSelf();
  });

  final repository = ref.read(suggestionsRepositoryProvider);
  final result = await repository.fetchMySuggestions();
  return result.fold((failure) => throw StateError(failure.message), (data) => data);
});

// Read — single suggestion by id

final suggestionByIdProvider = FutureProvider.family<SuggestionModel, String>((
  ref,
  id,
) async {
  final repository = ref.read(suggestionsRepositoryProvider);
  final result = await repository.fetchSuggestionById(id);
  return result.fold((failure) => throw StateError(failure.message), (data) => data);
});

// Mutation — insert

class SubmitSuggestionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Creates a [locations] row (map pin) then a linked [suggestions] row.
  Future<void> submit(SuggestionModel suggestion) async {
    state = const AsyncLoading();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = AsyncError('You must be logged in.', StackTrace.current);
      return;
    }
    if (suggestion.latitude == null || suggestion.longitude == null) {
      state = AsyncError(
        'Drop a map pin so the spot can appear on the map.',
        StackTrace.current,
      );
      return;
    }

    final now = DateTime.now();
    final locationEntity = Location(
      id: '',
      name: suggestion.name.trim(),
      description: (suggestion.description ?? '').trim(),
      category: LocationCategory.fromString(suggestion.category),
      coordinates: CoordinatesModel(
        latitude: suggestion.latitude!,
        longitude: suggestion.longitude!,
      ),
      address: suggestion.address.trim(),
      priceRange: PriceRange.budget,
      photoUrls: const [],
      createdAt: now,
      submittedBy: user.id,
      isSeeded: true,
      seededAt: now,
    );
    final locationModel = LocationModel.fromEntity(locationEntity);

    final locationRepo = ref.read(locationRepositoryProvider);
    final createdEither = await locationRepo.createLocation(locationModel);

    await createdEither.fold<Future<void>>(
      (failure) async {
        state = AsyncError(failure.message, StackTrace.current);
      },
      (created) async {
        final suggestionRow = suggestion.copyWith(
          locationId: created.id,
          status: 'approved',
        );
        final insertResult = await ref
            .read(suggestionsRepositoryProvider)
            .insertSuggestion(suggestionRow);
        await insertResult.fold<Future<void>>(
          (failure) async {
            await locationRepo.deleteLocation(created.id);
            state = AsyncError(failure.message, StackTrace.current);
          },
          (_) async {
            invalidateLocationExploreRankingCaches(ref.invalidate);
            ref.invalidate(mySuggestionsProvider);
            state = const AsyncData(null);
          },
        );
      },
    );
  }
}

final submitSuggestionProvider =
    AsyncNotifierProvider<SubmitSuggestionNotifier, void>(
      SubmitSuggestionNotifier.new,
    );

// Mutation — update

class UpdateSuggestionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> edit(SuggestionModel suggestion) async {
    state = const AsyncLoading();
    final result = await ref
        .read(suggestionsRepositoryProvider)
        .updateSuggestion(suggestion);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) {
        ref.invalidate(mySuggestionsProvider);
        ref.invalidate(suggestionByIdProvider(suggestion.id));
        return const AsyncData(null);
      },
    );
  }
}

final updateSuggestionProvider =
    AsyncNotifierProvider<UpdateSuggestionNotifier, void>(
      UpdateSuggestionNotifier.new,
    );

// Mutation — delete

class DeleteSuggestionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    final result = await ref
        .read(suggestionsRepositoryProvider)
        .deleteSuggestion(id);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) {
        ref.invalidate(mySuggestionsProvider);
        return const AsyncData(null);
      },
    );
  }
}

final deleteSuggestionProvider =
    AsyncNotifierProvider<DeleteSuggestionNotifier, void>(
      DeleteSuggestionNotifier.new,
    );
