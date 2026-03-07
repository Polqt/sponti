import 'package:sponti/features/onboarding/domain/repositories/onboarding_repository.dart';

class CheckOnboardingUseCase {
  final OnboardingRepository repository;

  CheckOnboardingUseCase({required this.repository});

  Future<bool> call() {
    return repository.hasCompletedOnboarding();
  }
}
