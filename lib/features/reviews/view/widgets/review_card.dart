import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpontiColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarStrip(rating: review.rating),
              const SizedBox(width: 8),
              Text(
                timeago.format(review.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: SpontiColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment.isEmpty ? 'No comment yet' : review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: SpontiColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (review.hasPhotos) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: review.photos[index],
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarStrip extends StatelessWidget {
  const _StarStrip({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: isFilled ? SpontiColors.accent : SpontiColors.textMuted,
        );
      }),
    );
  }
}
