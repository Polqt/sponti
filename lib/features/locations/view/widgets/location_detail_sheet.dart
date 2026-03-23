import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/detail_info.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_header.dart';
import 'package:sponti/features/locations/view/widgets/location_hours_dropdown_card.dart';
import 'package:sponti/features/locations/view/widgets/tags_selector.dart';

Future<void> showLocationDetailSheet(
  BuildContext context, {
  required Location location,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _LocationDetailSheet(location: location),
  );
}

class _LocationDetailSheet extends StatefulWidget {
  const _LocationDetailSheet({required this.location});

  final Location location;

  @override
  State<_LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<_LocationDetailSheet> {
  static const double _midSize = 0.76;
  static const double _maxSize = 0.96;

  late final DraggableScrollableController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _snapToNearest({double velocity = 0}) {
    if (!_controller.isAttached) return;
    final size = _controller.size;

    // Fast swipe down OR dragged well below midpoint → let modal dismiss itself.
    // We animate to 0 which triggers shouldCloseOnMinExtent to close the modal.
    final shouldDismiss = velocity > 500 || size < _midSize * 0.65;

    if (shouldDismiss) {
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInCubic,
      );
      return;
    }

    // Fast swipe up → max
    if (velocity < -500) {
      _controller.animateTo(
        _maxSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    // Snap to nearest of mid / max
    final target = (size - _midSize).abs() <= (size - _maxSize).abs()
        ? _midSize
        : _maxSize;
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: topPadding + 12),
      child: DraggableScrollableSheet(
        controller: _controller,
        expand: false,
        initialChildSize: _midSize,
        minChildSize: 0.0,
        maxChildSize: _maxSize,
        snap: true,
        snapSizes: const [_midSize, _maxSize],
        snapAnimationDuration: const Duration(milliseconds: 300),
        builder: (context, sheetScrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: SpontiColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // ── Handle ──────────────────────────────────────────────────
                // Dragging here moves the sheet via _controller.jumpTo().
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) {
                    if (!_controller.isAttached) return;
                    final delta = -d.delta.dy / screenHeight;
                    _controller.jumpTo(
                      (_controller.size + delta).clamp(0.0, _maxSize),
                    );
                  },
                  onVerticalDragEnd: (d) =>
                      _snapToNearest(velocity: d.primaryVelocity ?? 0),
                  child: const _SheetHandle(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SizedBox.shrink(
                        child: ListView(
                          controller: sheetScrollController,
                          physics: const NeverScrollableScrollPhysics(),
                        ),
                      ),
                      NotificationListener<ScrollNotification>(
                        onNotification: (_) => true, // absorb, don't bubble
                        child: CustomScrollView(
                          controller: _scrollController,
                          primary: false,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _LocationHero(location: widget.location),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                bottomPadding + 28,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _LocationDetailSections(
                                  location: widget.location,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: SpontiColors.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _LocationHero extends StatelessWidget {
  const _LocationHero({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (location.hasPhotos)
                CachedNetworkImage(
                  imageUrl: location.primaryPhoto,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => CategoryShimmer(color: categoryColor),
                  errorWidget: (_, _, _) => CategoryGradient(
                    category: location.category,
                    emojiFontSize: 56,
                  ),
                )
              else
                CategoryGradient(
                  category: location.category,
                  emojiFontSize: 56,
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategoryPill(
                            location: location,
                            categoryColor: categoryColor,
                          ),
                          if (location.isHiddenGem)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: SpontiColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hidden gem',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: SpontiColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OpenStatusPill(isOpen: location.isOpenNow),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.location, required this.categoryColor});

  final Location location;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(location.category.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            location.category.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDetailSections extends StatelessWidget {
  const _LocationDetailSections({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(location.category.colorValue);
    final hasQuickInfo =
        location.hasWifi ||
        location.isPetFriendly ||
        location.hasParking ||
        location.distanceKm != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationNameSection(location: location, categoryColor: categoryColor),
        if (hasQuickInfo) ...[
          const SizedBox(height: 16),
          QuickInfoRow(location: location),
        ],
        const SizedBox(height: 16),
        StatsRow(location: location),
        if (location.photoUrls.length > 1) ...[
          const SizedBox(height: 20),
          _LocationPhotoGallery(
            photoUrls: location.photoUrls.skip(1).toList(growable: false),
            category: location.category,
            categoryColor: categoryColor,
          ),
        ],
        if (location.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            children: [
              Text(
                location.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SpontiColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
        if (location.operatingHours != null) ...[
          const SizedBox(height: 16),
          LocationHoursDropdownCard(hours: location.operatingHours!),
        ],
        const SizedBox(height: 16),
        if (location.hasContact) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Contact',
            icon: Icons.call_outlined,
            children: [
              if (location.contactNumber != null)
                InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: location.contactNumber!,
                ),
              if (location.websiteUrl != null) ...[
                if (location.contactNumber != null) const SizedBox(height: 14),
                InfoRow(
                  icon: Icons.language_rounded,
                  label: 'Website',
                  value: location.websiteUrl!,
                ),
              ],
              if (location.instagramHandle != null) ...[
                const SizedBox(height: 14),
                InfoRow(
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  value: '${location.instagramHandle}',
                ),
              ],
            ],
          ),
        ],
        if (location.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          TagsDisplay(tags: location.tags),
        ],
      ],
    );
  }
}

class _LocationPhotoGallery extends StatelessWidget {
  const _LocationPhotoGallery({
    required this.photoUrls,
    required this.category,
    required this.categoryColor,
  });

  final List<String> photoUrls;
  final LocationCategory category;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 16,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'More photos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: SpontiColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photoUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  imageUrl: photoUrls[index],
                  width: 176,
                  height: 132,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => SizedBox(
                    width: 176,
                    height: 132,
                    child: CategoryShimmer(color: categoryColor),
                  ),
                  errorWidget: (_, _, _) => SizedBox(
                    width: 176,
                    height: 132,
                    child: CategoryGradient(category: category),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
