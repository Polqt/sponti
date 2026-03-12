import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/profile/view/widgets/profile_header.dart';
import 'package:sponti/features/profile/view/widgets/profile_photo_picker.dart';
import 'package:sponti/features/profile/view/widgets/profile_stats_card.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final authUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: profileAsync.when(
        loading: () => const _ProfileShimmer(),
        error: (e, _) => AppErrorState(
          message: 'Could not load profile.',
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return AppErrorState(
              message: 'Profile not found.',
              onRetry: () => ref.invalidate(profileProvider),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: SpontiColors.surface,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      ProfileHeader(
                        profile: profile,
                        onEditTap: () => context.push(RouteName.editProfile),
                        onAvatarTap: authUser != null
                            ? () =>
                                  _pickAndUploadPhoto(context, ref, authUser.id)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      ProfileStatsCard(profile: profile),
                      const SizedBox(height: 28),
                      _MenuSection(
                        title: 'My Activity',
                        items: [
                          _MenuItem(
                            icon: Icons.location_on_rounded,
                            label: 'My Check-ins',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.bookmark_rounded,
                            label: 'Saved Spots',
                            onTap: () => context.go(RouteName.favorites),
                          ),
                          _MenuItem(
                            icon: Icons.add_location_alt_rounded,
                            label: 'Suggested Spots',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _MenuSection(
                        title: 'Preferences',
                        items: [
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Privacy',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppButton.destructive(
                          label: 'Sign Out',
                          prefixIcon: Icons.logout_rounded,
                          onPressed: () => _confirmSignOut(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _pickAndUploadPhoto(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final picked = await ProfilePhotoPicker.show(context);
  if (picked == null) return;

  await ref
      .read(profileProvider.notifier)
      .uploadPhoto(
        userId: userId,
        bytes: picked.bytes,
        extension: picked.extension,
      );
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final shouldSignOut =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: SpontiColors.error),
              ),
            ),
          ],
        ),
      ) ??
      false;

  if (!shouldSignOut || !context.mounted) return;

  final signedOut = await ref.read(authProvider.notifier).signOut();
  if (!context.mounted) return;

  if (!signedOut) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign out failed. Please try again.')),
    );
    return;
  }

  ref.invalidate(profileProvider);
  context.go(RouteName.signin);
}


class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionLabel(label: title),
        const SizedBox(height: 12),
        for (final item in items)
          _MenuTile(icon: item.icon, label: item.label, onTap: item.onTap),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: SpontiColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SpontiColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: SpontiColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: SpontiColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(child: AppShimmer.circle(size: 96)),
          const SizedBox(height: 16),
          Center(child: AppShimmer(height: 20, width: 160)),
          const SizedBox(height: 8),
          Center(child: AppShimmer(height: 14, width: 100)),
          const SizedBox(height: 24),
          AppShimmer(height: 76, borderRadius: 16),
          const SizedBox(height: 28),
          for (int i = 0; i < 5; i++) ...[
            AppShimmer(height: 56, borderRadius: 14),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
