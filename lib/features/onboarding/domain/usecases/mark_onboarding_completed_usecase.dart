import 'package:sponti/features/onboarding/domain/repositories/onboarding_repository.dart';

class MarkOnboardingCompletedUseCase {
  final OnboardingRepository repository;

  MarkOnboardingCompletedUseCase({required this.repository});

  Future<void> call() {
    return repository.markOnboardingAsCompleted();
  }
}
