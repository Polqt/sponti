import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/suggestions/data/suggestions_repository.dart';
import 'package:sponti/features/suggestions/domain/suggestion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final suggestionsRepositoryProvider = Provider<SuggestionsRepository>((ref) {
  return SuggestionsRepository(Supabase.instance.client);
});

class SubmitSuggestionNotifier extends AsyncNotifier<void> {
  SuggestionsRepository get _repository =>
      ref.read(suggestionsRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<void> submit(SuggestionModel suggestion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.submitSuggestion(suggestion);
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final submitSuggestionProvider =
    AsyncNotifierProvider<SubmitSuggestionNotifier, void>(
      SubmitSuggestionNotifier.new,
    );
