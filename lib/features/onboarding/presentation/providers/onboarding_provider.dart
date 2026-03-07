import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:sponti/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:sponti/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:sponti/features/onboarding/domain/usecases/check_onboarding_usecase.dart';
import 'package:sponti/features/onboarding/domain/usecases/mark_onboarding_completed_usecase.dart';

final onboardingLocalDatasourceProvider = Provider<OnboardingLocalDatasource>((ref) {
  return OnboardingLocalDatasourceImpl();
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final datasource = ref.watch(onboardingLocalDatasourceProvider);
  return OnboardingRepositoryImpl(localDatasource: datasource);
});

final checkOnboardingUseCaseProvider = Provider<CheckOnboardingUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return CheckOnboardingUseCase(repository: repository);
});

final markOnboardingCompletedUseCaseProvider = Provider<MarkOnboardingCompletedUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return MarkOnboardingCompletedUseCase(repository: repository);
});

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final useCase = ref.watch(checkOnboardingUseCaseProvider);
  return useCase.call();
});
