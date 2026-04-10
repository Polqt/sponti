import 'package:equatable/equatable.dart';

enum StreakBadgeTier { sevenDays, thirtyDays, hundredDays }

extension StreakBadgeTierX on StreakBadgeTier {
  int get requiredDays => switch (this) {
    StreakBadgeTier.sevenDays => 7,
    StreakBadgeTier.thirtyDays => 30,
    StreakBadgeTier.hundredDays => 100,
  };

  String get label => switch (this) {
    StreakBadgeTier.sevenDays => '7 Days',
    StreakBadgeTier.thirtyDays => '30 Days',
    StreakBadgeTier.hundredDays => '100 Days',
  };
}

class CheckInStreak extends Equatable {
  const CheckInStreak({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastCheckInDate,
    required this.earnedBadges,
  });

  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastCheckInDate;
  final List<StreakBadgeTier> earnedBadges;

  bool get hasStreak => currentStreakDays > 0;

  @override
  List<Object?> get props => [
    currentStreakDays,
    longestStreakDays,
    lastCheckInDate,
    earnedBadges,
  ];
}
