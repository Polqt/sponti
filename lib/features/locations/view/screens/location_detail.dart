import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_about_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_contact_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_hero.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_hero_actions.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_name_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_photo_gallery_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_reviews_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_stats_strip.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_tags_section.dart';
import 'package:sponti/features/locations/view/widgets/location_hours_dropdown_card.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/reviews/view/widgets/review_action_button.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';

class LocationDetailPage extends ConsumerStatefulWidget {
  const LocationDetailPage({
    super.key,
    required this.locationId,
  });

  final String locationId;

  @override
  ConsumerState<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends ConsumerState<LocationDetailPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationDetailProvider(widget.locationId));
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      appBar: AppBar(
        backgroundColor: SpontiColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Location'),
      ),
      body: locationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SpontiColors.primary),
        ),
        error: (error, _) => _LocationDetailErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(locationDetailProvider(widget.locationId)),
        ),
        data: (location) => LocationDetail(
          location: location,
          scrollController: _scrollController,
          bottomPadding: bottomPadding,
        ),
      ),
    );
  }
}

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

  void _handleCheckInResult(bool didCheckIn, int previousCount) {
    if (!mounted) return;

    setState(() {
      _optimisticCheckInCount = didCheckIn
          ? previousCount + 1
          : (previousCount > 0 ? previousCount - 1 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final liveLocation = ref
        .watch(locationStreamProvider(location.id))
        .valueOrNull;
    final liveReviews = ref.watch(reviewsStreamProvider(location.id)).valueOrNull;
    final sourceLocation = liveLocation ?? location;
    final displayedReviewCount = liveReviews?.length ?? sourceLocation.reviewCount;
    final displayedRating = switch (liveReviews) {
      null => sourceLocation.rating,
      [] => 0.0,
      final reviews => reviews.fold<double>(
            0,
            (sum, review) => sum + review.rating,
          ) /
          reviews.length,
    };
    final displayedCheckInCount =
        _optimisticCheckInCount ?? sourceLocation.checkInCount;

    if (_optimisticCheckInCount != null &&
        sourceLocation.checkInCount == _optimisticCheckInCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _optimisticCheckInCount = null);
      });
    }

    final extraPhotoUrls = sourceLocation.photoUrls.skip(1).toList(growable: false);
    final hasQuickInfo =
        sourceLocation.hasWifi ||
        sourceLocation.isPetFriendly ||
        sourceLocation.hasParking ||
        sourceLocation.distanceKm != null;

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: CustomScrollView(
        controller: widget.scrollController,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: LocationDetailHero(
              location: sourceLocation,
              actionButtons: LocationDetailHeroActions(
                locationId: location.id,
                checkInCount: displayedCheckInCount,
                onCheckInResult: _handleCheckInResult,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationDetailInset(
                    top: 18,
                    child: LocationDetailNameSection(
                      location: sourceLocation,
                      rating: displayedRating,
                      reviewCount: displayedReviewCount,
                    ),
                  ),
                  LocationDetailInset(
                    top: 18,
                    child: LocationDetailStatsStrip(
                      reviewCount: displayedReviewCount,
                      rating: displayedRating,
                      checkInCount: displayedCheckInCount,
                    ),
                  ),
                  LocationDetailInset(
                    top: 16,
                    child: ReviewActionButton(
                      locationId: location.id,
                      locationName: sourceLocation.name,
                    ),
                  ),
                  LocationDetailReviewsSection(locationId: location.id),
                  if (hasQuickInfo)
                    LocationDetailInset(
                      top: 20,
                      child: QuickInfoRow(location: sourceLocation),
                    ),
                  if (extraPhotoUrls.isNotEmpty)
                    LocationPhotoGallerySection(
                      photoUrls: extraPhotoUrls,
                      category: sourceLocation.category,
                    ),
                  const LocationDetailDivider(top: 24),
                  if (sourceLocation.description.isNotEmpty) ...[
                    LocationAboutSection(description: sourceLocation.description),
                    const LocationDetailDivider(top: 20),
                  ],
                  if (sourceLocation.operatingHours case final hours?) ...[
                    LocationDetailInset(
                      top: 20,
                      child: LocationHoursDropdownCard(hours: hours),
                    ),
                    const LocationDetailDivider(top: 20),
                  ],
                  if (sourceLocation.hasContact) ...[
                    LocationContactSection(location: sourceLocation),
                    const LocationDetailDivider(top: 20),
                  ],
                  if (sourceLocation.tags.isNotEmpty)
                    LocationTagsSection(tags: sourceLocation.tags),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDetailErrorState extends StatelessWidget {
  const _LocationDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AppErrorState(message: message),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        ),
      ],
    );
  }
}
