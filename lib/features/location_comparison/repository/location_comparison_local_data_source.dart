import 'package:hive_flutter/hive_flutter.dart';
import 'package:sponti/core/constants/app_constants.dart';

abstract interface class LocationComparisonLocalDataSource {
  Future<List<String>> getPinnedIds();
  Future<void> savePinnedIds(List<String> ids);
}

class LocationComparisonLocalDataSourceImpl
    implements LocationComparisonLocalDataSource {
  const LocationComparisonLocalDataSourceImpl();

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(AppConstants.hiveBoxUserPrefs)) {
      return Hive.box(AppConstants.hiveBoxUserPrefs);
    }
    return Hive.openBox(AppConstants.hiveBoxUserPrefs);
  }

  @override
  Future<List<String>> getPinnedIds() async {
    final box = await _getBox();
    final raw = box.get(
      AppConstants.hiveKeyComparisonPinnedIds,
      defaultValue: const <dynamic>[],
    );
    if (raw is! List) return const <String>[];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  @override
  Future<void> savePinnedIds(List<String> ids) async {
    final box = await _getBox();
    await box.put(AppConstants.hiveKeyComparisonPinnedIds, ids);
  }
}
