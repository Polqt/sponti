import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';

abstract interface class GroupPlansRepository {
  Future<Either<Failure, GroupPlan>> createGroupPlan({
    required String name,
    required String description,
  });

  Future<Either<Failure, GroupPlan>> getGroupPlan(String planId);

  Future<Either<Failure, List<GroupPlan>>> getUserGroupPlans();

  Future<Either<Failure, void>> addParticipant({
    required String planId,
    required String userId,
  });

  Future<Either<Failure, List<PlanParticipant>>> getPlanParticipants(
    String planId,
  );

  Future<Either<Failure, void>> respondToInvite({
    required String planId,
    required PlanParticipationStatus status,
  });

  Future<Either<Failure, List<PlanLocationSuggestion>>> getPlanSuggestions(
    String planId,
  );

  Future<Either<Failure, void>> vote({
    required String planId,
    required String locationId,
  });

  Future<Either<Failure, List<PlanVote>>> getPlanVotes(String planId);

  Future<Either<Failure, void>> decidePlan({
    required String planId,
    required String winningLocationId,
  });

  Future<Either<Failure, void>> cancelPlan(String planId);
}
