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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);

    final updated = profile.copyWith(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    );

    final success = await ref.read(profileProvider.notifier).updateProfile(
      updated,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      });
    }
  }

  Future<void> _changePhoto() async {
    final authUser = ref.read(currentUserProvider);
    if (authUser == null) return;

    final picked = await ProfilePhotoPicker.show(context);
    if (picked == null) return;

    await ref.read(profileProvider.notifier).uploadPhoto(
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
            padding: const EdgeInsetsGeometry.only(right: 12),
            child: AppButton(
              label: 'Save',
              size: AppButtonSize.small,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
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
            ],
          ),
        ),
      ),
    );
  }
}
