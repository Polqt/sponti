import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/icon_helpers.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';

Future<void> showRankingFilterSheet(
  BuildContext context,
  WidgetRef ref,
  ExploreFilter filter,
) async {
  final selected = await _showExploreSheet<String>(
    context: context,
    title: 'Ranking',
    initialValue: filter.rankingFilter,
    options: const [
      _ExploreSheetOption(
        value: 'trending',
        label: 'Trending',
        subtitle: 'Most check-ins this week',
      ),
      _ExploreSheetOption(
        value: 'lowkey',
        label: 'Lowkey',
        subtitle: 'Hidden gems, fewer crowds',
      ),
      _ExploreSheetOption(
        value: 'new',
        label: 'New',
        subtitle: 'Added in the last 30 days',
      ),
    ],
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
      (p) => _ExploreSheetOption<PriceRange?>(
        value: p,
        label: p.label,
        subtitle: p.symbol,
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
  LocationCategory? selected = filter.categoryFilter;

  final applied = await showModalBottomSheet<_CategorySheetResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return _SheetScaffold(
            title: 'Category',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _CategorySheetRow(
                        label: 'All',
                        fallbackIcon: Icons.grid_view_rounded,
                        color: SpontiColors.primary,
                        selected: selected == null,
                        onTap: () => setModalState(() => selected = null),
                      ),
                      for (final category in LocationCategory.values)
                        _CategorySheetRow(
                          label: category.label,
                          emoji: category.emoji,
                          assetPath: _categoryFilterAsset(category),
                          fallbackIcon: _categoryFilterIcon(category),
                          color: Color(category.colorValue),
                          selected: selected == category,
                          onTap: () =>
                              setModalState(() => selected = category),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Apply',
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_CategorySheetResult(selected)),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (applied == null || applied.value == filter.categoryFilter) return;

  ref.read(exploreFilterProvider.notifier).setCategory(applied.value);
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
}) async {
  T selected = initialValue;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return _SheetScaffold(
            title: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in options)
                        _ExploreRadioRow<T>(
                          option: option,
                          selected: selected == option.value,
                          onTap: () =>
                              setModalState(() => selected = option.value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Apply',
                  onPressed: () => Navigator.of(context).pop(selected),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: const BoxDecoration(
            color: SpontiColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SpontiColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SpontiColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreRadioRow<T> extends StatelessWidget {
  const _ExploreRadioRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ExploreSheetOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? SpontiColors.primary.withValues(alpha: 0.08)
                  : SpontiColors.surfaceVariant.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? SpontiColors.primary : SpontiColors.outline,
              ),
            ),
            child: Row(
              children: [
                Radio<T>(
                  value: option.value,
                  groupValue: selected ? option.value : null,
                  onChanged: (_) => onTap(),
                  activeColor: SpontiColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SpontiColors.textPrimary,
                        ),
                      ),
                      if (option.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SpontiColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreSheetOption<T> {
  const _ExploreSheetOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

class _CategorySheetResult {
  const _CategorySheetResult(this.value);

  final LocationCategory? value;
}

class _CategorySheetRow extends StatelessWidget {
  const _CategorySheetRow({
    required this.label,
    required this.fallbackIcon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.assetPath,
    this.emoji,
  });

  final String label;
  final String? assetPath;
  final String? emoji;
  final IconData fallbackIcon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.14)
                  : SpontiColors.surfaceVariant.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : SpontiColors.outline,
              ),
            ),
            child: Row(
              children: [
                _CategoryPreviewChip(
                  label: label,
                  emoji: emoji,
                  assetPath: assetPath,
                  fallbackIcon: fallbackIcon,
                  color: color,
                  isSelected: selected,
                ),
                const Spacer(),
                Radio<bool>(
                  value: true,
                  groupValue: selected,
                  onChanged: (_) => onTap(),
                  activeColor: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPreviewChip extends StatelessWidget {
  const _CategoryPreviewChip({
    required this.label,
    required this.fallbackIcon,
    required this.color,
    required this.isSelected,
    this.assetPath,
    this.emoji,
  });

  final String label;
  final String? assetPath;
  final String? emoji;
  final IconData fallbackIcon;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? color : SpontiColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.14)
            : SpontiColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? color : SpontiColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
          ],
          _CategoryPreviewIcon(
            assetPath: assetPath,
            fallbackIcon: fallbackIcon,
            foregroundColor: foreground,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPreviewIcon extends StatelessWidget {
  const _CategoryPreviewIcon({
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

    return FutureBuilder<ResolvedCategoryIcon>(
      future: resolveCategoryIcon(path),
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
