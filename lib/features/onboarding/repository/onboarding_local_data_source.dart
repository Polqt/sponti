import 'package:hive_flutter/hive_flutter.dart';
import 'package:sponti/core/constants/app_constants.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> hasCompletedOnboarding();
  Future<void> markOnboardingAsCompleted();
  Future<void> resetOnboarding();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(AppConstants.hiveBoxUserPrefs)) {
      return Hive.box(AppConstants.hiveBoxUserPrefs);
    }
    return Hive.openBox(AppConstants.hiveBoxUserPrefs);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final box = await _getBox();
    return box.get(AppConstants.hiveKeyOnboardingDone, defaultValue: false)
        as bool;
  }

  @override
  Future<void> markOnboardingAsCompleted() async {
    final box = await _getBox();
    await box.put(AppConstants.hiveKeyOnboardingDone, true);
  }

  @override
  Future<void> resetOnboarding() async {
    final box = await _getBox();
    await box.put(AppConstants.hiveKeyOnboardingDone, false);
  }
}
