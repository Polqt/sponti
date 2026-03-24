import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

part 'explore_filter_sheet_components.dart';
part 'explore_category_filter_sheet.dart';

Future<void> showRankingFilterSheet(
  BuildContext context,
  WidgetRef ref,
  ExploreFilter filter,
) async {
  final options = ExploreRanking.values
      .map(
        (ranking) => _ExploreSheetOption(
          value: ranking,
          label: ranking.label,
          subtitle: ranking.subtitle,
        ),
      )
      .toList(growable: false);

  final selected = await _showExploreSheet<ExploreRanking>(
    context: context,
    title: 'Ranking',
    initialValue: filter.rankingFilter,
    options: options,
  );

  if (selected == null || selected == filter.rankingFilter) return;

  ref.read(exploreFilterProvider.notifier).setRanking(selected);
  await ref.read(exploreProvider.notifier).onFilterChanged();
}

Future<void> showPriceFilterSheet(
  BuildContext context,
  WidgetRef ref,
  ExploreFilter filter,
) async {
  final options = [
    const _ExploreSheetOption<PriceRange?>(value: null, label: 'Any price'),
    ...PriceRange.values.map(
      (price) => _ExploreSheetOption<PriceRange?>(
        value: price,
        label: price.label,
        subtitle: price.symbol,
      ),
    ),
  ];

  final selected = await _showExploreSheet<PriceRange?>(
    context: context,
    title: 'Price',
    initialValue: filter.priceFilter,
    options: options,
  );

  if (selected == filter.priceFilter) return;

  ref.read(exploreFilterProvider.notifier).setPrice(selected);
  await ref.read(exploreProvider.notifier).onFilterChanged();
}

Future<void> showCategoryFilterSheet(
  BuildContext context,
  WidgetRef ref,
  ExploreFilter filter,
) async {
  final selected = await _showCategoryExploreSheet(
    context: context,
    initialValue: filter.categoryFilter,
  );

  if (selected == null || selected.value == filter.categoryFilter) return;

  ref.read(exploreFilterProvider.notifier).setCategory(selected.value);
  await ref.read(exploreProvider.notifier).onFilterChanged();
  if (context.mounted) {
    context.go(RouteName.explore);
  }
}

Future<T?> _showExploreSheet<T>({
  required BuildContext context,
  required String title,
  required T initialValue,
  required List<_ExploreSheetOption<T>> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _SelectableExploreSheet<T>(
        title: title,
        initialValue: initialValue,
        options: options,
      );
    },
  );
}
