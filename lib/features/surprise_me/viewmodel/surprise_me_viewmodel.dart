import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

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
