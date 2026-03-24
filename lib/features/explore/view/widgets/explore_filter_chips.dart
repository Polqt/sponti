import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/glass_container.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';

class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.filter,
    required this.onTapRanking,
    required this.onTapPrice,
    required this.onTapCategory,
    required this.onToggleNowOpen,
    this.showCategoryChip = true,
  });

  final ExploreFilter filter;
  final VoidCallback onTapRanking;
  final VoidCallback onTapPrice;
  final VoidCallback onTapCategory;
  final VoidCallback onToggleNowOpen;
  final bool showCategoryChip;

  @override
  Widget build(BuildContext context) {
    final category = filter.categoryFilter;
    final price = filter.priceFilter;

    return GlassContainer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ExploreFilterChip(
              label: '${filter.rankingFilter.label} \u2713',
              color: _rankingColor(filter.rankingFilter),
              leading: const Icon(Icons.auto_awesome_rounded),
              isActive: true,
              onTap: onTapRanking,
            ),
            const SizedBox(width: 10),
            _ExploreFilterChip(
              label: price == null ? 'Any price' : '${_priceLabel(price)} \u2713',
              color: _priceColor(price),
              leading: const Icon(Icons.payments_outlined),
              isActive: price != null,
              onTap: onTapPrice,
            ),
            if (showCategoryChip) ...[
              const SizedBox(width: 10),
              _ExploreFilterChip(
                label: category == null ? 'Category' : '${category.label} \u2713',
                color: category == null
                    ? SpontiColors.textSecondary
                    : Color(category.colorValue),
                leading: category == null
                    ? const Icon(Icons.grid_view_rounded)
                    : LocationCategoryIcon(
                        category: category,
                        color: Color(category.colorValue),
                      ),
                isActive: category != null,
                onTap: onTapCategory,
              ),
            ],
            const SizedBox(width: 10),
            _ExploreFilterChip(
              label: filter.nowOpenOnly ? 'Now open \u2713' : 'Now open',
              color: SpontiColors.success,
              leading: const Icon(Icons.schedule_rounded),
              isActive: filter.nowOpenOnly,
              onTap: onToggleNowOpen,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreFilterChip extends StatelessWidget {
  const _ExploreFilterChip({
    required this.label,
    required this.color,
    required this.leading,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Widget leading;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? color : SpontiColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.14)
                : SpontiColors.surfaceVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? color : SpontiColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(size: 16, color: foreground),
                child: leading,
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
        ),
      ),
    );
  }
}

Color _rankingColor(ExploreRanking ranking) {
  return switch (ranking) {
    ExploreRanking.popular => const Color(0xFFE07A15),
    ExploreRanking.lowkey => const Color(0xFF3A7D44),
    ExploreRanking.newest => SpontiColors.accent,
    ExploreRanking.trending => SpontiColors.primary,
  };
}

String _priceLabel(PriceRange price) {
  return switch (price) {
    PriceRange.free => '\u2726',
    PriceRange.budget => '\u20B1',
    PriceRange.moderate => '\u20B1\u20B1',
    PriceRange.expensive => '\u20B1\u20B1\u20B1',
  };
}

Color _priceColor(PriceRange? price) {
  return switch (price) {
    PriceRange.free => SpontiColors.secondary,
    PriceRange.budget => SpontiColors.primary,
    PriceRange.moderate => SpontiColors.warning,
    PriceRange.expensive => const Color(0xFF7B4F2E),
    null => SpontiColors.textSecondary,
  };
}
