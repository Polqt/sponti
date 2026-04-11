import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/location_comparison/repository/location_comparison_local_data_source.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

const int kLocationComparisonMaxPins = 3;
const int kLocationComparisonMinPins = 2;

final locationComparisonLocalDataSourceProvider =
    Provider<LocationComparisonLocalDataSource>((ref) {
      return const LocationComparisonLocalDataSourceImpl();
    });

class LocationComparisonViewModel extends AsyncNotifier<List<String>> {
  LocationComparisonLocalDataSource get _local =>
      ref.read(locationComparisonLocalDataSourceProvider);

  @override
  Future<List<String>> build() => _local.getPinnedIds();

  Future<bool> togglePin(String locationId) async {
    final current = [...await future];
    final isPinned = current.contains(locationId);
    if (isPinned) {
      await unpin(locationId);
      return true;
    }

    return pin(locationId);
  }

  Future<bool> pin(String locationId) async {
    final current = [...await future];
    if (current.contains(locationId)) return true;
    if (current.length >= kLocationComparisonMaxPins) return false;

    final updated = [...current, locationId];
    state = AsyncData(updated);
    await _local.savePinnedIds(updated);
    return true;
  }

  Future<void> unpin(String locationId) async {
    final current = [...await future];
    final updated = current
        .where((id) => id != locationId)
        .toList(growable: false);
    state = AsyncData(updated);
    await _local.savePinnedIds(updated);
  }

  Future<void> clear() async {
    state = const AsyncData(<String>[]);
    await _local.savePinnedIds(const <String>[]);
  }
}

final pinnedComparisonIdsProvider =
    AsyncNotifierProvider<LocationComparisonViewModel, List<String>>(
      LocationComparisonViewModel.new,
    );

final pinnedComparisonIdSetProvider = Provider<Set<String>>((ref) {
  final ids = ref.watch(pinnedComparisonIdsProvider).valueOrNull ?? const <String>[];
  return ids.toSet();
});

final pinnedComparisonLocationsProvider = FutureProvider<List<Location>>((
  ref,
) async {
  final pinnedIds =
      ref.watch(pinnedComparisonIdsProvider).valueOrNull ?? const <String>[];
  if (pinnedIds.isEmpty) return const <Location>[];

  final repository = ref.read(locationRepositoryProvider);
  final results = await Future.wait(
    pinnedIds.map((id) => repository.getLocationById(id)),
  );
  return results
      .where((r) => r.isRight())
      .map((r) => r.getOrElse(() => throw StateError('unreachable')))
      .toList(growable: false);
});
