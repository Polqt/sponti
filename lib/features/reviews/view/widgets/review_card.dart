import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewCard extends ConsumerWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(review.userId));
    final reviewer = profileAsync.valueOrNull;
    final reviewerName = _displayNameFor(reviewer);
    final headline = review.hasPhotos
        ? '$reviewerName added ${review.photos.length} photo${review.photos.length == 1 ? '' : 's'}'
        : '$reviewerName left a review';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ReviewerAvatar(
          reviewer: reviewer,
          fallbackName: reviewerName,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review.hasPhotos) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SpontiColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ReviewPhotoStack(photoUrls: review.photos),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: SpontiColors.white,
                  borderRadius: BorderRadius.circular(22),
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
                        Expanded(
                          child: Text(
                            reviewerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: SpontiColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(review.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: SpontiColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StarStrip(rating: review.rating),
                    const SizedBox(height: 12),
                    Text(
                      review.comment.isEmpty ? 'No comment yet' : review.comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SpontiColors.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _displayNameFor(UserProfile? reviewer) {
    if (reviewer != null && reviewer.displayName.trim().isNotEmpty) {
      return reviewer.displayName;
    }

    final shortened = review.userId.length > 8
        ? review.userId.substring(0, 8)
        : review.userId;
    return '@$shortened';
  }
}

class _ReviewerAvatar extends StatelessWidget {
  const _ReviewerAvatar({
    required this.reviewer,
    required this.fallbackName,
  });

  final UserProfile? reviewer;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final initials = fallbackName.trim().isEmpty
        ? '?'
        : fallbackName.replaceFirst('@', '').trim()[0].toUpperCase();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: reviewer?.hasAvatar == true
            ? CachedNetworkImage(
                imageUrl: reviewer!.avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _AvatarFallback(initials: initials),
              )
            : _AvatarFallback(initials: initials),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SpontiColors.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: SpontiColors.textSecondary,
        ),
      ),
    );
  }
}

class _ReviewPhotoStack extends StatelessWidget {
  const _ReviewPhotoStack({
    required this.photoUrls,
  });

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = photoUrls.take(3).toList(growable: false);
    const double cardWidth = 172;
    const double cardHeight = 196;
    const double overlap = 28;

    return SizedBox(
      height: cardHeight,
      width: cardWidth + ((visiblePhotos.length - 1) * overlap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int index = visiblePhotos.length - 1; index >= 0; index--)
            Positioned(
              left: index * overlap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: visiblePhotos[index],
                  width: cardWidth,
                  height: cardHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
