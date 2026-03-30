import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<Location>>((ref) async {
      final query = ref.watch(searchQueryProvider).trim();

      if (query.length < 2) {
        return const <Location>[];
      }

      final result = await ref
          .read(locationRepositoryProvider)
          .searchLocations(query);
      return result.fold(
        (failure) => throw StateError(failure.message),
        (locations) => locations,
      );
    });
