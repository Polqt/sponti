import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_card.dart';

class ExploreBottomPanel extends StatelessWidget {
  const ExploreBottomPanel({
    super.key,
    required this.locationsAsync,
    required this.locations,
    required this.useListView,
    required this.selectedIndex,
    required this.isExpanded,
    required this.bottomInset,
    required this.pageController,
    required this.favoriteIds,
    required this.onExpandChanged,
    required this.onPageChanged,
    required this.onTapLocation,
    required this.onSaveToggle,
  });

  final AsyncValue<List<Location>> locationsAsync;
  final List<Location> locations;
  final bool useListView;
  final int selectedIndex;
  final bool isExpanded;
  final double bottomInset;
  final PageController pageController;
  final Set<String> favoriteIds;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Location> onTapLocation;
  final Future<void> Function(Location location) onSaveToggle;

  @override
  Widget build(BuildContext context) {
    final expandedHeight = MediaQuery.sizeOf(context).height * 0.55;
    final panelHeight = isExpanded ? expandedHeight : 118.0;

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottomInset + 12,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 100) {
            onExpandChanged(false);
          } else if (details.velocity.pixelsPerSecond.dy < -100) {
            onExpandChanged(true);
          }
        },
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: panelHeight,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: SpontiColors.surface.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: SpontiColors.outline.withValues(alpha: 0.72),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onExpandChanged(!isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: SpontiColors.textMuted.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${locations.length} spots found',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SpontiColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Expanded(child: _buildBody(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (locationsAsync.isLoading) {
      return _LoadingCards(isExpanded: isExpanded);
    }

    if (locations.isEmpty) {
      return AppEmptyState(
        emoji: '🔭',
        title: 'Nothing found',
        subtitle: 'Try a different filter combo',
      );
    }

    if (isExpanded) {
      if (useListView) {
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          itemCount: locations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final location = locations[index];
            final isSelected = index == selectedIndex;

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
                isSaved: favoriteIds.contains(location.id),
                onTap: () => onTapLocation(location),
                onSaveToggle: () => onSaveToggle(location),
              ),
            );
          },
        );
      }

      return Column(
        children: [
          SizedBox(
            height: 206,
            child: PageView.builder(
              controller: pageController,
              itemCount: locations.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final location = locations[index];
                final isSelected = index == selectedIndex;

                return Align(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 310,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
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
                      width: 310,
                      variant: LocationCardVariant.compact,
                      isSaved: favoriteIds.contains(location.id),
                      onTap: () => onTapLocation(location),
                      onSaveToggle: () => onSaveToggle(location),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _PageDots(
            itemCount: locations.length,
            selectedIndex: selectedIndex,
          ),
        ],
      );
    }

    final selectedLocation = locations[selectedIndex.clamp(0, locations.length - 1)];

    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onExpandChanged(true),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 200,
            width: 310,
            child: LocationCard(
              location: selectedLocation,
              width: 310,
              variant: LocationCardVariant.compact,
              isSaved: favoriteIds.contains(selectedLocation.id),
              onTap: () => onExpandChanged(true),
              onSaveToggle: () => onSaveToggle(selectedLocation),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < 2; index++) ...[
            _LoadingCard(isExpanded: isExpanded),
            if (index == 0) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 310,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer(
              height: isExpanded ? 120 : 84,
              width: 310,
              borderRadius: 18,
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              const AppShimmer(height: 14, width: 180, borderRadius: 8),
              const SizedBox(height: 8),
              const AppShimmer(height: 12, width: 220, borderRadius: 8),
              const SizedBox(height: 8),
              const AppShimmer(height: 12, width: 96, borderRadius: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.itemCount,
    required this.selectedIndex,
  });

  final int itemCount;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final item in items) ...[
          if (item == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SpontiColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: item == selectedIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: item == selectedIndex
                    ? SpontiColors.primary
                    : SpontiColors.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ],
    );
  }

  List<int?> _buildItems() {
    if (itemCount <= 10) {
      return List<int?>.generate(itemCount, (index) => index);
    }

    final start = (selectedIndex - 3).clamp(0, itemCount - 8);
    final end = (start + 8).clamp(0, itemCount);
    final items = <int?>[];

    if (start > 0) {
      items
        ..add(0)
        ..add(null);
    }

    for (var index = start; index < end; index++) {
      if (index != 0 && index != itemCount - 1) {
        items.add(index);
      }
    }

    if (end < itemCount) {
      items
        ..add(null)
        ..add(itemCount - 1);
    }

    return items.take(10).toList(growable: false);
  }
}
