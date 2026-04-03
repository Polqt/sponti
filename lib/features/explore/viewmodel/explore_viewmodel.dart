import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_model.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _unsetExploreField = Object();
const _exploreFetchLimit = 120;
const _exploreUnrankedOpenNowFetchLimit = 200;

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
    this.hasWifi = false,
    this.petFriendly = false,
    this.hasParking = false,
  });

  final ExploreRanking rankingFilter;
  final bool hasRankingFilter;
  final LocationCategory? categoryFilter;
  final PriceRange? priceFilter;
  final bool nowOpenOnly;
  final bool hasWifi;
  final bool petFriendly;
  final bool hasParking;

  ExploreFilter copyWith({
    ExploreRanking? rankingFilter,
    bool? hasRankingFilter,
    Object? categoryFilter = _unsetExploreField,
    Object? priceFilter = _unsetExploreField,
    bool? nowOpenOnly,
    bool? hasWifi,
    bool? petFriendly,
    bool? hasParking,
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
      hasWifi: hasWifi ?? this.hasWifi,
      petFriendly: petFriendly ?? this.petFriendly,
      hasParking: hasParking ?? this.hasParking,
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

  void setAmenities({
    required bool hasWifi,
    required bool petFriendly,
    required bool hasParking,
  }) {
    state = state.copyWith(
      hasWifi: hasWifi,
      petFriendly: petFriendly,
      hasParking: hasParking,
    );
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

  List<Location> _mapRowsToLocations(dynamic response) {
    final remote = ref.read(locationRemoteDataSourceProvider);
    final rows = response is List<dynamic> ? response : const <dynamic>[];

    return rows
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

  bool _matchesClientOnlyFilters(Location location, ExploreFilter filter) {
    if (filter.nowOpenOnly && !location.isOpenNow) {
      return false;
    }

    return true;
  }

  Future<List<Location>> _fetch(ExploreFilter filter) async {
    final client = Supabase.instance.client;

    late final List<Location> locations;
    if (filter.hasRankingFilter) {
      final response = await client.rpc(
        SupabaseRPC.getTrendingLocations,
        params: {
          'ranking_filter': filter.rankingFilter.rpcValue,
          'category_filter': filter.categoryFilter?.name,
          'price_filter': filter.priceFilter?.name,
          'now_open_only': filter.nowOpenOnly,
          'has_wifi_only': filter.hasWifi,
          'pet_friendly_only': filter.petFriendly,
          'has_parking_only': filter.hasParking,
          'limit_count': _exploreFetchLimit,
        },
      );

      locations = _mapRowsToLocations(response);
    } else {
      dynamic query = client.from(SupabaseTables.locations).select();
      if (filter.categoryFilter != null) {
        query = query.eq('category', filter.categoryFilter!.name);
      }
      if (filter.priceFilter != null) {
        query = query.eq('price_range', filter.priceFilter!.name);
      }
      if (filter.hasWifi) {
        query = query.eq('has_wifi', true);
      }
      if (filter.petFriendly) {
        query = query.eq('is_pet_friendly', true);
      }
      if (filter.hasParking) {
        query = query.eq('has_parking', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(
            filter.nowOpenOnly
                ? _exploreUnrankedOpenNowFetchLimit
                : _exploreFetchLimit,
          );
      locations = _mapRowsToLocations(response);
    }

    if (!filter.nowOpenOnly || filter.hasRankingFilter) {
      return locations;
    }

    return locations
        .where((location) => _matchesClientOnlyFilters(location, filter))
        .take(_exploreFetchLimit)
        .toList(growable: false);
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
