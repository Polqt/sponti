import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/onboarding/repository/onboarding_local_data_source.dart';
import 'package:sponti/features/onboarding/repository/onboarding_repository.dart';
import 'package:sponti/features/onboarding/repository/onboarding_repository_impl.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return OnboardingLocalDataSourceImpl();
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

class OnboardingViewModel extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(onboardingRepositoryProvider).hasCompletedOnboarding();
  }

  Future<void> markCompleted() async {
    await ref.read(onboardingRepositoryProvider).markOnboardingAsCompleted();
    state = const AsyncData(true);
  }

  Future<void> reset() async {
    await ref.read(onboardingRepositoryProvider).resetOnboarding();
    state = const AsyncData(false);
  }
}

final onboardingViewModelProvider =
    AsyncNotifierProvider<OnboardingViewModel, bool>(
      OnboardingViewModel.new,
    );

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  return ref.watch(onboardingViewModelProvider.future);
});
