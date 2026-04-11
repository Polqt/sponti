import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/locations/utils/location_explore_cache.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';

class ReviewActionButton extends ConsumerWidget {
  const ReviewActionButton({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton.outline(
      label: 'Review',
      size: AppButtonSize.medium,
      prefixIcon: Icons.rate_review_outlined,
      onPressed: () async {
        final didChange = await context.push<bool>(
          RouteName.reviewsPath(
            locationId: locationId,
            locationName: locationName,
          ),
        );

        if (didChange != true) {
          return;
        }

        ref.invalidate(reviewsByLocationProvider(locationId));
        ref.invalidate(reviewsStreamProvider(locationId));
        ref.invalidate(myReviewForLocationProvider(locationId));
        ref.invalidate(locationDetailProvider(locationId));
        invalidateLocationExploreRankingCaches(ref.invalidate);
      },
    );
  }
}
