import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_hours_dropdown_card.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class LocationDetail extends ConsumerStatefulWidget {
  const LocationDetail({
    super.key,
    required this.location,
    required this.scrollController,
    required this.bottomPadding,
  });

  final Location location;
  final ScrollController scrollController;
  final double bottomPadding;

  @override
  ConsumerState<LocationDetail> createState() => _LocationDetailState();
}

class _LocationDetailState extends ConsumerState<LocationDetail> {
  int? _optimisticCheckInCount;

  void _handleCheckInResult(bool? didCheckIn, int previousCount) {
    if (!mounted || didCheckIn == null) return;

    setState(() {
      _optimisticCheckInCount = didCheckIn
          ? previousCount + 1
          : (previousCount > 0 ? previousCount - 1 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final categoryColor = Color(location.category.colorValue);
    final checkInState = ref.watch(checkInProvider(location.id)).valueOrNull;
    final isCheckedIn = checkInState?.isCheckedIn ?? false;
    final liveLocation = ref
        .watch(locationStreamProvider(location.id))
        .valueOrNull;
    final liveCheckInCount = ref
        .watch(locationCheckInCountProvider(location.id))
        .valueOrNull;
    final sourceLocation = liveLocation ?? location;
    final displayedCheckInCount =
        _optimisticCheckInCount ??
        liveCheckInCount ??
        sourceLocation.checkInCount;

    if (_optimisticCheckInCount != null &&
        (liveCheckInCount == _optimisticCheckInCount ||
            sourceLocation.checkInCount == _optimisticCheckInCount)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _optimisticCheckInCount = null);
      });
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: CustomScrollView(
        controller: widget.scrollController,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _LocationHero(location: location)),
          SliverPadding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            sliver: SliverToBoxAdapter(
              child: _LocationDetailSections(
                location: location,
                sourceLocation: sourceLocation,
                categoryColor: categoryColor,
                isCheckedIn: isCheckedIn,
                displayedCheckInCount: displayedCheckInCount,
                onCheckInResult: _handleCheckInResult,
              ),
            ),
          ),
        ],
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
                          if (location.isHiddenGem) const _HiddenGemPill(),
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
  const _HiddenGemPill();

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
          Icon(
            Icons.auto_awesome_rounded,
            size: 13,
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
    );
  }
}

class _LocationDetailSections extends StatelessWidget {
  const _LocationDetailSections({
    required this.location,
    required this.sourceLocation,
    required this.categoryColor,
    required this.isCheckedIn,
    required this.displayedCheckInCount,
    required this.onCheckInResult,
  });

  final Location location;
  final Location sourceLocation;
  final Color categoryColor;
  final bool isCheckedIn;
  final int displayedCheckInCount;
  final void Function(bool?, int) onCheckInResult;

  bool get _hasQuickInfo =>
      location.hasWifi ||
      location.isPetFriendly ||
      location.hasParking ||
      location.distanceKm != null;

  @override
  Widget build(BuildContext context) {
    final extraPhotoUrls = location.photoUrls.skip(1).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionPadding(top: 18, child: _NameSection(location: location)),
        _SectionPadding(
          top: 18,
          child: _StatsStrip(
            location: sourceLocation,
            checkInCount: displayedCheckInCount,
          ),
        ),
        _SectionPadding(
          top: 16,
          child: _CheckInButton(
            location: location,
            isCheckedIn: isCheckedIn,
            checkInCount: displayedCheckInCount,
            onCheckInResult: onCheckInResult,
          ),
        ),
        _SectionPadding(top: 12, child: _ReviewButton(location: location)),
        if (_hasQuickInfo)
          _SectionPadding(top: 20, child: QuickInfoRow(location: location)),
        if (extraPhotoUrls.isNotEmpty)
          _SectionPadding(
            top: 24,
            horizontal: 0,
            child: _PhotoGallery(
              photoUrls: extraPhotoUrls,
              category: location.category,
              categoryColor: categoryColor,
            ),
          ),
        const _SectionDivider(top: 24),
        if (location.description.isNotEmpty) ...[
          _SectionPadding(
            top: 20,
            child: _AboutSection(description: location.description),
          ),
          const _SectionDivider(top: 20),
        ],
        if (location.operatingHours case final hours?) ...[
          _SectionPadding(
            top: 20,
            child: LocationHoursDropdownCard(hours: hours),
          ),
          const _SectionDivider(top: 20),
        ],
        if (location.hasContact) ...[
          _SectionPadding(top: 20, child: _ContactSection(location: location)),
          const _SectionDivider(top: 20),
        ],
        if (location.tags.isNotEmpty)
          _SectionPadding(top: 20, child: _TagsSection(tags: location.tags)),
      ],
    );
  }
}

class _SectionPadding extends StatelessWidget {
  const _SectionPadding({
    required this.top,
    required this.child,
    this.horizontal = 20,
  });

  final double top;
  final double horizontal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 0),
      child: child,
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.top});

  final double top;

  @override
  Widget build(BuildContext context) {
    return _SectionPadding(
      top: top,
      child: const Divider(color: SpontiColors.outline, height: 1),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SpontiColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

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
            const Icon(
              Icons.star_rounded,
              size: 14,
              color: SpontiColors.accent,
            ),
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.location, required this.checkInCount});

  final Location location;
  final int checkInCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          value: SpontiFormatter.compactNumber(location.reviewCount),
          label: 'Reviews',
          color: SpontiColors.primary,
        ),
        const _StatDivider(),
        _StatItem(
          value: SpontiFormatter.compactNumber(checkInCount),
          label: 'Check-ins',
          color: SpontiColors.secondary,
        ),
        const _StatDivider(),
        _StatItem(
          value: SpontiFormatter.rating(location.rating),
          label: 'Rating',
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
    required this.color,
  });

  final String value;
  final String label;
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

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({
    required this.location,
    required this.isCheckedIn,
    required this.checkInCount,
    required this.onCheckInResult,
  });

  final Location location;
  final bool isCheckedIn;
  final int checkInCount;
  final void Function(bool?, int) onCheckInResult;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          RouteName.checkInPath(
            locationId: location.id,
            locationName: location.name,
          ),
        );
        onCheckInResult(result, checkInCount);
      },
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

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    return AppButton.outline(
      label: 'Review',
      size: AppButtonSize.medium,
      prefixIcon: Icons.rate_review_outlined,
      onPressed: () => context.push(
        RouteName.reviewsPath(
          locationId: location.id,
          locationName: location.name,
        ),
      ),
    );
  }
}

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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle('Photos'),
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
              final photoUrl = photoUrls[index];
              return ClipRRect(
                key: ValueKey(photoUrl),
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
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

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('About'),
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

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final rows = <({IconData icon, String value})>[
      if (location.contactNumber case final contactNumber?)
        (icon: Icons.phone_outlined, value: contactNumber),
      if (location.websiteUrl case final websiteUrl?)
        (icon: Icons.language_rounded, value: websiteUrl),
      if (location.instagramHandle case final instagramHandle?)
        (icon: Icons.camera_alt_outlined, value: '@$instagramHandle'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Contact'),
        const SizedBox(height: 12),
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _ContactRow(icon: rows[index].icon, value: rows[index].value),
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

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Tags'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) => _TagChip(key: ValueKey(tag), tag: tag))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({super.key, required this.tag});

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
