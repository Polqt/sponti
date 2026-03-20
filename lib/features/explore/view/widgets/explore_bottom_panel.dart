import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/explore/view/widgets/explore_loading.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class ExploreBottomPanel extends StatefulWidget {
  const ExploreBottomPanel({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.selectedIndex,
    required this.bottomInset,
    required this.favoriteIds,
    required this.onExpandChanged,
    required this.onTapLocation,
    required this.onSaveToggle,
    this.onSheetProgressChanged,
    this.onClose,
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
  final ValueChanged<Location> onTapLocation;
  final Future<void> Function(Location location) onSaveToggle;
  final ValueChanged<double>? onSheetProgressChanged;
  final VoidCallback? onClose;
  final bool edgeToEdge;

  @override
  State<ExploreBottomPanel> createState() => _ExploreBottomPanelState();
}

class _ExploreBottomPanelState extends State<ExploreBottomPanel> {
  static const _minSize = 0.16;
  static const _maxSize = 0.62;
  static const _expandThreshold = 0.34;
  static const _bottomBarReserve = 86.0;
  static const _dismissEpsilon = 0.006;

  late final DraggableScrollableController _sheetController;
  double _chromeProgress = 0.0;
  bool _wasAboveMin = false;
  bool _isDismissing = false;
  int? _lastSelectedIndex;
  final _itemKeys = <String, GlobalKey>{};
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_handleSheetControllerChanged);
    _scheduleScrollSelectedIntoView();
  }

  @override
  void didUpdateWidget(covariant ExploreBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _animateToExpanded(widget.isExpanded);
    }

    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.locations.length != widget.locations.length) {
      _scheduleScrollSelectedIntoView();
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_handleSheetControllerChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _handleSheetControllerChanged() {
    final close = widget.onClose;
    if (close == null) return;
    if (!_sheetController.isAttached) return;
    if (!mounted) return;

    final size = _sheetController.size;
    final aboveMinNow = size > (_minSize + 0.02);
    if (aboveMinNow) _wasAboveMin = true;

    // If the user drags the sheet down to its collapsed snap point,
    // dismiss the sheet entirely instead of leaving it minimized.
    final atMin = size <= (_minSize + _dismissEpsilon);
    if (_wasAboveMin && atMin && !_isDismissing) {
      _isDismissing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        close();
      });
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
    if (!mounted) return;
    if (widget.locations.isEmpty) return;
    final index = widget.selectedIndex.clamp(0, widget.locations.length - 1);
    if (_lastSelectedIndex == index) return;
    _lastSelectedIndex = index;

    final locationId = widget.locations[index].id;
    final key = _itemKeys[locationId];
    final ctx = key?.currentContext;
    if (ctx == null) {
      // Key/context may not exist yet (first build). Try again next frame.
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

  Future<void> _animateToExpanded(bool expanded) async {
    if (!_sheetController.isAttached) return;
    final target = expanded ? _maxSize : _minSize;
    try {
      await _sheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // No-op: controller can throw if detached mid-animation.
    }
  }

  void _handleNotification(DraggableScrollableNotification notification) {
    final progress = ((notification.extent - _minSize) / (_maxSize - _minSize))
        .clamp(0.0, 1.0);
    widget.onSheetProgressChanged?.call(progress);

    if ((progress - _chromeProgress).abs() > 0.02) {
      setState(() => _chromeProgress = progress);
    } else {
      _chromeProgress = progress;
    }

    final expandedNow = notification.extent >= _expandThreshold;
    if (expandedNow != widget.isExpanded) {
      widget.onExpandChanged(expandedNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset dismiss guards if the sheet is shown again.
    if (_isDismissing) {
      _isDismissing = false;
      _wasAboveMin = false;
    }

    // When rendered edge-to-edge, avoid any transient bottom padding that can
    // appear before the first drag notification updates [_chromeProgress].
    final chrome = (widget.edgeToEdge ? 1.0 : _chromeProgress).clamp(0.0, 1.0);
    final bottomPadding =
        (widget.edgeToEdge ? 0.0 : (widget.bottomInset + 12)) +
        (_bottomBarReserve * (1.0 - chrome));
    final horizontalPadding = widget.edgeToEdge ? 0.0 : 12.0;
    final borderRadius = widget.edgeToEdge
        ? const BorderRadius.vertical(top: Radius.circular(24))
        : BorderRadius.circular(24);

    return Positioned.fill(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          _handleNotification(notification);
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _sheetController,
          minChildSize: _minSize,
          maxChildSize: _maxSize,
          initialChildSize: widget.isExpanded ? _maxSize : _minSize,
          snap: true,
          snapSizes: const [_minSize, _maxSize],
          builder: (context, scrollController) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: SpontiColors.surface.withValues(alpha: 0.7),
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: SpontiColors.outline.withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        children: [
                          _SheetHeader(
                            showCount: widget.isExpanded,
                            countText: '${widget.locations.length} spots found',
                          ),
                          _buildBody(context),
                        ],
                      ),
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

  Widget _buildBody(BuildContext context) {
    if (widget.locationsAsync.isLoading) {
      return const LoadingList();
    }

    if (widget.locations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: AppEmptyState(
          emoji: '🔭',
          title: 'Nothing found',
          subtitle: 'Try a different filter combo',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6),
      itemCount: widget.locations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Color(location.category.colorValue)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: LocationCard(
              location: location,
              variant: LocationCardVariant.fullWidth,
              isSaved: widget.favoriteIds.contains(location.id),
              onTap: () => widget.onTapLocation(location),
              onSaveToggle: () => widget.onSaveToggle(location),
            ),
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.showCount, required this.countText});

  final bool showCount;
  final String countText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SpontiColors.textMuted.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showCount) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                countText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SpontiColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
