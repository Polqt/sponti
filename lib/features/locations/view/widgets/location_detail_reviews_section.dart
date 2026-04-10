import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/view/widgets/location_detail_section.dart';
import 'package:sponti/features/reviews/view/widgets/review_card.dart';

import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';

class LocationDetailReviewsSection extends ConsumerWidget {
  const LocationDetailReviewsSection({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsByLocationProvider(locationId));
    final notifier = ref.read(reviewsByLocationProvider(locationId).notifier);

    return LocationDetailSection(
      title: 'Reviews',
      top: 24,
      child: SizedBox(
        width: double.infinity,
        child: reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: SpontiColors.primary),
            ),
          ),
          error: (_, _) => const _ReviewsMessageCard(
            message: 'Could not load reviews right now.',
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const _ReviewsMessageCard(
                message: 'No reviews yet. Be the first to share your thoughts.',
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int index = 0; index < reviews.length; index++) ...[
                  ReviewCard(
                    key: ValueKey<String>(reviews[index].id),
                    review: reviews[index],
                    locationName: locationName,
                  ),
                  if (index != reviews.length - 1) const SizedBox(height: 18),
                ],
                if (notifier.hasMore) ...[
                  const SizedBox(height: 18),
                  _LoadMoreReviewsButton(onTap: notifier.fetchNextPage),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadMoreReviewsButton extends StatefulWidget {
  const _LoadMoreReviewsButton({required this.onTap});

  final Future<String?> Function() onTap;

  @override
  State<_LoadMoreReviewsButton> createState() => _LoadMoreReviewsButtonState();
}

class _LoadMoreReviewsButtonState extends State<_LoadMoreReviewsButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: _loading
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _loading = true);
                final error = await widget.onTap();
                if (!mounted) return;
                setState(() => _loading = false);
                if (error != null) {
                  messenger.showSnackBar(SnackBar(content: Text(error)));
                }
              },
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SpontiColors.primary,
                ),
              )
            : const Text(
                'Load more reviews',
                style: TextStyle(
                  color: SpontiColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

class _ReviewsMessageCard extends StatelessWidget {
  const _ReviewsMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: SpontiColors.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}
