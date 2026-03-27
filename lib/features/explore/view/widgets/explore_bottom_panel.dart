import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
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
    this.onLocationTap,
    this.onSheetProgressChanged,
    this.onSheetExtentChanged,
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
  final ValueChanged<Location>? onLocationTap;
  final LocationCategory? selectedCategory;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final ValueChanged<double>? onSheetProgressChanged;
  final ValueChanged<double>? onSheetExtentChanged;
  final VoidCallback? onDismissed;
  final bool edgeToEdge;

  @override
  ConsumerState<ExploreBottomPanel> createState() => _ExploreBottomPanelState();
}

class _ExploreBottomPanelState extends ConsumerState<ExploreBottomPanel>
    with SingleTickerProviderStateMixin {
  static const double _minSize = 0.25;
  static const double _midSize = 0.50;
  static const double _maxSize = 0.92;
  static const double _floatingPillsReservedSpace = 54.0;

  static const double _expandThreshold = 0.35;

  late final AnimationController _sheetController;
  late final ScrollController _listController;
  final _itemKeys = <String, GlobalKey>{};
  int? _lastScrolledIndex;
  bool _scrollScheduled = false;
  late bool _reportedExpanded;

  @override
  void initState() {
    super.initState();
    _reportedExpanded = widget.isExpanded;
    _sheetController = AnimationController(
      vsync: this,
      lowerBound: _minSize,
      upperBound: _maxSize,
      value: widget.isExpanded ? _midSize : _minSize,
    )..addListener(_handleSheetExtentChanged);
    _listController = ScrollController();
    _scheduleScrollSelectedIntoView();
  }

  @override
  void didUpdateWidget(covariant ExploreBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneItemKeys();
    if (oldWidget.isExpanded != widget.isExpanded) {
      _reportedExpanded = widget.isExpanded;
      _animateTo(widget.isExpanded ? _midSize : _minSize);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.locations.length != widget.locations.length) {
      _scheduleScrollSelectedIntoView();
    }
  }

  void _pruneItemKeys() {
    if (_itemKeys.isEmpty) return;
    final activeIds = widget.locations.map((location) => location.id).toSet();
    _itemKeys.removeWhere((id, _) => !activeIds.contains(id));
  }

  @override
  void dispose() {
    _sheetController
      ..removeListener(_handleSheetExtentChanged)
      ..dispose();
    _listController.dispose();
    super.dispose();
  }

  void _handleSheetExtentChanged() {
    final extent = _sheetController.value.clamp(_minSize, _maxSize);
    final progress =
        ((extent - _minSize) / (_maxSize - _minSize)).clamp(0.0, 1.0);

    widget.onSheetProgressChanged?.call(progress);
    widget.onSheetExtentChanged?.call(extent);

    final expandedNow = extent >= _expandThreshold;
    if (expandedNow != _reportedExpanded) {
      _reportedExpanded = expandedNow;
      widget.onExpandChanged(expandedNow);
    }
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
    try {
      await _sheetController.animateTo(
        target.clamp(_minSize, _maxSize),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  void _updateSheetSize(double size) {
    _sheetController.value = size.clamp(_minSize, _maxSize);
  }

  void _snapToNearest({double velocity = 0}) {
    final size = _sheetController.value;

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
      return;
    }

    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoriteIdSetProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final hPad = widget.edgeToEdge ? 0.0 : 12.0;
    final radius = widget.edgeToEdge
        ? const BorderRadius.vertical(top: Radius.circular(30))
        : BorderRadius.circular(28);

    final panelChild = ClipRRect(
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
              _SheetHandle(
                screenHeight: screenHeight,
                currentSize: () => _sheetController.value,
                minSize: _minSize,
                maxSize: _maxSize,
                onSizeChanged: _updateSheetSize,
                onSnapNearest: _snapToNearest,
                countText: '${widget.locations.length} spots found',
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
              Expanded(
                child: Stack(
                  children: [
                    _buildList(
                      scrollController: _listController,
                      favoriteIds: favoriteIds,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _sheetController,
            child: panelChild,
            builder: (context, child) {
              final height = constraints.maxHeight * _sheetController.value;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                  child: SizedBox(
                    height: height,
                    child: child,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildList({
    required ScrollController scrollController,
    required Set<String> favoriteIds,
  }) {
    if (widget.locationsAsync.isLoading) {
      return ListView(
        controller: scrollController,
        primary: false,
        padding: const EdgeInsets.fromLTRB(
          16,
          14 + _floatingPillsReservedSpace,
          16,
          16,
        ),
        children: const [LoadingList()],
      );
    }

    if (widget.locations.isEmpty) {
      return ListView(
        controller: scrollController,
        primary: false,
        padding: const EdgeInsets.fromLTRB(
          16,
          16 + _floatingPillsReservedSpace,
          16,
          22,
        ),
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
      primary: false,
      padding: const EdgeInsets.fromLTRB(
        16,
        14 + _floatingPillsReservedSpace,
        16,
        24,
      ),
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
                  widget.onSelectLocation(location);
                  widget.onLocationTap?.call(location);
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({
    required this.screenHeight,
    required this.currentSize,
    required this.minSize,
    required this.maxSize,
    required this.onSizeChanged,
    required this.onSnapNearest,
    required this.countText,
  });

  final double screenHeight;
  final double Function() currentSize;
  final double minSize;
  final double maxSize;
  final ValueChanged<double> onSizeChanged;
  final void Function({double velocity}) onSnapNearest;
  final String countText;

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = -details.delta.dy / screenHeight;
    onSizeChanged((currentSize() + delta).clamp(minSize, maxSize));
  }

  void _onDragEnd(DragEndDetails details) {
    onSnapNearest(velocity: details.primaryVelocity ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Padding(
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
                  decoration: const BoxDecoration(
                    color: Color(0x14F97316),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
