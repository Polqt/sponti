import 'package:sponti/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:sponti/features/onboarding/data/datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDatasource localDatasource;

  OnboardingRepositoryImpl({required this.localDatasource});

  @override
  Future<bool> hasCompletedOnboarding() {
    return localDatasource.hasCompletedOnboarding();
  }

  @override
  Future<void> markOnboardingAsCompleted() {
    return localDatasource.markOnboardingAsCompleted();
  }

  @override
  Future<void> resetOnboarding() {
    return localDatasource.resetOnboarding();
  }
}
