import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';

enum LocationRanking {
  trending,
  popular,
  lowkey,
  newest;

  static LocationRanking? fromTitle(String title) => switch (title.toLowerCase()) {
    'trending' => LocationRanking.trending,
    'popular' => LocationRanking.popular,
    'lowkey' => LocationRanking.lowkey,
    'new' => LocationRanking.newest,
    _ => null,
  };
}

extension LocationRankingExtension on Location {
  LocationRanking? getPrimaryRanking(List<Location> allLocations) {
    if (allLocations.isEmpty) return null;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final relevantDate = seededAt ?? createdAt;

    if (isSeeded && relevantDate.isAfter(thirtyDaysAgo)) {
      return LocationRanking.newest;
    }

    final checkInCounts = allLocations.map((l) => l.checkInCount).toList()..sort();
    final reviewCounts = allLocations.map((l) => l.reviewCount).toList()..sort();
    
    final checkInP75 = _percentile(checkInCounts, 0.75);
    final reviewP75 = _percentile(reviewCounts, 0.75);
    final checkInP25 = _percentile(checkInCounts, 0.25);

    if (checkInCount >= checkInP75 && checkInCount > 0) {
      return LocationRanking.trending;
    }

    if ((rating >= 4.0 && reviewCount >= reviewP75) || reviewCount >= 10) {
      return LocationRanking.popular;
    }

    if (isHiddenGem || checkInCount <= checkInP25) {
      return LocationRanking.lowkey;
    }

    return null;
  }

  static double _percentile(List<int> sorted, double percentile) {
    if (sorted.isEmpty) return 0;
    final index = (sorted.length * percentile).floor().clamp(0, sorted.length - 1);
    return sorted[index].toDouble();
  }
}

extension LocationRankingColor on LocationRanking {
  Color get indicatorColor => switch (this) {
    LocationRanking.trending => const Color(0xFFD4458C),
    LocationRanking.popular => const Color(0xFFE07A15),
    LocationRanking.lowkey => SpontiColors.info,
    LocationRanking.newest => SpontiColors.success,
  };

  ExploreRanking get toExploreRanking => switch (this) {
    LocationRanking.trending => ExploreRanking.trending,
    LocationRanking.popular => ExploreRanking.popular,
    LocationRanking.lowkey => ExploreRanking.lowkey,
    LocationRanking.newest => ExploreRanking.newest,
  };
}
