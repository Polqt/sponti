import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/favorites/view/widgets/favorite_list_item.dart';
import 'package:sponti/features/favorites/view/widgets/favorites_filter.dart';
import 'package:sponti/features/favorites/view/widgets/favorites_search_field.dart';
import 'package:sponti/features/locations/model/location.dart';

class FavoritesBody extends StatelessWidget {
  const FavoritesBody({
    required this.favoriteIdsAsync,
    required this.favoriteLocationsAsync,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    super.key,
  });

  final AsyncValue<List<String>> favoriteIdsAsync;
  final AsyncValue<List<Location>> favoriteLocationsAsync;
  final String searchQuery;
  final LocationCategory? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LocationCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    if (favoriteIdsAsync.isLoading || favoriteLocationsAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: SpontiColors.primary),
      );
    }

    final error = favoriteIdsAsync.error ?? favoriteLocationsAsync.error;
    if (error != null) {
      return AppErrorState(message: error.toString());
    }

    final favoriteLocations =
        favoriteLocationsAsync.valueOrNull ?? const <Location>[];
    final filteredLocations = filterLocations(
      favoriteLocations,
      searchQuery,
      selectedCategory,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved spots',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep your next Bacolod plan ready to go.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FavoritesSearchField(
                  initialValue: searchQuery,
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 10),
                FavoritesCategoryFilters(
                  selectedCategory: selectedCategory,
                  onChanged: onCategoryChanged,
                ),
              ],
            ),
          ),
        ),
        if (favoriteLocations.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyStateSection(
              child: AppEmptyState(
                emoji: '🦗',
                title: 'your list is crickets',
                subtitle:
                    "those bookmark icons aren't just decorative. "
                    'go poke some spots and start a collection.',
                actionLabel: 'find something good',
                onAction: () => context.go(RouteName.location),
              ),
            ),
          )
        else if (filteredLocations.isEmpty)
          const SliverToBoxAdapter(
            child: _EmptyStateSection(
              child: AppEmptyState(
                emoji: '\u{1F50E}',
                title: 'No matches found',
                subtitle:
                    'Try a different name, category, or tag from your saved list.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final location = filteredLocations[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filteredLocations.length - 1 ? 0 : 14,
                  ),
                  child: FavoriteListItem(location: location),
                );
              }, childCount: filteredLocations.length),
            ),
          ),
      ],
    );
  }
}

class _EmptyStateSection extends StatelessWidget {
  const _EmptyStateSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    return SizedBox(height: viewportHeight * 0.58, child: child);
  }
}
