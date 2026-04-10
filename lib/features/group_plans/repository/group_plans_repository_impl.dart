import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/repository/group_plans_remote_data_source.dart';
import 'package:sponti/features/group_plans/repository/group_plans_repository.dart';

class GroupPlansRepositoryImpl extends BaseRepository
    implements GroupPlansRepository {
  const GroupPlansRepositoryImpl(this._remote);

  final GroupPlansRemoteDataSource _remote;

  @override
  Future<Either<Failure, GroupPlan>> createGroupPlan({
    required String name,
    required String description,
  }) => guard(
    () => _remote.createGroupPlan(name: name, description: description),
  );

  @override
  Future<Either<Failure, GroupPlan>> getGroupPlan(String planId) =>
      guard(() => _remote.getGroupPlan(planId));

  @override
  Future<Either<Failure, List<GroupPlan>>> getUserGroupPlans() =>
      guard(_remote.getUserGroupPlans);

  @override
  Future<Either<Failure, void>> addParticipant({
    required String planId,
    required String userId,
  }) => guard(() => _remote.addParticipant(planId: planId, userId: userId));

  @override
  Future<Either<Failure, List<PlanParticipant>>> getPlanParticipants(
    String planId,
  ) => guard(() => _remote.getPlanParticipants(planId));

  @override
  Future<Either<Failure, void>> vote({
    required String planId,
    required String locationId,
  }) => guard(() => _remote.vote(planId: planId, locationId: locationId));

  @override
  Future<Either<Failure, List<PlanVote>>> getPlanVotes(String planId) =>
      guard(() => _remote.getPlanVotes(planId));

  @override
  Future<Either<Failure, void>> decidePlan({
    required String planId,
    required String winningLocationId,
  }) => guard(
    () => _remote.decidePlan(
      planId: planId,
      winningLocationId: winningLocationId,
    ),
  );

  @override
  Future<Either<Failure, void>> cancelPlan(String planId) =>
      guard(() => _remote.cancelPlan(planId));
}
