import 'package:hive_flutter/hive_flutter.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> hasCompletedOnboarding();
  Future<void> markOnboardingAsCompleted();
  Future<void> resetOnboarding();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static const String _boxName = 'onboarding_box';
  static const String _completedKey = 'onboarding_completed';

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final box = await _getBox();
    return box.get(_completedKey, defaultValue: false) as bool;
  }

  @override
  Future<void> markOnboardingAsCompleted() async {
    final box = await _getBox();
    await box.put(_completedKey, true);
  }

  @override
  Future<void> resetOnboarding() async {
    final box = await _getBox();
    await box.put(_completedKey, false);
  }
}
