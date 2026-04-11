import 'package:equatable/equatable.dart';

enum PlanStatus { voting, decided, cancelled }

enum PlanParticipationStatus { pending, accepted, declined }

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
    required this.status,
    this.invitedBy,
    this.respondedAt,
  });

  final String id;
  final String planId;
  final String userId;
  final DateTime joinedAt;
  final PlanParticipationStatus status;
  final String? invitedBy;
  final DateTime? respondedAt;

  bool get isPending => status == PlanParticipationStatus.pending;
  bool get isAccepted => status == PlanParticipationStatus.accepted;
  bool get isDeclined => status == PlanParticipationStatus.declined;

  @override
  List<Object?> get props => [
    id,
    planId,
    userId,
    joinedAt,
    status,
    invitedBy,
    respondedAt,
  ];
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

class PlanLocationSuggestion extends Equatable {
  const PlanLocationSuggestion({
    required this.id,
    required this.planId,
    required this.locationId,
    required this.suggestedBy,
    required this.suggestedAt,
  });

  final String id;
  final String planId;
  final String locationId;
  final String suggestedBy;
  final DateTime suggestedAt;

  @override
  List<Object?> get props => [
    id,
    planId,
    locationId,
    suggestedBy,
    suggestedAt,
  ];
}
