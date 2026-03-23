import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_hours_dropdown_card.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

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

    final shouldDismiss = velocity > 500 || size < _midSize * 0.65;

    if (shouldDismiss) {
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInCubic,
      );
      return;
    }

    if (velocity < -500) {
      _controller.animateTo(
        _maxSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }

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
                // ── Handle ────────────────────────────────────────────────
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
                        onNotification: (_) => true,
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
                                0,
                                0,
                                0,
                                bottomPadding + 28,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _LocationDetailBody(
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

// ── Handle ─────────────────────────────────────────────────────────────────────

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

// ── Hero image ─────────────────────────────────────────────────────────────────

class _LocationHero extends StatelessWidget {
  const _LocationHero({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(location.category.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 210,
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
              // Bottom gradient scrim
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _CategoryPill(
                            location: location,
                            categoryColor: categoryColor,
                          ),
                          if (location.isHiddenGem)
                            _HiddenGemPill(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: categoryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(location.category.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
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

class _HiddenGemPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 13, color: SpontiColors.accent),
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
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _LocationDetailBody extends ConsumerWidget {
  const _LocationDetailBody({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = Color(location.category.colorValue);
    final checkInState = ref.watch(checkInProvider(location.id)).valueOrNull;
    final isCheckedIn = checkInState?.isCheckedIn ?? false;

    final hasQuickInfo = location.hasWifi ||
        location.isPetFriendly ||
        location.hasParking ||
        location.distanceKm != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name + meta ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: _NameSection(location: location),
        ),

        // ── Stats ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: _StatsStrip(location: location),
        ),

        // ── Check-in CTA ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _CheckInButton(
            location: location,
            isCheckedIn: isCheckedIn,
          ),
        ),

        // ── Quick amenity badges ─────────────────────────────────────────
        if (hasQuickInfo) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: QuickInfoRow(location: location),
          ),
        ],

        // ── Photo gallery ────────────────────────────────────────────────
        if (location.photoUrls.length > 1) ...[
          const SizedBox(height: 24),
          _PhotoGallery(
            photoUrls: location.photoUrls.skip(1).toList(growable: false),
            category: location.category,
            categoryColor: categoryColor,
          ),
        ],

        // ── Divider ──────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Divider(color: SpontiColors.outline, height: 1),
        ),

        // ── About ─────────────────────────────────────────────────────────
        if (location.description.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _AboutSection(description: location.description),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Divider(color: SpontiColors.outline, height: 1),
          ),
        ],

        // ── Hours ─────────────────────────────────────────────────────────
        if (location.operatingHours != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: LocationHoursDropdownCard(hours: location.operatingHours!),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Divider(color: SpontiColors.outline, height: 1),
          ),
        ],

        // ── Contact ───────────────────────────────────────────────────────
        if (location.hasContact) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _ContactSection(location: location),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Divider(color: SpontiColors.outline, height: 1),
          ),
        ],

        // ── Tags ──────────────────────────────────────────────────────────
        if (location.tags.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _TagsSection(tags: location.tags),
          ),
        ],
      ],
    );
  }
}

// ── Name section ──────────────────────────────────────────────────────────────

class _NameSection extends StatelessWidget {
  const _NameSection({required this.location});
  final Location location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                location.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            if (location.isVerified) ...[
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: SpontiColors.info,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: SpontiColors.accent),
            const SizedBox(width: 3),
            Text(
              SpontiFormatter.rating(location.rating),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SpontiColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${SpontiFormatter.reviewCount(location.reviewCount)})',
              style: const TextStyle(
                fontSize: 13,
                color: SpontiColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: SpontiColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              location.priceRange.label,
              style: const TextStyle(
                fontSize: 13,
                color: SpontiColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: SpontiColors.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location.address,
                style: const TextStyle(
                  fontSize: 13,
                  color: SpontiColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Stats strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends ConsumerWidget {
  const _StatsStrip({required this.location});
  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live stream — falls back to the initial location value while connecting.
    final live = ref.watch(locationStreamProvider(location.id)).valueOrNull;
    final src = live ?? location;

    return Row(
      children: [
        _StatItem(
          value: SpontiFormatter.compactNumber(src.reviewCount),
          label: 'Reviews',
          icon: Icons.reviews_outlined,
          color: SpontiColors.primary,
        ),
        const _StatDivider(),
        _StatItem(
          value: SpontiFormatter.compactNumber(src.checkInCount),
          label: 'Check-ins',
          icon: Icons.pin_drop_outlined,
          color: SpontiColors.secondary,
        ),
        const _StatDivider(),
        _StatItem(
          value: SpontiFormatter.rating(src.rating),
          label: 'Rating',
          icon: Icons.star_outline_rounded,
          color: SpontiColors.accent,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SpontiColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: SpontiColors.outline,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ── Check-in button ───────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({
    required this.location,
    required this.isCheckedIn,
  });

  final Location location;
  final bool isCheckedIn;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        RouteName.checkInPath(
          locationId: location.id,
          locationName: location.name,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 50,
        decoration: BoxDecoration(
          color: isCheckedIn
              ? SpontiColors.secondary.withValues(alpha: 0.1)
              : SpontiColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCheckedIn
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: isCheckedIn ? SpontiColors.secondary : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isCheckedIn ? 'Visited' : 'Check in',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isCheckedIn ? SpontiColors.secondary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo gallery ─────────────────────────────────────────────────────────────

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Photos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SpontiColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: photoUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: photoUrls[index],
                  width: 172,
                  height: 130,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => SizedBox(
                    width: 172,
                    height: 130,
                    child: CategoryShimmer(color: categoryColor),
                  ),
                  errorWidget: (_, _, _) => SizedBox(
                    width: 172,
                    height: 130,
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

// ── About ─────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: SpontiColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: SpontiColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Contact ───────────────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.location});
  final Location location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: SpontiColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        if (location.contactNumber != null)
          _ContactRow(
            icon: Icons.phone_outlined,
            value: location.contactNumber!,
          ),
        if (location.websiteUrl != null) ...[
          if (location.contactNumber != null) const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.language_rounded,
            value: location.websiteUrl!,
          ),
        ],
        if (location.instagramHandle != null) ...[
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.camera_alt_outlined,
            value: '@${location.instagramHandle}',
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SpontiColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: SpontiColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Tags ──────────────────────────────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: SpontiColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _TagChip(tag: tag)).toList(),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textSecondary,
        ),
      ),
    );
  }
}
