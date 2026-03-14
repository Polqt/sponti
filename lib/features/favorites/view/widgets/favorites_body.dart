import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/favorites/view/widgets/favorite_list_item.dart';
import 'package:sponti/features/locations/model/location.dart';

class FavoritesBody extends StatelessWidget {
  const FavoritesBody({
    required this.favoriteIdsAsync,
    required this.favoriteLocationsAsync,
    required this.searchQuery,
    required this.onSearchChanged,
    super.key,
  });

  final AsyncValue<List<String>> favoriteIdsAsync;
  final AsyncValue<List<Location>> favoriteLocationsAsync;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

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
    final filteredLocations = _filterLocations(favoriteLocations, searchQuery);

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
                const SizedBox(height: 18),
                _SavedSummaryCard(
                  totalCount: favoriteLocations.length,
                  filteredCount: filteredLocations.length,
                ),
                const SizedBox(height: 16),
                _FavoritesSearchField(
                  initialValue: searchQuery,
                  onChanged: onSearchChanged,
                ),
              ],
            ),
          ),
        ),
        if (favoriteLocations.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyStateSection(
              child: AppEmptyState(
                emoji: '\u{1F4CD}',
                title: 'No saved places yet',
                subtitle:
                    'Tap the save icon on a spot to keep it here for your next spontaneous trip.',
                actionLabel: 'Explore spots',
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

List<Location> _filterLocations(List<Location> locations, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return locations;

  return locations
      .where((location) {
        final haystack = [
          location.name,
          location.address,
          location.category.label,
          ...location.tags,
        ].join(' ').toLowerCase();

        return haystack.contains(query);
      })
      .toList(growable: false);
}

class _SavedSummaryCard extends StatelessWidget {
  const _SavedSummaryCard({
    required this.totalCount,
    required this.filteredCount,
  });

  final int totalCount;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6D7), Color(0xFFFFF3E8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: SpontiColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount saved',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  filteredCount == totalCount
                      ? 'Everything you bookmarked is ready here.'
                      : '$filteredCount result${filteredCount == 1 ? '' : 's'} from your saved list.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSearchField extends StatelessWidget {
  const _FavoritesSearchField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search saved spots',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: initialValue.isEmpty
            ? null
            : IconButton(
                onPressed: () => onChanged(''),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
