import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class BottomRailPanel extends StatefulWidget {
  const BottomRailPanel({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.selectedCategory,
    required this.isExpanded,
    required this.bottomInset,
    required this.onExpandChanged,
    required this.onTapCategory,
    required this.onTapLocation,
  });

  final List<Location> locations;
  final String? selectedId;
  final LocationCategory? selectedCategory;
  final bool isExpanded;
  final double bottomInset;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<LocationCategory> onTapCategory;
  final ValueChanged<Location> onTapLocation;

  @override
  State<BottomRailPanel> createState() => _BottomRailPanelState();
}

class _BottomRailPanelState extends State<BottomRailPanel> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(BottomRailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != null &&
        widget.selectedId != oldWidget.selectedId &&
        widget.isExpanded) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final index = widget.locations.indexWhere((l) => l.id == widget.selectedId);
    if (index < 0) return;

    const cardWidth = 200.0;
    const separatorWidth = 12.0;
    final targetOffset = index * (cardWidth + separatorWidth);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: widget.bottomInset + 88,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 100) {
            widget.onExpandChanged(false);
          } else if (details.velocity.pixelsPerSecond.dy < -100) {
            widget.onExpandChanged(true);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onExpandChanged(!widget.isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: SpontiColors.textMuted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          CategoryChip(
                            label: 'All',
                            icon: Icons.grid_view_rounded,
                            color: SpontiColors.primary,
                            isSelected: widget.selectedCategory == null,
                            onTap: () {
                              if (widget.selectedCategory != null) {
                                widget.onTapCategory(widget.selectedCategory!);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          for (final category in LocationCategory.values) ...[
                            CategoryChip(
                              label: category.label,
                              icon: category.icon,
                              color: Color(category.colorValue),
                              isSelected: widget.selectedCategory == category,
                              onTap: () => widget.onTapCategory(category),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: widget.isExpanded && widget.locations.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: SizedBox(
                              height: 184,
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.locations.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final location = widget.locations[index];
                                  final isSelected =
                                      location.id == widget.selectedId;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(
                                                location.category.colorValue,
                                              )
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: LocationCard(
                                      location: location,
                                      width: 200,
                                      onTap: () =>
                                          widget.onTapLocation(location),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
