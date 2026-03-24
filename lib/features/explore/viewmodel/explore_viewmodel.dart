import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _unsetExploreField = Object();

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
    this.categoryFilter,
    this.priceFilter,
    this.nowOpenOnly = false,
  });

  final ExploreRanking rankingFilter;
  final LocationCategory? categoryFilter;
  final PriceRange? priceFilter;
  final bool nowOpenOnly;

  ExploreFilter copyWith({
    ExploreRanking? rankingFilter,
    Object? categoryFilter = _unsetExploreField,
    Object? priceFilter = _unsetExploreField,
    bool? nowOpenOnly,
  }) {
    return ExploreFilter(
      rankingFilter: rankingFilter ?? this.rankingFilter,
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

  void setRanking(ExploreRanking ranking) {
    state = state.copyWith(rankingFilter: ranking);
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
  Future<List<Location>> build() => _fetch();

  Future<List<Location>> _fetch() async {
    final filter = ref.read(exploreFilterProvider);
    final response = await Supabase.instance.client.rpc(
      SupabaseRPC.getTrendingLocations,
      params: {
        'ranking_filter': filter.rankingFilter.rpcValue,
        'category_filter': filter.categoryFilter?.name,
        'limit_count': 30,
      },
    );

    final rows = response is List<dynamic> ? response : const <dynamic>[];
    var locations = rows
        .map((row) => LocationModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .cast<Location>()
        .toList(growable: false);

    if (filter.priceFilter != null) {
      locations = locations
          .where((location) => location.priceRange == filter.priceFilter)
          .toList(growable: false);
    }

    if (filter.nowOpenOnly) {
      locations = locations
          .where((location) => location.isOpenNow)
          .toList(growable: false);
    }

    return locations;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> onFilterChanged() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final exploreFilterProvider =
    NotifierProvider<ExploreFilterViewModel, ExploreFilter>(
      ExploreFilterViewModel.new,
    );

final exploreProvider = AsyncNotifierProvider<ExploreViewModel, List<Location>>(
  ExploreViewModel.new,
);
