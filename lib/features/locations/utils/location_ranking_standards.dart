/// Product v1 thresholds for map/cohort ranking labels.
///
/// See [docs/LOCATION_RANKING_STANDARDS.md](../../../../docs/LOCATION_RANKING_STANDARDS.md).
/// Explore feed ordering uses `get_trending_locations` (global sort), not percentiles.
abstract final class LocationRankingStandards {
  LocationRankingStandards._();

  static const int newListingWindowDays = 30;

  /// Minimum lifetime check-ins before a place can be labeled Trending on the map.
  static const int trendingMinLifetimeCheckIns = 4;

  /// Minimum saves for the Popular (favorites) path.
  static const int popularMinFavorites = 3;

  static const double popularMinRating = 4.0;

  /// Strong review signal without relying on a thin cohort.
  static const int popularMinReviewsAbsolute = 10;

  /// Minimum reviews when using rating + cohort review percentile.
  static const int popularMinReviewsPercentilePath = 3;

  /// Lowkey “quiet” spots: bottom quartile must also be at most this many check-ins.
  static const int lowkeyMaxCheckIns = 3;
}
