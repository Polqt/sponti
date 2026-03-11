abstract class OnboardingRepository {
  Future<bool> hasCompletedOnboarding();
  Future<void> markOnboardingAsCompleted();
  Future<void> resetOnboarding();
}
