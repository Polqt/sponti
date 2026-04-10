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

class LocationRankingSnapshot {
  LocationRankingSnapshot._({
    required this.thirtyDaysAgo,
    required this.checkInP75,
    required this.reviewP75,
    required this.checkInP25,
  });

  factory LocationRankingSnapshot.fromLocations(
    List<Location> locations, {
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    if (locations.isEmpty) {
      return LocationRankingSnapshot._(
        thirtyDaysAgo: referenceTime.subtract(const Duration(days: 30)),
        checkInP75: 0,
        reviewP75: 0,
        checkInP25: 0,
      );
    }

    final checkInCounts = locations.map((location) => location.checkInCount).toList()
      ..sort();
    final reviewCounts = locations.map((location) => location.reviewCount).toList()
      ..sort();

    return LocationRankingSnapshot._(
      thirtyDaysAgo: referenceTime.subtract(const Duration(days: 30)),
      checkInP75: _percentile(checkInCounts, 0.75),
      reviewP75: _percentile(reviewCounts, 0.75),
      checkInP25: _percentile(checkInCounts, 0.25),
    );
  }

  final DateTime thirtyDaysAgo;
  final double checkInP75;
  final double reviewP75;
  final double checkInP25;

  LocationRanking? rankingFor(Location location) {
    final relevantDate = location.seededAt ?? location.createdAt;

    if (location.isSeeded && relevantDate.isAfter(thirtyDaysAgo)) {
      return LocationRanking.newest;
    }

    if (location.checkInCount >= checkInP75 && location.checkInCount > 0) {
      return LocationRanking.trending;
    }

    if ((location.rating >= 4.0 && location.reviewCount >= reviewP75) ||
        location.reviewCount >= 10) {
      return LocationRanking.popular;
    }

    if (location.isHiddenGem || location.checkInCount <= checkInP25) {
      return LocationRanking.lowkey;
    }

    return null;
  }

  static double _percentile(List<int> sorted, double percentile) {
    if (sorted.isEmpty) return 0;
    final index =
        (sorted.length * percentile).floor().clamp(0, sorted.length - 1);
    return sorted[index].toDouble();
  }
}

extension LocationRankingSnapshotList on List<Location> {
  LocationRankingSnapshot createRankingSnapshot({DateTime? now}) =>
      LocationRankingSnapshot.fromLocations(this, now: now);
}

extension LocationRankingExtension on Location {
  LocationRanking? getPrimaryRanking(List<Location> allLocations) {
    if (allLocations.isEmpty) return null;
    return allLocations.createRankingSnapshot().rankingFor(this);
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
