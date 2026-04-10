import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class FeatureFlags {
  const FeatureFlags({
    required this.useRankedSearch,
    required this.useCursorPagination,
    required this.useLocationMetrics,
    required this.trendingMinCheckIns,
  });

  factory FeatureFlags.fromEnvironment() {
    return FeatureFlags(
      useRankedSearch: _readBoolFlag('FEATURE_RANKED_SEARCH'),
      useCursorPagination: _readBoolFlag('FEATURE_CURSOR_PAGINATION'),
      useLocationMetrics: _readBoolFlag('FEATURE_LOCATION_METRICS'),
      trendingMinCheckIns: _readIntFlag('TRENDING_MIN_CHECKINS', defaultValue: 3),
    );
  }

  final bool useRankedSearch;
  final bool useCursorPagination;
  final bool useLocationMetrics;
  /// Minimum 7-day check-in total for a location to be considered trending.
  final int trendingMinCheckIns;

  static bool _readBoolFlag(String key) {
    final raw = dotenv.env[key]?.trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }

  static int _readIntFlag(String key, {required int defaultValue}) {
    final raw = dotenv.env[key]?.trim();
    if (raw == null || raw.isEmpty) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }
}

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags.fromEnvironment();
});
