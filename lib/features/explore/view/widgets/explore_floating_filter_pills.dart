import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';

class ExploreFloatingFilterPills extends ConsumerStatefulWidget {
  const ExploreFloatingFilterPills({
    super.key,
    required this.filter,
    required this.bottomOffset,
  });

  final ExploreFilter filter;
  final double bottomOffset;

  @override
  ConsumerState<ExploreFloatingFilterPills> createState() => _ExploreFloatingFilterPillsState();
}

class _ExploreFloatingFilterPillsState extends ConsumerState<ExploreFloatingFilterPills> {
  bool _showDiscoveryDropdown = false;
  bool _showBudgetDropdown = false;
  final _discoveryKey = GlobalKey();
  final _budgetKey = GlobalKey();

  void _toggleDiscoveryDropdown() {
    setState(() {
      _showDiscoveryDropdown = !_showDiscoveryDropdown;
      _showBudgetDropdown = false;
    });
  }

  void _toggleBudgetDropdown() {
    setState(() {
      _showBudgetDropdown = !_showBudgetDropdown;
      _showDiscoveryDropdown = false;
    });
  }

  void _closeDropdowns() {
    if (_showDiscoveryDropdown || _showBudgetDropdown) {
      setState(() {
        _showDiscoveryDropdown = false;
        _showBudgetDropdown = false;
      });
    }
  }

  Future<void> _selectRanking(ExploreRanking ranking) async {
    ref.read(exploreFilterProvider.notifier).setRanking(ranking);
    _closeDropdowns();
    await ref.read(exploreProvider.notifier).refresh();
  }

  Future<void> _selectPrice(PriceRange? price) async {
    ref.read(exploreFilterProvider.notifier).setPrice(price);
    _closeDropdowns();
    await ref.read(exploreProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ranking = widget.filter.rankingFilter;
    final price = widget.filter.priceFilter;

    return Stack(
      children: [
        if (_showDiscoveryDropdown || _showBudgetDropdown)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdowns,
              child: Container(color: Colors.transparent),
            ),
          ),
        Positioned(
          left: 16,
          bottom: widget.bottomOffset + 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactFilterPill(
                key: _discoveryKey,
                colors: _getRankingColors(ranking),
                showDots: true,
                isActive: true,
                isOpen: _showDiscoveryDropdown,
                onTap: _toggleDiscoveryDropdown,
              ),
              const SizedBox(width: 8),
              _CompactFilterPill(
                key: _budgetKey,
                symbol: _getPriceSymbol(price),
                isActive: price != null,
                isOpen: _showBudgetDropdown,
                onTap: _toggleBudgetDropdown,
              ),
            ],
          ),
        ),
        if (_showDiscoveryDropdown)
          _DiscoveryDropdownCard(
            pillKey: _discoveryKey,
            bottomOffset: widget.bottomOffset,
            selectedRanking: ranking,
            onSelect: _selectRanking,
          ),
        if (_showBudgetDropdown)
          _BudgetDropdownCard(
            pillKey: _budgetKey,
            bottomOffset: widget.bottomOffset,
            selectedPrice: price,
            onSelect: _selectPrice,
          ),
      ],
    );
  }
}

class _CompactFilterPill extends StatelessWidget {
  const _CompactFilterPill({
    super.key,
    this.colors,
    this.symbol,
    this.showDots = false,
    required this.isActive,
    required this.isOpen,
    required this.onTap,
  });

  final List<Color>? colors;
  final String? symbol;
  final bool showDots;
  final bool isActive;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDots && colors != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < colors!.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors![i],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  )
                else if (symbol != null)
                  Text(
                    symbol!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? SpontiColors.textPrimary : SpontiColors.textSecondary,
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: SpontiColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryDropdownCard extends StatelessWidget {
  const _DiscoveryDropdownCard({
    required this.pillKey,
    required this.bottomOffset,
    required this.selectedRanking,
    required this.onSelect,
  });

  final GlobalKey pillKey;
  final double bottomOffset;
  final ExploreRanking selectedRanking;
  final ValueChanged<ExploreRanking> onSelect;

  @override
  Widget build(BuildContext context) {
    final renderBox = pillKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);
    
    if (offset == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      bottom: bottomOffset + 60,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'filter places that are',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SpontiColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final ranking in ExploreRanking.values)
              _DropdownOption(
                label: ranking.label.toLowerCase(),
                color: _rankingColor(ranking),
                isSelected: selectedRanking == ranking,
                onTap: () => onSelect(ranking),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetDropdownCard extends StatelessWidget {
  const _BudgetDropdownCard({
    required this.pillKey,
    required this.bottomOffset,
    required this.selectedPrice,
    required this.onSelect,
  });

  final GlobalKey pillKey;
  final double bottomOffset;
  final PriceRange? selectedPrice;
  final ValueChanged<PriceRange?> onSelect;

  @override
  Widget build(BuildContext context) {
    final renderBox = pillKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);
    
    if (offset == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      bottom: bottomOffset + 60,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'filter by budget',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SpontiColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _DropdownOption(
              label: 'Any price',
              color: SpontiColors.textSecondary,
              isSelected: selectedPrice == null,
              onTap: () => onSelect(null),
            ),
            for (final price in PriceRange.values)
              _DropdownOption(
                label: price.label,
                color: _priceColor(price),
                isSelected: selectedPrice == price,
                onTap: () => onSelect(price),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownOption extends StatelessWidget {
  const _DropdownOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : SpontiColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.radio_button_checked,
                  size: 20,
                  color: color,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  size: 20,
                  color: SpontiColors.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Color> _getRankingColors(ExploreRanking ranking) {
  return switch (ranking) {
    ExploreRanking.trending => [
      const Color(0xFFE91E63),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
    ],
    ExploreRanking.popular => [
      const Color(0xFFE07A15),
      const Color(0xFFFFB74D),
      const Color(0xFFFF9800),
    ],
    ExploreRanking.lowkey => [
      const Color(0xFF3A7D44),
      const Color(0xFF66BB6A),
      const Color(0xFF81C784),
    ],
    ExploreRanking.newest => [
      SpontiColors.accent,
      const Color(0xFFBA68C8),
      const Color(0xFF9C27B0),
    ],
  };
}

String _getPriceSymbol(PriceRange? price) {
  return switch (price) {
    PriceRange.free => '✦',
    PriceRange.budget => '₱',
    PriceRange.moderate => '₱₱',
    PriceRange.expensive => '₱₱₱',
    null => '₱₱₱₱',
  };
}

Color _rankingColor(ExploreRanking ranking) {
  return switch (ranking) {
    ExploreRanking.popular => const Color(0xFFE07A15),
    ExploreRanking.lowkey => const Color(0xFF3A7D44),
    ExploreRanking.newest => SpontiColors.accent,
    ExploreRanking.trending => SpontiColors.primary,
  };
}

Color _priceColor(PriceRange price) {
  return switch (price) {
    PriceRange.free => SpontiColors.secondary,
    PriceRange.budget => SpontiColors.primary,
    PriceRange.moderate => SpontiColors.warning,
    PriceRange.expensive => const Color(0xFF7B4F2E),
  };
}
