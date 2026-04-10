import 'package:equatable/equatable.dart';

enum PlanStatus { voting, decided, cancelled }

class GroupPlan extends Equatable {
  const GroupPlan({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.winningLocationId,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String createdBy;
  final PlanStatus status;
  final String? winningLocationId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    createdBy,
    status,
    winningLocationId,
    createdAt,
    updatedAt,
  ];
}

class PlanParticipant extends Equatable {
  const PlanParticipant({
    required this.id,
    required this.planId,
    required this.userId,
    required this.joinedAt,
  });

  final String id;
  final String planId;
  final String userId;
  final DateTime joinedAt;

  @override
  List<Object?> get props => [id, planId, userId, joinedAt];
}

class PlanVote extends Equatable {
  const PlanVote({
    required this.id,
    required this.planId,
    required this.userId,
    required this.locationId,
    required this.votedAt,
  });

  final String id;
  final String planId;
  final String userId;
  final String locationId;
  final DateTime votedAt;

  @override
  List<Object?> get props => [id, planId, userId, locationId, votedAt];
}
