import 'package:sponti/features/group_plans/models/group_plan.dart';

class GroupPlanModel extends GroupPlan {
  const GroupPlanModel({
    required super.id,
    required super.name,
    required super.createdBy,
    required super.status,
    required super.createdAt,
    super.description,
    super.winningLocationId,
    super.updatedAt,
  });

  factory GroupPlanModel.fromJson(Map<String, dynamic> json) {
    return GroupPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String,
      status: _parseStatus(json['status'] as String?),
      winningLocationId: json['winning_location_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'name': name,
    'description': description,
    'created_by': createdBy,
    'status': status.name,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'description': description,
    'status': status.name,
    'winning_location_id': winningLocationId,
  };

  static PlanStatus _parseStatus(String? value) {
    return switch (value) {
      'voting' => PlanStatus.voting,
      'decided' => PlanStatus.decided,
      'cancelled' => PlanStatus.cancelled,
      _ => PlanStatus.voting,
    };
  }
}

class PlanParticipantModel extends PlanParticipant {
  const PlanParticipantModel({
    required super.id,
    required super.planId,
    required super.userId,
    required super.joinedAt,
  });

  factory PlanParticipantModel.fromJson(Map<String, dynamic> json) {
    return PlanParticipantModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {'plan_id': planId, 'user_id': userId};
}

class PlanVoteModel extends PlanVote {
  const PlanVoteModel({
    required super.id,
    required super.planId,
    required super.userId,
    required super.locationId,
    required super.votedAt,
  });

  factory PlanVoteModel.fromJson(Map<String, dynamic> json) {
    return PlanVoteModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      userId: json['user_id'] as String,
      locationId: json['location_id'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'plan_id': planId,
    'user_id': userId,
    'location_id': locationId,
  };
}
