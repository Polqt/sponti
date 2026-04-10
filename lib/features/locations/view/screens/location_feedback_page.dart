import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/core/services/storage_upload_service.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/core/widgets/location_feedback_widgets.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/locations/view/widgets/location_feedback_sections.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';

class LocationFeedbackPage extends ConsumerStatefulWidget {
  const LocationFeedbackPage({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.initialMode,
  });

  final String locationId;
  final String locationName;
  final LocationFeedbackMode initialMode;

  @override
  ConsumerState<LocationFeedbackPage> createState() =>
      _LocationFeedbackPageState();
}

class _LocationFeedbackPageState extends ConsumerState<LocationFeedbackPage> {
  final TextEditingController _checkInNoteController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _existingVisitedPhotoUrls = <String>[];
  final List<XFile> _pickedVisitedPhotos = <XFile>[];
  final List<String> _existingReviewPhotoUrls = <String>[];
  final List<XFile> _pickedReviewPhotos = <XFile>[];
  late final ProviderSubscription<AsyncValue<CheckInState>>
      _checkInSubscription;
  late final ProviderSubscription<AsyncValue<Review?>> _reviewSubscription;

  late LocationFeedbackMode _activeMode;
  String? _hydratedCheckInId;
  String? _hydratedReviewId;
  int _selectedRating = 5;
  bool _isSavingCheckIn = false;
  bool _isSavingReview = false;
  bool _justCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.initialMode;
    _checkInSubscription = ref.listenManual<AsyncValue<CheckInState>>(
      checkInProvider(widget.locationId),
      (_, next) {
        final myCheckIn = next.valueOrNull?.myCheckIn;
        if (myCheckIn == null || myCheckIn.id == _hydratedCheckInId || !mounted) {
          return;
        }
        _hydrateCheckIn(myCheckIn);
      },
      fireImmediately: true,
    );
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
    _checkInSubscription.close();
    _reviewSubscription.close();
    _checkInNoteController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _hydrateCheckIn(CheckIn checkIn) {
    setState(() {
      _hydratedCheckInId = checkIn.id;
      _checkInNoteController.text = checkIn.note ?? '';
      _existingVisitedPhotoUrls
        ..clear()
        ..addAll(checkIn.photos);
      _pickedVisitedPhotos.clear();
    });
  }

  void _hydrateReview(Review review) {
    setState(() {
      _hydratedReviewId = review.id;
      _selectedRating = review.rating;
      _reviewController.text = review.comment;
      _existingReviewPhotoUrls
        ..clear()
        ..addAll(review.photos);
      _pickedReviewPhotos.clear();
    });
  }

  Future<void> _pickVisitedPhotos() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty || !mounted) return;

    setState(() => _pickedVisitedPhotos.addAll(files));
  }

  Future<void> _pickReviewPhotos() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty || !mounted) return;

    setState(() => _pickedReviewPhotos.addAll(files));
  }

  void _removeVisitedExistingPhoto(int index) {
    setState(() => _existingVisitedPhotoUrls.removeAt(index));
  }

  void _removeVisitedPickedPhoto(int index) {
    setState(() => _pickedVisitedPhotos.removeAt(index));
  }

  void _removeReviewExistingPhoto(int index) {
    setState(() => _existingReviewPhotoUrls.removeAt(index));
  }

  void _removeReviewPickedPhoto(int index) {
    setState(() => _pickedReviewPhotos.removeAt(index));
  }

  Future<void> _saveCheckIn() async {
    if (_isSavingCheckIn) return;

    setState(() => _isSavingCheckIn = true);
    final note = _checkInNoteController.text.trim();
    final uploadResult = await ref.read(storageUploadServiceProvider).uploadLocationPhotos(
      files: _pickedVisitedPhotos,
      locationId: widget.locationId,
      folder: LocationPhotoUploadFolder.checkIns,
    );
    if (!mounted) return;

    final checkInPhotos = [
      ..._existingVisitedPhotoUrls,
      ...uploadResult.uploadedUrls,
    ];

    final notifier = ref.read(checkInProvider(widget.locationId).notifier);
    final success = await notifier.checkIn(
      note: note.isEmpty ? null : note,
      photos: checkInPhotos,
    );

    if (!mounted) return;
    setState(() => _isSavingCheckIn = false);

    if (uploadResult.failedMessages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uploadResult.failedMessages.first),
        ),
      );
    }
    if (!success) return;
    setState(() => _justCheckedIn = true);
    context.pop(true);
  }

  Future<void> _deleteCheckIn() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Remove check-in?'),
        content: const Text(
          'This will remove your check-in from this location.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSavingCheckIn = true);
    final notifier = ref.read(checkInProvider(widget.locationId).notifier);
    final success = await notifier.deleteCheckIn();
    if (!mounted) return;
    setState(() => _isSavingCheckIn = false);
    if (success) {
      context.pop(false);
    }
  }

  Future<void> _saveReview() async {
    if (_isSavingReview) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save a review.')),
      );
      return;
    }

    setState(() => _isSavingReview = true);

    final uploadResult = await ref.read(storageUploadServiceProvider).uploadLocationPhotos(
      files: _pickedReviewPhotos,
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
      photos: [..._existingReviewPhotoUrls, ...uploadResult.uploadedUrls],
      createdAt: DateTime.now(),
    );

    final repository = ref.read(reviewsRepositoryProvider);
    final result = _hydratedReviewId == null
        ? await repository.createReview(review)
        : await repository.updateReview(review);

    if (!mounted) return;
    setState(() => _isSavingReview = false);

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
        if (uploadResult.failedMessages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadResult.failedMessages.first),
            ),
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

  void _onModeSelected(LocationFeedbackMode mode) {
    if (mode == _activeMode) return;
    setState(() => _activeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final checkInState =
        ref.watch(checkInProvider(widget.locationId)).valueOrNull ??
        const CheckInState();
    final currentUser = ref.watch(currentUserProvider);
    final avatarUrl = currentUser?.avatarUrl;
    final displayName = currentUser?.displayName ?? 'You';
    final existingReviewState =
        ref.watch(myReviewForLocationProvider(widget.locationId));
    final isCheckedIn = !_justCheckedIn && checkInState.isCheckedIn;

    return Scaffold(
      backgroundColor: SpontiColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              LocationFeedbackHeader(
                title: widget.locationName.isEmpty
                    ? 'LOCATION FEEDBACK'
                    : widget.locationName.toUpperCase(),
                onClose: () => context.pop(),
              ),
              const SizedBox(height: 18),
              LocationFeedbackModeSwitcher(
                selectedMode: _activeMode,
                onModeSelected: _onModeSelected,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _activeMode == LocationFeedbackMode.reviews
                        ? LocationFeedbackReviewColumn(
                            key: const ValueKey('reviews-column'),
                            avatarUrl: avatarUrl,
                            displayName: displayName,
                            existingReviewState: existingReviewState,
                            selectedRating: _selectedRating,
                            onRatingSelected: (value) {
                              setState(() => _selectedRating = value);
                            },
                            existingPhotoUrls: _existingReviewPhotoUrls,
                            pickedPhotos: _pickedReviewPhotos,
                            onAddPhotos: _pickReviewPhotos,
                            onRemoveExistingPhoto: _removeReviewExistingPhoto,
                            onRemovePickedPhoto: _removeReviewPickedPhoto,
                            controller: _reviewController,
                          )
                        : LocationFeedbackVisitedColumn(
                            key: const ValueKey('visited-column'),
                            isCheckedIn: isCheckedIn,
                            existingPhotoUrls: _existingVisitedPhotoUrls,
                            pickedPhotos: _pickedVisitedPhotos,
                            onAddPhotos: _pickVisitedPhotos,
                            onRemoveExistingPhoto: _removeVisitedExistingPhoto,
                            onRemovePickedPhoto: _removeVisitedPickedPhoto,
                            controller: _checkInNoteController,
                            onDelete: _isSavingCheckIn ? null : _deleteCheckIn,
                          ),
                  ),
                ),
              ),
              AppButton(
                label: _activeMode == LocationFeedbackMode.reviews
                    ? (_isSavingReview ? 'Saving...' : 'Save review')
                    : (_isSavingCheckIn
                          ? 'Saving...'
                          : (isCheckedIn ? 'Update check-in' : 'Save')),
                prefixIcon: Icons.check_circle_rounded,
                size: AppButtonSize.large,
                isLoading: _activeMode == LocationFeedbackMode.reviews
                    ? _isSavingReview
                    : _isSavingCheckIn,
                onPressed: _activeMode == LocationFeedbackMode.reviews
                    ? (_isSavingReview ? null : _saveReview)
                    : (_isSavingCheckIn ? null : _saveCheckIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
