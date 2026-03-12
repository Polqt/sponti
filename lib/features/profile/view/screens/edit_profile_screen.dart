import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/profile/view/widgets/profile_header.dart';
import 'package:sponti/features/profile/view/widgets/profile_photo_picker.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);

    final normalizedUsername = _usernameController.text.trim().replaceFirst(
      RegExp(r'^@+'),
      '',
    );
    final normalizedBio = _bioController.text.trim();

    final updated = profile.copyWith(
      fullName: _nameController.text.trim(),
      username: normalizedUsername,
      bio: normalizedBio,
    );

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(updated);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
  }

  Future<void> _changePhoto() async {
    final authUser = ref.read(currentUserProvider);
    if (authUser == null) return;

    final picked = await ProfilePhotoPicker.show(context);
    if (picked == null) return;

    await ref
        .read(profileProvider.notifier)
        .uploadPhoto(
          userId: authUser.id,
          bytes: picked.bytes,
          extension: picked.extension,
        );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      appBar: AppBar(
        backgroundColor: SpontiColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              label: 'Save',
              size: AppButtonSize.small,
              isFullWidth: false,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile != null)
                  Center(
                    child: ProfileHeader(
                      profile: profile,
                      onAvatarTap: _changePhoto,
                    ),
                  ),
                const SizedBox(height: 32),
                const _FieldLabel('Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(hintText: 'Enter your full name'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Name is required';
                    }
                    if (text.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Username'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  maxLength: 20,
                  decoration: _decoration(
                    hintText: 'Choose a username',
                    prefixText: '@',
                    counterText: '',
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    if (raw.isEmpty) return null;
                    final username = raw.replaceFirst(RegExp(r'^@+'), '');
                    final isValid = RegExp(
                      r'^[a-zA-Z0-9_.]{3,20}$',
                    ).hasMatch(username);
                    if (!isValid) {
                      return 'Use 3-20 letters, numbers, "_" or "."';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Bio'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  maxLength: 160,
                  decoration: _decoration(
                    hintText: 'Tell people about yourself',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration({
  required String hintText,
  String? prefixText,
  String? counterText,
}) {
  const radius = BorderRadius.all(Radius.circular(12));
  const border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: SpontiColors.outline),
  );

  return InputDecoration(
    hintText: hintText,
    prefixText: prefixText,
    counterText: counterText,
    filled: true,
    fillColor: SpontiColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: SpontiColors.primary, width: 1.4),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: SpontiColors.error),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: SpontiColors.error, width: 1.4),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: SpontiColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
