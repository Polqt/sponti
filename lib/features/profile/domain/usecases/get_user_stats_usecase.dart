import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/profile/domain/entities/user_profile.dart';
import 'package:sponti/features/profile/domain/repositories/profile_repository.dart';

@lazySingleton
class GetUserStatsUseCase implements UseCase<UserStats, String> {
  const GetUserStatsUseCase(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserStats>> call(String userId) =>
      _repository.getUserStats(userId);
}
