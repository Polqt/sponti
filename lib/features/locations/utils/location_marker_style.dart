import 'package:flutter/material.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';

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

  return activePriceFilter?.accentColor;
}
