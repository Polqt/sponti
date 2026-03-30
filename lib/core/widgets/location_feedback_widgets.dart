import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/core/theme/app_colors.dart';

enum LocationFeedbackMode { reviews, visited }

class LocationFeedbackHeader extends StatelessWidget {
  const LocationFeedbackHeader({
    super.key,
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

class LocationFeedbackModeSwitcher extends StatelessWidget {
  const LocationFeedbackModeSwitcher({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LocationFeedbackMode selectedMode;
  final ValueChanged<LocationFeedbackMode> onModeSelected;

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
              selected: selectedMode == LocationFeedbackMode.reviews,
              onTap: () => onModeSelected(LocationFeedbackMode.reviews),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ModeChip(
              label: 'visited',
              selected: selectedMode == LocationFeedbackMode.visited,
              onTap: () => onModeSelected(LocationFeedbackMode.visited),
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackSectionLabel extends StatelessWidget {
  const FeedbackSectionLabel(this.text, {super.key});

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

class FeedbackCommentField extends StatelessWidget {
  const FeedbackCommentField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SpontiColors.outline,
          width: 1.3,
        ),
      ),
      child: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: hintText,
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

class FeedbackPhotoList extends StatelessWidget {
  const FeedbackPhotoList({
    super.key,
    required this.existingPhotoUrls,
    required this.pickedPhotos,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemovePickedPhoto,
    this.addLabel = 'add photo',
    this.maxItems,
  });

  final List<String> existingPhotoUrls;
  final List<XFile> pickedPhotos;
  final VoidCallback onAddPhotos;
  final ValueChanged<int> onRemoveExistingPhoto;
  final ValueChanged<int> onRemovePickedPhoto;
  final String addLabel;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final totalItems = existingPhotoUrls.length + pickedPhotos.length;
    final canAddMore = maxItems == null || totalItems < maxItems!;
    final itemCount = totalItems + (canAddMore ? 1 : 0);

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (canAddMore && index == 0) {
            return _AddPhotoTile(
              key: const ValueKey('add-photo-tile'),
              label: addLabel,
              onTap: onAddPhotos,
            );
          }

          final normalizedIndex = canAddMore ? index - 1 : index;
          if (normalizedIndex < existingPhotoUrls.length) {
            return _FeedbackPhotoTile.network(
              key: ValueKey(existingPhotoUrls[normalizedIndex]),
              url: existingPhotoUrls[normalizedIndex],
              onRemove: () => onRemoveExistingPhoto(normalizedIndex),
            );
          }

          final pickedIndex = normalizedIndex - existingPhotoUrls.length;
          return _FeedbackPhotoTile.file(
            key: ValueKey(pickedPhotos[pickedIndex].path),
            file: pickedPhotos[pickedIndex],
            onRemove: () => onRemovePickedPhoto(pickedIndex),
          );
        },
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

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
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
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: SpontiColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
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

class _FeedbackPhotoTile extends StatelessWidget {
  const _FeedbackPhotoTile.network({
    super.key,
    required this.url,
    required this.onRemove,
  })  : file = null,
        isRemote = true;

  const _FeedbackPhotoTile.file({
    super.key,
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
