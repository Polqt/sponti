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
    final filteredLocations = _filterLocations(
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
                _FavoritesSearchField(
                  initialValue: searchQuery,
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 12),
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SpontiColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _FavoritesCategoryFilters(
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

List<Location> _filterLocations(
  List<Location> locations,
  String rawQuery,
  LocationCategory? selectedCategory,
) {
  final query = rawQuery.trim().toLowerCase();

  return locations
      .where((location) {
        final matchesCategory =
            selectedCategory == null || location.category == selectedCategory;
        if (!matchesCategory) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

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

class _FavoritesCategoryFilters extends StatelessWidget {
  const _FavoritesCategoryFilters({
    required this.selectedCategory,
    required this.onChanged,
  });

  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FavoritesCategoryChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null,
            color: SpontiColors.primary,
            onTap: () => onChanged(null),
          ),
          for (final category in LocationCategory.values) ...[
            const SizedBox(width: 10),
            _FavoritesCategoryChip(
              label: category.label,
              icon: _categoryFilterIcon(category),
              isSelected: selectedCategory == category,
              color: Color(category.colorValue),
              onTap: () => onChanged(
                selectedCategory == category ? null : category,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoritesCategoryChip extends StatelessWidget {
  const _FavoritesCategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? color : SpontiColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryFilterIcon(LocationCategory category) {
  return switch (category) {
    LocationCategory.food => Icons.restaurant_rounded,
    LocationCategory.coffee => Icons.local_cafe_rounded,
    LocationCategory.nature => Icons.park_rounded,
    LocationCategory.nightlife => Icons.nightlife_rounded,
    LocationCategory.arts => Icons.palette_rounded,
    LocationCategory.activities => Icons.sports_esports_rounded,
  };
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
