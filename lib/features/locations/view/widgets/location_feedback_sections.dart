import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/core/widgets/location_feedback_widgets.dart';
import 'package:sponti/features/reviews/model/review.dart';

class LocationFeedbackReviewColumn extends StatelessWidget {
  const LocationFeedbackReviewColumn({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    required this.existingReviewState,
    required this.selectedRating,
    required this.onRatingSelected,
    required this.existingPhotoUrls,
    required this.pickedPhotos,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemovePickedPhoto,
    required this.controller,
  });

  final String? avatarUrl;
  final String displayName;
  final AsyncValue<Review?> existingReviewState;
  final int selectedRating;
  final ValueChanged<int> onRatingSelected;
  final List<String> existingPhotoUrls;
  final List<XFile> pickedPhotos;
  final VoidCallback onAddPhotos;
  final ValueChanged<int> onRemoveExistingPhoto;
  final ValueChanged<int> onRemovePickedPhoto;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationFeedbackComposerHeader(
          avatarUrl: avatarUrl,
          displayName: displayName,
          subtitle: existingReviewState.when(
            data: (review) =>
                review == null ? 'Write a review' : 'Edit review',
            loading: () => 'Loading review...',
            error: (_, _) => 'Write a review',
          ),
        ),
        const SizedBox(height: 18),
        const FeedbackSectionLabel('Rating'),
        const SizedBox(height: 10),
        LocationFeedbackStarRatingRow(
          selectedRating: selectedRating,
          onRatingSelected: onRatingSelected,
        ),
        const SizedBox(height: 22),
        const FeedbackSectionLabel('Photos'),
        const SizedBox(height: 10),
        FeedbackPhotoList(
          existingPhotoUrls: existingPhotoUrls,
          pickedPhotos: pickedPhotos,
          onAddPhotos: onAddPhotos,
          onRemoveExistingPhoto: onRemoveExistingPhoto,
          onRemovePickedPhoto: onRemovePickedPhoto,
        ),
        const SizedBox(height: 22),
        const FeedbackSectionLabel('What do you think?'),
        const SizedBox(height: 10),
        FeedbackCommentField(
          controller: controller,
          hintText: 'What do you think?',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class LocationFeedbackVisitedColumn extends StatelessWidget {
  const LocationFeedbackVisitedColumn({
    super.key,
    required this.isCheckedIn,
    required this.existingPhotoUrls,
    required this.pickedPhotos,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemovePickedPhoto,
    required this.controller,
    required this.onDelete,
  });

  final bool isCheckedIn;
  final List<String> existingPhotoUrls;
  final List<XFile> pickedPhotos;
  final VoidCallback onAddPhotos;
  final ValueChanged<int> onRemoveExistingPhoto;
  final ValueChanged<int> onRemovePickedPhoto;
  final TextEditingController controller;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCheckedIn) ...[
          const LocationFeedbackEditableCheckInBanner(),
          const SizedBox(height: 18),
        ],
        const FeedbackSectionLabel('Photos'),
        const SizedBox(height: 10),
        FeedbackPhotoList(
          existingPhotoUrls: existingPhotoUrls,
          pickedPhotos: pickedPhotos,
          onAddPhotos: onAddPhotos,
          onRemoveExistingPhoto: onRemoveExistingPhoto,
          onRemovePickedPhoto: onRemovePickedPhoto,
          addLabel: 'add photo',
          maxItems: 1,
        ),
        const SizedBox(height: 24),
        const FeedbackSectionLabel('Add a note'),
        const SizedBox(height: 10),
        FeedbackCommentField(
          controller: controller,
          hintText: 'What did you think? Share your experience...',
        ),
        if (isCheckedIn) ...[
          const SizedBox(height: 24),
          AppButton.destructive(
            label: 'Remove check-in',
            prefixIcon: Icons.delete_outline_rounded,
            size: AppButtonSize.medium,
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

class LocationFeedbackEditableCheckInBanner extends StatelessWidget {
  const LocationFeedbackEditableCheckInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpontiColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: SpontiColors.secondary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You already checked in here. You can edit your note or photo anytime.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: SpontiColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationFeedbackComposerHeader extends StatelessWidget {
  const LocationFeedbackComposerHeader({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    required this.subtitle,
  });

  final String? avatarUrl;
  final String displayName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final initials = displayName.trim().isEmpty ? '?' : displayName.trim()[0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: SpontiColors.surfaceVariant,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SpontiColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SpontiColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: SpontiColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LocationFeedbackStarRatingRow extends StatelessWidget {
  const LocationFeedbackStarRatingRow({
    super.key,
    required this.selectedRating,
    required this.onRatingSelected,
  });

  final int selectedRating;
  final ValueChanged<int> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = rating <= selectedRating;

        return IconButton(
          onPressed: () => onRatingSelected(rating),
          iconSize: 36,
          splashRadius: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
            color: isSelected ? SpontiColors.accent : SpontiColors.textSecondary,
          ),
        );
      }),
    );
  }
}
