import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/explore/view/widgets/explore_budget_filter_modal.dart';
import 'package:sponti/features/explore/view/widgets/explore_discovery_filter_modal.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_category_row.dart';

class ExploreBottomPanelFrame extends StatelessWidget {
  const ExploreBottomPanelFrame({
    super.key,
    required this.radius,
    required this.screenHeight,
    required this.controller,
    required this.minSize,
    required this.maxSize,
    required this.countText,
    required this.filter,
    required this.isExpanded,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSnapNearest,
    required this.child,
    this.onRankingChanged,
    this.onPriceChanged,
    this.amenityFilters,
  });

  final BorderRadius radius;
  final double screenHeight;
  final DraggableScrollableController controller;
  final double minSize;
  final double maxSize;
  final String countText;
  final ExploreFilter filter;
  final bool isExpanded;
  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final void Function({double velocity}) onSnapNearest;
  final Widget child;
  final ValueChanged<ExploreRanking?>? onRankingChanged;
  final ValueChanged<PriceRange?>? onPriceChanged;
  final Widget? amenityFilters;
  static const _panelDecoration = BoxDecoration(
    color: Color(0xFFF8F6F1),
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xB8FFFFFF)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: _panelDecoration.copyWith(borderRadius: radius),
        child: Column(
          children: [
            ExploreBottomPanelDragHandle(
              screenHeight: screenHeight,
              controller: controller,
              minSize: minSize,
              maxSize: maxSize,
              onSnapNearest: onSnapNearest,
            ),
            ExploreBottomPanelHeaderRow(
              countText: countText,
              filter: filter,
              isExpanded: isExpanded,
              onRankingChanged: onRankingChanged,
              onPriceChanged: onPriceChanged,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: LocationCategoryRow(
                selectedCategory: selectedCategory,
                onChanged: onCategoryChanged,
              ),
            ),
            ?amenityFilters,
            const Divider(height: 1, thickness: 1, color: Color(0x14A68F7B)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class ExploreBottomPanelDragHandle extends StatelessWidget {
  const ExploreBottomPanelDragHandle({
    super.key,
    required this.screenHeight,
    required this.controller,
    required this.minSize,
    required this.maxSize,
    required this.onSnapNearest,
  });

  final double screenHeight;
  final DraggableScrollableController controller;
  final double minSize;
  final double maxSize;
  final void Function({double velocity}) onSnapNearest;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!controller.isAttached) return;
    final delta = -details.delta.dy / screenHeight;
    controller.jumpTo((controller.size + delta).clamp(minSize, maxSize));
  }

  void _onDragEnd(DragEndDetails details) =>
      onSnapNearest(velocity: details.primaryVelocity ?? 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: SpontiColors.textMuted.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreBottomPanelHeaderRow extends StatelessWidget {
  const ExploreBottomPanelHeaderRow({
    super.key,
    required this.countText,
    required this.filter,
    required this.isExpanded,
    this.onRankingChanged,
    this.onPriceChanged,
  });

  final String countText;
  final ExploreFilter filter;
  final bool isExpanded;
  final ValueChanged<ExploreRanking?>? onRankingChanged;
  final ValueChanged<PriceRange?>? onPriceChanged;

  Future<void> _onRankingTap(BuildContext context) async {
    final result = await showDiscoveryFilterModal(
      context: context,
      initialValue: filter.hasRankingFilter ? filter.rankingFilter : null,
    );
    onRankingChanged?.call(result);
  }

  Future<void> _onPriceTap(BuildContext context) async {
    final result = await showBudgetFilterModal(
      context: context,
      initialValue: filter.priceFilter,
    );
    onPriceChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nearby picks',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  countText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            ExploreBottomPanelFilterPill(
              label: filter.hasRankingFilter
                  ? filter.rankingFilter.label
                  : 'Any',
              color: filter.hasRankingFilter
                  ? exploreRankingColor(filter.rankingFilter)
                  : SpontiColors.textSecondary,
              isActive: filter.hasRankingFilter,
              onTap: () => _onRankingTap(context),
            ),
            const SizedBox(width: 6),
            ExploreBottomPanelFilterPill(
              label: filter.priceFilter?.symbol ?? 'Any',
              color: filter.priceFilter != null
                  ? explorePriceColor(filter.priceFilter!)
                  : SpontiColors.textSecondary,
              isActive: filter.priceFilter != null,
              onTap: () => _onPriceTap(context),
            ),
          ],
        ],
      ),
    );
  }
}

class ExploreBottomPanelFilterPill extends StatelessWidget {
  const ExploreBottomPanelFilterPill({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = true,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.1)
                : SpontiColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.45)
                  : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? color : SpontiColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 13,
                color: isActive ? color : SpontiColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color exploreRankingColor(ExploreRanking ranking) => switch (ranking) {
  ExploreRanking.trending => SpontiColors.primary,
  ExploreRanking.popular => const Color(0xFFE07A15),
  ExploreRanking.lowkey => const Color(0xFF3A7D44),
  ExploreRanking.newest => SpontiColors.accent,
};

Color explorePriceColor(PriceRange price) => switch (price) {
  PriceRange.free => SpontiColors.secondary,
  PriceRange.budget => SpontiColors.primary,
  PriceRange.moderate => SpontiColors.warning,
  PriceRange.expensive => const Color(0xFF7B4F2E),
};
