import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_ranking_standards.dart';

/// Community-submitted locations stay in the Lowkey tier until engagement
/// crosses the same floors used elsewhere for trending / popular / reviews.
bool _communitySubmissionGraduated(Location location) {
  return location.checkInCount >=
          LocationRankingStandards.trendingMinLifetimeCheckIns ||
      location.favoriteCount >= LocationRankingStandards.popularMinFavorites ||
      location.reviewCount >=
          LocationRankingStandards.popularMinReviewsAbsolute;
}

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
    required this.favoriteP75,
  });

  factory LocationRankingSnapshot.fromLocations(
    List<Location> locations, {
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    if (locations.isEmpty) {
      return LocationRankingSnapshot._(
        thirtyDaysAgo: referenceTime.subtract(
          Duration(days: LocationRankingStandards.newListingWindowDays),
        ),
        checkInP75: 0,
        reviewP75: 0,
        checkInP25: 0,
        favoriteP75: 0,
      );
    }

    final checkInCounts = locations.map((location) => location.checkInCount).toList()
      ..sort();
    final reviewCounts = locations.map((location) => location.reviewCount).toList()
      ..sort();
    final favoriteCounts = locations.map((location) => location.favoriteCount).toList()
      ..sort();

    return LocationRankingSnapshot._(
      thirtyDaysAgo: referenceTime.subtract(
        Duration(days: LocationRankingStandards.newListingWindowDays),
      ),
      checkInP75: _percentile(checkInCounts, 0.75),
      reviewP75: _percentile(reviewCounts, 0.75),
      checkInP25: _percentile(checkInCounts, 0.25),
      favoriteP75: _percentile(favoriteCounts, 0.75),
    );
  }

  final DateTime thirtyDaysAgo;
  final double checkInP75;
  final double reviewP75;
  final double checkInP25;
  final double favoriteP75;

  /// True when the location has any community signal (not just "listed").
  bool _hasEngagement(Location location) =>
      location.checkInCount > 0 ||
      location.reviewCount > 0 ||
      location.favoriteCount > 0;

  LocationRanking? rankingFor(Location location) {
    if (location.submittedBy != null && !_communitySubmissionGraduated(location)) {
      return LocationRanking.lowkey;
    }

    final relevantDate = location.seededAt ?? location.createdAt;
    final isRecentSeeded =
        location.isSeeded && relevantDate.isAfter(thirtyDaysAgo);
    final engaged = _hasEngagement(location);

    final minTrend = LocationRankingStandards.trendingMinLifetimeCheckIns;
    if (location.checkInCount >= minTrend &&
        (location.checkInCount >= checkInP75 || checkInP75 < minTrend)) {
      return LocationRanking.trending;
    }

    final minFav = LocationRankingStandards.popularMinFavorites;
    final popularByFavorites = location.favoriteCount >= minFav &&
        (location.favoriteCount >= favoriteP75 || favoriteP75 < minFav);

    final popularByReviews =
        (location.rating >= LocationRankingStandards.popularMinRating &&
            location.reviewCount >= reviewP75 &&
            location.reviewCount >=
                LocationRankingStandards.popularMinReviewsPercentilePath) ||
            location.reviewCount >=
                LocationRankingStandards.popularMinReviewsAbsolute;

    if (popularByFavorites || popularByReviews) {
      return LocationRanking.popular;
    }

    if (isRecentSeeded && !engaged) {
      return LocationRanking.newest;
    }

    // Recent seeds with visits but below the trending floor: still "under the radar"
    // (shows under Lowkey filter instead of no tier).
    if (isRecentSeeded &&
        engaged &&
        location.checkInCount > 0 &&
        location.checkInCount < minTrend) {
      return LocationRanking.lowkey;
    }

    final quietCap = LocationRankingStandards.lowkeyMaxCheckIns;
    if (location.isHiddenGem ||
        (location.checkInCount <= checkInP25 &&
            location.checkInCount <= quietCap)) {
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
