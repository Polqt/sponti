import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/favorites/view/widgets/favorites_body.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);
    final favoriteLocationsAsync = ref.watch(favoriteLocationsProvider);
    final searchQuery = ref.watch(favoritesSearchQueryProvider);
    final selectedCategory = ref.watch(favoritesCategoryFilterProvider);
    final pinnedCount = ref.watch(pinnedComparisonIdsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      floatingActionButton: pinnedCount >= kLocationComparisonMinPins
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RouteName.locationComparisonPath()),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Compare'),
            )
          : null,
      body: SafeArea(
        child: FavoritesBody(
          favoriteIdsAsync: favoriteIdsAsync,
          favoriteLocationsAsync: favoriteLocationsAsync,
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
          onSearchChanged: (value) {
            ref.read(favoritesSearchQueryProvider.notifier).state = value;
          },
          onCategoryChanged: (value) {
            ref.read(favoritesCategoryFilterProvider.notifier).state = value;
          },
        ),
      ),
    );
  }
}
