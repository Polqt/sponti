import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/favorites/view/widgets/favorites_body.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);
    final favoriteLocationsAsync = ref.watch(favoriteLocationsProvider);
    final searchQuery = ref.watch(favoritesSearchQueryProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: FavoritesBody(
          favoriteIdsAsync: favoriteIdsAsync,
          favoriteLocationsAsync: favoriteLocationsAsync,
          searchQuery: searchQuery,
          onSearchChanged: (value) {
            ref.read(favoritesSearchQueryProvider.notifier).state = value;
          },
        ),
      ),
    );
  }
}
