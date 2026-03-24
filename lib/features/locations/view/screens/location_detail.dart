import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/check_in/view/widgets/check_in_action_button.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_badges.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_about_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_contact_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_hero.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_name_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_photo_gallery_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_stats_strip.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_tags_section.dart';
import 'package:sponti/features/locations/view/widgets/location_hours_dropdown_card.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/reviews/view/widgets/review_action_button.dart';

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
    final checkInState = ref.watch(checkInProvider(location.id)).valueOrNull;
    final liveLocation = ref.watch(locationStreamProvider(location.id)).valueOrNull;
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

    final extraPhotoUrls = location.photoUrls.skip(1).toList(growable: false);
    final hasQuickInfo =
        location.hasWifi ||
        location.isPetFriendly ||
        location.hasParking ||
        location.distanceKm != null;

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: CustomScrollView(
        controller: widget.scrollController,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: LocationDetailHero(location: location)),
          SliverPadding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationDetailInset(
                    top: 18,
                    child: LocationDetailNameSection(location: location),
                  ),
                  LocationDetailInset(
                    top: 18,
                    child: LocationDetailStatsStrip(
                      location: sourceLocation,
                      checkInCount: displayedCheckInCount,
                    ),
                  ),
                  LocationDetailInset(
                    top: 16,
                    child: CheckInActionButton(
                      locationId: location.id,
                      locationName: location.name,
                      isCheckedIn: checkInState?.isCheckedIn ?? false,
                      checkInCount: displayedCheckInCount,
                      onCheckInResult: _handleCheckInResult,
                    ),
                  ),
                  LocationDetailInset(
                    top: 12,
                    child: ReviewActionButton(
                      locationId: location.id,
                      locationName: location.name,
                    ),
                  ),
                  if (hasQuickInfo)
                    LocationDetailInset(
                      top: 20,
                      child: QuickInfoRow(location: location),
                    ),
                  if (extraPhotoUrls.isNotEmpty)
                    LocationPhotoGallerySection(
                      photoUrls: extraPhotoUrls,
                      category: location.category,
                    ),
                  const LocationDetailDivider(top: 24),
                  if (location.description.isNotEmpty) ...[
                    LocationAboutSection(description: location.description),
                    const LocationDetailDivider(top: 20),
                  ],
                  if (location.operatingHours case final hours?) ...[
                    LocationDetailInset(
                      top: 20,
                      child: LocationHoursDropdownCard(hours: hours),
                    ),
                    const LocationDetailDivider(top: 20),
                  ],
                  if (location.hasContact) ...[
                    LocationContactSection(location: location),
                    const LocationDetailDivider(top: 20),
                  ],
                  if (location.tags.isNotEmpty)
                    LocationTagsSection(tags: location.tags),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
