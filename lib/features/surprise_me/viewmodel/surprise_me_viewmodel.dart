import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class SurpriseMeNotifier extends AsyncNotifier<LocationModel?> {
  @override
  Future<LocationModel?> build() async => null;

  Future<void> pickRandom(List<String> categories) async {
    state = const AsyncLoading();

    final repo = ref.read(locationRepositoryProvider);
    final result = await repo.getAllLocations();

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (locations) {
        final normalized = categories
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet();

        final filtered = normalized.isEmpty
            ? locations
            : locations
                  .where(
                    (location) => normalized.contains(
                      location.category.name.toLowerCase(),
                    ),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return AsyncError(
            'no spots found for those categories',
            StackTrace.current,
          );
        }

        final random = Random();
        final picked = filtered[random.nextInt(filtered.length)];
        final model = picked is LocationModel
            ? picked
            : LocationModel.fromEntity(picked);

        return AsyncData(model);
      },
    );
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final surpriseMeProvider =
    AsyncNotifierProvider<SurpriseMeNotifier, LocationModel?>(
      SurpriseMeNotifier.new,
    );
