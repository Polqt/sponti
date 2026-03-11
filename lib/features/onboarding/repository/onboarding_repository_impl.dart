import 'package:sponti/features/onboarding/repository/onboarding_local_data_source.dart';
import 'package:sponti/features/onboarding/repository/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this.localDataSource);

  final OnboardingLocalDataSource localDataSource;

  @override
  Future<bool> hasCompletedOnboarding() {
    return localDataSource.hasCompletedOnboarding();
  }

  @override
  Future<void> markOnboardingAsCompleted() {
    return localDataSource.markOnboardingAsCompleted();
  }

  @override
  Future<void> resetOnboarding() {
    return localDataSource.resetOnboarding();
  }
}
