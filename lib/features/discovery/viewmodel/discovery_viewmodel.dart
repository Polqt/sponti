import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/config.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/model/discovery_curator.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DiscoveryColumn { forYou, friends, leaderboards }

extension DiscoveryCategoryLabel on LocationCategory {
  String get discoveryLabel => switch (this) {
    LocationCategory.food => 'EAT',
    LocationCategory.coffee => 'CAFES',
    LocationCategory.nightlife => 'BARS',
    LocationCategory.activities => 'GO OUT',
    LocationCategory.arts => 'SHOPS',
    LocationCategory.nature => 'STROLL',
  };
}

class DiscoveryCardData {
  const DiscoveryCardData({
    required this.title,
    required this.subtitle,
    required this.chipColor,
    required this.placeholderColors,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color chipColor;
  final List<Color> placeholderColors;
  final IconData icon;
}

const discoveryTopPicks = <DiscoveryCardData>[
  DiscoveryCardData(
    title: 'Trending',
    subtitle: 'they keep coming back',
    chipColor: Color(0xFFD4458C),
    placeholderColors: [Color(0xFFF5E5DC), Color(0xFFD7B89A)],
    icon: Icons.local_fire_department_rounded,
  ),
  DiscoveryCardData(
    title: 'Lowkey',
    subtitle: 'spots unknown to some',
    chipColor: SpontiColors.info,
    placeholderColors: [Color(0xFFF6F1EB), Color(0xFFD7ECE9)],
    icon: Icons.visibility_off_rounded,
  ),
  DiscoveryCardData(
    title: 'Popular',
    subtitle: 'people love these spots!',
    chipColor: Color(0xFFE07A15),
    placeholderColors: [Color(0xFF321033), Color(0xFF6D235C)],
    icon: Icons.favorite_rounded,
  ),
  DiscoveryCardData(
    title: 'New',
    subtitle: 'be their first customer!',
    chipColor: SpontiColors.success,
    placeholderColors: [Color(0xFF20342A), Color(0xFF4E8E63)],
    icon: Icons.auto_awesome_rounded,
  ),
];

const discoveryCategories = <LocationCategory>[
  LocationCategory.food,
  LocationCategory.coffee,
  LocationCategory.nightlife,
  LocationCategory.activities,
  LocationCategory.arts,
  LocationCategory.nature,
];

@immutable
class DiscoveryViewState {
  const DiscoveryViewState({
    this.activeColumn = DiscoveryColumn.forYou,
    this.expandedCategories = const <LocationCategory>{},
  });

  final DiscoveryColumn activeColumn;
  final Set<LocationCategory> expandedCategories;

  String get sectionTitle => switch (activeColumn) {
    DiscoveryColumn.forYou => 'Top Picks',
    DiscoveryColumn.friends => 'Friends',
    DiscoveryColumn.leaderboards => 'Leaderboards',
  };

  bool isCategoryExpanded(LocationCategory category) =>
      expandedCategories.contains(category);

  DiscoveryViewState copyWith({
    DiscoveryColumn? activeColumn,
    Set<LocationCategory>? expandedCategories,
  }) {
    return DiscoveryViewState(
      activeColumn: activeColumn ?? this.activeColumn,
      expandedCategories: expandedCategories == null
          ? this.expandedCategories
          : Set.unmodifiable(expandedCategories),
    );
  }
}

class DiscoveryViewModel extends AutoDisposeNotifier<DiscoveryViewState> {
  @override
  DiscoveryViewState build() => const DiscoveryViewState();

  void setActiveColumn(DiscoveryColumn column) {
    if (state.activeColumn == column) return;
    state = state.copyWith(activeColumn: column);
  }

  void toggleCategory(LocationCategory category) {
    final expandedCategories = Set<LocationCategory>.from(
      state.expandedCategories,
    );

    if (expandedCategories.contains(category)) {
      expandedCategories.remove(category);
    } else {
      expandedCategories.add(category);
    }

    state = state.copyWith(expandedCategories: expandedCategories);
  }
}

final discoveryViewModelProvider =
    AutoDisposeNotifierProvider<DiscoveryViewModel, DiscoveryViewState>(
      DiscoveryViewModel.new,
    );

const _topCuratorsLimit = 8;
const _curatorProfileColumns =
    'id, full_name, username, avatar_url, total_reviews, total_check_ins, updated_at';

enum DiscoveryCuratorRanking { overall, reviewers, visitors }

@immutable
class DiscoveryCuratorLeaderboards {
  const DiscoveryCuratorLeaderboards({
    required this.topCurators,
    required this.topReviewers,
    required this.topVisitors,
  });

  final List<DiscoveryCurator> topCurators;
  final List<DiscoveryCurator> topReviewers;
  final List<DiscoveryCurator> topVisitors;

  bool get isEmpty =>
      topCurators.isEmpty && topReviewers.isEmpty && topVisitors.isEmpty;
}

List<Location> _parseLocations(
  List<dynamic> response,
  LocationRemoteDataSource remote,
) {
  return response
      .map(
        (item) => LocationModel.fromJson(
          remote.resolvePhotoUrls(item as Map<String, dynamic>),
        ),
      )
      .toList(growable: false);
}

final _discoveryLocationRemote = LocationRemoteDataSourceImpl(
  Supabase.instance.client,
);

List<DiscoveryCurator> _parseCurators(List<dynamic> rows) {
  return rows
      .map((item) => DiscoveryCurator.fromJson(item as Map<String, dynamic>))
      .where((curator) => curator.activityScore > 0)
      .toList(growable: false);
}

List<DiscoveryCurator> _rankCurators(
  List<DiscoveryCurator> curators,
  DiscoveryCuratorRanking ranking,
) {
  final ranked = curators.where((curator) {
    return switch (ranking) {
      DiscoveryCuratorRanking.overall => curator.activityScore > 0,
      DiscoveryCuratorRanking.reviewers => curator.totalReviews > 0,
      DiscoveryCuratorRanking.visitors => curator.totalCheckIns > 0,
    };
  }).toList();

  ranked.sort((a, b) {
    final primaryComparison = switch (ranking) {
      DiscoveryCuratorRanking.overall => b.activityScore.compareTo(
        a.activityScore,
      ),
      DiscoveryCuratorRanking.reviewers => b.totalReviews.compareTo(
        a.totalReviews,
      ),
      DiscoveryCuratorRanking.visitors => b.totalCheckIns.compareTo(
        a.totalCheckIns,
      ),
    };
    if (primaryComparison != 0) return primaryComparison;

    final secondaryComparison = switch (ranking) {
      DiscoveryCuratorRanking.overall => b.totalReviews.compareTo(
        a.totalReviews,
      ),
      DiscoveryCuratorRanking.reviewers => b.totalCheckIns.compareTo(
        a.totalCheckIns,
      ),
      DiscoveryCuratorRanking.visitors => b.totalReviews.compareTo(
        a.totalReviews,
      ),
    };
    if (secondaryComparison != 0) return secondaryComparison;

    final tertiaryComparison = switch (ranking) {
      DiscoveryCuratorRanking.overall => b.totalCheckIns.compareTo(
        a.totalCheckIns,
      ),
      DiscoveryCuratorRanking.reviewers => b.activityScore.compareTo(
        a.activityScore,
      ),
      DiscoveryCuratorRanking.visitors => b.activityScore.compareTo(
        a.activityScore,
      ),
    };
    if (tertiaryComparison != 0) return tertiaryComparison;

    final nameComparison = a.rankingKey.compareTo(b.rankingKey);
    if (nameComparison != 0) return nameComparison;

    return a.id.compareTo(b.id);
  });

  return List.unmodifiable(ranked.take(_topCuratorsLimit));
}

DiscoveryCuratorLeaderboards _buildCuratorLeaderboards(
  List<DiscoveryCurator> curators, {
  List<DiscoveryCurator>? overallCurators,
}) {
  return DiscoveryCuratorLeaderboards(
    topCurators: overallCurators == null
        ? _rankCurators(curators, DiscoveryCuratorRanking.overall)
        : _rankCurators(overallCurators, DiscoveryCuratorRanking.overall),
    topReviewers: _rankCurators(curators, DiscoveryCuratorRanking.reviewers),
    topVisitors: _rankCurators(curators, DiscoveryCuratorRanking.visitors),
  );
}

/// Fetches top spots per category ordered by favorites count (popular ranking).
final categoryTopSpotsProvider = FutureProvider.autoDispose
    .family<List<Location>, LocationCategory>((ref, category) async {
      final client = Supabase.instance.client;
      final remote = _discoveryLocationRemote;

      final response = await client.rpc(
        SupabaseRPC.getTrendingLocations,
        params: {
          'ranking_filter': 'popular',
          'category_filter': category.name,
          'limit_count': 10,
        },
      );

      return _parseLocations(response as List<dynamic>, remote);
    });

final curatorLeaderboardsProvider =
    StreamProvider.autoDispose<DiscoveryCuratorLeaderboards>((ref) async* {
      final client = Supabase.instance.client;
      final responses = await Future.wait<dynamic>([
        client.rpc(
          SupabaseRPC.getTopCurators,
          params: {'limit_count': _topCuratorsLimit},
        ),
        client
            .from(SupabaseTables.profiles)
            .select(_curatorProfileColumns)
            .limit(_topCuratorsLimit * 4),
      ]);

      yield _buildCuratorLeaderboards(
        _parseCurators(responses[1] as List<dynamic>),
        overallCurators: _parseCurators(responses[0] as List<dynamic>),
      );

      yield* client
          .from(SupabaseTables.profiles)
          .stream(primaryKey: const ['id'])
          .limit(_topCuratorsLimit * 4)
          .map(_parseCurators)
          .map(_buildCuratorLeaderboards);
    });
