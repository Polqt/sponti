import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class LocationBottomSheet extends StatefulWidget {
  const LocationBottomSheet({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.selectedCategory,
    required this.favoriteIds,
    required this.bottomInset,
    required this.onTapCategory,
    required this.onTapAllCategories,
    required this.onTapLocation,
    required this.onTapFavorite,
    required this.isExpanded,
    required this.onExpandChanged,
    this.onSheetProgressChanged,
  });

  final List<Location> locations;
  final String? selectedId;
  final LocationCategory? selectedCategory;
  final Set<String> favoriteIds;
  final double bottomInset;
  final ValueChanged<LocationCategory> onTapCategory;
  final VoidCallback onTapAllCategories;
  final ValueChanged<Location> onTapLocation;
  final ValueChanged<Location> onTapFavorite;
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<double>? onSheetProgressChanged;

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  static const _minSize = 0.16;
  static const _maxSize = 0.62;
  static const _expandThreshold = 0.34;
  static const _bottomBarReserve = 86.0;

  late final DraggableScrollableController _sheetController;
  double _chromeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
  }

  @override
  void didUpdateWidget(covariant LocationBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _animateToExpanded(widget.isExpanded);
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
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
      // Controller can throw if detached mid-animation.
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
    final bottomPadding = widget.bottomInset +
        12 +
        (_bottomBarReserve * (1.0 - _chromeProgress.clamp(0.0, 1.0)));

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
                padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      decoration: BoxDecoration(
                        color: SpontiColors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: SpontiColors.outline.withValues(alpha: 0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 2),
                        children: [
                          const _GrabHandle(),
                          _CategoryRow(
                            selectedCategory: widget.selectedCategory,
                            onTapAll: widget.onTapAllCategories,
                            onTapCategory: widget.onTapCategory,
                          ),
                          if (widget.isExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${widget.locations.length} spots found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: SpontiColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          if (widget.locations.isEmpty)
                            const SizedBox.shrink()
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                top: widget.isExpanded ? 4 : 0,
                              ),
                              itemCount: widget.isExpanded
                                  ? widget.locations.length
                                  : 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final location = widget.isExpanded
                                    ? widget.locations[index]
                                    : widget.locations.firstWhere(
                                        (l) => l.id == widget.selectedId,
                                        orElse: () => widget.locations.first,
                                      );
                                final isSelected =
                                    location.id == widget.selectedId;

                                return AnimatedContainer(
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
                                    isSaved: widget.favoriteIds.contains(
                                      location.id,
                                    ),
                                    onTap: () => widget.onTapLocation(location),
                                    onSaveToggle: () =>
                                        widget.onTapFavorite(location),
                                  ),
                                );
                              },
                            ),
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
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: SpontiColors.textMuted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.selectedCategory,
    required this.onTapAll,
    required this.onTapCategory,
  });

  final LocationCategory? selectedCategory;
  final VoidCallback onTapAll;
  final ValueChanged<LocationCategory> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoryChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            color: SpontiColors.primary,
            isSelected: selectedCategory == null,
            onTap: onTapAll,
          ),
          const SizedBox(width: 8),
          for (final category in LocationCategory.values) ...[
            CategoryChip(
              label: category.label,
              icon: category.icon,
              color: Color(category.colorValue),
              isSelected: selectedCategory == category,
              onTap: () => onTapCategory(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

