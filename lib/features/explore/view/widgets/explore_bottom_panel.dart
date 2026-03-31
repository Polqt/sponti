import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/explore/view/widgets/explore_budget_filter_modal.dart';
import 'package:sponti/features/explore/view/widgets/explore_discovery_filter_modal.dart';
import 'package:sponti/features/explore/view/widgets/explore_loading.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';
import 'package:sponti/features/locations/view/widgets/location_category_row.dart';

class ExploreBottomPanel extends ConsumerStatefulWidget {
  const ExploreBottomPanel({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.selectedIndex,
    required this.bottomInset,
    required this.onExpandChanged,
    required this.onSelectLocation,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.filter,
    this.onRankingChanged,
    this.onPriceChanged,
    this.onLocationTap,
    this.onSheetProgressChanged,
    this.onDismissed,
    this.edgeToEdge = false,
    this.isExpanded = false,
  });

  final AsyncValue<List<Location>> locationsAsync;
  final List<Location> locations;
  final int selectedIndex;
  final bool isExpanded;
  final double bottomInset;
  final ExploreFilter filter;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<Location> onSelectLocation;
  final ValueChanged<ExploreRanking?>? onRankingChanged;
  final ValueChanged<PriceRange?>? onPriceChanged;
  final ValueChanged<Location>? onLocationTap;
  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final ValueChanged<double>? onSheetProgressChanged;
  final VoidCallback? onDismissed;
  final bool edgeToEdge;

  @override
  ConsumerState<ExploreBottomPanel> createState() => _ExploreBottomPanelState();
}

class _ExploreBottomPanelState extends ConsumerState<ExploreBottomPanel> {
  static const double _minSize = 0.25;
  static const double _midSize = 0.50;
  static const double _maxSize = 0.92;
  static const double _expandThreshold = 0.35;

  late final DraggableScrollableController _sheetController;
  // Own scroll controller — fully decoupled from DraggableScrollableSheet so
  // list scrolling never resizes the sheet or fires sheet notifications.
  late final ScrollController _listScrollController;

  double _chromeProgress = 0.0;
  final _itemKeys = <String, GlobalKey>{};
  int? _lastScrolledIndex;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _listScrollController = ScrollController();
    _scheduleScrollSelectedIntoView();
  }

  @override
  void didUpdateWidget(covariant ExploreBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneItemKeys();
    if (oldWidget.isExpanded != widget.isExpanded) {
      _animateTo(widget.isExpanded ? _midSize : _minSize);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.locations.length != widget.locations.length) {
      _scheduleScrollSelectedIntoView();
    }
  }

  void _pruneItemKeys() {
    if (_itemKeys.isEmpty) return;
    final activeIds = widget.locations.map((l) => l.id).toSet();
    _itemKeys.removeWhere((id, _) => !activeIds.contains(id));
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollSelectedIntoView() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      _scrollSelectedIntoView();
    });
  }

  void _scrollSelectedIntoView() {
    if (!mounted || widget.locations.isEmpty) return;
    final index = widget.selectedIndex.clamp(0, widget.locations.length - 1);
    if (_lastScrolledIndex == index) return;
    _lastScrolledIndex = index;

    final key = _itemKeys[widget.locations[index].id];
    final ctx = key?.currentContext;
    if (ctx == null) {
      _scheduleScrollSelectedIntoView();
      return;
    }

    // Target the list's own scroll position directly — never the sheet's
    // scrollable — so ensureVisible cannot change the sheet extent.
    final renderObject = ctx.findRenderObject();
    if (renderObject == null || !_listScrollController.hasClients) {
      _scheduleScrollSelectedIntoView();
      return;
    }
    _listScrollController.position.ensureVisible(
      renderObject,
      alignment: 0.18,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _animateTo(double target) async {
    if (!_sheetController.isAttached) return;
    try {
      await _sheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  void _snapToNearest({double velocity = 0}) {
    if (!_sheetController.isAttached) return;
    final size = _sheetController.size;

    double target;
    if (velocity < -600) {
      target = size < _midSize ? _midSize : _maxSize;
    } else if (velocity > 600) {
      target = size > _midSize ? _midSize : _minSize;
    } else {
      final distMin = (size - _minSize).abs();
      final distMid = (size - _midSize).abs();
      final distMax = (size - _maxSize).abs();
      if (distMin <= distMid && distMin <= distMax) {
        target = _minSize;
      } else if (distMid <= distMax) {
        target = _midSize;
      } else {
        target = _maxSize;
      }
    }

    if (target == _minSize && widget.onDismissed != null) {
      _animateTo(_minSize).then((_) {
        if (mounted) widget.onDismissed!();
      });
    } else {
      _animateTo(target);
    }
  }

  void _onSheetNotification(DraggableScrollableNotification n) {
    final progress = ((n.extent - _minSize) / (_maxSize - _minSize)).clamp(0.0, 1.0);
    widget.onSheetProgressChanged?.call(progress);

    if ((progress - _chromeProgress).abs() > 0.02) {
      _chromeProgress = progress;
      if (mounted) setState(() {});
    } else {
      _chromeProgress = progress;
    }

    final expandedNow = n.extent >= _expandThreshold;
    if (expandedNow != widget.isExpanded) {
      widget.onExpandChanged(expandedNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoriteIdSetProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final hPad = widget.edgeToEdge ? 0.0 : 12.0;
    final radius = widget.edgeToEdge
        ? const BorderRadius.vertical(top: Radius.circular(30))
        : BorderRadius.circular(28);

    return Positioned.fill(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          _onSheetNotification(n);
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _sheetController,
          minChildSize: _minSize,
          maxChildSize: _maxSize,
          initialChildSize: widget.isExpanded ? _midSize : _minSize,
          snap: true,
          snapSizes: const [_minSize, _midSize, _maxSize],
          snapAnimationDuration: const Duration(milliseconds: 320),
          builder: (context, sheetScrollController) {
            // Attach sheetScrollController to an invisible zero-size ListView so
            // the framework is satisfied. The real list uses _listScrollController
            // and is fully decoupled from the sheet extent.
            return Stack(
              children: [
                SizedBox.shrink(
                  child: ListView(
                    controller: sheetScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F1).withValues(alpha: 0.97),
                          borderRadius: radius,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Drag handle — only this strip resizes the sheet.
                            _DragHandle(
                              screenHeight: screenHeight,
                              controller: _sheetController,
                              minSize: _minSize,
                              maxSize: _maxSize,
                              onSnapNearest: _snapToNearest,
                            ),
                            // Title row + filter pills — taps are never consumed
                            // by the drag recogniser above.
                            _HeaderRow(
                              countText: '${widget.locations.length} spots found',
                              filter: widget.filter,
                              isExpanded: widget.isExpanded,
                              onRankingChanged: widget.onRankingChanged,
                              onPriceChanged: widget.onPriceChanged,
                            ),
                            // Category row — fixed, never scrolls.
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: LocationCategoryRow(
                                selectedCategory: widget.selectedCategory,
                                onChanged: widget.onCategoryChanged,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0x14A68F7B),
                            ),
                            Expanded(child: _buildList(favoriteIds: favoriteIds)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList({required Set<String> favoriteIds}) {
    if (widget.locationsAsync.isLoading) {
      return ListView(
        controller: _listScrollController,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: const [LoadingList()],
      );
    }

    if (widget.locations.isEmpty) {
      return ListView(
        controller: _listScrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        children: const [
          AppEmptyState(
            emoji: '🔭',
            title: 'Nothing found',
            subtitle: 'Try a different filter combo',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _listScrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: widget.locations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final location = widget.locations[index];
        final isSelected = index == widget.selectedIndex;
        final key = _itemKeys.putIfAbsent(
          location.id,
          () => GlobalKey(debugLabel: 'explore_item_${location.id}'),
        );
        return KeyedSubtree(
          key: key,
          child: RepaintBoundary(
            child: AnimatedContainer(
              key: ValueKey(location.id),
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Color(location.category.colorValue)
                      : const Color(0x14A68F7B),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: LocationCard(
                location: location,
                variant: LocationCardVariant.fullWidth,
                isSaved: favoriteIds.contains(location.id),
                showShadow: false,
                onTap: () {
                  final onLocationTap = widget.onLocationTap;
                  if (onLocationTap != null) {
                    onLocationTap(location);
                    return;
                  }

                  widget.onSelectLocation(location);
                },
                onSaveToggle: () =>
                    ref.read(favoriteIdsProvider.notifier).toggle(location.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _DragHandle — thin strip at the top; ONLY this widget drives sheet resize.
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle({
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

  void _onDragUpdate(DragUpdateDetails d) {
    if (!controller.isAttached) return;
    final delta = -d.delta.dy / screenHeight;
    controller.jumpTo((controller.size + delta).clamp(minSize, maxSize));
  }

  void _onDragEnd(DragEndDetails d) =>
      onSnapNearest(velocity: d.primaryVelocity ?? 0);

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

// ---------------------------------------------------------------------------
// _HeaderRow — title + count + filter pills. No drag recogniser here so
// pill taps are never swallowed by the sheet's gesture arena.
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
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
    // null means "None" — reset to default trending.
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
            _FilterPill(
              label: filter.hasRankingFilter ? filter.rankingFilter.label : 'Any',
              color: filter.hasRankingFilter
                  ? _rankingColor(filter.rankingFilter)
                  : SpontiColors.textSecondary,
              isActive: filter.hasRankingFilter,
              onTap: () => _onRankingTap(context),
            ),
            const SizedBox(width: 6),
            _FilterPill(
              label: filter.priceFilter?.symbol ?? 'Any',
              color: filter.priceFilter != null
                  ? _priceColor(filter.priceFilter!)
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

// ---------------------------------------------------------------------------
// _FilterPill — compact tappable chip used in the header row.
// ---------------------------------------------------------------------------

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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

Color _rankingColor(ExploreRanking ranking) => switch (ranking) {
  ExploreRanking.trending => SpontiColors.primary,
  ExploreRanking.popular => const Color(0xFFE07A15),
  ExploreRanking.lowkey => const Color(0xFF3A7D44),
  ExploreRanking.newest => SpontiColors.accent,
};

Color _priceColor(PriceRange price) => switch (price) {
  PriceRange.free => SpontiColors.secondary,
  PriceRange.budget => SpontiColors.primary,
  PriceRange.moderate => SpontiColors.warning,
  PriceRange.expensive => const Color(0xFF7B4F2E),
};
