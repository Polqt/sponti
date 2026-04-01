import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/view/widgets/profile_header.dart';
import 'package:sponti/features/profile/view/widgets/profile_photo_picker.dart';
import 'package:sponti/features/profile/view/widgets/profile_stats_card.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class _AnimatedFadeIn extends StatefulWidget {
  const _AnimatedFadeIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final viewedUserId = userId ?? authUser?.id;
    final isOwnProfile = viewedUserId != null && viewedUserId == authUser?.id;
    final profileAsync = viewedUserId == null || viewedUserId.isEmpty
        ? const AsyncValue<UserProfile?>.data(null)
        : isOwnProfile
        ? ref.watch(profileProvider)
        : ref.watch(userProfileProvider(viewedUserId));
    final statsAsync = viewedUserId == null || viewedUserId.isEmpty
        ? const AsyncValue<UserStats?>.data(null)
        : ref.watch(userStatsProvider(viewedUserId));

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: profileAsync.when(
        loading: () => const _ProfileShimmer(),
        error: (e, _) => AppErrorState(
          message: 'Could not load profile.',
          onRetry: () => _refreshProfile(ref, viewedUserId, isOwnProfile),
        ),
        data: (profile) {
          if (profile == null) {
            return AppErrorState(
              message: 'Profile not found.',
              onRetry: () => _refreshProfile(ref, viewedUserId, isOwnProfile),
            );
          }

          final resolvedProfile = _mergeProfileStats(
            profile,
            statsAsync.valueOrNull,
          );

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: SpontiColors.surface,
                elevation: 0,
                pinned: false,
                automaticallyImplyLeading: !isOwnProfile,
                leading: isOwnProfile
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.pop(),
                      ),
                title: isOwnProfile ? null : const Text('Profile'),
                toolbarHeight: isOwnProfile ? 0 : kToolbarHeight,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _AnimatedFadeIn(
                        delay: Duration.zero,
                        child: ProfileHeader(
                          profile: resolvedProfile,
                          onAvatarTap: isOwnProfile && authUser != null
                              ? () => _pickAndUploadPhoto(
                                  context,
                                  ref,
                                  authUser.id,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AnimatedFadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: ProfileStatsCard(profile: resolvedProfile),
                      ),
                      if (isOwnProfile) ...[
                        const SizedBox(height: 32),
                        _AnimatedFadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: _MenuSection(
                            title: 'My Activity',
                            items: [
                              _MenuItem(
                                icon: Icons.location_on_rounded,
                                iconColor: SpontiColors.primary,
                                label: 'My Check-ins',
                                onTap: () => context.push(RouteName.myCheckIns),
                              ),
                              _MenuItem(
                                icon: Icons.bookmark_rounded,
                                iconColor: SpontiColors.primary,
                                label: 'Saved Spots',
                                onTap: () => context.go(RouteName.favorites),
                              ),
                              _MenuItem(
                                icon: Icons.add_location_alt_rounded,
                                iconColor: SpontiColors.secondary,
                                label: 'Suggested Spots',
                                onTap: () =>
                                    context.push(RouteName.suggestSpot),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AnimatedFadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: _MenuSection(
                            title: 'Settings',
                            items: [
                              _MenuItem(
                                icon: Icons.edit_rounded,
                                iconColor: SpontiColors.secondary,
                                label: 'Edit Profile',
                                onTap: () =>
                                    context.push(RouteName.editProfile),
                              ),
                              _MenuItem(
                                icon: Icons.logout_rounded,
                                iconColor: SpontiColors.error,
                                label: 'Sign Out',
                                onTap: () => _confirmSignOut(context, ref),
                              ),
                            ],
                          ),
                        ),
                      ],
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

UserProfile _mergeProfileStats(UserProfile profile, UserStats? stats) {
  if (stats == null) {
    return profile;
  }

  return profile.copyWith(
    checkInCount: stats.checkInCount,
    favoritesCount: stats.favoritesCount,
    spotsSuggested: stats.spotsSuggested,
  );
}

void _refreshProfile(WidgetRef ref, String? userId, bool isOwnProfile) {
  if (isOwnProfile) {
    ref.invalidate(profileProvider);
  } else if (userId != null && userId.isNotEmpty) {
    ref.invalidate(userProfileProvider(userId));
  }

  if (userId != null && userId.isNotEmpty) {
    ref.invalidate(userStatsProvider(userId));
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
        contentType: picked.contentType,
      )
      .then((errorMessage) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage ?? 'Profile photo updated successfully.',
            ),
          ),
        );
      });
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

  ref.invalidate(authProvider);
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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _MenuTile(
                    icon: items[i].icon,
                    iconColor: items[i].iconColor,
                    label: items[i].label,
                    onTap: items[i].onTap,
                  ),
                  if (i < items.length - 1)
                    Container(
                      height: 1,
                      margin: EdgeInsets.zero,
                      color: SpontiColors.outline.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
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
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? SpontiColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.05),
        highlightColor: color.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: SpontiColors.textMuted.withValues(alpha: 0.5),
              ),
            ],
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
