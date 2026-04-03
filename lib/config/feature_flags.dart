import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class FeatureFlags {
  const FeatureFlags({
    required this.useRankedSearch,
    required this.useCursorPagination,
    required this.useLocationMetrics,
  });

  factory FeatureFlags.fromEnvironment() {
    return FeatureFlags(
      useRankedSearch: _readBoolFlag('FEATURE_RANKED_SEARCH'),
      useCursorPagination: _readBoolFlag('FEATURE_CURSOR_PAGINATION'),
      useLocationMetrics: _readBoolFlag('FEATURE_LOCATION_METRICS'),
    );
  }

  final bool useRankedSearch;
  final bool useCursorPagination;
  final bool useLocationMetrics;

  static bool _readBoolFlag(String key) {
    final raw = dotenv.env[key]?.trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }
}

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags.fromEnvironment();
});
