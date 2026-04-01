import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';

Color locationPriceAccentColor(PriceRange price) => switch (price) {
  PriceRange.free => SpontiColors.secondary,
  PriceRange.budget => SpontiColors.primary,
  PriceRange.moderate => SpontiColors.warning,
  PriceRange.expensive => const Color(0xFF7B4F2E),
};

LocationRanking? resolveLocationMarkerRanking({
  required LocationRanking? ranking,
  required LocationRanking? activeRankingFilter,
}) => activeRankingFilter ?? ranking;

Color? resolveLocationMarkerAccent({
  required LocationRanking? ranking,
  required LocationRanking? activeRankingFilter,
  required PriceRange? activePriceFilter,
}) {
  final rankingIndicator = resolveLocationMarkerRanking(
    ranking: ranking,
    activeRankingFilter: activeRankingFilter,
  );
  if (rankingIndicator != null) {
    return rankingIndicator.indicatorColor;
  }

  if (activePriceFilter != null) {
    return locationPriceAccentColor(activePriceFilter);
  }

  return null;
}
