import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/repository/location_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _unsetExploreField = Object();
const _exploreFetchLimit = 1000;

enum ExploreRanking {
  trending(
    'trending',
    'Trending',
    'Most check-ins overall',
  ),
  popular(
    'popular',
    'Popular',
    'Most favorited by users',
  ),
  lowkey(
    'lowkey',
    'Lowkey',
    'Most suggested spot categories',
  ),
  newest(
    'new',
    'New',
    'Latest seeded spots from us',
  );

  const ExploreRanking(this.rpcValue, this.label, this.subtitle);

  final String rpcValue;
  final String label;
  final String subtitle;
}

class ExploreFilter {
  const ExploreFilter({
    this.rankingFilter = ExploreRanking.trending,
    this.hasRankingFilter = true,
    this.categoryFilter,
    this.priceFilter,
    this.nowOpenOnly = false,
  });

  final ExploreRanking rankingFilter;
  final bool hasRankingFilter;
  final LocationCategory? categoryFilter;
  final PriceRange? priceFilter;
  final bool nowOpenOnly;

  ExploreFilter copyWith({
    ExploreRanking? rankingFilter,
    bool? hasRankingFilter,
    Object? categoryFilter = _unsetExploreField,
    Object? priceFilter = _unsetExploreField,
    bool? nowOpenOnly,
  }) {
    return ExploreFilter(
      rankingFilter: rankingFilter ?? this.rankingFilter,
      hasRankingFilter: hasRankingFilter ?? this.hasRankingFilter,
      categoryFilter: identical(categoryFilter, _unsetExploreField)
          ? this.categoryFilter
          : categoryFilter as LocationCategory?,
      priceFilter: identical(priceFilter, _unsetExploreField)
          ? this.priceFilter
          : priceFilter as PriceRange?,
      nowOpenOnly: nowOpenOnly ?? this.nowOpenOnly,
    );
  }
}

class ExploreFilterViewModel extends Notifier<ExploreFilter> {
  @override
  ExploreFilter build() => const ExploreFilter();

  void setRanking(ExploreRanking? ranking) {
    state = state.copyWith(
      rankingFilter: ranking ?? state.rankingFilter,
      hasRankingFilter: ranking != null,
    );
  }

  void toggleCategory(LocationCategory category) {
    state = state.copyWith(
      categoryFilter: state.categoryFilter == category ? null : category,
    );
  }

  void setCategory(LocationCategory? category) {
    state = state.copyWith(categoryFilter: category);
  }

  void togglePrice(PriceRange price) {
    state = state.copyWith(
      priceFilter: state.priceFilter == price ? null : price,
    );
  }

  void setPrice(PriceRange? price) {
    state = state.copyWith(priceFilter: price);
  }

  void toggleNowOpen() {
    state = state.copyWith(nowOpenOnly: !state.nowOpenOnly);
  }

  void clearAll() {
    state = const ExploreFilter();
  }
}

class ExploreViewModel extends AsyncNotifier<List<Location>> {
  @override
  Future<List<Location>> build() {
    final filter = ref.watch(exploreFilterProvider);
    return _fetch(filter);
  }

  Future<List<Location>> _fetch(ExploreFilter filter) async {
    final client = Supabase.instance.client;
    final remote = LocationRemoteDataSourceImpl(client);

    late final List<Location> locations;
    if (filter.hasRankingFilter) {
      final response = await client.rpc(
        SupabaseRPC.getTrendingLocations,
        params: {
          'ranking_filter': filter.rankingFilter.rpcValue,
          'category_filter': filter.categoryFilter?.name,
          'limit_count': _exploreFetchLimit,
        },
      );

      final rows = response is List<dynamic> ? response : const <dynamic>[];
      locations = rows
          .map(
            (row) => LocationModel.fromJson(
              remote.resolvePhotoUrls(
                Map<String, dynamic>.from(row as Map),
              ),
            ),
          )
          .cast<Location>()
          .toList(growable: false);
    } else {
      dynamic query = client.from(SupabaseTables.locations).select();
      if (filter.categoryFilter != null) {
        query = query.eq('category', filter.categoryFilter!.name);
      }
      final response = await query
          .order('created_at', ascending: false)
          .limit(_exploreFetchLimit);
      final rows = response is List<dynamic> ? response : const <dynamic>[];
      locations = rows
          .map(
            (row) => LocationModel.fromJson(
              remote.resolvePhotoUrls(
                Map<String, dynamic>.from(row as Map),
              ),
            ),
          )
          .cast<Location>()
          .toList(growable: false);
    }

    if (filter.priceFilter != null || filter.nowOpenOnly) {
      return locations.where((location) {
        if (filter.priceFilter != null &&
            location.priceRange != filter.priceFilter) {
          return false;
        }
        if (filter.nowOpenOnly && !location.isOpenNow) {
          return false;
        }
        return true;
      }).toList(growable: false);
    }

    return locations;
  }

  Future<void> refresh() async {
    final filter = ref.read(exploreFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filter));
  }
}

final exploreFilterProvider =
    NotifierProvider<ExploreFilterViewModel, ExploreFilter>(
      ExploreFilterViewModel.new,
    );

final exploreProvider = AsyncNotifierProvider<ExploreViewModel, List<Location>>(
  ExploreViewModel.new,
);
