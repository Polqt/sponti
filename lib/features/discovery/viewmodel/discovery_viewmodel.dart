import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/constants/api_constants.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/model/discovery_curator.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DiscoveryColumn { forYou, friends }

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

  String get sectionTitle =>
      activeColumn == DiscoveryColumn.forYou ? 'TOP PICKS' : 'FRIENDS';

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

List<Location> _parseLocations(
  List<dynamic> response,
  LocationRemoteDataSourceImpl remote,
) {
  return response
      .map(
        (item) => LocationModel.fromJson(
          remote.resolvePhotoUrls(item as Map<String, dynamic>),
        ),
      )
      .toList(growable: false);
}

List<DiscoveryCurator> _parseCurators(List<dynamic> rows) {
  final curators = rows
      .map((item) => DiscoveryCurator.fromJson(item as Map<String, dynamic>))
      .where((curator) => curator.activityScore > 0)
      .toList();

  curators.sort((a, b) {
    final scoreComparison = b.activityScore.compareTo(a.activityScore);
    if (scoreComparison != 0) return scoreComparison;

    final reviewComparison = b.totalReviews.compareTo(a.totalReviews);
    if (reviewComparison != 0) return reviewComparison;

    final checkInComparison = b.totalCheckIns.compareTo(a.totalCheckIns);
    if (checkInComparison != 0) return checkInComparison;

    final nameComparison = a.rankingKey.compareTo(b.rankingKey);
    if (nameComparison != 0) return nameComparison;

    return a.id.compareTo(b.id);
  });

  return List.unmodifiable(curators.take(_topCuratorsLimit));
}

/// Fetches top spots per category ordered by favorites count (popular ranking).
final categoryTopSpotsProvider = FutureProvider.autoDispose
    .family<List<Location>, LocationCategory>((ref, category) async {
  final client = Supabase.instance.client;
  final remote = LocationRemoteDataSourceImpl(client);

  final response = await client.rpc(
    ApiConstants.rpcGetTrendingLocations,
    params: {
      'ranking_filter': 'popular',
      'category_filter': category.name,
      'limit_count': 10,
    },
  );

  return _parseLocations(response as List<dynamic>, remote);
});

final topCuratorsProvider = StreamProvider.autoDispose<List<DiscoveryCurator>>((
  ref,
) async* {
  final client = Supabase.instance.client;
  final initialResponse = await client.rpc(
    ApiConstants.rpcGetTopCurators,
    params: {'limit_count': _topCuratorsLimit},
  );

  yield _parseCurators(initialResponse as List<dynamic>);

  yield* client
      .from(ApiConstants.profilesTable)
      .stream(primaryKey: const ['id'])
      .map(_parseCurators);
});
