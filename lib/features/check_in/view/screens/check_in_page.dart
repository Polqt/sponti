import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _noteController = TextEditingController();
  XFile? _pickedPhoto;
  // Prevents the "already checked in" banner from flashing during pop animation.
  bool _justCheckedIn = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (file != null) setState(() => _pickedPhoto = file);
  }

  void _removePhoto() => setState(() => _pickedPhoto = null);

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    String? photoUrl;

    if (_pickedPhoto != null) {
      photoUrl = await _uploadPhoto(_pickedPhoto!);
      if (photoUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed, saving without photo.')),
        );
      }
    }

    final notifier = ref.read(checkInProvider(widget.locationId).notifier);
    final success = await notifier.checkIn(
      note: note.isEmpty ? null : note,
      photoUrl: photoUrl,
    );

    if (!mounted) return;
    if (success) {
      setState(() => _justCheckedIn = true);
      Navigator.of(context).pop(true);
    }
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
    final notifier = ref.read(checkInProvider(widget.locationId).notifier);
    final success = await notifier.deleteCheckIn();
    if (success && mounted) Navigator.of(context).pop(false);
  }

  /// Uploads the picked photo to Supabase Storage and returns the public URL.
  Future<String?> _uploadPhoto(XFile file) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      final ext = file.path.split('.').last;
      final path = 'check_ins/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('location-photos').uploadBinary(
        path,
        await File(file.path).readAsBytes(),
        fileOptions: const FileOptions(upsert: true),
      );

      return client.storage.from('location-photos').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkInProvider(widget.locationId));
    final checkInState = state.valueOrNull;
    final isLoading = checkInState?.isLoading ?? false;
    // Guard: don't flip to the "already checked in" banner while we're
    // still in the pop animation after a successful check-in.
    final isAlreadyCheckedIn =
        !_justCheckedIn && (checkInState?.isCheckedIn ?? false);

    return Scaffold(
      backgroundColor: SpontiColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              _Header(
                title: widget.locationName.toUpperCase(),
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              _ModeSwitcher(
                selected: _ReviewMode.visited,
                onReviewsTap: () {
                  context.go(
                    RouteName.reviewsPath(
                      locationId: widget.locationId,
                      locationName: widget.locationName,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAlreadyCheckedIn) ...[
                        _AlreadyCheckedInBanner(
                          onDelete: isLoading ? null : _deleteCheckIn,
                        ),
                      ] else ...[
                        _SectionLabel('Add a photo'),
                        const SizedBox(height: 10),
                        _PhotoPicker(
                          photo: _pickedPhoto,
                          onPick: _pickPhoto,
                          onRemove: _removePhoto,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Add a note'),
                        const SizedBox(height: 10),
                        _NoteField(controller: _noteController),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
              AppButton(
                label: isLoading ? 'Saving...' : 'Save',
                prefixIcon: Icons.check_circle_rounded,
                size: AppButtonSize.large,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
    required this.selected,
    required this.onReviewsTap,
  });

  final _ReviewMode selected;
  final VoidCallback onReviewsTap;

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
              selected: selected == _ReviewMode.reviews,
              onTap: onReviewsTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ModeChip(
              label: 'visited',
              selected: selected == _ReviewMode.visited,
              onTap: () {},
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

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 8,
      style: const TextStyle(
        fontSize: 15,
        color: SpontiColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: 'What did you think? Share your experience…',
        hintStyle: TextStyle(
          fontSize: 14,
          color: SpontiColors.textMuted.withValues(alpha: 0.7),
          height: 1.5,
        ),
        filled: true,
        fillColor: SpontiColors.surfaceVariant,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpontiColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  final XFile? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(photo!.path),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SpontiColors.dark.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: SpontiColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SpontiColors.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: SpontiColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add a photo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SpontiColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyCheckedInBanner extends StatelessWidget {
  const _AlreadyCheckedInBanner({required this.onDelete});
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SpontiColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SpontiColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 36,
                  color: SpontiColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "You've been here!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SpontiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You already checked in to this location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: SpontiColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton.destructive(
          label: 'Remove check-in',
          prefixIcon: Icons.delete_outline_rounded,
          size: AppButtonSize.medium,
          onPressed: onDelete,
        ),
      ],
    );
  }
}
