import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/core/theme/app_colors.dart';

class ProfilePhotoPicker {
  ProfilePhotoPicker._();

  static Future<PickedPhoto?> show(BuildContext context) async {
    return showModalBottomSheet<PickedPhoto>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PhotoPickerSheet(),
    );
  }
}

class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.extension});
  final Uint8List bytes;
  final String extension;
}

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet();

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final extension = (ext == 'png') ? 'png' : 'jpg';

    if (context.mounted) {
      Navigator.of(
        context,
      ).pop(PickedPhoto(bytes: bytes, extension: extension));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsGeometry.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SpontiColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Change Profile Photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 20),

            _PickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Library',
              onTap: () => _pick(context, ImageSource.gallery),
            ),

            const SizedBox(height: 12),

            _PickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              onTap: () => _pick(context, ImageSource.camera),
            ),

            const SizedBox(height: 12),

            _PickerOption(
              icon: Icons.close_rounded,
              label: 'Cancel',
              isDestructive: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? SpontiColors.textMuted
        : SpontiColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: SpontiColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
