import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/explore/view/widgets/explore_loading.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';
import 'package:sponti/features/locations/view/widgets/location_category_row.dart';

class ExploreBottomPanel extends StatefulWidget {
  const ExploreBottomPanel({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.selectedIndex,
    required this.bottomInset,
    required this.favoriteIds,
    required this.onExpandChanged,
    required this.onSelectLocation,
    required this.onSaveToggle,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.onSheetProgressChanged,
    this.edgeToEdge = false,
    this.isExpanded = false,
  });

  final AsyncValue<List<Location>> locationsAsync;
  final List<Location> locations;
  final int selectedIndex;
  final bool isExpanded;
  final double bottomInset;
  final Set<String> favoriteIds;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<Location> onSelectLocation;
  final Future<void> Function(Location) onSaveToggle;
  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final ValueChanged<double>? onSheetProgressChanged;
  final bool edgeToEdge;

  /// When `true` the sheet stretches edge-to-edge (used inside [LocationScreen]).

  @override
  State<ExploreBottomPanel> createState() => _ExploreBottomPanelState();
}

class _ExploreBottomPanelState extends State<ExploreBottomPanel> {
  static const double _minSize = 0.24;
  static const double _maxSize = 0.40;
  static const double _expandThreshold = 0.30;
  static const double _bottomBarReserve = 86.0;
  late final DraggableScrollableController _sheetController;
  double _chromeProgress = 0.0;
  final _itemKeys = <String, GlobalKey>{};
  int? _lastScrolledIndex;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _scheduleScrollSelectedIntoView();
  }

  @override
  void didUpdateWidget(covariant ExploreBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _animateTo(widget.isExpanded ? _maxSize : _minSize);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.locations.length != widget.locations.length) {
      _scheduleScrollSelectedIntoView();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
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
    Scrollable.ensureVisible(
      ctx,
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  void _onHeaderDragUpdate(DragUpdateDetails details, double screenHeight) {
    if (!_sheetController.isAttached) return;
    final delta = -details.delta.dy / screenHeight;
    _sheetController.jumpTo(
      (_sheetController.size + delta).clamp(_minSize, _maxSize),
    );
  }

  void _onHeaderDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v < -300) {
      _animateTo(_maxSize);
    } else if (v > 300) {
      _animateTo(_minSize);
    } else if (_sheetController.isAttached) {
      _animateTo(
        _sheetController.size >= (_minSize + _maxSize) / 2
            ? _maxSize
            : _minSize,
      );
    }
  }

  void _onSheetNotification(DraggableScrollableNotification n) {
    final progress = ((n.extent - _minSize) / (_maxSize - _minSize)).clamp(
      0.0,
      1.0,
    );
    widget.onSheetProgressChanged?.call(progress);

    if ((progress - _chromeProgress).abs() > 0.02) {
      setState(() => _chromeProgress = progress);
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final chrome = (widget.edgeToEdge ? 1.0 : _chromeProgress).clamp(0.0, 1.0);
    final bottomPadding =
        (widget.edgeToEdge ? 0.0 : widget.bottomInset + 12) +
        _bottomBarReserve * (1.0 - chrome);
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
          initialChildSize: widget.isExpanded ? _maxSize : _minSize,
          snap: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPadding),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6F1).withValues(alpha: 0.94),
                      borderRadius: radius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (d) =>
                              _onHeaderDragUpdate(d, screenHeight),
                          onVerticalDragEnd: _onHeaderDragEnd,
                          child: _SheetHeader(
                            countText: '${widget.locations.length} spots found',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
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
                        Expanded(child: _buildList(context, scrollController)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ScrollController scrollController) {
    // Loading skeleton
    if (widget.locationsAsync.isLoading) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: const [LoadingList()],
      );
    }

    if (widget.locations.isEmpty) {
      return ListView(
        controller: scrollController,
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
      controller: scrollController,
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
          child: AnimatedContainer(
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
              isSaved: widget.favoriteIds.contains(location.id),
              showShadow: false,
              onTap: () => widget.onSelectLocation(location),
              onSaveToggle: () => widget.onSaveToggle(location),
            ),
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.countText});

  final String countText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: SpontiColors.textMuted.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x14F97316),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFFF97316),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby picks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: SpontiColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14F97316),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Swipe up',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFF97316),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
