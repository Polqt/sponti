import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/glass_container.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';

class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.filter,
    required this.onTapRanking,
    required this.onTapPrice,
    required this.onTapCategory,
    required this.onToggleNowOpen,
  });

  final ExploreFilter filter;
  final VoidCallback onTapRanking;
  final VoidCallback onTapPrice;
  final VoidCallback onTapCategory;
  final VoidCallback onToggleNowOpen;

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
              label: '${_rankingLabel(filter.rankingFilter)} ✓',
              color: _rankingColor(filter.rankingFilter),
              icon: Icons.auto_awesome_rounded,
              isActive: true,
              onTap: onTapRanking,
            ),
            const SizedBox(width: 10),
            _ExploreFilterChip(
              label: price == null ? 'Any price' : '${_priceLabel(price)} ✓',
              color: _priceColor(price),
              icon: Icons.payments_outlined,
              isActive: price != null,
              onTap: onTapPrice,
            ),
            const SizedBox(width: 10),
            _ExploreFilterChip(
              label: category == null
                  ? 'Category'
                  : '${category.emoji} ${category.label} ✓',
              color: category == null
                  ? SpontiColors.textSecondary
                  : Color(category.colorValue),
              icon: category?.icon ?? Icons.grid_view_rounded,
              isActive: category != null,
              onTap: onTapCategory,
            ),
            const SizedBox(width: 10),
            _ExploreFilterChip(
              label: filter.nowOpenOnly ? 'Now open ✓' : 'Now open',
              color: SpontiColors.success,
              icon: Icons.schedule_rounded,
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
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
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
              Icon(icon, size: 16, color: foreground),
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

String _rankingLabel(String ranking) {
  return switch (ranking) {
    'lowkey' => 'Lowkey',
    'new' => 'New',
    _ => 'Trending',
  };
}

Color _rankingColor(String ranking) {
  return switch (ranking) {
    'lowkey' => const Color(0xFF3A7D44),
    'new' => SpontiColors.accent,
    _ => SpontiColors.primary,
  };
}

String _priceLabel(PriceRange price) {
  return switch (price) {
    PriceRange.free => '✦',
    PriceRange.budget => '₱',
    PriceRange.moderate => '₱₱',
    PriceRange.expensive => '₱₱₱',
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
