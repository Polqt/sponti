import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            iconAssetPath: null,
            fallbackIcon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null,
            color: SpontiColors.primary,
            onTap: () => onChanged(null),
          ),
          for (final category in LocationCategory.values) ...[
            const SizedBox(width: 10),
            _FavoritesCategoryChip(
              label: category.label,
              iconAssetPath: _categoryFilterAsset(category),
              fallbackIcon: _categoryFilterIcon(category),
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
    required this.iconAssetPath,
    required this.fallbackIcon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? iconAssetPath;
  final IconData fallbackIcon;
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
              _FavoritesCategoryIcon(
                assetPath: iconAssetPath,
                fallbackIcon: fallbackIcon,
                foregroundColor: foregroundColor,
              ),
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

class _FavoritesCategoryIcon extends StatelessWidget {
  const _FavoritesCategoryIcon({
    required this.assetPath,
    required this.fallbackIcon,
    required this.foregroundColor,
  });

  final String? assetPath;
  final IconData fallbackIcon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return Icon(fallbackIcon, size: 16, color: foregroundColor);
    }

    return FutureBuilder<_ResolvedCategoryIcon>(
      future: _resolveCategoryIcon(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 16, height: 16);
        }

        final resolved = snapshot.data;
        if (resolved == null) {
          return Icon(fallbackIcon, size: 16, color: foregroundColor);
        }

        if (resolved.bytes != null) {
          return Image.memory(
            resolved.bytes!,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          );
        }

        if (resolved.svg != null) {
          return SvgPicture.string(
            resolved.svg!,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
          );
        }

        return Icon(fallbackIcon, size: 16, color: foregroundColor);
      },
    );
  }
}

class _ResolvedCategoryIcon {
  const _ResolvedCategoryIcon({this.bytes, this.svg});

  final Uint8List? bytes;
  final String? svg;
}

final Map<String, Future<_ResolvedCategoryIcon>> _iconCache =
    <String, Future<_ResolvedCategoryIcon>>{};

Future<_ResolvedCategoryIcon> _resolveCategoryIcon(String assetPath) {
  return _iconCache.putIfAbsent(assetPath, () async {
    final bundledFallback = _bundledCategorySvg(assetPath);
    final svg = await rootBundle.loadString(
      assetPath,
      cache: false,
    ).catchError((_) => bundledFallback);
    if (svg == null) {
      return const _ResolvedCategoryIcon();
    }

    final match = RegExp(
      r'data:image\/png;base64,([^"]+)',
      caseSensitive: false,
    ).firstMatch(svg);
    final encoded = match?.group(1);
    if (encoded != null) {
      return _ResolvedCategoryIcon(bytes: base64Decode(encoded));
    }

    return _ResolvedCategoryIcon(svg: svg);
  });
}

String? _bundledCategorySvg(String assetPath) {
  return switch (assetPath) {
    'assets/icons/stroll.svg' => _strollSvg,
    'assets/icons/arts.svg' => _artsSvg,
    _ => null,
  };
}

const String _strollSvg =
    '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M9 2.25C10.6569 2.25 12 3.59315 12 5.25C12 6.12868 11.622 6.91907 11.0198 7.46845C12.7107 8.2726 13.875 9.99615 13.875 12C13.875 12.4142 13.5392 12.75 13.125 12.75H10.125V15C10.125 15.4142 9.78921 15.75 9.375 15.75H8.625C8.21079 15.75 7.875 15.4142 7.875 15V12.75H4.875C4.46079 12.75 4.125 12.4142 4.125 12C4.125 9.99615 5.28932 8.2726 6.98016 7.46845C6.37805 6.91907 6 6.12868 6 5.25C6 3.59315 7.34315 2.25 9 2.25Z" fill="#7A746D"/>'
    '</svg>';

const String _artsSvg =
    '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M9 2.25C5.27208 2.25 2.25 5.27208 2.25 9C2.25 12.7279 5.27208 15.75 9 15.75C10.1739 15.75 11.125 14.7989 11.125 13.625C11.125 13.1891 10.9937 12.7838 10.7686 12.4465C10.6024 12.1972 10.5 11.8977 10.5 11.5732C10.5 10.7099 11.1997 10.0103 12.063 10.0103H13.125C14.7819 10.0103 15.75 8.73481 15.75 7.3125C15.75 4.52208 12.7279 2.25 9 2.25Z" fill="#7A746D"/>'
    '<circle cx="5.625" cy="8.25" r="1.125" fill="#7A746D"/>'
    '<circle cx="8.625" cy="5.625" r="1.125" fill="#7A746D"/>'
    '<circle cx="11.625" cy="7.125" r="1.125" fill="#7A746D"/>'
    '</svg>';

String? _categoryFilterAsset(LocationCategory category) {
  return switch (category) {
    LocationCategory.food => 'assets/icons/munch.svg',
    LocationCategory.coffee => 'assets/icons/coffee.svg',
    LocationCategory.nature => 'assets/icons/stroll.svg',
    LocationCategory.nightlife => 'assets/icons/nightlife.svg',
    LocationCategory.arts => 'assets/icons/arts.svg',
    LocationCategory.activities => 'assets/icons/fun.svg',
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
