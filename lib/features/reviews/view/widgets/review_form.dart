import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';

class ReviewForm extends StatefulWidget {
  const ReviewForm({
    super.key,
    required this.locationName,
    this.authorName = 'Your account',
    this.postingDestination = 'Posting publicly across Google',
  });

  final String locationName;
  final String authorName;
  final String postingDestination;

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.locationName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            _ReviewAuthorHeader(
              authorName: widget.authorName,
              postingDestination: widget.postingDestination,
            ),
            const SizedBox(height: 28),
            _StarRatingRow(
              selectedRating: _selectedRating,
              onRatingSelected: (value) {
                setState(() => _selectedRating = value);
              },
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Add photos & videos',
              variant: AppButtonVariant.secondary,
              prefixIcon: Icons.add_photo_alternate_outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Choose a rating first, then add a review.',
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            AppButton(
              label: 'Post',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.large,
              onPressed: _selectedRating == 0 ? null : () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewAuthorHeader extends StatelessWidget {
  const _ReviewAuthorHeader({
    required this.authorName,
    required this.postingDestination,
  });

  final String authorName;
  final String postingDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = authorName.trim().isEmpty ? '?' : authorName.trim()[0];

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: SpontiColors.primary,
          child: Text(
            initials.toUpperCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: SpontiColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                postingDestination,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Icon(
          Icons.info_outline,
          color: SpontiColors.textSecondary,
          size: 30,
        ),
      ],
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.selectedRating,
    required this.onRatingSelected,
  });

  final int selectedRating;
  final ValueChanged<int> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = rating <= selectedRating;

        return IconButton(
          onPressed: () => onRatingSelected(rating),
          iconSize: 40,
          splashRadius: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
            color: isSelected
                ? SpontiColors.accent
                : SpontiColors.textSecondary,
          ),
        );
      }),
    );
  }
}
