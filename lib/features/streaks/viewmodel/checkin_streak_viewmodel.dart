import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/streaks/model/checkin_streak.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final checkInStreakProvider = FutureProvider<CheckInStreak>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const CheckInStreak(
      currentStreakDays: 0,
      longestStreakDays: 0,
      lastCheckInDate: null,
      earnedBadges: <StreakBadgeTier>[],
    );
  }

  final response = await Supabase.instance.client.rpc(
    SupabaseRPC.getUserCheckInStreak,
    params: {'target_user_id': userId},
  );

  final rows = response as List<dynamic>;
  if (rows.isEmpty) {
    return const CheckInStreak(
      currentStreakDays: 0,
      longestStreakDays: 0,
      lastCheckInDate: null,
      earnedBadges: <StreakBadgeTier>[],
    );
  }

  final data = rows.first as Map<String, dynamic>;
  final longest = (data['longest_streak_days'] as num?)?.toInt() ?? 0;
  final earnedBadges = StreakBadgeTier.values
      .where((tier) => longest >= tier.requiredDays)
      .toList(growable: false);

  return CheckInStreak(
    currentStreakDays: (data['current_streak_days'] as num?)?.toInt() ?? 0,
    longestStreakDays: longest,
    lastCheckInDate: switch (data['last_check_in_date']) {
      final String dateText when dateText.isNotEmpty => DateTime.tryParse(dateText),
      _ => null,
    },
    earnedBadges: earnedBadges,
  );
});
