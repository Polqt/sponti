import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const double _bottomButtonHeight = 54;

  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _existingPhotoUrls = [];
  final List<XFile> _pickedPhotos = [];

  _ReviewMode _selectedMode = _ReviewMode.reviews;
  int _selectedRating = 5;
  bool _isSaving = false;
  bool _hydratedReview = false;
  String? _hydratedReviewId;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (files.isEmpty || !mounted) return;
    setState(() => _pickedPhotos.addAll(files));
  }

  Future<String?> _uploadPhoto(XFile file) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      final ext = file.path.split('.').last;
      final path =
          'reviews/$userId/${widget.locationId}/${DateTime.now().microsecondsSinceEpoch}.$ext';

      await client.storage.from(SupabaseBuckets.locationPhotos).uploadBinary(
            path,
            await File(file.path).readAsBytes(),
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      return client.storage
          .from(SupabaseBuckets.locationPhotos)
          .getPublicUrl(path);
    } catch (_) {
      return null;
    }
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

    final uploadedUrls = <String>[];
    for (final file in _pickedPhotos) {
      final url = await _uploadPhoto(file);
      if (url != null) uploadedUrls.add(url);
    }

    if (!mounted) return;

    final review = Review(
      id: _hydratedReviewId ?? '',
      locationId: widget.locationId,
      userId: user.id,
      rating: _selectedRating,
      comment: _reviewController.text.trim(),
      photos: [..._existingPhotoUrls, ...uploadedUrls],
      createdAt: DateTime.now(),
    );

    final result = await ref.read(reviewsRepositoryProvider).createReview(review);

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) => context.pop(true),
    );
  }

  void _hydrateReview(Review review) {
    if (_hydratedReviewId == review.id) return;
    _hydratedReviewId = review.id;
    _hydratedReview = true;
    _selectedRating = review.rating;
    _reviewController.text = review.comment;
    _existingPhotoUrls
      ..clear()
      ..addAll(review.photos);
    _pickedPhotos.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final avatarUrl = currentUser?.avatarUrl;
    final displayName = currentUser?.displayName ?? 'You';
    final existingReviewState =
        ref.watch(myReviewForLocationProvider(widget.locationId));

    ref.listen<AsyncValue<Review?>>(
      myReviewForLocationProvider(widget.locationId),
      (previous, next) {
        final review = next.valueOrNull;
        if (review != null && !_hydratedReview) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _hydrateReview(review));
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: SpontiColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              _Header(
                title: widget.locationName.isEmpty
                    ? 'REVIEWS'
                    : widget.locationName.toUpperCase(),
                onClose: () => context.pop(),
              ),
              const SizedBox(height: 18),
              _ModeSwitcher(
                selectedMode: _selectedMode,
                onModeSelected: (mode) {
                  if (mode == _ReviewMode.visited) {
                    context.go(
                      RouteName.checkInPath(
                        locationId: widget.locationId,
                        locationName: widget.locationName,
                      ),
                    );
                    return;
                  }

                  setState(() => _selectedMode = mode);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ComposerHeader(
                        avatarUrl: avatarUrl,
                        displayName: displayName,
                        subtitle: existingReviewState.when(
                          data: (review) =>
                              review == null ? 'Write a review' : 'Edit review',
                          loading: () => 'Loading review...',
                          error: (_, __) => 'Write a review',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionLabel('Rating'),
                      const SizedBox(height: 10),
                      _StarRatingRow(
                        selectedRating: _selectedRating,
                        onRatingSelected: (value) {
                          setState(() => _selectedRating = value);
                        },
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel('Photos'),
                      const SizedBox(height: 10),
                      _PhotoRail(
                        existingPhotoUrls: _existingPhotoUrls,
                        pickedPhotos: _pickedPhotos,
                        onAddPhotos: _pickPhotos,
                        onRemoveExistingPhoto: (index) {
                          setState(() => _existingPhotoUrls.removeAt(index));
                        },
                        onRemovePickedPhoto: (index) {
                          setState(() => _pickedPhotos.removeAt(index));
                        },
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel('What do you think?'),
                      const SizedBox(height: 10),
                      _CommentComposer(controller: _reviewController),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: _bottomButtonHeight,
                child: _BottomSaveButton(
                  isLoading: _isSaving,
                  onTap: _isSaving ? null : _saveReview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ReviewMode { reviews, visited }

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: SpontiColors.textPrimary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: SpontiColors.textPrimary,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final _ReviewMode selectedMode;
  final ValueChanged<_ReviewMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SpontiColors.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'reviews',
              selected: selectedMode == _ReviewMode.reviews,
              onTap: () => onModeSelected(_ReviewMode.reviews),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ModeChip(
              label: 'visited',
              selected: selectedMode == _ReviewMode.visited,
              onTap: () => onModeSelected(_ReviewMode.visited),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SpontiColors.dark : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? SpontiColors.white : SpontiColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerHeader extends StatelessWidget {
  const _ComposerHeader({
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SpontiColors.textSecondary,
        letterSpacing: 0.3,
      ),
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

class _PhotoRail extends StatelessWidget {
  const _PhotoRail({
    required this.existingPhotoUrls,
    required this.pickedPhotos,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemovePickedPhoto,
  });

  final List<String> existingPhotoUrls;
  final List<XFile> pickedPhotos;
  final VoidCallback onAddPhotos;
  final ValueChanged<int> onRemoveExistingPhoto;
  final ValueChanged<int> onRemovePickedPhoto;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _AddPhotoTile(onTap: onAddPhotos),
      for (var index = 0; index < existingPhotoUrls.length; index++)
        _PhotoTile.network(
          url: existingPhotoUrls[index],
          onRemove: () => onRemoveExistingPhoto(index),
        ),
      for (var index = 0; index < pickedPhotos.length; index++)
        _PhotoTile.file(
          file: pickedPhotos[index],
          onRemove: () => onRemovePickedPhoto(index),
        ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => tiles[index],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        decoration: BoxDecoration(
          color: SpontiColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SpontiColors.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 34,
              color: SpontiColors.primary,
            ),
            const SizedBox(height: 6),
            const Text(
              'add photo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SpontiColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile.network({
    required this.url,
    required this.onRemove,
  })  : file = null,
        isRemote = true;

  const _PhotoTile.file({
    required this.file,
    required this.onRemove,
  })  : url = null,
        isRemote = false;

  final String? url;
  final XFile? file;
  final bool isRemote;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final child = isRemote
        ? CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            width: 112,
            height: 130,
          )
        : Image.file(
            File(file!.path),
            width: 112,
            height: 130,
            fit: BoxFit.cover,
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(width: 112, height: 130, child: child),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SpontiColors.outline,
          style: BorderStyle.solid,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 7,
        decoration: InputDecoration(
          hintText: 'what do you think?',
          hintStyle: TextStyle(
            fontSize: 14,
            color: SpontiColors.textMuted.withValues(alpha: 0.8),
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 14,
          color: SpontiColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _BottomSaveButton extends StatelessWidget {
  const _BottomSaveButton({
    required this.onTap,
    required this.isLoading,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isLoading
                  ? SpontiColors.dark.withValues(alpha: 0.72)
                  : SpontiColors.dark,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: SpontiColors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: SpontiColors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'save',
                          style: TextStyle(
                            color: SpontiColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
