import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/core/services/storage_upload_service.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/core/widgets/location_feedback_widgets.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/locations/utils/location_explore_cache.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/locations/view/widgets/location_feedback_sections.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _existingPhotoUrls = <String>[];
  final List<XFile> _pickedPhotos = <XFile>[];

  late final ProviderSubscription<AsyncValue<Review?>> _reviewSubscription;

  String? _hydratedReviewId;
  int _selectedRating = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reviewSubscription = ref.listenManual<AsyncValue<Review?>>(
      myReviewForLocationProvider(widget.locationId),
      (_, next) {
        final review = next.valueOrNull;
        if (review == null || review.id == _hydratedReviewId || !mounted) {
          return;
        }
        _hydrateReview(review);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _reviewSubscription.close();
    _reviewController.dispose();
    super.dispose();
  }

  void _hydrateReview(Review review) {
    setState(() {
      _hydratedReviewId = review.id;
      _selectedRating = review.rating;
      _reviewController.text = review.comment;
      _existingPhotoUrls
        ..clear()
        ..addAll(review.photos);
      _pickedPhotos.clear();
    });
  }

  Future<void> _pickPhotos() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty || !mounted) return;

    setState(() => _pickedPhotos.addAll(files));
  }

  void _removeExistingPhoto(int index) {
    setState(() => _existingPhotoUrls.removeAt(index));
  }

  void _removePickedPhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  Future<void> _saveReview() async {
    if (_isSaving) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save a review.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final uploadResult = await ref.read(storageUploadServiceProvider).uploadLocationPhotos(
          files: _pickedPhotos,
          locationId: widget.locationId,
          folder: LocationPhotoUploadFolder.reviews,
        );
    if (!mounted) return;

    final review = Review(
      id: _hydratedReviewId ?? '',
      locationId: widget.locationId,
      userId: user.id,
      rating: _selectedRating,
      comment: _reviewController.text.trim(),
      photos: [..._existingPhotoUrls, ...uploadResult.uploadedUrls],
      createdAt: DateTime.now(),
    );

    final repository = ref.read(reviewsRepositoryProvider);
    final result = _hydratedReviewId == null
        ? await repository.createReview(review)
        : await repository.updateReview(review);

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) async {
        ref.invalidate(myReviewForLocationProvider(widget.locationId));
        ref.invalidate(reviewsByLocationProvider(widget.locationId));
        ref.invalidate(reviewsStreamProvider(widget.locationId));
        ref.invalidate(locationDetailProvider(widget.locationId));
        invalidateLocationExploreRankingCaches(ref.invalidate);
        if (uploadResult.failedMessages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uploadResult.failedMessages.first)),
          );
        }
        await _showReviewSuccessDialog(updated: _hydratedReviewId != null);
        if (mounted) {
          context.pop(true);
        }
      },
    );
  }

  Future<void> _showReviewSuccessDialog({required bool updated}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(updated ? 'Review updated' : 'Review sent'),
        content: Text(
          updated
              ? 'Your review changes have been saved.'
              : 'Your review has been sent successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final existingReviewState =
        ref.watch(myReviewForLocationProvider(widget.locationId));

    return Scaffold(
      backgroundColor: SpontiColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              LocationFeedbackHeader(
                title: widget.locationName.isEmpty
                    ? 'REVIEWS'
                    : widget.locationName.toUpperCase(),
                onClose: () => context.pop(),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: LocationFeedbackReviewColumn(
                    avatarUrl: currentUser?.avatarUrl,
                    displayName: currentUser?.displayName ?? 'You',
                    existingReviewState: existingReviewState,
                    selectedRating: _selectedRating,
                    onRatingSelected: (value) {
                      setState(() => _selectedRating = value);
                    },
                    existingPhotoUrls: _existingPhotoUrls,
                    pickedPhotos: _pickedPhotos,
                    onAddPhotos: _pickPhotos,
                    onRemoveExistingPhoto: _removeExistingPhoto,
                    onRemovePickedPhoto: _removePickedPhoto,
                    controller: _reviewController,
                  ),
                ),
              ),
              AppButton(
                label: _isSaving ? 'Saving...' : 'Save review',
                prefixIcon: Icons.check_circle_rounded,
                size: AppButtonSize.large,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
