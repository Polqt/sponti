import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/suggestions/repository/suggestions_remote_data_source.dart';
import 'package:sponti/features/suggestions/repository/suggestions_repository_impl.dart';
import 'package:sponti/features/suggestions/model/suggestion_model.dart';
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

  Future<void> submit(SuggestionModel suggestion) async {
    state = const AsyncLoading();
    final result = await ref
        .read(suggestionsRepositoryProvider)
        .insertSuggestion(suggestion);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) {
        ref.invalidate(mySuggestionsProvider);
        return const AsyncData(null);
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
