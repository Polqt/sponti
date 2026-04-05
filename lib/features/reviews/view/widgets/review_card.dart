import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';
import 'package:timeago/timeago.dart' as timeago;

void _invalidateReviewProviders(WidgetRef ref, String locationId) {
  ref.invalidate(reviewsByLocationProvider(locationId));
  ref.invalidate(reviewsStreamProvider(locationId));
  ref.invalidate(myReviewForLocationProvider(locationId));
  ref.invalidate(locationDetailProvider(locationId));
}

class ReviewCard extends ConsumerStatefulWidget {
  const ReviewCard({
    super.key,
    required this.review,
    required this.locationName,
  });

  final Review review;
  final String locationName;

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  bool _isDeleting = false;

  Future<void> _openEdit() async {
    final didChange = await context.push<bool>(
      RouteName.reviewsPath(
        locationId: widget.review.locationId,
        locationName: widget.locationName,
      ),
    );
    if (didChange == true && mounted) {
      _invalidateReviewProviders(ref, widget.review.locationId);
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this review?'),
        content: const Text(
          'Are you sure you want to delete this review? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: SpontiColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final result =
        await ref.read(reviewsRepositoryProvider).deleteReview(widget.review.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        _invalidateReviewProviders(ref, widget.review.locationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final profileAsync = ref.watch(userProfileProvider(review.userId));
    final reviewer = profileAsync.valueOrNull;
    final reviewerName = _displayNameFor(reviewer);
    final headline = review.hasPhotos
        ? '$reviewerName added ${review.photos.length} photo${review.photos.length == 1 ? '' : 's'}'
        : '$reviewerName left a review';

    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner =
        currentUserId != null && currentUserId == review.userId;

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
                _ReviewPhotoStack(
                  photoUrls: review.photos,
                ),
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
                        if (isOwner) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: 'Edit review',
                            onPressed: _isDeleting ? null : _openEdit,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: _isDeleting
                                  ? SpontiColors.textMuted
                                  : SpontiColors.primary,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: 'Delete review',
                            onPressed: _isDeleting ? null : _confirmAndDelete,
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SpontiColors.error,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: SpontiColors.error,
                                  ),
                          ),
                        ],
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

    final shortened = widget.review.userId.length > 8
        ? widget.review.userId.substring(0, 8)
        : widget.review.userId;
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openReviewPhotoGallery(
                    context,
                    photoUrls,
                    index,
                  ),
                  borderRadius: BorderRadius.circular(20),
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
              ),
            ),
        ],
      ),
    );
  }
}

void _openReviewPhotoGallery(
  BuildContext context,
  List<String> allUrls,
  int initialIndex,
) {
  if (allUrls.isEmpty) return;
  final safeIndex = initialIndex.clamp(0, allUrls.length - 1);
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _ReviewPhotosViewer(
        photos: allUrls,
        initialIndex: safeIndex,
      );
    },
  );
}

class _ReviewPhotosViewer extends StatefulWidget {
  const _ReviewPhotosViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_ReviewPhotosViewer> createState() => _ReviewPhotosViewerState();
}

class _ReviewPhotosViewerState extends State<_ReviewPhotosViewer> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              itemBuilder: (context, i) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: widget.photos[i],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: SpontiColors.primary,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
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
